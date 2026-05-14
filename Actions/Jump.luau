local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)
local Specs = require(ReplicatedStorage.Modules.Specs)
local Glide = require(script.Parent.Glide)
local EventManager = require(ReplicatedStorage.Modules.EventManager_Local)
local JumpPowerConfig = require(ReplicatedStorage.Modules.Input.Config.JumpPower)
local CharacterMovement = require(script.Parent.Parent.Util.CharacterMovement)

local Jump = {}
local MAX_BLOCK_BAR_JUMP_BONUS = 1.5

local function getBlockBarAlpha(State)
	if not State.BlockHoldStarted or not State.BlockHoldDuration then
		return 0
	end

	local elapsed = os.clock() - State.BlockHoldStarted
	return math.clamp(elapsed / State.BlockHoldDuration, 0, 1)
end

local function calculateJumpPower(State, Context, oldWalkSpeed)
	local height = Context.Data:Get("Height", 1.75)
	local physical = Context.Data:Get("Physical", "")

	local jumpPower = JumpPowerConfig.Calculate({
		Height = height,
		WalkSpeed = oldWalkSpeed,
		Physical = physical,
		Specs = Specs,

		IsBlockMode = not State.JumpMode,
		IsSetterMode = State.SetMode == true,
		IsStepApproach = State.JumpHalf == true,
	})
	if not State.JumpMode then
		local blockBarAlpha = State.BlockBarAlpha or 0
		jumpPower += blockBarAlpha * MAX_BLOCK_BAR_JUMP_BONUS
	end

	return jumpPower
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

local function openBlockGui(State)
	local blockGui = State.BlockGui
	if not blockGui then
		return
	end
	if not blockGui:FindFirstChild("Main") then
		return
	end

	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

	local main = blockGui.Main
	local bar = main:FindFirstChild("Bar")

	if bar then
		bar.Size = UDim2.new(1, 0, 0, 0)
	end

	TweenService:Create(blockGui, info, {
		StudsOffsetWorldSpace = Vector3.new(2.5, 0, 0),
	}):Play()

	task.delay(0.1, function()
		if not blockGui.Parent then
			return
		end

		TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0,
		}):Play()

		if bar then
			TweenService:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0,
			}):Play()
		end

		local textLabel = main:FindFirstChild("TextLabel")
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
				TextTransparency = 0.41,
			}):Play()
		end

		local stroke = main:FindFirstChild("UIStroke")
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
				Transparency = 0.46,
			}):Play()
		end

		local points = main:FindFirstChild("Points")
		if points then
			for _, frame in ipairs(points:GetChildren()) do
				if frame:IsA("Frame") then
					TweenService
						:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
							BackgroundTransparency = 0.46,
						})
						:Play()
				end
			end
		end
	end)
end

local function closeBlockGui(State)
	local blockGui = State.BlockGui
	if not blockGui then
		return
	end
	if not blockGui:FindFirstChild("Main") then
		return
	end

	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

	local main = blockGui.Main
	local bar = main:FindFirstChild("Bar")

	TweenService:Create(blockGui, info, {
		StudsOffsetWorldSpace = Vector3.new(0, 0, 0),
	}):Play()

	TweenService:Create(main, info, {
		BackgroundTransparency = 1,
	}):Play()

	if bar then
		TweenService:Create(bar, info, {
			BackgroundTransparency = 1,
		}):Play()
	end

	local textLabel = main:FindFirstChild("TextLabel")
	if textLabel then
		TweenService:Create(textLabel, info, {
			TextTransparency = 1,
		}):Play()
	end

	local stroke = main:FindFirstChild("UIStroke")
	if stroke then
		TweenService:Create(stroke, info, {
			Transparency = 1,
		}):Play()
	end

	local points = main:FindFirstChild("Points")
	if points then
		for _, frame in ipairs(points:GetChildren()) do
			if frame:IsA("Frame") then
				TweenService:Create(frame, info, {
					BackgroundTransparency = 1,
				}):Play()
			end
		end
	end
end

local function startBlockBar(State)
	local blockGui = State.BlockGui
	if not blockGui then
		return
	end

	local main = blockGui:FindFirstChild("Main")
	if not main then
		return
	end

	local bar = main:FindFirstChild("Bar")
	if not bar then
		return
	end

	if State.BlockBarTween then
		State.BlockBarTween:Cancel()
		State.BlockBarTween = nil
	end

	bar.Size = UDim2.new(1, 0, 0, 0)

	local TweenService = game:GetService("TweenService")

	State.BlockBarTween = TweenService:Create(
		bar,
		TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
		{ Size = UDim2.new(1, 0, 1, 0) }
	)

	State.BlockBarTween:Play()
end

local function getSpikeJumpAnimation(Context)
	local spikeAnim = Context.Data:Get("SpikeAnim", "Default")
	local dominantArm = Context.Data:Get("DominantArm", "R")

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
	State.Spiked = false
	State.InAirTiltable = false
	State.Spikable = true
	State.Setable = true
	State.SpaceHeld = false
	State.CurrentTilt = "None"

	State.BlockHolding = false
	State.BlockJumpQueued = false

	State.BlockBarAlpha = 0
	State.BlockHoldStarted = nil
	State.BlockHoldDuration = nil

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

	if State.BlockBarTween then
		State.BlockBarTween:Cancel()
		State.BlockBarTween = nil
	end

	closeBlockGui(State)

	if State.AvailableSpikeIdle then
		stopTrack(State.AvailableSpikeIdle)
		State.AvailableSpikeIdle = nil
	end

	CharacterMovement.Reset(State, oldWalkSpeed)
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
	local duration = 0.55

	if Context.Data:Get("Physical", "None") == "Athletic" then
		duration -= 0.05
	end

	if
		Context.Data:Get("Technical", "None") == "Step Approach"
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

	-- BLOCK MODE WINDUP
	if not State.JumpMode then
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

		return
	end

	-- SETTER MODE WINDUP
	if State.SetMode then
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

		return
	end

	-- SPIKE MODE WINDUP
	local spikeAnim = Context.Data:Get("SpikeAnim", "Default")
	local dominantArm = Context.Data:Get("DominantArm", "R")

	local library = AnimationModule.Library.Spiking[spikeAnim]
	if library then
		State.AvailableJumpDelay = AnimationModule:PlayAnimation(Context.Player, {
			AdjustSpeed = 0.4 / duration,
			AdjustWeight = 1,
			Animation = library[dominantArm .. "H_JumpWindup"],
		})
	end
end

local function performJump(State, Context, oldWalkSpeed)
	local humanoid = State.Humanoid
	local rootPart = State.RootPart

	local humanoid = State.Humanoid
	local rootPart = State.RootPart

	if not humanoid or not rootPart then
		State.Ready = true
		State.Jumped = false
		State.SpaceHeld = false
		return
	end

	if not humanoid.Parent or not rootPart.Parent then
		State.Ready = true
		State.Jumped = false
		State.SpaceHeld = false
		return
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		State.Ready = true
		State.Jumped = false
		State.SpaceHeld = false
		return
	end

	local approachDirection = humanoid.MoveDirection

	if State.AvailableJumpDelay then
		State.AvailableJumpDelay:Stop()
		State.AvailableJumpDelay:Remove()
		State.AvailableJumpDelay = nil
	end

	local jumpPower = calculateJumpPower(State, Context, oldWalkSpeed)
	local tilt, origin = createTiltOrigin(State)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "JumpMovement"
	bodyVelocity.MaxForce = Vector3.new(15000, 0, 15000)

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

	local originalAirVelocity = bodyVelocity.Velocity
	local currentAirVelocity = originalAirVelocity
	local minimumAirSpeed = originalAirVelocity.Magnitude * (State.MinGlideSpeedMultiplier or 0.15)
	local glideSlowRate = State.GlideSlowRate or 3.5

	State.GlideConnection = EventManager.Subscribe(function(dt)
		if not State.Jumped then
			return
		end

		if not bodyVelocity or not bodyVelocity.Parent then
			return
		end

		Glide.Update(State, Context)

		if State.SpaceHeld then
			local currentSpeed = currentAirVelocity.Magnitude

			if currentSpeed > minimumAirSpeed then
				local alpha = 1 - math.exp(-dt * glideSlowRate)
				currentAirVelocity = currentAirVelocity:Lerp(Vector3.zero, alpha)

				if currentAirVelocity.Magnitude < minimumAirSpeed then
					currentAirVelocity = currentAirVelocity.Unit * minimumAirSpeed
				end

				bodyVelocity.Velocity = currentAirVelocity
			end
		end
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
		-- BLOCK MODE INIT AFTER RELEASE/FULL BAR
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

		local isFakeApe = Context.Data:Get("Technical", "None") == "Fake Ape" or Specs.Get(nil, "Fake Ape")

		if isFakeApe and State.FakeAping then
			State.AvailableSpikeIdle = playAnimation(Context, getSpikeJumpAnimation(Context))
		else
			local setIdle = AnimationModule.Library.Setting.SetMode.Idle

			if not setIdle then
				warn("[Jump] Missing SetMode.Idle animation")
			else
				State.AvailableSpikeIdle = playAnimation(Context, setIdle)
			end
		end
	else
		-- SPIKE MODE INIT
		State.Spikable = true
		State.Setable = true
		State.JumpSetted = false

		State.AvailableSpikeIdle = playAnimation(Context, getSpikeJumpAnimation(Context))
	end

	setupLanding(State, Context, tilt, origin, bodyVelocity, oldWalkSpeed)
end

function Jump.Begin(State, Context)
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
	State.SpaceHeld = true

	local oldWalkSpeed = humanoid.WalkSpeed
	State.LastJumpWalkSpeed = oldWalkSpeed

	-- BLOCK MODE: hold bar first, jump on release or full bar
	if not State.JumpMode then
		State.BlockHolding = true
		State.BlockJumpQueued = false
		State.BlockHoldStarted = os.clock()
		State.BlockHoldDuration = 0.6

		openBlockGui(State)
		startBlockBar(State)
		playJumpWindup(State, Context, State.BlockHoldDuration)

		task.delay(State.BlockHoldDuration, function()
			if not State.BlockHolding then
				return
			end

			if State.BlockJumpQueued then
				return
			end

			State.BlockBarAlpha = 1
			State.BlockJumpQueued = true
			State.BlockHolding = false

			closeBlockGui(State)
			performJump(State, Context, oldWalkSpeed)
		end)

		return
	end

	-- SPIKE / SETTER MODE: normal approach delay
	local duration = getApproachDuration(State, Context)

	playJumpWindup(State, Context, duration)

	task.wait(duration)

	performJump(State, Context, oldWalkSpeed)
end

function Jump.End(State, Context)
	State.SpaceHeld = false

	if State.JumpMode then
		return
	end

	if not State.BlockHolding then
		return
	end

	if State.BlockJumpQueued then
		return
	end

	State.BlockJumpQueued = true
	State.BlockHolding = false

	if State.BlockBarTween then
		State.BlockBarTween:Cancel()
		State.BlockBarTween = nil
	end

	State.BlockBarAlpha = getBlockBarAlpha(State)

	closeBlockGui(State)

	performJump(State, Context, State.LastJumpWalkSpeed or 16)
end

return Jump
