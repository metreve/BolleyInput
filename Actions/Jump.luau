local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)
local Specs = require(ReplicatedStorage.Modules.Specs)
local Glide = require(script.Parent.Glide)
local EventManager = require(ReplicatedStorage.Modules.EventManager_Local)

local Jump = {}

local function getJump(height, boosted)
	local baseHeight = 1.75
	local baseJump = boosted and 21 or 23.5

	return baseJump - ((height - baseHeight) * 6)
end

local function getHeightJumpDefaults(height, boosted)
	height = math.round((height or 1.75) * 100) / 100
	return math.round(getJump(height, boosted) * 10) / 10
end

local function stopTrack(track)
	if track then
		track:Stop()
		track:Remove()
	end
end

local function playAnimation(Context, animation)
	if not animation then
		warn("[Jump] Missing animation")
		return nil
	end

	return AnimationModule:PlayAnimation(Context.Player, {
		AdjustSpeed = 1,
		AdjustWeight = 1,
		Animation = animation,
	})
end

local function getSpikeJumpAnimation(Context)
	local data = Context.Data

	local spikeAnim = data:GetAttribute("SpikeAnim") or "Default"
	local dominantArm = data:GetAttribute("DominantArm") or "R"

	local spikeLibrary = AnimationModule.Library.Spiking[spikeAnim]
	if not spikeLibrary then
		warn("[Jump] Missing spike animation library:", spikeAnim)
		return nil
	end

	return spikeLibrary[dominantArm .. "H_Jump"]
end

local function createTiltOrigin(State)
	local rootPart = State.RootPart
	if not rootPart then
		return nil, nil
	end

	local oldTilt = rootPart:FindFirstChild("Tilt")
	if oldTilt then
		oldTilt:Destroy()
	end

	local tilt = Instance.new("BodyGyro")
	tilt.Name = "Tilt"
	tilt.MaxTorque = Vector3.new(0.6, 0.6, 0.6) * 30000
	tilt.CFrame = rootPart.CFrame
	tilt.Parent = rootPart

	local origin = Instance.new("CFrameValue")
	origin.Name = "Origin"
	origin.Value = tilt.CFrame + Vector3.new(0, 10, 0)
	origin.Parent = tilt

	return tilt, origin
end

local function calculateJumpPower(State, Context, oldWalkSpeed)
	local data = Context.Data

	local height = data:GetAttribute("Height") or 1.75
	local jumpValue = getHeightJumpDefaults(height, false)

	if oldWalkSpeed >= 19 then
		local momentum = oldWalkSpeed - 16
		jumpValue += momentum / 2
	end

	if data:GetAttribute("Physical") == "Bounce" or Specs.Get(nil, "Bounce") then
		jumpValue += 1
	end

	if data:GetAttribute("Physical") == "Buffed Bounce" or Specs.Get(nil, "Buffed Bounce") then
		jumpValue += 2
	end

	if data:GetAttribute("Physical") == "Athletic" or Specs.Get(nil, "Athletic") then
		jumpValue += 0.5
	end

	if Specs.Get(nil, "Slightly Buffed Athletic") then
		jumpValue += 0.75
	end

	if Specs.Get(nil, "Buffed Athletic") then
		jumpValue += 1
	end

	if State.JumpHalf then
		jumpValue /= 1.2
	end

	return jumpValue
end

local function cleanupAirState(State, Context, tilt, origin, bodyVelocity, oldWalkSpeed)
	local humanoid = State.Humanoid

	if State.LandingConnection then
		State.LandingConnection:Disconnect()
		State.LandingConnection = nil
	end

	State.JumpSetted = false
	State.Switchable = true
	State.Ready = true
	State.Jumped = false
	State.InAirTiltable = false
	State.Spikable = true
	State.Setable = true

	Context.PickupsManager:FireServer("ServeLF", false)

	if State.GlideConnection then
		State.GlideConnection:Disconnect()
		State.GlideConnection = nil
	end

	Glide.Clear(State)

	if tilt then
		tilt:Destroy()
	end

	if origin then
		origin:Destroy()
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
	end

	if State.AvailableBlockAnim then
		stopTrack(State.AvailableBlockAnim)
		State.AvailableBlockAnim = nil
	end

	if State.AvailableSideTiltAnim then
		stopTrack(State.AvailableSideTiltAnim)
		State.AvailableSideTiltAnim = nil
	end

	if State.AvailableSpikeIdle then
		stopTrack(State.AvailableSpikeIdle)
		State.AvailableSpikeIdle = nil
	end

	if humanoid and humanoid.Parent then
		humanoid.AutoRotate = true
		humanoid.JumpPower = 0
		humanoid.WalkSpeed = oldWalkSpeed or 16
	end
end

local function setupLanding(State, Context, tilt, origin, bodyVelocity, oldWalkSpeed)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end

	if State.LandingConnection then
		State.LandingConnection:Disconnect()
		State.LandingConnection = nil
	end

	State.LandingConnection = humanoid.StateChanged:Connect(function(_, state)
		if state ~= Enum.HumanoidStateType.Landed and state ~= Enum.HumanoidStateType.Running then
			return
		end

		if humanoid.FloorMaterial == Enum.Material.Air then
			return
		end

		cleanupAirState(State, Context, tilt, origin, bodyVelocity, oldWalkSpeed)
	end)
end

local function getApproachDuration(State, Context)
	local duration = 0.4

	if Context.Data:GetAttribute("Physical") == "Athletic" or Specs.Get(nil, "Athletic") then
		duration -= 0.05
	end

	if Specs.Get(nil, "Fast Approach") then
		duration -= 0.025
	end

	if Specs.Get(nil, "Buffed Athletic") then
		duration -= 0.05
	end

	if
		Context.Data:GetAttribute("Technical") == "Step Approach"
		and State.UsingStepApproach
		and not State.FakeAping
		and State.JumpMode
	then
		duration = 0.2
		State.JumpHalf = true
	else
		State.JumpHalf = false
	end

	return math.max(duration, 0.12)
end

local function playJumpWindup(State, Context, duration)
	if State.AvailableJumpDelay then
		State.AvailableJumpDelay:Stop()
		State.AvailableJumpDelay:Remove()
		State.AvailableJumpDelay = nil
	end

	if State.JumpMode then
		if not State.SetMode then
			local spikeAnim = Context.Data:GetAttribute("SpikeAnim") or "Default"
			local dominantArm = Context.Data:GetAttribute("DominantArm") or "R"

			local library = AnimationModule.Library.Spiking[spikeAnim]
			if library then
				State.AvailableJumpDelay = AnimationModule:PlayAnimation(Context.Player, {
					AdjustSpeed = 0.4 / duration,
					AdjustWeight = 1,
					Animation = library[dominantArm .. "H_JumpWindup"],
				})
			end
		else
			local anim

			if State.Humanoid.MoveDirection ~= Vector3.zero then
				anim = AnimationModule.Library.Blocking.Default_Small.BlockJumpWindupMoving
			else
				anim = AnimationModule.Library.Blocking.Default_Small.BlockJumpWindup
			end

			State.AvailableJumpDelay = AnimationModule:PlayAnimation(Context.Player, {
				AdjustSpeed = 1,
				AdjustWeight = 1,
				Animation = anim,
			})
		end
	else
		local anim

		if State.Humanoid.MoveDirection ~= Vector3.zero then
			anim = AnimationModule.Library.Blocking.Default_Small.BlockJumpWindupMoving
		else
			anim = AnimationModule.Library.Blocking.Default_Small.BlockJumpWindup
		end

		State.AvailableJumpDelay = AnimationModule:PlayAnimation(Context.Player, {
			AdjustSpeed = 1,
			AdjustWeight = 1,
			Animation = anim,
		})
	end
end

function Jump.Start(State, Context)
	local humanoid = State.Humanoid
	local rootPart = State.RootPart
	local character = State.Character

	if not humanoid or not rootPart or not character then
		return
	end
	if not State.Ready then
		return
	end
	if State.Dived then
		return
	end
	if State.Jumped then
		return
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	State.Ready = false
	State.Jumped = true
	State.Spiked = false
	State.JumpSetted = false
	State.Switchable = false
	State.CurrentTilt = "None"
	State.Spikable = false

	local oldWalkSpeed = humanoid.WalkSpeed
	local duration = getApproachDuration(State, Context)

	playJumpWindup(State, Context, duration)

	task.wait(duration)
	local approachDirection = humanoid.MoveDirection

	if not humanoid.Parent or not rootPart.Parent then
		return
	end

	if State.AvailableJumpDelay then
		State.AvailableJumpDelay:Stop()
		State.AvailableJumpDelay:Remove()
		State.AvailableJumpDelay = nil
	end

	local jumpPower = calculateJumpPower(State, Context, oldWalkSpeed)
	local tilt, origin = createTiltOrigin(State)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "JumpMovement"
	bodyVelocity.MaxForce = Vector3.new(6000, 0, 6000)

	local jumpSpeedMultiplier = State.JumpMode and 0.7 or 0.6
	bodyVelocity.Velocity = approachDirection * (oldWalkSpeed * jumpSpeedMultiplier)
	bodyVelocity.Parent = rootPart

	humanoid.UseJumpPower = true
	humanoid.JumpPower = jumpPower
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	if State.GlideConnection then
		State.GlideConnection:Disconnect()
		State.GlideConnection = nil
	end

	State.GlideConnection = EventManager.Subscribe(function()
		if not State.Jumped then
			return
		end

		-- Only updates LocalValues.GlideKeys.
		-- Do not change bodyVelocity here, or WASD becomes air steering.
		Glide.Update(State, Context)
	end, { "RunService", "RenderStepped" }, "Input_Glide_" .. Context.Player.UserId)

	Context.PickupsManager:FireServer("ServeLF", false)

	if Context.Remotes:FindFirstChild("JumpMarker") then
		Context.Remotes.JumpMarker:FireServer()
	end

	task.delay(0.045, function()
		if State.Jumped then
			State.InAirTiltable = true
		end
	end)

	if not State.JumpMode then
		-- BLOCK MODE INIT
		State.Spikable = false
		State.Setable = false
		State.JumpSetted = false

		State.AvailableBlockAnim = playAnimation(Context, AnimationModule.Library.Blocking.Default_Small.DefaultBlock)

		Context.ChangeStatus:FireServer("Blocking")
	elseif State.SetMode then
		-- SETTER MODE INIT
		State.Spikable = false
		State.Setable = true
		State.JumpSetted = false

		local isFakeApe = Context.Data:GetAttribute("Technical") == "Fake Ape" or Specs.Get(nil, "Fake Ape")

		if isFakeApe and State.FakeAping then
			State.AvailableSpikeIdle = playAnimation(Context, getSpikeJumpAnimation(Context))
		else
			State.AvailableSpikeIdle = playAnimation(Context, AnimationModule.Library.Setting.SetMode.Idle)
		end

		Context.ChangeStatus:FireServer("Setting")
	else
		-- SPIKE MODE INIT
		State.Spikable = true
		State.Setable = true
		State.JumpSetted = false

		State.AvailableSpikeIdle = playAnimation(Context, getSpikeJumpAnimation(Context))
	end

	setupLanding(State, Context, tilt, origin, bodyVelocity, oldWalkSpeed)
end

return Jump
