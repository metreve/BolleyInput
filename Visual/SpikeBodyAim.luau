local TweenService = game:GetService("TweenService")

local SpikeBodyAim = {}

local Config = {
	Enabled = true,

	MaxYawDegrees = 35,
	Influence = 0.8,
	Invert = true,

	TweenInTime = 0.08,
	HoldTime = 0.5,
	TweenOutTime = 0.3,

	WaistAmount = 1,
	NeckAmount = 0.5,
}

local activeTweens = {}
local originalC0 = {}

local function cancelTween(joint)
	if activeTweens[joint] then
		activeTweens[joint]:Cancel()
		activeTweens[joint] = nil
	end
end

local function getMotor(character, name)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name == name then
			return descendant
		end
	end

	return nil
end

local function saveOriginal(joint)
	if joint and not originalC0[joint] then
		originalC0[joint] = joint.C0
	end
end

local function tweenC0(joint, targetC0, duration)
	if not joint then
		return
	end

	cancelTween(joint)

	local tween = TweenService:Create(
		joint,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ C0 = targetC0 }
	)

	activeTweens[joint] = tween
	tween:Play()
end

function SpikeBodyAim.PlayForCharacter(character, cameraLookVector)
	if not Config.Enabled then
		return
	end

	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local waist = getMotor(character, "Waist")
	local neck = getMotor(character, "Neck")

	if not waist then
		return
	end

	saveOriginal(waist)
	saveOriginal(neck)

	local flatCameraLook = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z)
	if flatCameraLook.Magnitude < 0.05 then
		return
	end

	flatCameraLook = flatCameraLook.Unit

	local localCameraDirection = rootPart.CFrame:VectorToObjectSpace(flatCameraLook)
	local yawOffset = math.deg(math.atan2(localCameraDirection.X, -localCameraDirection.Z))

	if Config.Invert then
		yawOffset = -yawOffset
	end

	yawOffset = math.clamp(yawOffset, -Config.MaxYawDegrees, Config.MaxYawDegrees)
	yawOffset *= Config.Influence

	local yaw = math.rad(yawOffset)

	local waistBase = originalC0[waist]
	local neckBase = neck and originalC0[neck]

	local waistTarget = waistBase * CFrame.Angles(0, yaw * Config.WaistAmount, 0)
	tweenC0(waist, waistTarget, Config.TweenInTime)

	if neck and neckBase then
		local neckTarget = neckBase * CFrame.Angles(0, yaw * Config.NeckAmount, 0)
		tweenC0(neck, neckTarget, Config.TweenInTime)
	end

	task.delay(Config.HoldTime, function()
		if waist and waist.Parent and originalC0[waist] then
			tweenC0(waist, originalC0[waist], Config.TweenOutTime)
		end

		if neck and neck.Parent and originalC0[neck] then
			tweenC0(neck, originalC0[neck], Config.TweenOutTime)
		end
	end)
end

local function getCameraYawOffset(rootPart)
	local camera = workspace.CurrentCamera
	if not camera then
		return 0
	end

	local cameraLook = camera.CFrame.LookVector
	local flatCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z)

	if flatCameraLook.Magnitude < 0.05 then
		return 0
	end

	flatCameraLook = flatCameraLook.Unit

	local localCameraDirection = rootPart.CFrame:VectorToObjectSpace(flatCameraLook)
	local yawOffset = math.deg(math.atan2(localCameraDirection.X, -localCameraDirection.Z))

	if Config.Invert then
		yawOffset = -yawOffset
	end

	yawOffset = math.clamp(yawOffset, -Config.MaxYawDegrees, Config.MaxYawDegrees)

	return yawOffset * Config.Influence
end

function SpikeBodyAim.Play(State, Context)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	SpikeBodyAim.PlayForCharacter(State.Character, camera.CFrame.LookVector)
end

function SpikeBodyAim.Reset(State)
	local character = State.Character
	if not character then
		return
	end

	local waist = getMotor(character, "Waist")
	local neck = getMotor(character, "Neck")

	if waist and originalC0[waist] then
		cancelTween(waist)
		waist.C0 = originalC0[waist]
	end

	if neck and originalC0[neck] then
		cancelTween(neck)
		neck.C0 = originalC0[neck]
	end
end

return SpikeBodyAim
