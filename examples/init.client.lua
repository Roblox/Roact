local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local exampleData = {
	{
		name = "hello-roact",
		label = "Hello, Roact!",
	},
	{
		name = "clock",
		label = "Clock",
	},
	{
		name = "changed-signal",
		label = "Changed Signal",
	},
	{
		name = "stress-test",
		label = "Stress Test",
	},
	{
		name = "event",
		label = "Event",
	},
	{
		name = "ref",
		label = "Ref",
	},
	{
		name = "binding",
		label = "Binding",
	},
	{
		name = "shop-page",
		label = "Shop Page",
	},
}

for _, example in ipairs(exampleData) do
	example.source = script:WaitForChild(example.name)
	example.start = require(example.source)
end

local Examples = {}

Examples.exampleList = nil

function Examples.makeBackButton()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Back to Examples"

	local button = Instance.new("TextButton")
	button.Font = Enum.Font.SourceSans
	button.TextSize = 20
	button.Size = UDim2.new(0, 150, 0, 80)
	button.Position = UDim2.new(0, 0, 0.5, 0)
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.Text = "Back to Examples"
	button.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
	button.BorderColor3 = Color3.new(0, 0, 0)

	button.Activated:Connect(function()
		screenGui:Destroy()

		Examples.onStop()
		Examples.onStop = nil

		Examples.exampleList = Examples.makeExampleList()
		Examples.exampleList.Parent = PlayerGui
	end)

	button.Parent = screenGui

	return screenGui
end

function Examples.openExample(example)
	Examples.exampleList:Destroy()

	local back = Examples.makeBackButton()
	back.Parent = PlayerGui

	Examples.onStop = example.start()
end

function Examples.makeExampleList()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Roact Examples"

	local exampleList = Instance.new("ScrollingFrame")
	exampleList.Size = UDim2.new(0, 400, 0, 600)
	exampleList.CanvasSize = UDim2.new(0, 400, 0, 80 * #exampleData)
	exampleList.Position = UDim2.new(0.5, 0, 0.5, 0)
	exampleList.AnchorPoint = Vector2.new(0.5, 0.5)
	exampleList.BorderSizePixel = 2
	exampleList.BackgroundColor3 = Color3.new(1, 1, 1)
	exampleList.TopImage = "rbxassetid://29050676"
	exampleList.MidImage = "rbxassetid://29050676"
	exampleList.BottomImage = "rbxassetid://29050676"
	exampleList.Parent = screenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = exampleList

	for index, example in ipairs(exampleData) do
		local label = ("%s\nexamples/%s"):format(example.label, example.name)

		local exampleCard = Instance.new("TextButton")
		exampleCard.Name = "Example: " .. example.name
		exampleCard.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
		exampleCard.BorderSizePixel = 0
		exampleCard.Text = label
		exampleCard.Font = Enum.Font.SourceSans
		exampleCard.TextSize = 20
		exampleCard.Size = UDim2.new(1, 0, 0, 80)
		exampleCard.LayoutOrder = index

		exampleCard.Activated:Connect(function()
			Examples.openExample(example)
		end)

		exampleCard.Parent = exampleList

		local bottomBorder = Instance.new("Frame")
		bottomBorder.Name = "Bottom Border"
		bottomBorder.Position = UDim2.new(0, 0, 1, -1)
		bottomBorder.Size = UDim2.new(0, 400, 0, 1)
		bottomBorder.BorderSizePixel = 0
		bottomBorder.BackgroundColor3 = Color3.new(0, 0, 0)
		bottomBorder.ZIndex = 2
		bottomBorder.Parent = exampleCard
	end

	return screenGui
end

Examples.exampleList = Examples.makeExampleList()
Examples.exampleList.Parent = PlayerGui