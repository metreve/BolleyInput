local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)
local Specs = require(ReplicatedStorage.Modules.Specs)

local Set = {}

local function getPlayer(Context)
	return Context.Player
end

local function getHumanoid(State)
	return State.Humanoid
end

local function getRootPart(State)
	return State.RootPart
end

local function getAnimations()
	return ReplicatedStorage:WaitForChild("Animations")
end

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function isFacingCamera(State)
	local character = State.Character
	if not character then
		return "JFront"
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return "JFront"
	end

	local camera = workspace.CurrentCamera
	local cameraLookVector = camera.CFrame.LookVector

	local relativeDirection = rootPart.CFrame:VectorToObjectSpace(cameraLookVector)

	local angle = math.atan2(relativeDirection.X, -relativeDirection.Z)
	local degree = math.deg(angle)

	if degree < 0 then
		degree += 360
	end

	if degree >= 337.5 or degree < 22.5 then
		return "JFront"
	elseif degree >= 22.5 and degree < 67.5 then
		return "FrontRight"
	elseif degree >= 67.5 and degree < 112.5 then
		return "Right"
	elseif degree >= 112.5 and degree < 157.5 then
		return "BackRight"
	elseif degree >= 157.5 and degree < 202.5 then
		return "JBack"
	elseif degree >= 202.5 and degree < 247.5 then
		return "BackLeft"
	elseif degree >= 247.5 and degree < 292.5 then
		return "Left"
	elseif degree >= 292.5 and degree < 337.5 then
		return "FrontLeft"
	end

	return "JFront"
end

local function playSettingAnimation(Context, animation)
	if not animation then
		warn("[Set] Missing setting animation")
		return
	end

	AnimationModule:PlayAnimation(Context.Player, {
		AdjustSpeed = 1,
		AdjustWeight = 1,
		Animation = animation,
	})
end

function Set.Front(State, Context)
	local humanoid = getHumanoid(State)
	if not humanoid then
		return
	end

	if not State.Setable then
		return
	end
	if State.Dived then
		return
	end
	if State.SpaceHeld then
		return
	end

	fireControlDisplay(Context, "Front Set")

	if State.Ready and not State.Spiked then
		State.Ready = false
		State.Spikable = false

		local camera = workspace.CurrentCamera

		if State.SetMode then
			Context.PlayerAction:FireServer("SetMode", camera.CFrame.LookVector.Unit)

			local direction = isFacingCamera(State)
			playSettingAnimation(Context, AnimationModule.Library.Setting.SetMode[direction])

			Context.ChangeStatus:FireServer("Setting")
		else
			Context.PlayerAction:FireServer("NotSetMode")
			playSettingAnimation(Context, AnimationModule.Library.Setting.Default_Small.FrontSet)

			Context.ChangeStatus:FireServer("Setting")
		end

		task.delay(0.8, function()
			State.Spikable = true

			if not State.AutoServe then
				State.Ready = true
			end
		end)

		return
	end

	if humanoid.FloorMaterial == Enum.Material.Air and not State.JumpSetted and not State.Spiked then
		State.JumpSetted = true
		State.Spikable = false

		local camera = workspace.CurrentCamera

		if State.SetMode then
			Context.PlayerAction:FireServer("SetMode", camera.CFrame.LookVector.Unit)

			local direction = isFacingCamera(State)
			playSettingAnimation(Context, AnimationModule.Library.Setting.SetMode[direction])

			Context.ChangeStatus:FireServer("Setting")
		else
			Context.PlayerAction:FireServer("NotSetMode")
			playSettingAnimation(Context, AnimationModule.Library.Setting.Default_Small.JFront)

			Context.ChangeStatus:FireServer("Setting")
		end

		task.delay(1, function()
			State.Spikable = true
		end)
	end
end

function Set.Back(State, Context)
	local humanoid = getHumanoid(State)
	if not humanoid then
		return
	end

	if State.SetMode and humanoid.FloorMaterial == Enum.Material.Air then
		return
	end
	if not State.Setable then
		return
	end
	if State.Dived then
		return
	end
	if State.SpaceHeld then
		return
	end

	fireControlDisplay(Context, "Back Set")

	if State.Ready and not State.Spiked then
		State.Ready = false
		State.Spikable = false

		playSettingAnimation(Context, AnimationModule.Library.Setting.Default_Small.BackSet)
		Context.ChangeStatus:FireServer("Backsetting")

		task.delay(0.8, function()
			State.Spikable = true

			if not State.AutoServe then
				State.Ready = true
			end
		end)

		return
	end

	if State.Jumped and not State.JumpSetted and not State.Spiked then
		State.JumpSetted = true
		State.Spikable = false

		playSettingAnimation(Context, AnimationModule.Library.Setting.Default_Small.JBack)
		Context.ChangeStatus:FireServer("Backsetting")

		task.delay(1, function()
			State.Spikable = true
		end)
	end
end

function Set.Dump(State, Context)
	local rootPart = getRootPart(State)
	if not rootPart then
		return
	end
	if State.Dived then
		return
	end

	local tilt = rootPart:FindFirstChild("Tilt")

	if not tilt then
		Set.Front(State, Context)
		return
	end

	local _, _, shifting = tilt.CFrame:ToOrientation()

	if math.abs(shifting) < 0.1 then
		Set.Front(State, Context)
		return
	end

	fireControlDisplay(Context, "Dumping")

	local isLeftDump = shifting > 0
	local animation = isLeftDump and AnimationModule.Library.Setting.Default_Small.LeftDump
		or AnimationModule.Library.Setting.Default_Small.RightDump

	local status = isLeftDump and "DumpingL" or "DumpingR"

	if State.Ready and not State.Spiked then
		State.Ready = false
		State.Spikable = false

		playSettingAnimation(Context, animation)
		Context.ChangeStatus:FireServer(status)

		task.delay(1, function()
			State.Spikable = true

			if not State.AutoServe then
				State.Ready = true
			end
		end)

		return
	end

	if State.Jumped and not State.JumpSetted and State.JumpMode and rootPart.Velocity.Y > 0 and not State.Spiked then
		State.JumpSetted = true
		State.Spikable = false

		playSettingAnimation(Context, animation)
		Context.ChangeStatus:FireServer(status)

		task.delay(1, function()
			State.Spikable = true
		end)
	end
end

return Set
