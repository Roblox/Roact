In certain situations, Roact's reconciliation process is ill-suited for managing some Instance properties. For cases like this, Roact provides escape hatches in the form of Bindings and Refs.

Bindings and Refs are intended to be used in cases where Roact cannot solve a problem directly, or its solution might not be performant enough, like:

* Invoking functions on Roblox Instances
* Dynamically resizing a host component to fit its contents
* Gamepad selection
* Animations

## Bindings

Bindings are special objects that Roact automatically unwraps into values. When a binding is updated, Roact will change only the specific properties that are subscribed to it.

### Binding Properties

Bindings can be used to provide an external source for a prop value, or to update those values outside of the Roact reconciliation process.

First, create a binding and an updater using `Roact.createBinding()` and put the results somewhere persistent. `createBinding` returns two results: a binding object and an updater function, which is used to update the binding's value.

```lua
local Foo = Roact.Component:extend("Foo")

function Foo:init()
	-- createBinding takes an initial value; for our purposes, 0 is fine
	self.clickCount, self.updateClickCount = Roact.createBinding(0)
end
```

Then, connect the binding value to something that we're rendering and the updater to something that will invoke it.

```lua
function Foo:render()
	return Roact.createElement("TextButton", {
		-- Roact unwraps the binding, sets the Text property to the binding's value,
		-- and subscribes to the binding
		Text = self.clickCount,
		[Roact.Event.Activated] = function()
			-- When the user clicks the button, the count will be incremented and
			-- Roact will update any properties that are subscribed to the binding
			self.updateClickCount(self.clickCount:getValue() + 1)
		end
	})
end
```

The result of this example is a `TextButton` that displays the number of times it's been clicked. In this case, we connect the updater to the button's `Activated` event. Other use cases could be connecting it to some external property in `didMount` or passing it to a child component as a callback.

### Mapped Bindings

Often, a binding's value isn't useful by itself. It needs to be transformed into some other value in order to be useful when assigned to an Instance property.

Let's modify the above component to make use of a mapped binding:

```lua hl_lines="3 4 5 6"
function Foo:render()
	return Roact.createElement("TextButton", {
		-- Roact will receive the mapped value from the binding
		Text = self.clickCount:map(function(value)
			return "Clicks: " .. tostring(value)
		end),
		[Roact.Event.Activated] = function()
			-- When the user clicks the button, the count will be incremented
			self.updateClickCount(self.clickCount:getValue() + 1)
		end
	})
end
```

Our mapped binding transforms the number of clicks into a string. Now the `TextButton` will display "Clicks: 0" instead of just the number!

## Refs

While bindings are most helpful for individual props, we often want to access an entire Roblox Instance and its methods.

*Refs* are a special type of binding that point to Roblox Instance objects that are created by Roact.

Refs can only be attached to host components. This is different from React, where refs can be used to call members of composite components.

### Refs in Action
To use a ref, call `Roact.createRef()` and put the result somewhere persistent. Generally, that means that refs are only used inside stateful components.

```lua
local Foo = Roact.Component:extend("Foo")

function Foo:init()
	self.textBoxRef = Roact.createRef()
end
```

Next, use the ref inside of `render` by creating a host component. Refs use the special key `Roact.Ref`.

```lua
function Foo:render()
	return Roact.createElement("TextBox", {
		[Roact.Ref] = self.textBoxRef,
	})
end
```

Finally, we can use the value of the ref at any point after our component is mounted.

```lua
function Foo:didMount()
	-- The actual Instance can be retrieved using the `getValue` method
	local textBox = self.textBoxRef:getValue()

	print("TextBox has this text:", textBox.Text)
end
```

### Refs as Host Properties
In addition to providing access to underlying Roblox objects, refs also provide a handy shortcut for Roblox Instance properties that expect another Instance as their value. One commonly-encountered example is `NextSelectionLeft` and its counterparts.

Roact's Roblox renderer knows that bindings are not valid Roblox Instance values, so it will unwrap them for you:

```lua
local Bar = Roact.Component:extend("Bar")

function Bar:init()
	self.leftButtonRef = Roact.createRef()
	self.rightButtonRef = Roact.createRef()
end

function Bar:render()
	return Roact.createElement("Frame", nil, {
		LeftButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.leftButtonRef,
			NextSelectionRight = self.rightButtonRef,
		}),
		RightButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.rightButtonRef,
			NextSelectionLeft = self.leftButtonRef,
		})
	})
end
```

Since refs use bindings under the hood, they will be automatically updated whenever the ref changes. This means there's no need to worry about the order in which refs are assigned relative to when properties that use them get set.

### Ref Forwarding
In Roact 1.x, refs can only be applied to host components, _not_ stateful or function components. However, stateful or function components may accept a ref in order to pass it along to an underlying host component. In order to implement this, we wrap the given component with `Roact.forwardRef`.

Suppose we have a styled TextBox component that still needs to accept a ref, so that users of the component can trigger functionality like `TextBox:CaptureFocus()`:

```lua
local function FancyTextBox(props)
	return Roact.createElement("TextBox", {
		Multiline = true,
		PlaceholderText = "Enter your text here",
		PlaceholderColor3 = Color3.new(0.4, 0.4, 0.4),
		[Roact.Change.Text] = props.onTextChange,
	})
end
```

If we were to create an element using the above component, we'd be unable to get a ref to point to the underlying "TextBox" Instance:

```lua
local Form = Roact.Component:extend("Form")
function Form:init()
	self.textBoxRef = Roact.createRef()
end

function Form:render()
	return Roact.createElement(FancyTextBox, {
		onTextChange = function(value)
			print("text value updated to:", value)
		end
		-- This doesn't actually get assigned to the underlying TextBox!
		[Roact.Ref] = self.textBoxRef,
	})
end

function Form:didMount()
	-- Since self.textBoxRef never gets assigned to a host component, this
	-- doesn't work, and in fact will be an attempt to access a nil reference!
	self.textBoxRef.current:CaptureFocus()
end
```

In this instance, `FancyTextBox` simply doesn't do anything with the ref passed into it. However, we can easily update it using forwardRef:

```lua
local FancyTextBox = Roact.forwardRef(function(props, ref)
	return Roact.createElement("TextBox", {
		Multiline = true,
		PlaceholderText = "Enter your text here",
		PlaceholderColor3 = Color3.new(0.4, 0.4, 0.4),
		[Roact.Change.Text] = props.onTextChange,
		[Roact.Ref] = ref,
	})
end)
```

With the above change, `FancyTextBox` now accepts a ref and assigns it to the "TextBox" host component that it renders under the hood. Our `Form` implementation will successfully capture focus on `didMount`.

### Function Refs
The original ref API was based on functions instead of objects (and does not use bindings). Its use is not recommended for most cases anymore.

This style of ref involves passing a function as the `Roact.Ref` prop as opposed to a dedicated ref object:

```lua
local function Baz(props)
	return Roact.createElement("TextBox", {
		[Roact.Ref] = function(instance)
			-- Be careful to guard against nil refs; this is a gotcha of
			-- function refs.
			if instance ~= nil then
				print("TextBox has this text:", instance.Text)
			else
				print("TextBox ref removed.")
			end
		end,
	})
end
```

!!! warning
	Function refs, unlike bindings, *cannot* be used as properties for host components. This will result in an error. 

!!! warning
	When a function ref is called, it's not guaranteed that its sibling or parent components have finished mounting. Causing side effects here can cause difficult-to-trace bugs.

!!! warning
	When a component with a function ref unmounts, or when the ref value changes, the component's ref is passed `nil`.