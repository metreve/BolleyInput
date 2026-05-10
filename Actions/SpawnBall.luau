local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)

local Tilt = {}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function getTiltObjects(State)
	local rootPart = State.RootPart
	if not rootPart then
		return nil, nil
	end

	local tilt = rootPart:FindFirstChild("Tilt")

	if not tilt then
		tilt = Instance.new("BodyGyro")
		tilt.Name = "Tilt"
		tilt.MaxTorque = Vector3.new(0.6, 0.6, 0.6)
		tilt.CFrame = rootPart.CFrame
		tilt.Parent = rootPart
	end

	local origin = tilt:FindFirstChild("Origin")
	if not origin then
		origin = Instance.new("CFrameValue")
		origin.Name = "Origin"
		origin.Value = rootPart.CFrame
		origin.Parent = tilt
	end

	return tilt, origin
end

local function resetTiltOnLanding(State, Context, oldFov)
	local character = State.Character
	local humanoid = State.Humanoid

	if not character or not humanoid then
		return
	end

	if State.AwaitForState then
		State.AwaitForState:Disconnect()
		State.AwaitForState = nil
	end

	State.AwaitForState = humanoid.StateChanged:Connect(function(_, state)
		if state ~= Enum.HumanoidStateType.Landed then
			return
		end

		if humanoid.FloorMaterial == Enum.Material.Air then
			return
		end

		if State.AvailableSideTiltAnim then
			State.AvailableSideTiltAnim:Stop()
			State.AvailableSideTiltAnim:Remove()
			State.AvailableSideTiltAnim = nil
		end

		State.Switchable = true
		State.FovApplied = false

		TweenService:Create(
			workspace.CurrentCamera,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ FieldOfView = tonumber(oldFov) }
		):Play()

		TweenService:Create(
			humanoid,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CameraOffset = Vector3.new(0, 0, 0) }
		):Play()
	end)
end

local function playBlockTiltAnimation(State, Context, direction)
	if State.JumpMode then
		return
	end

	if State.AvailableSideTiltAnim then
		State.AvailableSideTiltAnim:Stop()
		State.AvailableSideTiltAnim:Remove()
		State.AvailableSideTiltAnim = nil
	end

	local library = AnimationModule.Library.Blocking.Default_Small
	local animation

	if direction == "Forward" then
		if State.VBlocking then
			animation = library["V BlockW"]
		else
			animation = library.KillBlock
		end
	elseif direction == "Left" then
		animation = library.LeftBlock
	elseif direction == "Right" then
		animation = library.RightBlock
	end

	if animation then
		State.AvailableSideTiltAnim = AnimationModule:PlayAnimation(Context.Player, {
			AdjustSpeed = 1,
			AdjustWeight = 1,
			Animation = animation,
		})
	end
end

function Tilt.Apply(State, Context, direction)
	if State.SetMode then
		return
	end
	if not State.InAirTiltable then
		return
	end

	local rootPart = State.RootPart
	local humanoid = State.Humanoid

	if not rootPart or not humanoid then
		return
	end

	local tilt, origin = getTiltObjects(State)
	if not tilt or not origin then
		return
	end

	local oldFov = Context.Data:GetAttribute("FOV") or workspace.CurrentCamera.FieldOfView

	if direction == "Forward" then
		fireControlDisplay(Context, "Jump + W")

		State.CurrentTilt = "W"
		Context.Remotes.TiltType:FireServer("W")

		playBlockTiltAnimation(State, Context, direction)
		resetTiltOnLanding(State, Context, oldFov)

		if not State.JumpMode then
			Context.ChangeStatus:FireServer("Front", "Block Tilt")
		end

		tilt.CFrame = origin.Value * CFrame.Angles(math.rad(-90), 0, 0)

		if Context.Data:GetAttribute("FOVE") then
			if not State.FovApplied then
				State.FovApplied = true

				TweenService:Create(
					workspace.CurrentCamera,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ FieldOfView = oldFov - 5 }
				):Play()
			end

			TweenService:Create(
				humanoid,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ CameraOffset = Vector3.new(0, 0, -1.5) }
			):Play()
		end
	elseif direction == "Left" then
		if not State.JumpMode and State.VBlocking then
			return
		end

		fireControlDisplay(Context, "Jump + A")

		State.CurrentTilt = "A"
		Context.Remotes.TiltType:FireServer("A")

		playBlockTiltAnimation(State, Context, direction)
		resetTiltOnLanding(State, Context, oldFov)

		if State.JumpMode then
			tilt.CFrame = origin.Value * CFrame.Angles(0, 0, math.rad(90))
		else
			tilt.CFrame = origin.Value
			Context.ChangeStatus:FireServer("Left", "Block Tilt")
		end

		TweenService:Create(
			workspace.CurrentCamera,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ FieldOfView = tonumber(oldFov) }
		):Play()

		TweenService:Create(
			humanoid,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CameraOffset = Vector3.new(-1.5, 0, 0) }
		):Play()
	elseif direction == "Back" then
		fireControlDisplay(Context, "Jump + S")

		State.CurrentTilt = "S"
		Context.Remotes.TiltType:FireServer("S")

		if State.AvailableSideTiltAnim then
			State.AvailableSideTiltAnim:Stop()
			State.AvailableSideTiltAnim:Remove()
			State.AvailableSideTiltAnim = nil
		end

		tilt.CFrame = origin.Value * CFrame.Angles(math.rad(90), 0, 0)

		if not State.JumpMode then
			Context.ChangeStatus:FireServer("None", "Block Tilt")
		end

		TweenService:Create(
			workspace.CurrentCamera,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ FieldOfView = tonumber(oldFov) }
		):Play()

		TweenService:Create(
			humanoid,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CameraOffset = Vector3.new(0, 0, 1.5) }
		):Play()
	elseif direction == "Right" then
		if not State.JumpMode and State.VBlocking then
			return
		end

		fireControlDisplay(Context, "Jump + D")

		State.CurrentTilt = "D"
		Context.Remotes.TiltType:FireServer("D")

		playBlockTiltAnimation(State, Context, direction)
		resetTiltOnLanding(State, Context, oldFov)

		if State.JumpMode then
			tilt.CFrame = origin.Value * CFrame.Angles(0, 0, math.rad(-90))
		else
			tilt.CFrame = origin.Value
			Context.ChangeStatus:FireServer("Right", "Block Tilt")
		end

		TweenService:Create(
			workspace.CurrentCamera,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ FieldOfView = tonumber(oldFov) }
		):Play()

		TweenService:Create(
			humanoid,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CameraOffset = Vector3.new(1.5, 0, 0) }
		):Play()
	end
end

return Tilt
