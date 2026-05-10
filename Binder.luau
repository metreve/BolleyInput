local ContextActionService = game:GetService("ContextActionService")

local Binder = {}

local boundActions = {}

local function bind(actionName, callback, createTouchButton, ...)
	if boundActions[actionName] then
		ContextActionService:UnbindAction(actionName)
	end

	ContextActionService:BindAction(actionName, callback, createTouchButton, ...)
	boundActions[actionName] = true
end

function Binder.Bind(actions)
	bind("SpawnBall", actions.SpawnBall, false, Enum.KeyCode.G)
	bind("PowerUp", actions.PowerUp, false, Enum.KeyCode.Equals, Enum.KeyCode.ButtonR1)
	bind("PowerDown", actions.PowerDown, false, Enum.KeyCode.Minus, Enum.KeyCode.ButtonL1)

	bind("Sprint", actions.Sprint, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	bind("Dive", actions.Dive, false, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonX)

	bind("JumpMode", actions.JumpMode, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	bind("SetMode", actions.SetMode, false, Enum.KeyCode.R)

	bind("FrontSet", actions.FrontSet, false, Enum.KeyCode.E)
	bind("BackSet", actions.BackSet, false, Enum.KeyCode.F)
	bind("Dump", actions.Dump, false, Enum.KeyCode.C)

	bind("Jump", actions.Jump, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

function Binder.UnbindAll()
	for actionName in pairs(boundActions) do
		ContextActionService:UnbindAction(actionName)
	end

	table.clear(boundActions)
end

return Binder
