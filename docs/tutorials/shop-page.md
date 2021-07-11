# Shop page
_Goal: Create a page to sell developer products in a game._

<div align="center">
	<a href="../../images/shop-page.jpg">
		<img src="../../images/shop-page.jpg" alt="Shop Page Preview" />
	</a>
</div>

---

## The ShopPage Component

Let's start by creating the top level component, which will be the page that contains the items for sale in the game. When creating a new component, we need to think about what this component will manage and what will be given to that component from the parent component.

In our case, the ShopPage component we're making will receive its products from a parent component: that means that the product items will be received as props in our component.

!!! Note
	<h5>Props or state?</h5>
	This is a question that often comes to our mind when we start working with Roact. Remember that state is internal to the component. Things that are relevant only to a component should go in the state.

	On the other hand, props are used to pass data from parent components to child components. It implies that both parent component and its child are aware of the structure of the props dictionary and depend on it.

For our first draft of the component, we will define some props to be able to pass parameters to customize our shop page. We will start by adding the following:

  - **frameProps:** a dictionary of props that will be passed to the ScrollingFrame to change its visuals
  - **items:** a list of objects that represent the products we want to sell
  - **padding:** the number of pixels between each of our items in the shop

```lua
local ShopPage = Roact.Component:extend("ShopPage")

function ShopPage:render()
	local props = self.props

	local items = props.items
	local frameProps = props.frameProps
	local padding = props.padding

	return Roact.createElement("ScrollingFrame", frameProps, {
		UIGrid = Roact.createElement("UIGridLayout", {
			CellPadding = UDim2.new(0, padding, 0, padding),
			CellSize = UDim2.new(0, 100, 0, 100),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

return ShopPage
```

As you can see, `frameProps` is used when creating the ScrollingFrame! This way, we can control how the container looks from outside the parent of the component.

---

### Viewing the Component

Now that we have started working on our first component, we want to be able to see the results. To do that, let's create a LocalScript that will let us view our component. This script needs to mount our ShopPage into a parent, which will simply be a ScreenGui.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- we assume here that the components are located in
-- a folder under ReplicatedStorage
local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ShopPage = require(Components:WaitForChild("ShopPage"))

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local shopPage = Roact.createElement(ShopPage, {
	-- we're not ready for this yet so it's just
	-- an empty list
	items = {},
	padding = 10,
	frameProps = {
		-- here we define the properties of the ScrollingFrame
		-- for our ShopPage
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 3, 20),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0.5, 0),
	},
})

Roact.mount(shopPage, screenGui)
```

The two important things to notice here are:

  - An element is created from our ShopPage component, where we specified the different props we want
  - `Roact.mount` will create the real GUI instances we need to see the results

---

### Adjusting Canvas Size from Items

We want to adjust the ScrollingFrame so its *CanvasSize* property always fits the height of the items. For that, we will add new props to control the sizing of the grid elements.

  - **itemsPerRow:** the number of items on each row
  - **itemAspectRatio:** the aspect ratio of each item

We can pass those props down from the script that mounts the ShopPage component. We can edit the previous script to add those props.

```lua
local shopPage = Roact.createElement(ShopPage, {
	items = {},
	-- add the new props with any value you would like
	itemAspectRatio = 1,
	itemsPerRow = 3,
	--
	padding = 10,
	frameProps = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 3, 20),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0.5, 0),
	},
})
```

With these new props, we are going to be able to compute the optimal cell size for our grid and also the height of the ScrollingFrame's *CanvasSize*. Once the *AbsoluteSize* property of our ScrollingFrame changes, we will update the state of our component with the new computed cell size and height. Let's add these computed values to the component state.

```lua
function ShopPage:init()
	-- set default values
	self:setState({
		cellSize = 0,
		canvasHeight = 0,
	})
end
```

And update the render method to use the state.

```lua
function ShopPage:render()
	local props = self.props

	local items = props.items
	local frameProps = props.frameProps
	local padding = props.padding

	local cellSize = state.cellSize
	local canvasHeight = state.canvasHeight

	-- we need to clone the frameProps because we can't mutate it!
	local newFrameProps = {}

	for key, value in pairs(frameProps) do
		newFrameProps[key] = value
	end

	-- now that we have cloned the ScrollingFrame props, we add new entries
	newFrameProps.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)

	return Roact.createElement("ScrollingFrame", newFrameProps, {
		UIGrid = Roact.createElement("UIGridLayout", {
			CellPadding = UDim2.new(0, padding, 0, padding),
			-- now we can use the cellSize from the state!
			CellSize = UDim2.new(0, cellSize, 0, cellSize * itemAspectRatio),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end
```

Then, we need to update the state when the ScrollingFrame size changes. To connect a function to a changed property event, we use [`Roact.Change`](https://roblox.github.io/roact/api-reference/#roactchange). In our case, we will listen to the `AbsoluteSize` property change of the ScrollingFrame. The cell size of the grid will be computed to maximize the horizontal space. After, the aspect ratio of the items are used to find the vertical space needed to contain all of them.

```lua
function ShopPage:init()
	...

	self.onAbsoluteSizeChanged = function(frame)
		local props = self.props
		local padding = props.padding
		local itemsPerRow = props.itemsPerRow

		local totalWidth = frame.AbsoluteSize.X
		local cellWidth = (totalWidth - padding * (itemsPerRow + 1)) / itemsPerRow
		local cellHeight = cellWidth / props.itemAspectRatio
		local rows = math.ceil(#props.items / itemsPerRow)
		local canvasHeight = rows * cellHeight + padding * (rows + 1)

		-- we update the state with the new values
		self:setState({
			cellSize = cellWidth,
			canvasHeight = canvasHeight,
		})
	end
end

function ShopPage:render()
	...
	-- connect the function in the render method
	newFrameProps[Roact.Change.AbsoluteSize] = self.onAbsoluteSizeChanged
	...
end
```

!!! Note
	<h5>Aspect Ratio</h5>
	Aspect ratio is a number that represent the relation between the width and the height of an image. It can easily be calculated by dividing the width by the height of the image. In the previous snippet, we are using the given aspect ratio to calculate the space needed to fit all the items. We start by calculating the width of a cell by taking the width of the scrolling frame, removing the padding between all the items and then divide it by the number of items on a row.

	```lua
	availableWidth = totalWidth - padding * (itemsPerRow + 1)
	cellWidth = availableWidth / itemsPerRow
	```

	So now in order to maintain the aspect ratio, we can calculate the height of the cell by dividing the width by the aspect ratio.

	```lua
	cellHeight = cellWidth / aspectRatio
	```

---

## Adding Items

In the previous section we created a ScrollingFrame that contains a UIGridLayout object. Now, we want to add elements that represent each item we sell in our shop. In order to be able to add a variable amount of items in our component, we will iterate on the list of products to create an element for each of them.

To keep our component simple, let's divide this feature into different components:

  - **Item:** a card that shows the price of an item with its image, and when clicked prompts the player to buy the product
  - **ItemList:** iterate on the list of items to create each individual Item element

---

### ItemList

This component will simply be given the product list and create all the Item elements. Since it does not need any internal state, a functional component will do the job. We have not made our Item component yet, but we will pretend it is there for now.

We will define the props that the Item component will use to render its component. We will make it accepts these props:

  - **image:** the image representing the product that the component will display.
  - **price:** how many robux the product costs.
  - **productId:** the identifier of the developer product.
  - **order:** used to specify the order of the items in the shop. We will make this optional, so if it is not provided, it will sort the items by their costs.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local Item = require(Components:WaitForChild("Item"))

local function ItemList(props)
	local items = props.items

	local elements = {}

	for i=1, #items do
		local item = items[i]

		elements[item.identifier] = Roact.createElement(Item, {
			image = item.image,
			price = item.price,
			productId = item.productId,
			order = item.order,
		})
	end

	return Roact.createFragment(elements)
end

return ItemList
```

!!! Note
	<h5>Fragments</h5>
	Elements contained in a Fragment are parented to the Fragment's parent. That way responsibilities of the grid view can be split from the content. The ShopPage component will handle the grid view, so it owns the *UIGridLayout* object, and it will give the responsibility to the *ItemList* component to take care of the content.

With that, we can go change our render function in the ShopPage component to create an element of ItemList and pass the items list as a prop.

```lua
return Roact.createElement("ScrollingFrame", frameProps, {
	UIGrid = Roact.createElement("UIGridLayout", {
		CellPadding = UDim2.new(0, padding, 0, padding),
		CellSize = UDim2.new(0, 100, 0, 100),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Items = Roact.createElement(ItemList, {
		items = items,
	}),
})
```

---

## Item
For our last component, we are going to use a stateful component to be able to use some lifecycle methods. Let's start first by doing a basic view of our props.

```lua
local PADDING = 20

local Item = Roact.Component:extend("Item")

function Item:render()
	local props = self.props

	local image = props.image
	local price = props.price
	local order = props.order or price

	return Roact.createElement("ImageButton", {
		BackgroundTransparency = 1,
		Image = "",
		LayoutOrder = order,
	}, {
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = image,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -PADDING, 1, -PADDING),
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

return Item
```

We can now populate our shop with an item! Let's go back to where we mount our ShopPage component and add an item to our list. Don't forget to customize the settings here: put an image that fits your product, enter the price and the developer product ID.

```lua
local shopPage = Roact.createElement(ShopPage, {
	items = {
		{
			identifier = "Red Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=139618072&width=420&height=420&format=png",
			price = 30,
			-- here we should have a valid developer product id
			productId = 0,
		},
	},
	frameProps = {
		-- here we define the properties of the ScrollingFrame for our ShopPage
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 3, 20),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0.5, 0),
	},
	padding = 10,
})
```

Now, we want to prompt the player to buy the product when he clicks on the button. For that, we will use the *Activated* event to fire a function. We can create this function in the [`init`](https://roblox.github.io/roact/guide/state-and-lifecycle/#lifecycle-methods) lifecycle method.

```lua
local MarketplaceService = game:GetService("MarketplaceService")

function Item:init()
	self.onActivated = function()
		local props = self.props

		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, props.productId)
	end
end
```

Then, we simply use `Roact.Event.Activated` to tell Roact to connect the function to the _Activated_ event.

```lua
function Item:render()
	...

return Roact.createElement("ImageButton", {
	BackgroundTransparency = 1,
	Image = "",
	LayoutOrder = order,
	[Roact.Event.Activated] = self.onActivated,
}, {
	...
}

	...
end
```

!!! Note
	<h5>Why are there brackets here?</h5>
	In lua, the keys in a table can be any value. The most common way to map keys and values in a table construction is with `foo = something`. In this case, `foo` will be considered a string. So if we had this entry in a table `t`, we can access its value with `t.foo` or `t["foo"]`.

	What if we want a key like `"foo.bar"`? For this, the lua syntax allow us to write this entry as `["foo.bar"] = something`. So between the brackets, any value can be given. That is why brackets are use for `Roact.Event.Activated`: we don't want to pass a string that could collide with other props, instead we use a unique value owned by Roact.

---

## Adding Animations

To make our UI more lively, we are going to use [*TweenService*](https://developer.roblox.com/en-us/api-reference/class/TweenService) for animations. The goal is to make the icon bigger when the mouse is inside the button. To be able to do that, we need a reference to the roblox instance we want to animate. Roact can provide that through refs. First we start by creating the ref in the [`init`](https://roblox.github.io/roact/guide/state-and-lifecycle/#lifecycle-methods) lifecycle method.

```lua
function Item:init()
	self.ref = Roact.createRef()
	...
end
```

Since we want to animate the size of the icon, the ref is going to be in the ImageLabel props.

```lua
Icon = Roact.createElement("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Image = image,
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(1, -PADDING, 1, -PADDING),
	[Roact.Ref] = self.ref,
}),
```

Next step is to create the Tween object when the component is mounted. The [`didMount`](https://roblox.github.io/roact/guide/state-and-lifecycle/#lifecycle-methods) lifecycle method is perfectly suited for this case, since it will be called once the instance is created.

```lua
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
```

Don't forget to clean up! When the component will be unmounted, we need to destroy the Tween objects that were created. We use the [`willUnmount`](https://roblox.github.io/roact/guide/state-and-lifecycle/#lifecycle-methods) lifecycle method to do this.

```lua
function Item:willUnmount()
	self.toBigIcon:Destroy()
	self.toNormalIcon:Destroy()
end
```

---

## Integration in a non-Roact project
If your game already has UI elements, you don't have to redo them in Roact in order to integrate this ShopPage component into your game. Roact can be used in an existing UI tree. For example, let's say you would have a ScreenGui with a Frame inside where you'd would like to put this component. In a LocalScript, you would simply have to mount the ShopPage component in the Frame.

```lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("MyScreenGui")
local frame = screenGui:WaitForChild("TheShopPageContainer")

local shopPage = Roact.createElement(ShopPage, {
	items = {...}, -- Put your items here
	itemAspectRatio = 1,
	itemsPerRow = 3,
	padding = 10,
	frameProps = {
		-- Customize the scrolling frame here. For example, we can
		-- make this one transparent and fill up the container
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
	},
})

Roact.mount(shopPage, frame)
```

As you can see from this, it is possible to slowly port an existing UI to use Roact by mounting components into existing instances of the UI.
