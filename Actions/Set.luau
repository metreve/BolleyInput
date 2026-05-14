local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)
local Specs = require(ReplicatedStorage.Modules.Specs)

local Set = {}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function startSetCooldown(State)
	State.SetCooldown = true

	task.delay(State.SetCooldownTime or 0.25, function()
		State.SetCooldown = false
	end)
end

local function playAnimation(Context, animation)
	if not animation then
		warn("[Set] Missing animation")
		return nil
	end

	return AnimationModule:PlayAnimation(Context.Player, {
		AdjustSpeed = 1,
		AdjustWeight = 1,
		Animation = animation,
	})
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

local function stopSpikeIdle(State)
	if State.AvailableSpikeIdle then
		State.AvailableSpikeIdle:Stop()
		State.AvailableSpikeIdle:Remove()
		State.AvailableSpikeIdle = nil
	end
end

local function canSet(State)
	if State.SetCooldown then
		return false
	end
	if not State.Setable then
		return false
	end
	if State.Dived then
		return false
	end
	if State.JumpSetted then
		return false
	end
	if State.Spiked then
		return false
	end

	return true
end

local function resetGroundSetState(State, Context, delayTime)
	task.delay(delayTime or 0.45, function()
		local humanoid = State.Humanoid

		if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
			State.JumpSetted = false
			State.Setable = true
			State.Spikable = true
		end
	end)
end

local function doSetModeSet(State, Context)
	local camera = workspace.CurrentCamera
	local direction = isFacingCamera(State)

	stopSpikeIdle(State)

	State.JumpSetted = true
	State.Setable = false
	State.Spikable = false

	Context.PlayerAction:FireServer("SetMode", camera.CFrame.LookVector.Unit)
	Context.ChangeStatus:FireServer("Setting")

	local setModeLibrary = AnimationModule.Library.Setting.SetMode
	local animation = setModeLibrary[direction] or setModeLibrary.JFront

	playAnimation(Context, animation)
end

local function doNormalFrontSet(State, Context)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end

	stopSpikeIdle(State)

	State.JumpSetted = true
	State.Spikable = false

	Context.PlayerAction:FireServer("NotSetMode")
	Context.ChangeStatus:FireServer("Setting")

	if humanoid.FloorMaterial == Enum.Material.Air then
		playAnimation(Context, AnimationModule.Library.Setting.Default_Small.JFront)
	else
		playAnimation(Context, AnimationModule.Library.Setting.Default_Small.FrontSet)
		resetGroundSetState(State, Context, 0.45)
	end

	task.delay(1, function()
		State.Spikable = true
	end)
end

local function doBackSet(State, Context)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end

	stopSpikeIdle(State)

	State.JumpSetted = true
	State.Spikable = false

	Context.PlayerAction:FireServer("NotSetMode")
	Context.ChangeStatus:FireServer("Backsetting")

	if humanoid.FloorMaterial == Enum.Material.Air then
		playAnimation(Context, AnimationModule.Library.Setting.Default_Small.JBack)
	else
		playAnimation(Context, AnimationModule.Library.Setting.Default_Small.BackSet)
		resetGroundSetState(State, Context, 0.45)
	end

	task.delay(1, function()
		State.Spikable = true
	end)
end

function Set.Front(State, Context)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end
	if not canSet(State) then
		return
	end
	startSetCooldown(State)
	fireControlDisplay(Context, "Front Set")

	if State.SetMode then
		doSetModeSet(State, Context)
	else
		doNormalFrontSet(State, Context)
	end
end

function Set.Back(State, Context)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end
	if not canSet(State) then
		return
	end
	startSetCooldown(State)
	if State.SetMode then
		Set.Front(State, Context)
		return
	end

	fireControlDisplay(Context, "Back Set")
	doBackSet(State, Context)
end

function Set.Dump(State, Context)
	local rootPart = State.RootPart
	if not rootPart then
		return
	end
	if not canSet(State) then
		return
	end
	startSetCooldown(State)
	if State.SetMode then
		Set.Front(State, Context)
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

	stopSpikeIdle(State)

	State.JumpSetted = true
	State.Spikable = false

	local isLeftDump = shifting > 0

	local animation = isLeftDump and AnimationModule.Library.Setting.Default_Small.LeftDump
		or AnimationModule.Library.Setting.Default_Small.RightDump

	local status = isLeftDump and "DumpingL" or "DumpingR"

	playAnimation(Context, animation)
	Context.ChangeStatus:FireServer(status)

	task.delay(1, function()
		State.Spikable = true
	end)
end

return Set
