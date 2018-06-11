--[[
	The reconciler uses the virtual DOM generated by components to create a real
	tree of Roblox instances.

	The reonciler has three basic operations:
	* mount (previously reify)
	* reconcile
	* unmount (previously teardown)

	Mounting is the process of creating new components. This is first
	triggered when the user calls `Roact.mount` on an element. This is where the
	structure of the component tree is built, later used and modified by the
	reconciliation and unmounting steps.

	Reconciliation accepts an existing concrete instance tree (created by mount)
	along with a new element that describes the desired tree. The reconciler
	will do the minimum amount of work required to update tree's components to
	match the new element, sometimes invoking mount to create new branches.

	Unmounting destructs for the tree. It will crawl through the tree,
	destroying nodes from the bottom up.

	Much of the reconciler's work is done by Component, which is the base for
	all stateful components in Roact. Components can trigger reconciliation (and
	implicitly, unmounting) via state updates that come with their own caveats.
]]

local Core = require(script.Parent.Core)
local Event = require(script.Parent.Event)
local Change = require(script.Parent.Change)
local getDefaultPropertyValue = require(script.Parent.getDefaultPropertyValue)
local SingleEventManager = require(script.Parent.SingleEventManager)
local Symbol = require(script.Parent.Symbol)
local Heapstack = require(script.Parent.Heapstack)

local isInstanceHandle = Symbol.named("isInstanceHandle")

local NO_CHILDREN = {}
local DEFAULT_SOURCE = "\t<Use Roact.setGlobalConfig with the 'elementTracing' key to enable detailed tracebacks>"

--[[
	Sets the value of a reference to a new rendered object.
	Correctly handles both function-style and object-style refs.
]]
local function applyRef(ref, rbx)
	if not ref then
		return
	end

	if type(ref) == "table" then
		ref.current = rbx
	else
		ref(rbx)
	end
end

local function finalizeRbx(rbx, key, parent)
	-- This name can be passed through multiple components.
	-- What's important is the final Roblox Instance receives the name
	-- It's solely for debugging purposes; Roact doesn't use it.
	if type(key) == "string" then
		rbx.Name = key
	end
	rbx.Parent = parent
end

local Reconciler = {}

Reconciler._singleEventManager = SingleEventManager.new()

--[[
	Destroy the given Roact instance, all of its descendants, and associated
	Roblox instances owned by the components.
]]
function Reconciler.unmount(handle)
	local stack = Heapstack.new(true)
	stack:push(Reconciler._unmountInternal, stack, handle)
	stack:run()
end

function Reconciler._unmountInternal(stack, handle)
	local element = handle._element
	local componentType = type(element.component)

	if componentType == "string" then
		-- We're destroying a Roblox Instance-based object

		stack:push(handle._rbx.Destroy, handle._rbx)

		for _, childHandle in pairs(handle._children or NO_CHILDREN) do
			stack:push(Reconciler.unmount, childHandle)
		end

		-- Kill refs before we make changes, since any mutations past this point
		-- aren't relevant to components.
		handle._rbx = nil
		stack:push(applyRef, element.props[Core.Ref], nil)
	elseif componentType == "function" then
		-- Functional components can return nil
		if handle._child then
			stack:push(Reconciler.unmount, handle._child)
		end
	elseif componentType == "table" then
		if handle._child then
			stack:push(Reconciler.unmount, handle._child)
		end
		handle._instance:_unmount(stack)
	elseif element.component == Core.Portal then
		for _, childHandle in pairs(handle._children or NO_CHILDREN) do
			stack:push(Reconciler.unmount, childHandle)
		end
		handle._rbx = nil
	else
		error(("Cannot unmount invalid Roact component %q"):format(tostring(element.component)))
	end
end

--[[
	Public interface to reifier. Hides parameters used when recursing down the
	component tree.
]]
function Reconciler.mount(element, parent, key)
	if type(element) ~= "table" then
		if element == true or element == false then
			-- Ignore booleans of either value
			-- See https://github.com/Roblox/roact/issues/14
			return nil
		end
		error(("Cannot mount invalid Roact element %q"):format(tostring(element)))
	end

	local handle = {}
	local stack = Heapstack.new(true)
	stack:push(Reconciler._mountInternal, stack, handle, element, key, parent)
	stack:run()
	return handle._child
end

--[[
	Instantiates components to represent the given element.

	Parameters:
		- `parentHandle`: The handle of the parent so mount knows where to store the new child's handle
		- `element`: The element to mount
		- `key`: The Name to give the Roblox instance that gets created
		- `parent`: The root Roblox instance for the instance subtree (only set by primitive components)
		- `context`: Used to pass Roact context values down the tree (only set in reconcilation when mounting new elements)
		- `stack`: The Heapstack which keeps the stack on the heap, allowing for error recovery

	The structure created by this method is important to the functionality of
	the reconciliation methods; they depend on this structure being well-formed.
]]
function Reconciler._mountInternal(stack, parentHandle, element, key, parent, context)
	local handle = {
		[isInstanceHandle] = true,
		_key = key,
		_element = element,
		_context = context,
	}

	local isValidComponent = false
	local componentType = type(element.component)

	if componentType == "string" then
		isValidComponent = true

		-- Primitive/Portal elements are backed directly by Roblox Instances.
		local rbx = Instance.new(element.component)
		handle._rbx = rbx

		-- Attach ref values, since the instance is initialized now.
		stack:push(applyRef, element.props[Core.Ref], rbx)

		stack:push(finalizeRbx, rbx, key, parent)

		-- Create children!
		if element.props[Core.Children] then
			handle._children = {}
			for childKey, childElement in pairs(element.props[Core.Children]) do
				stack:push(Reconciler._mountInternal, stack, handle, childElement, childKey, rbx, context)
			end
		end

		-- Update Roblox properties
		stack:push(Reconciler._setRbxProps, rbx, element.props, element.source)
	elseif componentType == "function" then
		isValidComponent = true

		-- Functional elements have 0 or 1 children
		local childElement = element.component(element.props)
		if childElement then
			stack:push(Reconciler._mountInternal, stack, handle, childElement, key, parent, context)
		end
	elseif componentType == "table" then
		isValidComponent = true

		-- Stateful elements have 0 or 1 children
		stack:push(element.component._new, stack, handle, context)
	elseif element.component == Core.Portal then
		isValidComponent = true

		local target = element.props.target
		if not target then
			error(("Cannot mount Portal without specifying a target."):format(tostring(element)))
		elseif typeof(target) ~= "Instance" then
			error(("Cannot mount Portal with target of type %q."):format(typeof(target)))
		end
		handle._rbx = target

		-- Attach ref values, since the instance is initialized now.
		stack:push(applyRef, handle)

		-- Create children!
		if element.props[Core.Children] then
			handle._children = {}
			for childKey, childElement in pairs(element.props[Core.Children]) do
				stack:push(Reconciler._mountInternal, stack, handle, childElement, childKey, target, context)
			end
		end
	end

	if isValidComponent then
		if parentHandle._children then
			parentHandle._children[key] = handle
		else
			parentHandle._child = handle
		end
	else
		error(("Cannot mount invalid Roact component %q"):format(tostring(element.component)))
	end
end

--[[
	A public interface around _reconcileInternal
]]
function Reconciler.reconcile(handle, element)
	if type(element) ~= "table" then
		if element == true or element == false then
			-- Ignore booleans of either value
			-- See https://github.com/Roblox/roact/issues/14
			return nil
		end
		error(("Cannot reconcile to match invalid Roact element %q"):format(tostring(element)))
	elseif not (type(handle) == "table" and handle[isInstanceHandle]) then
		-- elements must be a table with isInstanceHandle set to true
		error(("Bad argument #1 to Reconciler.reconcile, expected component instance handle, found %s")
			:format(typeof(handle)), 2)
	end

	local stack = Heapstack.new(true)
	stack:push(Reconciler._reconcileInternal, stack, handle, element)
	stack:run()
end

--[[
	Applies the state given by newElement to an existing Roact instance.

	reconcile will return the instance that should be used. This instance can
	be different than the one that was passed in.
]]
function Reconciler._reconcileInternal(stack, parentHandle, handle, newElement)
	local oldElement = handle._element

	if newElement == nil then
		return stack:push(Reconciler._unmountInternal, stack, handle)
	end

	-- If the element changes type, we assume its subtree will be substantially
	-- different. This lets us skip comparisons of a large swath of nodes.
	if oldElement.component ~= newElement.component then
		local context
		if type(oldElement.component) == "table" then
			context = handle._instance._context
		else
			context = handle._context
		end

		stack:push(Reconciler._mountInternal, stack, parentHandle, newElement, handle._key, handle._parent, context)

		return stack:push(Reconciler._unmountInternal, stack, handle)
	end

	local newType = type(newElement.component)
	if newType == "string" then
		-- Change the ref in one pass before applying any changes.
		-- Roact doesn't provide any guarantees with regards to the sequencing
		-- between refs and other changes in the commit phase.
		local oldRef = oldElement.props[Core.Ref]
		local newRef = newElement.props[Core.Ref]
		if newRef ~= oldRef then
			stack:push(applyRef, oldRef, nil)
			stack:push(applyRef, newRef, handle._rbx)
		end

		-- Roblox Instance change
		-- Update properties and children of the Roblox object.
		stack:push(Reconciler._reconcilePrimitiveChildren, stack, handle, newElement)
		stack:push(Reconciler._reconcilePrimitiveProps, oldElement, newElement, handle)

	elseif newType == "function" then
		local rendered = newElement.component(newElement.props)
		if handle._child then
			-- Transition from tree to tree, even if 'rendered' is nil
			stack:push(Reconciler._reconcileInternal, stack, parentHandle, handle, rendered)
		elseif rendered then
			-- Transition from nil to new tree
			stack:push(Reconciler._mountInternal, stack, parentHandle, rendered, handle._key, handle._parent, handle._context)
		end
	elseif newType == "table" then
		-- Stateful elements can take care of themselves.
		stack:push(handle._instance._update, handle._instance, stack, newElement.props)
	elseif newElement.component == Core.Portal then
		stack:push(Reconciler._reconcilePrimitiveChildren, stack, handle, newElement)
		if handle._rbx ~= newElement.props.target then
			stack:push(Reconciler._unmountInternal, stack, handle)
			stack:push(Reconciler._mountInternal, stack, parentHandle, newElement, handle._parent, handle._key, handle._context)
		end
	else
		error(("Cannot reconcile to match invalid Roact component %q"):format(tostring(newElement.component)))
	end

	handle._element = newElement
end

--[[
	Reconciles the children of an existing Roact instance and the given element.
]]
function Reconciler._reconcilePrimitiveChildren(stack, handle, newElement)
	local childrenElements = newElement.props[Core.Children] or NO_CHILDREN
	local childrenHandles = handle._children or NO_CHILDREN

	if #childrenElements > 0 and not handle._children then
		childrenHandles = {}
		handle._children = childrenHandles
	elseif #childrenElements == 0 then
		handle._children = nil
	end

	-- Reconcile existing children that were changed or removed
	for key, childHandle in pairs(childrenHandles) do
		stack:push(Reconciler._reconcileInternal, stack, handle, childHandle, childrenElements[key])
	end

	-- Create children that were just added!
	for key, childElement in pairs(childrenElements) do
		-- Update if we didn't hit the child in the previous loop
		if not childrenHandles[key] then
			stack:push(Reconciler._mountInternal, handle, childElement, key, handle._rbx, handle._context)
		end
	end
end

--[[
	Reconciles the properties between two primitive Roact elements and applies
	the differences to the given Roblox object.
]]
function Reconciler._reconcilePrimitiveProps(fromElement, toElement, rbx)
	local changedProps = {}

	local fromProps = fromElement.props
	local toProps = toElement.props

	-- Set properties that were set with fromElement
	for key, oldValue in pairs(fromProps) do
		local newValue = toProps[key]

		-- Assume any property that can be set to nil has a default value of nil
		if newValue == nil then
			local _, value = getDefaultPropertyValue(rbx.ClassName, key)

			-- We don't care if getDefaultPropertyValue fails, because
			-- _setRbxProps will catch the error below.
			newValue = value
		end

		-- Roblox does this check for normal values, but we have special
		-- properties like events that warrant this.
		if oldValue ~= newValue then
			changedProps[key] = newValue
		end
	end

	-- Set properties that are new in toElement
	for key, newValue in pairs(toProps) do
		if fromProps[key] == nil then
			changedProps[key] = newValue
		end
	end

	if next(changedProps) then
		Reconciler._setRbxProps(rbx, changedProps, toElement.source)
	end
end


local function _setRbxProps(rbx, props, state)
	local key, value = next(props, state.key)
	state.key = key

	while key do
		local keyType = type(key)
		if keyType == "string" then
			-- Regular property
			rbx[key] = value
		elseif keyType == "table" then
			-- Special property with extra data attached.
			if key.type == Event then
				Reconciler._singleEventManager:connect(rbx, key.name, value)
			elseif key.type == Change then
				Reconciler._singleEventManager:connectProperty(rbx, key.name, value)
			else
				error(("Invalid special property type %q"):format(tostring(key.type)))
			end
		elseif keyType ~= "userdata" then
			-- Userdata values are special markers, usually created by Symbol
			-- They have no data attached other than being unique keys
			error(("Properties with a key type of %q are not supported"):format(keyType))
		end
		key, value = next(props, key)
		state.key = key
	end
end

--[[
	Sets the properties on a Roblox object, following Roact's rules for special
	case properties.
]]
function Reconciler._setRbxProps(rbx, props, source)
	local state = {}
	local success, reason = pcall(_setRbxProps, rbx, props, state)

	while not success do
		local warning = ("Failed to set property on primitive instance of class %s\n%s\n%s"):format(
			rbx.ClassName,
			reason,
			source or DEFAULT_SOURCE
		)

		warn(warning)
		print() -- an uncolored newline without a timestamp prepended

		success, reason = pcall(_setRbxProps, rbx, props, state)
	end
end

return Reconciler
