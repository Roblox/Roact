return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should throw on mount if not overridden", function()
		local MyComponent = Component:extend("MyComponent")

		local element = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		local success, result = pcall(function()
			noopReconciler.mountVirtualNode(element, hostParent, key)
		end)

		expect(success).to.equal(false)
		expect(result:match("MyComponent")).to.be.ok()
		expect(result:match("render")).to.be.ok()
	end)

	it("should be invoked when a component is mounted", function()
		local Foo = Component:extend("Foo")

		local capturedProps
		local capturedState
		local renderSpy = createSpy(function(self)
			capturedProps = self.props
			capturedState = self.state
		end)
		Foo.render = renderSpy.value

		local element = createElement(Foo)
		local hostParent = nil
		local key = "Foo Test"

		noopReconciler.mountVirtualNode(element, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local renderArguments = renderSpy:captureValues("self", "props", "state")

		expect(Type.of(renderArguments.self)).to.equal(Type.StatefulComponentInstance)
		assertDeepEqual(capturedProps, {})
		assertDeepEqual(capturedState, {})
	end)

	it("should be invoked when a component is updated via props", function()
		local Foo = Component:extend("Foo")

		local capturedProps
		local capturedState
		local renderSpy = createSpy(function(self, props, state)
			expect(props).to.equal(self.props)
			expect(state).to.equal(self.state)

			capturedProps = self.props
			capturedState = self.state
		end)
		Foo.render = renderSpy.value

		local initialProps = {
			a = 2,
		}
		local element = createElement(Foo, initialProps)
		local hostParent = nil
		local key = "Foo Test"

		local node = noopReconciler.mountVirtualNode(element, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local firstRenderArguments = renderSpy:captureValues("self", "props", "state")
		local firstProps = capturedProps
		local firstState = capturedState

		expect(Type.of(firstRenderArguments.self)).to.equal(Type.StatefulComponentInstance)
		assertDeepEqual(firstProps, initialProps)
		assertDeepEqual(firstState, {})

		local updatedProps = {
			a = 3,
		}
		local newElement = createElement(Foo, updatedProps)

		noopReconciler.updateVirtualNode(node, newElement)

		expect(renderSpy.callCount).to.equal(2)

		local secondRenderArguments = renderSpy:captureValues("self", "props", "state")
		local secondProps = capturedProps
		local secondState = capturedState

		expect(Type.of(secondRenderArguments.self)).to.equal(Type.StatefulComponentInstance)
		expect(secondProps).never.to.equal(firstProps)
		assertDeepEqual(secondProps, updatedProps)
		expect(secondState).to.equal(firstState)
	end)

	it("should be invoked when a component is updated via state", function()
		local Foo = Component:extend("Foo")

		local setState
		function Foo:init()
			setState = function(...)
				return self:setState(...)
			end
		end

		local capturedProps
		local capturedState
		local renderSpy = createSpy(function(self)
			capturedProps = self.props
			capturedState = self.state
		end)
		Foo.render = renderSpy.value

		local element = createElement(Foo)
		local hostParent = nil
		local key = "Foo Test"

		noopReconciler.mountVirtualNode(element, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local firstRenderArguments = renderSpy:captureValues("self", "props", "state")
		local firstProps = capturedProps
		local firstState = capturedState

		expect(Type.of(firstRenderArguments.self)).to.equal(Type.StatefulComponentInstance)

		setState({})

		expect(renderSpy.callCount).to.equal(2)

		local renderArguments = renderSpy:captureValues("self", "props", "state")

		expect(Type.of(renderArguments.self)).to.equal(Type.StatefulComponentInstance)
		expect(capturedProps).to.equal(firstProps)
		expect(capturedState).never.to.equal(firstState)
	end)

	itSKIP("Test defaultProps on initial render", function() end)
	itSKIP("Test defaultProps on prop update", function() end)
	itSKIP("Test defaultProps on state update", function() end)
end