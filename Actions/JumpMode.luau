local JumpMode = {}

local function updateBars()
	-- Later this will call UI.Bars.Update()
end

function JumpMode.Toggle(State, Context)
	if not State.Switchable then
		return
	end

	State.JumpMode = not State.JumpMode
	State.SetMode = false

	Context.Player.PlayerGui.Misc.ControlDisplay.Event:Fire("Jumpmode Switch")

	updateBars()
end

function JumpMode.SetMode(State, Context)
	if not State.Switchable then
		return
	end

	Context.Player.PlayerGui.Misc.ControlDisplay.Event:Fire("Setmode Switch")

	State.SetMode = not State.SetMode

	if State.SetMode then
		State.JumpMode = false
	else
		State.JumpMode = true
	end

	updateBars()
end

return JumpMode
