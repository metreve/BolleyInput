local JumpMode = {}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

function JumpMode.Toggle(State, Context)
	if not State.Switchable then
		return
	end

	-- Toggle between spike and block.
	-- Leaving setter mode when manually switching jump/block.
	State.SetMode = false
	State.JumpMode = not State.JumpMode

	fireControlDisplay(Context, "Jumpmode Switch")
end

function JumpMode.SetMode(State, Context)
	if not State.Switchable then
		return
	end

	-- Setter mode is still a jump/spike-style jump, NOT blocker mode.
	State.SetMode = not State.SetMode

	if State.SetMode then
		State.JumpMode = true
	else
		State.JumpMode = true
	end

	fireControlDisplay(Context, "Setmode Switch")
end

return JumpMode
