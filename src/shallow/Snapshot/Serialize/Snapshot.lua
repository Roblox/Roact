local RoactRoot = script.Parent.Parent.Parent.Parent

local Markers = require(script.Parent.Markers)
local ElementKind = require(RoactRoot.ElementKind)
local Type = require(RoactRoot.Type)
local Ref = require(RoactRoot.PropMarkers.Ref)

local function sortSerializedChildren(childA, childB)
	return childA.hostKey < childB.hostKey
end

local Snapshot = {}

function Snapshot.type(wrapperComponent)
	local kind = ElementKind.fromComponent(wrapperComponent)

	local typeData = {
		kind = kind,
	}

	if kind == ElementKind.Host then
		typeData.className = wrapperComponent
	elseif kind == ElementKind.Stateful then
		typeData.componentName = tostring(wrapperComponent)
	end

	return typeData
end

function Snapshot.signal(signal)
	local signalToString = tostring(signal)
	local signalName = signalToString:match("Signal (%w+)")

	assert(signalName ~= nil, ("Can not extract signal name from %q"):format(signalToString))

	return {
		[Markers.Signal] = signalName
	}
end

function Snapshot.propValue(prop)
	local propType = type(prop)

	if propType == "string"
		or propType == "number"
		or propType == "boolean"
	then
		return prop

	elseif propType == "function" then
		return Markers.AnonymousFunction

	elseif typeof(prop) == "RBXScriptSignal" then
		return Snapshot.signal(prop)

	elseif propType == "userdata" then
		return prop

	elseif propType == "table" then
		return Snapshot.props(prop)

	else
		warn(("Snapshot does not support prop with value %q (type %q)"):format(
			tostring(prop),
			propType
		))
		return Markers.Unknown
	end
end

function Snapshot.props(wrapperProps)
	local serializedProps = {}

	for key, prop in pairs(wrapperProps) do
		if type(key) == "string"
			or Type.of(key) == Type.HostChangeEvent
			or Type.of(key) == Type.HostEvent
		then
			serializedProps[key] = Snapshot.propValue(prop)

		elseif key == Ref then
			local current = prop:getValue()

			if current then
				serializedProps[key] = {
					className = current.ClassName,
				}
			else
				serializedProps[key] = Markers.EmptyRef
			end

		else
			error(("Snapshot does not support prop with key %q (type: %s)"):format(
				tostring(key),
				type(key)
			))
		end
	end

	return serializedProps
end

function Snapshot.children(children)
	local serializedChildren = {}

	for i=1, #children do
		local childWrapper = children[i]

		serializedChildren[i] = Snapshot.child(childWrapper)
	end

	table.sort(serializedChildren, sortSerializedChildren)

	return serializedChildren
end

function Snapshot.child(wrapper)
	return {
		type = Snapshot.type(wrapper.component),
		hostKey = wrapper.hostKey,
		props = Snapshot.props(wrapper.props),
		children = Snapshot.children(wrapper.children),
	}
end

function Snapshot.new(wrapper)
	local childSnapshot = Snapshot.child(wrapper)
	childSnapshot.hostKey = nil

	return childSnapshot
end

return Snapshot
