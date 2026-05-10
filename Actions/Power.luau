local Power = {}

local holding = {
	Increase = false,
	Decrease = false,
}

local function firePower(Context, amount)
	Context.PowerHandler:FireServer("P", amount)
end

local function startHolding(Context, change)
	if holding[change] then
		return
	end

	holding[change] = true

	task.spawn(function()
		while holding[change] do
			if change == "Increase" then
				firePower(Context, 1)
			elseif change == "Decrease" then
				firePower(Context, -1)
			end

			task.wait(0.08)
		end
	end)
end

function Power.Handle(State, Context, change, inputState)
	if not State.PowerChangeable then
		return
	end

	if inputState == Enum.UserInputState.Begin then
		startHolding(Context, change)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		holding[change] = false
	end
end

function Power.SetPreset(Context, index)
	local keybindFolder = Context.Player:WaitForChild("Keybinds")
	local value = keybindFolder:GetAttribute("PowerKey" .. tostring(index))

	if value then
		Context.PowerHandler:FireServer(value)
	end
end

return Power
