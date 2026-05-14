local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(ReplicatedStorage.Modules.Specs)

local Stamina = {}

local BASE_REGEN_TIME = 0.95

local function getHeightMaxEnergy(height)
	height = tonumber(height) or 1.75

	local maxEnergy = 10

	if height > 2.1 then
		maxEnergy = 10
	elseif height > 2 then
		maxEnergy = 11
	elseif height > 1.9 then
		maxEnergy = 12
	elseif height > 1.8 then
		maxEnergy = 13
	elseif height > 1.7 then
		maxEnergy = 14
	end

	return maxEnergy
end

function Stamina.GetMax(State, Context)
	local height = Context.Data:Get("Height", 1.75)
	local physical = Context.Data:Get("Physical", "")

	local maxEnergy = getHeightMaxEnergy(height)

	if physical == "Big Lungs" or Specs.Get(nil, "Big Lungs") then
		maxEnergy += 3
	end

	if physical == "All-Rounder" then
		maxEnergy += 1
	end

	if Specs.Get(nil, "Buffed All Rounder") or Specs.Get(nil, "Buffed All-Rounder") then
		maxEnergy += 2
	end

	if physical == "Athletic" or Specs.Get(nil, "Athletic") then
		maxEnergy += 1
	end

	if Specs.Get(nil, "Slightly Buffed Athletic") then
		maxEnergy += 1
	end

	if Specs.Get(nil, "Buffed Athletic") then
		maxEnergy += 2
	end

	return maxEnergy
end

function Stamina.Init(State, Context)
	State.MaxEnergy = 10
	State.Energy = State.MaxEnergy

	State.Stamina = State.Energy
	State.MaxStamina = State.MaxEnergy

	State.StaminaRegenRunning = false

	task.spawn(function()
		-- Let input finish binding first.
		task.wait(0.5)

		local success, result = pcall(function()
			Stamina.RefreshMax(State, Context)
		end)

		if not success then
			warn("[Stamina] Failed to refresh max stamina:", result)
		end
	end)
end

function Stamina.RefreshMax(State, Context)
	local oldMax = State.MaxEnergy or 10

	local success, newMax = pcall(function()
		return Stamina.GetMax(State, Context)
	end)

	if not success or typeof(newMax) ~= "number" then
		warn("[Stamina] GetMax failed, using old max:", newMax)
		newMax = oldMax
	end

	State.MaxEnergy = newMax
	State.MaxStamina = newMax

	if State.Energy == nil then
		State.Energy = newMax
	elseif State.Energy >= oldMax then
		State.Energy = newMax
	else
		State.Energy = math.clamp(State.Energy, 0, newMax)
	end

	State.Stamina = State.Energy
end

function Stamina.CanUse(State, amount)
	amount = amount or 1
	return (State.Energy or 0) >= amount
end

function Stamina.Use(State, Context, amount)
	amount = amount or 1

	if not Stamina.CanUse(State, amount) then
		return false
	end

	State.Energy = math.max((State.Energy or 0) - amount, 0)
	State.Stamina = State.Energy
	return true
end

function Stamina.Add(State, Context, amount)
	amount = amount or 1

	Stamina.RefreshMax(State, Context)

	State.Energy = math.min((State.Energy or 0) + amount, State.MaxEnergy)
	State.Stamina = State.Energy
end

function Stamina.StartRegen(State, Context, Bars)
	if State.StaminaRegenRunning then
		print("[Stamina] Regen already running")
		return
	end

	print("[Stamina] Starting regen loop")

	State.StaminaRegenRunning = true

	task.spawn(function()
		while State.StaminaRegenRunning do
			Stamina.RefreshMax(State, Context)

			local maxEnergy = State.MaxEnergy or Stamina.GetMax(State, Context)
			local energy = State.Energy or maxEnergy

			local character = State.Character
			local humanoid = State.Humanoid
			local rootPart = State.RootPart

			local canRegen = true
			local regenMultiplier = 1

			if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
				canRegen = false
			end

			if rootPart and rootPart.AssemblyLinearVelocity.Magnitude > 1 then
				regenMultiplier = 0.5
			end

			if canRegen and energy < maxEnergy then
				State.Energy = math.min(energy + 1, maxEnergy)
				State.Stamina = State.Energy

				if Bars then
					Bars.UpdateStamina(State, Context)
				end
			end

			local staminaRegenValue = 1

			local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
			if gameValues and gameValues:FindFirstChild("staminaRegen") then
				staminaRegenValue = gameValues.staminaRegen.Value
			end

			local waitTime = BASE_REGEN_TIME / staminaRegenValue

			if regenMultiplier == 0.5 then
				waitTime *= 2
			end

			task.wait(waitTime)
		end

		print("[Stamina] Regen loop stopped")
	end)
end

function Stamina.StopRegen(State)
	State.StaminaRegenRunning = false
end

return Stamina
