## Methods

### Roact.createElement
```
Roact.createElement(component, [props, [children]]) -> RoactElement
```

Creates a new Roact element representing the given `component`. Elements are lightweight descriptions about what a Roblox Instance should look like, like a blueprint!

The `children` argument is shorthand for adding a `Roact.Children` key to `props`. It should be specified as a dictionary of names to elements.

`component` can be a string, a function, or a table created by `Component:extend`.

!!! caution
	Make sure not to modify `props` or `children` after they're passed into `createElement`!

---

### Roact.createFragment

!!! success "Added in Roact 1.0.0"

```
Roact.createFragment(elements) -> RoactFragment
```

Creates a new Roact fragment with the provided table of elements. Fragments allow grouping of elements without the need for intermediate containing objects like `Frame`s.

!!! caution
	Make sure not to modify `elements` after they're passed into `createFragment`!

---

### Roact.mount
```
Roact.mount(element, [parent, [key]]) -> RoactTree
```

!!! info
	`Roact.mount` is also available via the deprecated alias `Roact.reify`. It will be removed in a future release.

Creates a Roblox Instance given a Roact element, and optionally a `parent` to put it in, and a `key` to use as the instance's `Name`.

The result is a `RoactTree`, which is an opaque handle that represents a tree of components owned by Roact. You can pass this to APIs like `Roact.unmount`. It'll also be used for future debugging APIs.

---

### Roact.update
```
Roact.update(tree, element) -> RoactTree
```

!!! info
	`Roact.update` is also available via the deprecated alias `Roact.reconcile`. It will be removed in a future release.

Updates an existing instance handle with a new element, returning a new handle. This can be used to update a UI created with `Roact.mount` by passing in a new element with new props.

`update` can be used to change the props of a component instance created with `mount` and is useful for putting Roact content into non-Roact applications.

As of Roact 1.0, the returned `RoactTree` object will always be the same value as the one passed in.

---

### Roact.unmount
```
Roact.unmount(tree) -> void
```

!!! info
	`Roact.unmount` is also available via the deprecated alias `Roact.teardown`. It will be removed in a future release.

Destroys the given `RoactTree` and all of its descendants. Does not operate on a Roblox Instance -- this must be given a handle that was returned by `Roact.mount`.

---

### Roact.oneChild
`Roact.oneChild(children) -> RoactElement | nil`

Given a dictionary of children, returns a single child element.

If `children` contains more than one child, `oneChild` function will throw an error. This is intended to denote an error when using the component using `oneChild`.

If `children` is `nil` or contains no children, `oneChild` will return `nil`.

---

### Roact.createBinding

!!! success "Added in Roact 1.0.0"

```
Roact.createBinding(initialValue) -> Binding, updateFunction
where
	updateFunction: (newValue) -> ()
```

The first value returned is a `Binding` object, which will typically be passed as a prop to a Roact host component. The second is a function that can be called with a new value to update the binding.

A `Binding` has the following API:

#### getValue
```
Binding:getValue() -> value
```

Returns the internal value of the binding. This is helpful when updating a binding relative to its current value.

!!! warning
	Using `getValue` inside a component's `render` method is dangerous! Using the unwrapped value directly won't allow Roact to subscribe to a binding's updates. To guarantee that a bound value will update, use the binding itself for your prop value.

#### map
```
Binding:map(mappingFunction) -> Binding
where
	mappingFunction: (value) -> mappedValue
```

Returns a new binding that maps the existing binding's value to something else. For example, `map` can be used to transform an animation progress value like `0.4` into a property that can be consumed by a Roblox Instance like `UDim2.new(0.4, 0, 1, 0)`.

---

### Roact.joinBindings

!!! success "Added in Roact 1.1.0"

```
Roact.joinBindings(bindings) -> Binding
where
	bindings: { [any]: Binding }
```

Combines multiple bindings into a single binding. The new binding's value will have the same keys as the input table of bindings.

`joinBindings` is usually used alongside `Binding:map`:

```lua
local function Flex()
	local aSize, setASize = Roact.createBinding(Vector2.new())
	local bSize, setBSize = Roact.createBinding(Vector2.new())

	return Roact.createElement("Frame", {
		Size = Roact.joinBindings({aSize, bSize}):map(function(sizes)
			local sum = Vector2.new()

			for _, size in ipairs(sizes) do
				sum = sum + size
			end

			return UDim2.new(0, sum.X,  0, sum.Y)
		end),
	}, {
		A = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			[Roact.Change.AbsoluteSize] = function(instance)
				setASize(instance.Size)
			end,
		}),
		B = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = aSize:map(function(size)
				return UDim2.new(0, 0, 0, size.Y)
			end),
			[Roact.Change.AbsoluteSize] = function(instance)
				setBSize(instance.Size)
			end,
		}),
	})
end
```

---

### Roact.createRef
```
Roact.createRef() -> Ref
```

Creates a new reference object that can be used with [Roact.Ref](#roactref).

---

### Roact.forwardRef

!!! success "Added in Roact 1.4.0"

```
Roact.createRef(render: (props: table, ref: Ref) -> RoactElement) -> RoactComponent
```

Creates a new component given a render function that accepts both props and a ref, allowing a ref to be forwarded to an underlying host component via [Roact.Ref](#roactref).

---

### Roact.createContext

!!! success "Added in Roact 1.3.0"

```
Roact.createContext(defaultValue: any) -> RoactContext

type RoactContext = {
	Provider: Component,
	Consumer: Component,
	[private fields]
}
```

Creates a new context provider and consumer. For a usage guide, see [Advanced Concepts: Context](../advanced/context).

`defaultValue` is given to consumers if they have no `Provider` ancestors. It is up to users of Roact's context API to turn this case into an error if it is an invalid state.

`Provider` and `Consumer` are both Roact components.

#### `Provider`
`Provider` accepts the following props:

* `value`: The value to put into the tree for this context value.
	* If the `Provider` is updated with a new `value`, any matching `Consumer` components will be re-rendered with the new value.
* `[Children]`: Any number of children to render underneath this provider.
	* Descendants of this component can receive the provided context value by using `Consumer`.

#### `Consumer`
`Consumer` accepts just one prop:

* `render(value) -> RoactElement | nil`: A function that will be invoked to render any children.
	* `render` will be called every time `Consumer` is rendered.

---

### Roact.setGlobalConfig
```
Roact.setGlobalConfig(configValues: Dictionary<string, bool>) -> void
```

The entry point for configuring Roact. Roact currently applies this to everything using this instance of Roact, so be careful using this with a project that has multiple consumers of Roact.

Once config values are set, they will apply from then on. This is primarily useful when developing as it can enable features that validate your code more strictly. Most of the settings here incur a performance cost and should typically be disabled in production environments.

Call this method once at the root of your project (before mounting any Roact elements):
```lua
Roact.setGlobalConfig({
	typeChecks = true,
	propValidation = true,
})
```

The following are the valid config keys that can be used, and what they do.

#### typeChecks
Enables type checks for Roact's public interface. This includes some of the following:

* Check that the `props` and `children` arguments to `Roact.createElement` are both tables or nil
* Check that `setState` is passing `self` as the first argument (it should be called like `self:setState(...)`)
* Confirm the `Roact.mount`'s first argument is a Roact element
* And much more!

#### internalTypeChecks
Enables type checks for internal functionality of Roact. This is typically only useful when debugging Roact itself. It will run similar type checks to those mentioned above, but only the private portion of the API.

#### elementTracing
When enabled, Roact will capture a stack trace at the site of each element creation and hold onto it, using it to provide additional details on certain kinds of errors. If you get an error that says "<enable element tracebacks>", try enabling this config value to help with debugging.

Enabling `elementTracing` also allows the use of the [getElementTraceback](#getelementtraceback) method on Component, which can also be helpful for debugging.

#### propValidation
Enables validation of props via the [validateProps](#validateprops) method on components. With this flag enabled, any validation written by component authors in a component's `validateProps` method will be run on every prop change. This is helpful during development for making sure components are being used correctly.

---

## Constants

### Roact.Children
This is the key that Roact uses internally to store the children that are attached to a Roact element.

If you're writing a new function component or stateful component that renders children like a host component, you can access `Roact.Children` in your props table.

---

### Roact.Ref
Use `Roact.Ref` as a key into the props of a host element to receive a handle to the underlying Roblox Instance.

Assign this key to a ref created with [createRef](#roactcreateref):
```lua
local ExampleComponent = Roact.Component:extend("ExampleComponent")

function ExampleComponent:init()
	-- Create a ref.
	self.ref = Roact.createRef()
end

function ExampleComponent:render()
	return Roact.createElement("Frame", {
		-- Use the ref to point to this rendered instance.
		[Roact.Ref] = self.ref,
	})
end

function ExampleComponent:didMount()
	-- Refs are a kind of binding, so we can access the Roblox Instance using getValue.
	print("Roblox Instance", self.ref:getValue())
end
```

!!! info
	Ref objects have a deprecated field called `current` that is always equal to the result of `getValue`. Assigning to the `current` field is not allowed. The field will be removed in a future release.

Alternatively, you can assign it to a function instead:
```lua
Roact.createElement("Frame", {
	-- The provided function will be called whenever the rendered instance changes.
	[Roact.Ref] = function(rbx)
		print("Roblox Instance", rbx)
	end,
})
```

!!! warning
	When `Roact.Ref` is given a function, Roact does not guarantee when this function will be run relative to the reconciliation of other props. If you try to read a Roblox property that's being set via a Roact prop, you won't know if you're reading it before or after Roact updates that prop!

!!! warning
	When `Roact.Ref` is given a function, it will be called with `nil` when the component instance is destroyed!

See [the refs guide](../advanced/bindings-and-refs#refs) for more details.

---

### Roact.Event
Index into `Roact.Event` to receive a key that can be used to connect to events when creating host elements:

```lua
Roact.createElement("ImageButton", {
	[Roact.Event.MouseButton1Click] = function(rbx, x, y)
		print(rbx, "clicked at position", x, y)
	end,
})
```

!!! info
	Event callbacks receive the Roblox Instance as the first parameter, followed by any parameters yielded by the event.

!!! warning
	When connecting to the `Changed` event, be careful not to call `setState` or other functions that will trigger renders. This will cause Roact to re-render during a render, and errors will be thrown!

See [the events guide](../guide/events) for more details.

---

### Roact.Change
Index into `Roact.Change` to receive a key that can be used to connect to [`GetPropertyChangedSignal`](http://wiki.roblox.com/index.php?title=API:Class/Instance/GetPropertyChangedSignal) events.

It's similar to `Roact.Event`:

```lua
Roact.createElement("ScrollingFrame", {
	[Roact.Change.CanvasPosition] = function(rbx)
		print("ScrollingFrame scrolled to", rbx.CanvasPosition)
	end,
})
```

!!! warning
	Property changed events are fired by Roact during the reconciliation phase. Be careful not to accidentally trigger a re-render in the middle of a re-render, or an error will be thrown!

---

### Roact.None
`Roact.None` is a special value that can be used to clear elements from your component state when calling `setState` or returning from `getDerivedStateFromProps`.

In Lua tables, removing a field from state is not possible by setting its value to `nil` because `nil` values mean the same thing as no value at all. If a field needs to be removed from state, it can be set to `Roact.None` when calling `setState`, which will ensure that the resulting state no longer contains it:

```lua
function MyComponent:didMount()
	self:setState({
		fieldToRemove = Roact.None
	})
end
```

---

## Component Types

### Roact.Component
The base component instance that can be extended to make stateful components.

Call `Roact.Component:extend("ComponentName")` to make a new stateful component with a given name.

---

### Roact.PureComponent
An extension of `Roact.Component` that only re-renders if its props or state change.

`PureComponent` implements the `shouldUpdate` lifecycle event with a shallow equality comparison. It's optimized for use with immutable data structures, which makes it a perfect fit for use with frameworks like Rodux.

`PureComponent` is not *always* faster, but can often result in significant performance improvements when used correctly.

---

### Roact.Portal
A component that represents a *portal* to a Roblox Instance. Portals are created using `Roact.createElement`.

Any children of a portal are put inside the Roblox Instance specified by the required `target` prop. That Roblox Instance should not be one created by Roact.

Portals are useful for creating dialogs managed by deeply-nested UI components, and enable Roact to represent and manage multiple disjoint trees at once.

See [the Portals guide](../advanced/portals) for a small tutorial and more details about portals.

---

## Component API

### defaultProps
```
static defaultProps: Dictionary<any, any>
```

If `defaultProps` is defined on a stateful component, any props that aren't specified when a component is created will be taken from there.

---

### init
```
init(initialProps) -> void
```

`init` is called exactly once when a new instance of a component is created. It can be used to set up the initial `state`, as well as any non-`render` related values directly on the component.

Use `setState` inside of `init` to set up your initial component state:

```lua
function MyComponent:init()
	self:setState({
		position = 0,
		velocity = 10
	})
end
```

In older versions of Roact, `setState` was disallowed in `init`, and you would instead assign to `state` directly. It's simpler to use `setState`, but assigning directly to `state` is still acceptable inside `init`:

```lua
function MyComponent:init()
	self.state = {
		position = 0,
		velocity = 10
	}
end
```

---

### render
```
render(props, state) -> Element | nil
```

`render` describes what a component should display at the current instant in time.

You can access the props and state of the component either through `self.props` and `self.state` respectively or through the arguments passed.

```lua
function MyComponent:render(props, state)
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. props.name .. "!"
	})
end
```

!!! info
	Roact assumes that `render` act likes a pure function: the result of `render` must depend only on `props` and `state`, and it must not have side-effects.

```lua
function MyComponent:render(props, state)
	-- This is okay:
	return Roact.createElement("TextLabel", {
		Text = props.text,
		Position = state.position
	})

	-- Ack! Depending on values outside props/state is not allowed!
	return Roact.createElement("TextLabel", {
		Text = self.someText,
		Position = getMousePosition(),
	})
end
```

`render` must be defined for all components. The default implementation of `render` throws an error; if your component does not render anything, define a render function that returns `nil` explicitly. This helps make sure that you don't _forget_ to define `render`!

```lua
function MyComponent:render()
	return nil
end
```

---

### setState
```
setState(stateUpdater | stateChange) -> void
```

`setState` *requests* an update to the component's state. Roact may schedule this update for a later time or resolve it immediately.

If a function is passed to `setState`, that function will be called with the current state and props as arguments:

```lua
function MyComponent:didMount()
	self:setState(function(prevState, props)
		return {
			counter = prevState.counter + 1
		}
	end)
end
```

If this function returns `nil`, Roact will not schedule a re-render and no state will be updated.

If a table is passed to `setState`, the values in that table will be merged onto the existing state:

```lua
function MyComponent:didMount()
	self:setState({
		foo = "bar"
	})
end
```

Setting a field in the state to `Roact.None` will clear it from the state. This is the only way to remove a field from a component's state!

!!! warning
	`setState` can be called from anywhere **except**:

	* Lifecycle hooks: `willUnmount`, `willUpdate`
	* Pure functions: `render`, `shouldUpdate`

	Calling `setState` inside of `init` has special behavior. The result of setState will be used to determine initial state, and no additional updates will be scheduled.

	Roact may support calling `setState` in currently-disallowed places in the future.

!!! warning
	**`setState` does not always resolve synchronously!** Roact may batch and reschedule state updates in order to reduce the number of total renders.

	When depending on the previous value of state, like when incrementing a counter, use the functional form to guarantee that all state updates occur!

	This behavior will be similar to the future behavior of React 17. See:

	* [RFClarification: why is `setState` asynchronous?](https://github.com/facebook/react/issues/11527#issuecomment-360199710)
	* [Does React keep the order for state updates?](https://stackoverflow.com/a/48610973/802794)

---

### shouldUpdate
```
shouldUpdate(nextProps, nextState) -> bool
```

`shouldUpdate` provides a way to override Roact's rerendering heuristics.

By default, components are re-rendered any time a parent component updates, or when state is updated via `setState`.

`PureComponent` implements `shouldUpdate` to only trigger a re-render any time the props are different based on shallow equality. In a future Roact update, *all* components may implement this check by default.

---

### validateProps

!!! success "Added in Roact 1.0.0"

```
static validateProps(props) -> (false, message: string) | true
```

`validateProps` is an optional method that can be implemented for a component. It provides a mechanism for verifying inputs passed into the component.

Every time props are updated, `validateProps` will be called with the new props before proceeding to `shouldUpdate` or `init`. It should return the same parameters that assert expects: a boolean, true if the props passed validation, false if they did not, plus a message explaining why they failed. If the first return value is true, the second value is ignored.

**For performance reasons, property validation is disabled by default.** To use this feature, enable `propValidation` via `setGlobalConfig`:

```
Roact.setGlobalConfig({
	propValidation = true
})
```

See [setGlobalConfig](#roactsetglobalconfig) for more details.

!!! note
	`validateProps` is a *static* lifecycle method. It does not have access to `self`, and must be a pure function.

!!! warning
	Depending on the implementation, `validateProps` can impact performance. Recommended practice is to enable prop validation during development and leave it off in production environments.

---

### getElementTraceback
```
getElementTraceback() -> string | nil
```

`getElementTraceback` gets the stack trace that the component was created in. This allows you to report error messages accurately.

## Lifecycle Methods
In addition to the base Component API, Roact exposes additional lifecycle methods that stateful components can hook into to be notified of various steps in the rendering process.

<div align="center">
	<a href="../images/lifecycle.svg">
		<img src="../images/lifecycle.svg" alt="Diagram of Roact Lifecycle" />
	</a>
</div>

### didMount
```
didMount() -> void
```

`didMount` is fired after the component finishes its initial render. At this point, all associated Roblox Instances have been created, and all components have finished mounting.

`didMount` is a good place to start initial network communications, attach events to services, or modify the Roblox Instance hierarchy.

---

### willUnmount
```
willUnmount() -> void
```

`willUnmount` is fired right before Roact begins unmounting a component instance's children.

`willUnmount` acts like a component's destructor, and is a good place to disconnect any manually-connected events.

---

### willUpdate
```
willUpdate(nextProps, nextState) -> void
```

`willUpdate` is fired after an update is started but before a component's state and props are updated.

---

### didUpdate
```
didUpdate(previousProps, previousState) -> void
```

`didUpdate` is fired after at the end of an update. At this point, Roact has updated the properties of any Roblox Instances and the component instance's props and state are up to date.

`didUpdate` is a good place to send network requests or dispatch Rodux actions, but make sure to compare `self.props` and `self.state` with `previousProps` and `previousState` to avoid triggering too many updates.

---

### getDerivedStateFromProps
```
static getDerivedStateFromProps(nextProps, lastState) -> nextStateSlice
```

Used to recalculate any state that depends on being synchronized with `props`.

Generally, you should use `didUpdate` to respond to props changing. If you find yourself copying props values to state as-is, consider using props or memoization instead.

`getDerivedStateFromProps` should return a table that contains the part of the state that should be updated.

```lua
function MyComponent.getDerivedStateFromProps(nextProps, lastState)
	return {
		someValue = nextProps.someValue
	}
end
```

As with `setState`, you can set use the constant `Roact.None` to remove a field from the state.

!!! note
	`getDerivedStateFromProps` is a *static* lifecycle method. It does not have access to `self`, and must be a pure function.

!!! caution
	`getDerivedStateFromProps` runs before `shouldUpdate` and any non-nil return will cause the state table to no longer be shallow-equal. This means that a `PureComponent` will rerender even if nothing actually changed. Similarly, any component implementing both `getDerivedStateFromProps` and `shouldUpdate` needs to do so in a way that takes this in to account.
