local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Roact)

local Item = Roact.Component:extend("Item")

local PADDING = 20

function Item:init()
	self.ref = Roact.createRef()
	self.onMouseEnter = function()
		self.toBigIcon:Play()
	end
	self.onMouseLeave = function()
		self.toNormalIcon:Play()
	end
	self.onActivated = function()
		local props = self.props

		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, props.productId)
	end
end

function Item:render()
	local props = self.props

	local image = props.image
	local price = props.price
	local order = props.order or price

	return Roact.createElement("ImageButton", {
		BackgroundTransparency = 1,
		Image = "",
		LayoutOrder = order,
		[Roact.Event.Activated] = self.onActivated,
		[Roact.Event.MouseEnter] = self.onMouseEnter,
		[Roact.Event.MouseLeave] = self.onMouseLeave,
	}, {
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = image,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -PADDING, 1, -PADDING),
			[Roact.Ref] = self.ref,
		}),
		PriceLabel = Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.SourceSans,
			Text = ("R$ %d"):format(price),
			TextColor3 = Color3.fromRGB(10, 200, 10),
			TextScaled = true,
			TextStrokeTransparency = 0,
			TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0.3, 0),
		}),
	})
end

function Item:didMount()
	local tweenInfo = TweenInfo.new(0.2)
	local icon = self.ref:getValue()

	self.toBigIcon = TweenService:Create(icon, tweenInfo, {
		Size = UDim2.new(1, 0, 1, 0),
	})
	self.toNormalIcon = TweenService:Create(icon, tweenInfo, {
		Size = UDim2.new(1, -PADDING, 1, -PADDING),
	})
end

function Item:willUnmount()
	self.toBigIcon:Destroy()
	self.toNormalIcon:Destroy()
end

return Item