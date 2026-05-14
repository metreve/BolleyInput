local MobileButtons = {}

function MobileButtons.Init(State, Context, actions)
	local playerGui = Context.PlayerGui
	local mobile = playerGui:FindFirstChild("MobileControls")

	if not mobile then
		return
	end

	local function connectButton(buttonName, callback)
		local button = mobile:FindFirstChild(buttonName, true)
		if not button then
			return
		end

		if button:IsA("GuiButton") then
			button.Activated:Connect(function()
				callback("Mobile", Enum.UserInputState.Begin, nil)
			end)
		end
	end

	connectButton("Dive", actions.Dive)
	connectButton("Sprint", actions.Sprint)
	connectButton("JumpMode", actions.JumpMode)
	connectButton("SetMode", actions.SetMode)
	connectButton("PowerUp", actions.PowerUp)
	connectButton("PowerDown", actions.PowerDown)
	connectButton("SpawnBall", actions.SpawnBall)
end

return MobileButtons
