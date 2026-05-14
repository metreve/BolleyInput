local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationModule = require(ReplicatedStorage.Modules.AnimationModule)
local Specs = require(ReplicatedStorage.Modules.Specs)
local Serve = require(script.Parent.Serve)
local SpikeBodyAim = require(script.Parent.Parent.Visuals.SpikeBodyAim)

local Click = {}

local spinStarted = false
local clickDebounce = false

local EXCLUDED_SERVE_LF_PARTS = {
	TopHitbox = true,
	BlockHitbox = true,
	RecHitbox = true,
	DiveHitbox = true,
	BlockVHitbox = true,
}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function playAnimation(Context, animation)
	if not animation then
		warn("[Click] Missing animation")
		return nil
	end

	return AnimationModule:PlayAnimation(Context.Player, {
		AdjustSpeed = 1,
		AdjustWeight = 1,
		Animation = animation,
	})
end

local function stopTrack(track)
	if track then
		track:Stop()
		track:Remove()
	end
end

local function getTouchingParts(part)
	local connection = part.Touched:Connect(function() end)
	local results = part:GetTouchingParts()
	connection:Disconnect()

	return results
end

local function checkServeLineFault(State, Context)
	local character = State.Character
	if not character then
		return
	end

	local serveLine = workspace:FindFirstChild("ServeLF")
	if not serveLine then
		return
	end

	Context.PickupsManager:FireServer("ServeLF", false)

	for _, part in ipairs(getTouchingParts(serveLine)) do
		if part.Parent == character and not EXCLUDED_SERVE_LF_PARTS[part.Name] then
			Context.PickupsManager:FireServer("ServeLF", true)
			break
		end
	end
end

local function handleServeClick(State, Context)
	local spinEvent = Context.ReplicatedStorage:FindFirstChild("spinEvent")

	if not spinEvent then
		warn("[Click] spinEvent missing, committing serve directly.")
		Serve.Commit(State, Context)
		return true
	end

	if clickDebounce then
		return true
	end

	clickDebounce = true

	if not spinStarted then
		spinStarted = true
		spinEvent:Fire("Stop")
	else
		spinStarted = false
		spinEvent:Fire("ActivateVert")
	end

	task.delay(0.35, function()
		clickDebounce = false
	end)

	return true
end

local function getReceiveAnimation(State, Context)
	local humanoid = State.Humanoid
	local character = State.Character

	if Context.Data:Get("RecAnim", "New") == "New" then
		local inBr = character and character:FindFirstChild("inBr")

		if inBr and inBr.Value == true then
			return AnimationModule.Library.Receiving.Default_Small.NewGenRec
		end

		return AnimationModule.Library.Receiving.Default_Small.BasicRec
	end

	return AnimationModule.Library.Receiving.Default_Small.BasicRec
end

local function receive(State, Context)
	local humanoid = State.Humanoid
	if not humanoid then
		return
	end

	if State.SpaceHeld then
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

	fireControlDisplay(Context, "LMB Down (Receiving)")

	State.Ready = false

	if State.AvailableRecAnim then
		stopTrack(State.AvailableRecAnim)
		State.AvailableRecAnim = nil
	end

	State.AvailableRecAnim = playAnimation(Context, getReceiveAnimation(State, Context))

	Context.ChangeStatus:FireServer("Receiving")
	checkServeLineFault(State, Context)

	local recoveryTime = 1

	if Context.Data:Get("Technical", "None") == "Swift Recovery" then
		recoveryTime = 0.65
	end

	task.delay(recoveryTime, function()
		if not State.AutoServe then
			State.Ready = true
		end

		if State.AvailableRecAnim then
			stopTrack(State.AvailableRecAnim)
			State.AvailableRecAnim = nil
		end
	end)
end

local function getCurrentTilt(State, Context)
	local currentTilt = State.CurrentTilt or "None"

	if currentTilt == "A" or currentTilt == "D" then
		return currentTilt
	end

	local UIS = Context.UserInputService

	if UIS:IsKeyDown(Enum.KeyCode.A) then
		return "A"
	end

	if UIS:IsKeyDown(Enum.KeyCode.D) then
		return "D"
	end

	local humanoid = State.Humanoid
	if humanoid and humanoid.MoveDirection.Magnitude >= 0.5 then
		local rootPart = State.RootPart

		if rootPart then
			local localMove = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

			if localMove.X <= -0.5 then
				return "A"
			elseif localMove.X >= 0.5 then
				return "D"
			end
		end
	end

	return currentTilt
end

local function getSpikeAnimation(Context)
	local data = Context.Data

	local spikeAnim = Context.Data:Get("SpikeAnim", "New Gen")
	local dominantArm = Context.Data:Get("DominantArm", "R")

	local library = AnimationModule.Library.Spiking[spikeAnim]

	if not library then
		warn("[Click] Missing spike library:", spikeAnim)
		library = AnimationModule.Library.Spiking["New Gen"]
	end

	local key = dominantArm .. "H_HardSwing"
	local animation = library[key]

	if not animation then
		warn("[Click] Missing spike animation:", key, "in", spikeAnim)
		return nil
	end

	return animation
end

local function spike(State, Context)
	local humanoid = State.Humanoid
	local rootPart = State.RootPart
	local character = State.Character

	if not humanoid or not rootPart or not character then
		return
	end
	if not State.Jumped then
		return
	end
	if State.Spiked then
		return
	end
	if not State.JumpMode then
		return
	end
	if not State.Spikable then
		return
	end
	if State.SetMode then
		return
	end

	fireControlDisplay(Context, "LMB Down (Spiking)")

	State.Spiked = true
	State.Spikable = false
	State.Setable = false

	if State.AvailableSpikeIdle then
		stopTrack(State.AvailableSpikeIdle)
		State.AvailableSpikeIdle = nil
	end

	local tilt = getCurrentTilt(State, Context)
	State.CurrentTilt = tilt

	local powerValue = character:FindFirstChild("Power")
	local power = powerValue and powerValue.Value or State.Power or 0

	local sideTiltHeld = tilt == "A" or tilt == "D"
	local hasSwiper = Context.Data:Get("Technical", "None") == "Swiper"

	if hasSwiper and power <= 9 and sideTiltHeld then
		local camera = workspace.CurrentCamera
		if camera then
			Context.PlayerAction:FireServer("SpikeCameraYaw", camera.CFrame.LookVector)
		end

		if tilt == "A" then
			Context.ChangeStatus:FireServer("SwipingL")
			playAnimation(Context, AnimationModule.Library.Swiper["L Swing"])
		else
			Context.ChangeStatus:FireServer("SwipingR")
			playAnimation(Context, AnimationModule.Library.Swiper["R Swing"])
		end
	else
		local camera = workspace.CurrentCamera
		if camera then
			Context.PlayerAction:FireServer("SpikeCameraYaw", camera.CFrame.LookVector)
		end

		SpikeBodyAim.Play(State, Context)
		playAnimation(Context, getSpikeAnimation(Context))
		Context.ChangeStatus:FireServer("Spiking")
		playAnimation(Context, getSpikeAnimation(Context))
	end

	task.delay(0.7, function()
		State.Spikable = true
	end)
end

function Click.Start(State, Context)
	if State.Dived then
		return
	end

	-- Serve spin state
	if State.Serve == 1 and State.VPressed then
		handleServeClick(State, Context)
		return
	end

	-- Ground click = receive
	if State.Ready and not State.Jumped then
		receive(State, Context)
		return
	end

	-- Air click = spike
	if State.Jumped then
		spike(State, Context)
		return
	end
end

function Click.Reset()
	spinStarted = false
	clickDebounce = false
end

return Click
