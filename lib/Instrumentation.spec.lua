return function()
	local Component = require(script.Parent.PureComponent)
	local Core = require(script.Parent.Core)
	local GlobalConfig = require(script.Parent.GlobalConfig)
	local Instrumentation = require(script.Parent.Instrumentation)
	local Reconciler = require(script.Parent.Reconciler)

	it("should count and time renders when enabled", function()
		GlobalConfig.set({
			["componentInstrumentation"] = true,
		})
		local triggerUpdate

		local TestComponent = Component:extend("TestComponent")
		function TestComponent:init()
			self.state = {
				value = 0
			}
		end

		function TestComponent:render()
			return nil
		end

		function TestComponent:didMount()
			triggerUpdate = function()
				self:setState({
					value = self.state.value + 1
				})
			end
		end

		local instance = Reconciler.reify(Core.createElement(TestComponent))

		local stats = Instrumentation.getCollectedStats()
		expect(stats.TestComponent).to.be.ok()
		expect(stats.TestComponent.renderCount).to.equal(1)
		expect(stats.TestComponent.renderTime).never.to.equal(0)

		triggerUpdate()
		expect(stats.TestComponent.renderCount).to.equal(2)

		Reconciler.teardown(instance)
		Instrumentation.clearCollectedStats()
		GlobalConfig.reset()
	end)

	it("should count and time shouldUpdate calls when enabled", function()
		GlobalConfig.set({
			["componentInstrumentation"] = true,
		})
		local triggerUpdate
		local willDoUpdate = false

		local TestComponent = Component:extend("TestComponent")

		function TestComponent:init()
			self.state = {
				value = 0,
			}
		end

		function TestComponent:shouldUpdate()
			return willDoUpdate
		end

		function TestComponent:didMount()
			triggerUpdate = function()
				self:setState({
					value = self.state.value + 1,
				})
			end
		end

		function TestComponent:render() end

		local instance = Reconciler.reify(Core.createElement(TestComponent))

		local stats = Instrumentation.getCollectedStats()

		willDoUpdate = true
		triggerUpdate()

		expect(stats.TestComponent).to.be.ok()
		expect(stats.TestComponent.updateReqCount).to.equal(1)
		expect(stats.TestComponent.didUpdateCount).to.equal(1)

		willDoUpdate = false
		triggerUpdate()

		expect(stats.TestComponent.updateReqCount).to.equal(2)
		expect(stats.TestComponent.didUpdateCount).to.equal(1)
		expect(stats.TestComponent.shouldUpdateTime).never.to.equal(0)

		Reconciler.teardown(instance)
		Instrumentation.clearCollectedStats()
		GlobalConfig.reset()
	end)
end