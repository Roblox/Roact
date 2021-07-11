local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Roact)

local Products = require(script:WaitForChild("Products"))

local Components = script:WaitForChild("Components")
local ShopPage = require(Components:WaitForChild("ShopPage"))

return function()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local shopPage = Roact.createElement(ShopPage, {
		items = Products,
		itemAspectRatio = 1,
		itemsPerRow = 3,
		padding = 10,
		frameProps = {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 3, 20),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.5, 0, 0.5, 0),
		},
	})

	local handle = Roact.mount(shopPage, screenGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end