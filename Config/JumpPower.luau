local JumpPower = {}

-- Tunable constants
JumpPower.BaseHeight = 1.75
JumpPower.BaseJumpPower = 23.5

-- Higher = taller players lose more jump power.
-- Lower = height matters less.
JumpPower.HeightPenaltyPerMeter = 7

-- Safety limits
JumpPower.MinJumpPower = 20.2
JumpPower.MaxJumpPower = 26.5

-- Sprint momentum
JumpPower.SprintStartSpeed = 19
JumpPower.NormalWalkSpeed = 16
JumpPower.MomentumDivider = 2.4
JumpPower.MaxMomentumBonus = 1.8

-- Mode modifiers
JumpPower.BlockModeMultiplier = 0.96
JumpPower.SetterModeMultiplier = 0.98
JumpPower.StepApproachMultiplier = 1 / 1.2

local PHYSICAL_BONUSES = {
	Bounce = 1,
	["Buffed Bounce"] = 2,
	Athletic = 0.5,
}

local SPEC_BONUSES = {
	["Slightly Buffed Athletic"] = 0.75,
	["Buffed Athletic"] = 1,
}

local function roundTo(value, step)
	step = step or 0.05
	return math.floor((value / step) + 0.5) * step
end

function JumpPower.GetHeightJump(height)
	height = tonumber(height) or JumpPower.BaseHeight

	local heightDifference = height - JumpPower.BaseHeight
	local jumpPower = JumpPower.BaseJumpPower - (heightDifference * JumpPower.HeightPenaltyPerMeter)

	return math.clamp(jumpPower, JumpPower.MinJumpPower, JumpPower.MaxJumpPower)
end

function JumpPower.GetMomentumBonus(walkSpeed)
	walkSpeed = tonumber(walkSpeed) or JumpPower.NormalWalkSpeed

	if walkSpeed < JumpPower.SprintStartSpeed then
		return 0
	end

	local bonus = (walkSpeed - JumpPower.NormalWalkSpeed) / JumpPower.MomentumDivider
	return math.clamp(bonus, 0, JumpPower.MaxMomentumBonus)
end

function JumpPower.GetAbilityBonus(physical, Specs)
	local bonus = 0

	bonus += PHYSICAL_BONUSES[physical] or 0

	if Specs then
		for specName, specBonus in pairs(SPEC_BONUSES) do
			if Specs.Get(nil, specName) then
				bonus += specBonus
			end
		end
	end

	return bonus
end

function JumpPower.Calculate(params)
	local height = params.Height or JumpPower.BaseHeight
	local walkSpeed = params.WalkSpeed or JumpPower.NormalWalkSpeed
	local physical = params.Physical or ""
	local Specs = params.Specs

	local jumpPower = JumpPower.GetHeightJump(height)

	jumpPower += JumpPower.GetMomentumBonus(walkSpeed)
	jumpPower += JumpPower.GetAbilityBonus(physical, Specs)

	if params.IsBlockMode then
		jumpPower *= JumpPower.BlockModeMultiplier
	end

	if params.IsSetterMode then
		jumpPower *= JumpPower.SetterModeMultiplier
	end

	if params.IsStepApproach then
		jumpPower *= JumpPower.StepApproachMultiplier
	end

	return roundTo(math.clamp(jumpPower, JumpPower.MinJumpPower, JumpPower.MaxJumpPower), 0.05)
end

return JumpPower
