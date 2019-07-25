local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ProductItemList = require(Components:WaitForChild("ProductItemList"))

local ShopPage = Roact.Component:extend("ShopPage")

ShopPage.defaultProps = {
	padding = 0,
}

function ShopPage:init()
	self:setState({
		cellSize = 100,
		canvasHeight = 100,
	})

	self.onAbsoluteSizeChanged = function(frame)
		local props = self.props
		local padding = props.padding
		local itemsPerRow = props.itemsPerRow

		local totalWidth = frame.AbsoluteSize.X
		local cellWidth = (totalWidth - padding * (itemsPerRow + 1)) / itemsPerRow
		local cellHeight = cellWidth * props.itemAspectRatio
		local rows = math.ceil(#props.items / itemsPerRow)
		local canvasHeight = rows * cellHeight + padding * (rows + 1)

		self:setState({
			cellSize = cellWidth,
			canvasHeight = canvasHeight,
		})
	end
end

function ShopPage:render()
	local props = self.props
	local state = self.state

	local items = props.items
	local itemAspectRatio = props.itemAspectRatio
	local frameProps = props.frameProps
	local padding = props.padding

	local cellSize = state.cellSize
	local canvasHeight = state.canvasHeight

	local newFrameProps = {}

	for key, value in pairs(frameProps) do
		newFrameProps[key] = value
	end

	newFrameProps.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
	newFrameProps.ClipsDescendants = true
	newFrameProps[Roact.Change.AbsoluteSize] = self.onAbsoluteSizeChanged

	return Roact.createElement("ScrollingFrame", newFrameProps, {
		UIGrid = Roact.createElement("UIGridLayout", {
			CellPadding = UDim2.new(0, padding, 0, padding),
			CellSize = UDim2.new(0, cellSize, 0, cellSize * itemAspectRatio),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		ProductItems = Roact.createElement(ProductItemList, {
			items = items
		}),
	})
end

return ShopPage