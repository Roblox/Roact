return function()
	local RoactRoot = script.Parent.Parent
	local ShallowWrapper = require(script.Parent.ShallowWrapper)

	local assertDeepEqual = require(RoactRoot.assertDeepEqual)
	local Children = require(RoactRoot.PropMarkers.Children)
	local createElement = require(RoactRoot.createElement)
	local createFragment = require(RoactRoot.createFragment)
	local createReconciler = require(RoactRoot.createReconciler)
	local RoactComponent = require(RoactRoot.Component)
	local RobloxRenderer = require(RoactRoot.RobloxRenderer)

	local robloxReconciler = createReconciler(RobloxRenderer)

	local function shallow(element, depth)
		depth = depth or 1
		local hostParent = Instance.new("Folder")

		local virtualNode = robloxReconciler.mountVirtualNode(element, hostParent, "ShallowTree")

		return ShallowWrapper.new(virtualNode, depth)
	end

	describe("single host element", function()
		local className = "TextLabel"

		local function Component(props)
			return createElement(className, props)
		end

		it("should have its component set to the given instance class", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.component).to.equal(className)
		end)

		it("children count should be zero", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(#result.children).to.equal(0)
		end)
	end)

	describe("single function element", function()
		local function FunctionComponent(props)
			return createElement("TextLabel")
		end

		local function Component(props)
			return createElement(FunctionComponent, props)
		end

		it("should have its component set to the functional component", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.component).to.equal(FunctionComponent)
		end)
	end)

	describe("single stateful element", function()
		local StatefulComponent = RoactComponent:extend("StatefulComponent")

		function StatefulComponent:render()
			return createElement("TextLabel")
		end

		local function Component(props)
			return createElement(StatefulComponent, props)
		end

		it("should have its component set to the given component class", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.component).to.equal(StatefulComponent)
		end)
	end)

	describe("depth", function()
		local unwrappedClassName = "TextLabel"
		local function A(props)
			return createElement(unwrappedClassName)
		end

		local function B(props)
			return createElement(A)
		end

		local function Component(props)
			return createElement(B)
		end

		local function ComponentWithChildren(props)
			return createElement("Frame", {}, {
				ChildA = createElement(A),
				ChildB = createElement(B),
			})
		end

		it("should unwrap function components when depth has not exceeded", function()
			local element = createElement(Component)

			local result = shallow(element, 3)

			expect(result.component).to.equal(unwrappedClassName)
		end)

		it("should stop unwrapping function components when depth has exceeded", function()
			local element = createElement(Component)

			local result = shallow(element, 2)

			expect(result.component).to.equal(A)
		end)

		it("should not unwrap the element when depth is zero", function()
			local element = createElement(Component)

			local result = shallow(element, 0)

			expect(result.component).to.equal(Component)
		end)

		it("should not unwrap children when depth is one", function()
			local element = createElement(ComponentWithChildren)

			local result = shallow(element)

			local childA = result:find({
				component = A,
			})
			expect(#childA).to.equal(1)

			local childB = result:find({
				component = B,
			})
			expect(#childB).to.equal(1)
		end)

		it("should unwrap children when depth is two", function()
			local element = createElement(ComponentWithChildren)

			local result = shallow(element, 2)

			local hostChild = result:find({
				component = unwrappedClassName,
			})
			expect(#hostChild).to.equal(1)

			local unwrappedBChild = result:find({
				component = A,
			})
			expect(#unwrappedBChild).to.equal(1)
		end)

		it("should not include any children when depth is zero", function()
			local element = createElement(ComponentWithChildren)

			local result = shallow(element, 0)

			expect(#result.children).to.equal(0)
		end)

		it("should not include any grand-children when depth is one", function()
			local function ParentComponent()
				return createElement("Folder", {}, {
					Child = createElement(ComponentWithChildren),
				})
			end

			local element = createElement(ParentComponent)

			local result = shallow(element, 1)

			expect(#result.children).to.equal(1)

			local componentWithChildrenWrapper = result:find({
				component = ComponentWithChildren,
			})[1]
			expect(componentWithChildrenWrapper).to.be.ok()

			expect(#componentWithChildrenWrapper.children).to.equal(0)
		end)
	end)

	describe("children count", function()
		local childClassName = "TextLabel"

		local function Component(props)
			local children = {}

			for i=1, props.childrenCount do
				children[("Key%d"):format(i)] = createElement(childClassName)
			end

			return createElement("Frame", {}, children)
		end

		it("should have 1 child when the element contains only one element", function()
			local element = createElement(Component, {
				childrenCount = 1,
			})

			local result = shallow(element)

			expect(#result.children).to.equal(1)
		end)

		it("should not have any children when the element does not contain elements", function()
			local element = createElement(Component, {
				childrenCount = 0,
			})

			local result = shallow(element)

			expect(#result.children).to.equal(0)
		end)

		it("should count children in a fragment", function()
			local element = createElement("Frame", {}, {
				Frag = createFragment({
					Label = createElement("TextLabel"),
					Button = createElement("TextButton"),
				})
			})

			local result = shallow(element)

			expect(#result.children).to.equal(2)
		end)

		it("should count children nested in fragments", function()
			local element = createElement("Frame", {}, {
				Frag = createFragment({
					SubFrag = createFragment({
						Frame = createElement("Frame"),
					}),
					Label = createElement("TextLabel"),
					Button = createElement("TextButton"),
				})
			})

			local result = shallow(element)

			expect(#result.children).to.equal(3)
		end)
	end)

	describe("props", function()
		it("should contains the same props using Host element", function()
			local function Component(props)
				return createElement("Frame", props)
			end

			local props = {
				BackgroundTransparency = 1,
				Visible = false,
			}
			local element = createElement(Component, props)

			local result = shallow(element)

			expect(result.props).to.be.ok()

			assertDeepEqual(props, result.props)
		end)

		it("should have the same props using function element", function()
			local function ChildComponent(props)
				return createElement("Frame", props)
			end

			local function Component(props)
				return createElement(ChildComponent, props)
			end

			local props = {
				BackgroundTransparency = 1,
				Visible = false,
			}
			local propsCopy = {}
			for key, value in pairs(props) do
				propsCopy[key] = value
			end
			local element = createElement(Component, props)

			local result = shallow(element)

			expect(result.component).to.equal(ChildComponent)
			expect(result.props).to.be.ok()

			assertDeepEqual(propsCopy, result.props)
		end)

		it("should not have the children property", function()
			local function ComponentWithChildren(props)
				return createElement("Frame", props, {
					Key = createElement("TextLabel"),
				})
			end

			local props = {
				BackgroundTransparency = 1,
				Visible = false,
			}

			local element = createElement(ComponentWithChildren, props)

			local result = shallow(element)

			expect(result.props).to.be.ok()
			expect(result.props[Children]).never.to.be.ok()
		end)

		it("should have the inherited props", function()
			local function Component(props)
				local frameProps = {
					LayoutOrder = 7,
				}
				for key, value in pairs(props) do
					frameProps[key] = value
				end

				return createElement("Frame", frameProps)
			end

			local element = createElement(Component, {
				BackgroundTransparency = 1,
				Visible = false,
			})

			local result = shallow(element)

			expect(result.props).to.be.ok()

			local expectProps = {
				BackgroundTransparency = 1,
				Visible = false,
				LayoutOrder = 7,
			}

			assertDeepEqual(expectProps, result.props)
		end)
	end)

	describe("getHostObject", function()
		it("should return the instance when it is a host component", function()
			local className = "Frame"
			local function Component(props)
				return createElement(className)
			end

			local element = createElement(Component)
			local wrapper = shallow(element)

			local instance = wrapper:getHostObject()

			expect(instance).to.be.ok()
			expect(instance.ClassName).to.equal(className)
		end)

		it("should return nil if it is a function component", function()
			local function Child()
				return createElement("Frame")
			end
			local function Component(props)
				return createElement(Child)
			end

			local element = createElement(Component)
			local wrapper = shallow(element)

			local instance = wrapper:getHostObject()

			expect(instance).never.to.be.ok()
		end)
	end)

	describe("find children", function()
		it("should throw if the constraint does not exist", function()
			local element = createElement("Frame")

			local result = shallow(element)

			local function findWithInvalidConstraint()
				result:find({
					nothing = false,
				})
			end

			expect(findWithInvalidConstraint).to.throw()
		end)

		it("should return children that matches all contraints", function()
			local function ComponentWithChildren()
				return createElement("Frame", {}, {
					ChildA = createElement("TextLabel", {
						Visible = false,
					}),
					ChildB = createElement("TextButton", {
						Visible = false,
					}),
				})
			end

			local element = createElement(ComponentWithChildren)

			local result = shallow(element)

			local children = result:find({
				className = "TextLabel",
				props = {
					Visible = false,
				},
			})

			expect(#children).to.equal(1)
		end)

		it("should return children from fragments", function()
			local childClassName = "TextLabel"

			local function ComponentWithFragment()
				return createElement("Frame", {}, {
					Fragment = createFragment({
						Child = createElement(childClassName),
					}),
				})
			end

			local element = createElement(ComponentWithFragment)

			local result = shallow(element)

			local children = result:find({
				className = childClassName
			})

			expect(#children).to.equal(1)
		end)

		it("should return children from nested fragments", function()
			local childClassName = "TextLabel"

			local function ComponentWithFragment()
				return createElement("Frame", {}, {
					Fragment = createFragment({
						SubFragment = createFragment({
							Child = createElement(childClassName),
						}),
					}),
				})
			end

			local element = createElement(ComponentWithFragment)

			local result = shallow(element)

			local children = result:find({
				className = childClassName
			})

			expect(#children).to.equal(1)
		end)
	end)

	describe("findUnique", function()
		it("should return the only child when no constraints are given", function()
			local element = createElement("Frame", {}, {
				Child = createElement("TextLabel"),
			})

			local result = shallow(element)

			local child = result:findUnique()

			expect(child.component).to.equal("TextLabel")
		end)

		it("should return the only child that satifies the constraint", function()
			local element = createElement("Frame", {}, {
				ChildA = createElement("TextLabel"),
				ChildB = createElement("TextButton"),
			})

			local result = shallow(element)

			local child = result:findUnique({
				className = "TextLabel",
			})

			expect(child.component).to.equal("TextLabel")
		end)

		it("should throw if there is not any child element", function()
			local element = createElement("Frame")

			local result = shallow(element)

			local function shouldThrow()
				result:findUnique()
			end

			expect(shouldThrow).to.throw()
		end)

		it("should throw if more than one child satisfies the constraint", function()
			local element = createElement("Frame", {}, {
				ChildA = createElement("TextLabel"),
				ChildB = createElement("TextLabel"),
			})

			local result = shallow(element)

			local function shouldThrow()
				result:findUnique({
					className = "TextLabel",
				})
			end

			expect(shouldThrow).to.throw()
		end)
	end)
end