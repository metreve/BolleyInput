local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)
local Specs = require(ReplicatedStorage.Modules.Specs)
local CharacterMovement = require(script.Parent.Parent.Util.CharacterMovement)

local Dive = {}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function playAnimation(Context, animation)
	if not animation then
		warn("[Dive] Missing animation")
		return nil
	end

	return AnimationModule:PlayAnimation(Context.Player, {
		AdjustSpeed = 1,
		AdjustWeight = 1,
		Animation = animation,
	})
end

local function playSound(Context, soundId, position)
	Context.EffectHandler:FireServer("Sound", soundId, position)
end

local function sendDiveSweat(State, Context, distance)
	local rootPart = State.RootPart
	if not rootPart then
		return
	end

	local targetPos = rootPart.Position + rootPart.CFrame.LookVector * distance
	targetPos = Vector3.new(targetPos.X, 0.2, targetPos.Z)

	local forward = rootPart.CFrame.LookVector
	local rotationCFrame = CFrame.lookAt(targetPos, targetPos + forward, Vector3.yAxis)
	local finalCFrame = rotationCFrame * CFrame.Angles(0, math.rad(90), 0)

	if distance == 25 then
		Context.EffectHandler:FireServer("DiveSweat", "Long", finalCFrame)
	else
		Context.EffectHandler:FireServer("DiveSweat", "", finalCFrame)
	end
end

local function restoreWalkSpeed(State, Context)
	local humanoid = State.Humanoid
	local character = State.Character
	if not humanoid or not character then
		return
	end

	if State.AutoServe then
		return
	end

	local tired = character:FindFirstChild("Tired")

	if tired and tired.Value then
		humanoid.WalkSpeed = 6
	else
		humanoid.WalkSpeed = 16

		if Specs.Get(nil, "Buffed Hasty") then
			humanoid.WalkSpeed += 4
		elseif
			Context.Data:Get("Physical", "None") == "Hasty"
			or Context.Data:Get("Technical", "None") == "Hasty"
			or Specs.Get(nil, "Hasty")
		then
			humanoid.WalkSpeed += 2
		end
	end

	humanoid.AutoRotate = true
end

local function getDiveVelocity(State, Context, oldWalkSpeed)
	local humanoid = State.Humanoid
	local rootPart = State.RootPart

	local oldDiveDistance = Specs.Get(nil, "Old Dive Distance")

	local standingStillDistance = oldDiveDistance and 45 or 30
	local movingSlowlyDistance = oldDiveDistance and 45 or 30
	local movingQuicklyDistance = oldDiveDistance and 55 or 35

	if humanoid.MoveDirection.Magnitude == 0 then
		sendDiveSweat(State, Context, 15)
		return rootPart.CFrame.LookVector * standingStillDistance
	end

	local direction = humanoid.MoveDirection.Unit

	if Context.UserInputService.GamepadEnabled == false and Context.Data:Get("DDives", false) == false then
		direction = rootPart.CFrame.LookVector
	end

	rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(direction.X, 0, direction.Z))

	if oldWalkSpeed >= 20 then
		sendDiveSweat(State, Context, 25)
		return direction * movingQuicklyDistance
	end

	sendDiveSweat(State, Context, 15)
	return direction * movingSlowlyDistance
end

local function startNetCheck(State, bodyVelocity)
	local rootPart = State.RootPart
	if not rootPart then
		return
	end

	task.spawn(function()
		while bodyVelocity and bodyVelocity.Parent do
			task.wait()

			if bodyVelocity.Velocity.Magnitude <= 0 then
				continue
			end

			local nets = {}

			for _, object in ipairs(workspace:GetChildren()) do
				if object.Name == "Net" then
					table.insert(nets, object)
				end
			end

			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = nets
			rayParams.FilterType = Enum.RaycastFilterType.Include

			local rayResult = workspace:Raycast(rootPart.Position, bodyVelocity.Velocity.Unit * 2.5, rayParams)

			if rayResult then
				bodyVelocity:Destroy()
				break
			end
		end
	end)
end

function Dive.Start(State, Context)
	local humanoid = State.Humanoid
	local rootPart = State.RootPart
	local character = State.Character

	if not humanoid or not rootPart or not character then
		return
	end
	if State.Dived then
		return
	end
	if State.Jumped then
		return
	end
	if State.Serve and State.Serve > 0 then
		return
	end
	if not State.Divable then
		return
	end
	if State.SpaceHeld then
		return
	end

	State.Dived = true
	State.Ready = false

	Context.ChangeStatus:FireServer("Diving")
	fireControlDisplay(Context, "Dive")

	if State.AvailableRecAnim then
		State.AvailableRecAnim:Stop()
		State.AvailableRecAnim = nil
	end

	if Context.Data:Get("FOVE", true) then
		TweenService:Create(
			humanoid,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CameraOffset = Vector3.new(0, -2, 0) }
		):Play()
	end

	local oldWalkSpeed = humanoid.WalkSpeed

	State.LastWalkSpeed = humanoid.WalkSpeed
	State.Dived = true

	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0

	workspace.CurrentCamera.CameraSubject = character:FindFirstChild("Head") or humanoid

	playSound(Context, "Sliding", rootPart.Position)

	State.CurrentDivingAnim = playAnimation(Context, AnimationModule.Library.Diving.Default_Small.FrontDive)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "DiveMovement"
	bodyVelocity.MaxForce = Vector3.new(20, 20, 20) * math.huge
	bodyVelocity.Velocity = getDiveVelocity(State, Context, oldWalkSpeed)
	bodyVelocity.Parent = rootPart

	startNetCheck(State, bodyVelocity)

	local tweenDuration = oldWalkSpeed >= 20 and 1.35 or 1
	local momentumTween = TweenService:Create(
		bodyVelocity,
		TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ Velocity = Vector3.zero }
	)

	momentumTween:Play()

	momentumTween.Completed:Once(function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end

		local recoveryTime = 0.4

		if Context.Data:Get("Technical", "None") == "Swift Recovery" then
			recoveryTime = 0.2
		end

		task.delay(recoveryTime, function()
			if not humanoid or not humanoid.Parent then
				return
			end

			restoreWalkSpeed(State, Context)

			State.Ready = true
			State.Dived = false

			if workspace.CurrentCamera then
				workspace.CurrentCamera.CameraSubject = humanoid
			end
		end)
	end)

	task.delay(0.5, function()
		if Context.Data:Get("FOVE", true) and humanoid and humanoid.Parent then
			TweenService:Create(
				humanoid,
				TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ CameraOffset = Vector3.zero }
			):Play()
		end

		CharacterMovement.Reset(State, 16)
	end)
end

return Dive
