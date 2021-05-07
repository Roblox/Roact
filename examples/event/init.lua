return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Roact = require(ReplicatedStorage.Roact)

	local playerGui = Players.LocalPlayer.PlayerGui

	local app = Roact.createElement("ScreenGui", nil, {
		Button = Roact.createElement("TextButton", {
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),

			-- Attach event listeners using `Roact.Event[eventName]`
			-- Event listeners get `rbx` as their first parameter
			-- followed by their normal event arguments.
			[Roact.Event.Activated] = function(_)
				print("The button was clicked!")
			end,
		}),
	})

	local handle = Roact.mount(app, playerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end
