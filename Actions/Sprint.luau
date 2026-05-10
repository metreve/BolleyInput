local Sprint = {}

local function debounce(State, name, duration)
	if State.DebounceList[name] then
		return true
	end

	State.DebounceList[name] = true

	task.delay(duration, function()
		State.DebounceList[name] = nil
	end)

	return false
end

function Sprint.Start(State, Context)
	local humanoid = State.Humanoid
	local character = State.Character

	if not humanoid or not character then
		return
	end
	if not State.Ready then
		return
	end
	if State.Dived then
		return
	end
	if State.Energy <= 0 then
		return
	end
	if humanoid.WalkSpeed == 0 then
		return
	end
	if debounce(State, "Sprint", 0.07) then
		return
	end

	State.Sprinting = true
	State.Energy -= 1

	humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed + 4, 0, 32.5)

	task.delay(1, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = math.max(humanoid.WalkSpeed - 2, 16)
		end
	end)

	task.delay(2, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = math.max(humanoid.WalkSpeed - 2, 16)
		end

		State.Sprinting = false
	end)
end

function Sprint.End(State, Context)
	State.SprintHeld = false
end

return Sprint
