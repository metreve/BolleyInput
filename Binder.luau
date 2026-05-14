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
	bind("SpawnBall", actions.SpawnBall, false, Enum.KeyCode.G, Enum.KeyCode.DPadLeft)
	bind("PowerUp", actions.PowerUp, false, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
	bind("PowerDown", actions.PowerDown, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)

	bind("Sprint", actions.Sprint, false, Enum.KeyCode.T, Enum.KeyCode.ButtonL2)
	bind("Dive", actions.Dive, false, Enum.KeyCode.Three, Enum.KeyCode.ButtonX)

	bind("JumpMode", actions.JumpMode, false, Enum.KeyCode.One, Enum.KeyCode.DPadUp)
	bind("SetMode", actions.SetMode, false, Enum.KeyCode.M)

	bind("FrontSet", actions.FrontSet, false, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
	bind("BackSet", actions.BackSet, false, Enum.KeyCode.R, Enum.KeyCode.ButtonB)
	bind("Dump", actions.Dump, false, Enum.KeyCode.Four)
	bind("Serve", actions.Serve, false, Enum.KeyCode.V, Enum.KeyCode.DPadDown)

	bind("Click", actions.Click, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	bind("Jump", actions.Jump, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	bind("PowerSet1", actions.PowerSet1, false, Enum.KeyCode.Z)
	bind("PowerSet2", actions.PowerSet2, false, Enum.KeyCode.X)
	bind("PowerSet3", actions.PowerSet3, false, Enum.KeyCode.C)
end

function Binder.UnbindAll()
	for actionName in pairs(boundActions) do
		ContextActionService:UnbindAction(actionName)
	end

	table.clear(boundActions)
end

return Binder
