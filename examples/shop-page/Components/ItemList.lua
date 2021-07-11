local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = script.Parent

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