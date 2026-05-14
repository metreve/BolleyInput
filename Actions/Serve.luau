local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)

local Serve = {}

local EXCLUDED_HITBOXES = {
	TopHitbox = true,
	BlockHitbox = true,
	RecHitbox = true,
	DiveHitbox = true,
	BlockVHitbox = true,
	BlockColission = true,
}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function getTouchingParts(part)
	local connection = part.Touched:Connect(function() end)
	local results = part:GetTouchingParts()
	connection:Disconnect()

	return results
end

local function playAnimation(Context, animation)
	if not animation then
		warn("[Serve] Missing animation")
		return nil
	end

	return AnimationModule:PlayAnimation(Context.Player, {
		AdjustSpeed = 1,
		AdjustWeight = 1,
		Animation = animation,
	})
end

local function setServeLineFault(State, Context)
	local character = State.Character
	if not character then
		return
	end

	local serveLine = workspace:FindFirstChild("ServeLF")
	if not serveLine then
		return
	end

	for _, part in ipairs(getTouchingParts(serveLine)) do
		if part.Parent == character and not EXCLUDED_HITBOXES[part.Name] then
			Context.PickupsManager:FireServer("ServeLF", true)
			break
		end
	end
end

local function showServeHints(State)
	local rootPart = State.RootPart
	if not rootPart then
		return
	end

	local hintsFolder = workspace:FindFirstChild("VisualHInts")
	if not hintsFolder then
		return
	end

	for _, hint in ipairs(hintsFolder:GetChildren()) do
		if hint:IsA("BasePart") and math.sign(rootPart.Position.Z) == math.sign(hint.Position.Z) then
			TweenService
				:Create(
					hint,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Transparency = 0.7 }
				)
				:Play()

			if hint:FindFirstChild("SurfaceGui") and hint.SurfaceGui:FindFirstChild("Frame") then
				TweenService:Create(
					hint.SurfaceGui.Frame,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ BackgroundTransparency = 0 }
				):Play()
			end

			task.delay(0.5, function()
				if not hint.Parent then
					return
				end

				TweenService:Create(
					hint,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Transparency = 1 }
				):Play()

				if hint:FindFirstChild("SurfaceGui") and hint.SurfaceGui:FindFirstChild("Frame") then
					TweenService:Create(
						hint.SurfaceGui.Frame,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{ BackgroundTransparency = 1 }
					):Play()
				end
			end)
		end
	end
end

local function resetServe(State, humanoid)
	if State.AvailableServeIdle then
		State.AvailableServeIdle:Stop()
		State.AvailableServeIdle:Remove()
		State.AvailableServeIdle = nil
	end

	State.PowerChangeable = true
	State.Ready = true
	State.Serve = 0
	State.VPressed = false

	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = 16
		humanoid.AutoRotate = true
	end
end

local function doServeToss(State, Context)
	local humanoid = State.Humanoid
	local character = State.Character
	if not humanoid or not character then
		return
	end

	State.Ready = false
	State.Serve = 1
	State.VPressed = true

	Context.PickupsManager:FireServer("ServeLF", false)

	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false

	task.wait(0.25)

	Context.InputHandler:FireServer("V")
	setServeLineFault(State, Context)

	playAnimation(Context, AnimationModule.Library.Serving.Default_Small.VToss)

	task.wait(1.25)

	Context.ChangeStatus:FireServer("Serving")

	task.wait(1)

	resetServe(State, humanoid)
end

local function startServeIdle(State, Context)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end

	State.Ready = false
	State.Serve = 1
	State.VPressed = true
	State.PowerChangeable = false

	Context.PickupsManager:FireServer("ServeLF", false)

	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false

	State.AvailableServeIdle = playAnimation(Context, AnimationModule.Library.Serving.Default_Small.Idle)

	local spinEvent = Context.ReplicatedStorage:FindFirstChild("spinEvent")
	if spinEvent then
		spinEvent:Fire("Activate")
	end

	task.delay(3, function()
		if State.Serve == 1 then
			resetServe(State, humanoid)
		end
	end)
end

function Serve.Commit(State, Context, serveType)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end

	if State.Serve ~= 1 then
		warn("[Serve.Commit] Not currently serving")
		return
	end

	local isFloat = serveType == "Float"

	task.delay(0.3, function()
		Context.InputHandler:FireServer("V", isFloat)

		State.VPressStage = "Horiz"

		task.delay(0.8, function()
			if State.AvailableServeIdle then
				State.AvailableServeIdle:Stop()
				State.AvailableServeIdle:Remove()
				State.AvailableServeIdle = nil
			end

			humanoid.WalkSpeed = 16
			humanoid.AutoRotate = true

			State.PowerChangeable = true
			State.Ready = true
			State.Serve = 0
			State.VPressed = false

			local Click = require(script.Parent.Click)
			Click.Reset()
		end)
	end)
end

function Serve.Init(State, Context)
	local spinEvent = Context.ReplicatedStorage:FindFirstChild("spinEvent")
	if not spinEvent then
		warn("[Serve.Init] spinEvent not found")
		return
	end

	if State.ServeSpinConnection then
		State.ServeSpinConnection:Disconnect()
		State.ServeSpinConnection = nil
	end

	State.ServeSpinConnection = spinEvent.Event:Connect(function(state, serveType)
		print("[Serve spinEvent]", state, serveType)

		if state ~= "VServe" then
			return
		end

		Serve.Commit(State, Context, serveType)
	end)
end

function Serve.Start(State, Context)
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
	if State.Serve > 0 then
		return
	end
	if rootPart.Position.Y > 10 then
		return
	end

	fireControlDisplay(Context, "Serving")

	local powerValue = character:FindFirstChild("Power")
	local power = powerValue and powerValue.Value or State.Power or 0

	if power >= 4 then
		doServeToss(State, Context)
		return
	end

	if math.abs(rootPart.Position.Z) >= 65 then
		startServeIdle(State, Context)
	else
		showServeHints(State)
	end
end

return Serve
