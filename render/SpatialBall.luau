local SpatialBallSystem = {}

-- Physics constants
local GRAVITY = Vector3.new(0, -9.8 * 3, 0)

-- Compression scales
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local POSITION_SCALE = 100
local VELOCITY_SCALE = 10

-- Replication thresholds
local MIN_POSITION_DELTA = 0.1
local MIN_VELOCITY_DELTA = 0.5

-- Ball state type
export type BallState = {
	Position: Vector3,
	Velocity: Vector3,
	Timestamp: number,
}

-- Check if delta is significant enough to replicate
function SpatialBallSystem.ShouldReplicate(current: BallState, last: BallState): boolean
	local posDelta = (current[1] - last[1]).Magnitude
	local velDelta = (current[2] - last[2]).Magnitude

	return posDelta >= MIN_POSITION_DELTA or velDelta >= MIN_VELOCITY_DELTA
end

-- Simulate physics
function SpatialBallSystem.SimulateStep(state: BallState, deltaTime: number): BallState
	local newstate = table.clone(state)
	local ballspeed = ReplicatedStorage.Ball.ballSpeed.Value
	deltaTime = deltaTime * ballspeed * 0.85

	-- Ensure timestamp exists
	if typeof(newstate[3]) ~= "number" then
		newstate[3] = workspace:GetServerTimeNow()
	end

	-- Update timestamp
	newstate[3] = newstate[3] + deltaTime

	-- Apply gravity to velocity
	newstate[2] = newstate[2] + GRAVITY * deltaTime

	-- Update position based on velocity
	newstate[1] = newstate[1] + newstate[2] * deltaTime

	return newstate
end

-- Predict state forward in time
function SpatialBallSystem.PredictState(state: BallState, targetTime: number): BallState
	local deltaTime = targetTime - state[3]
	if deltaTime <= 0 then
		return state
	end

	local predictedstate = state
	local stepSize = 1 / 60 -- 60 FPS simulation steps

	while deltaTime > 0 do
		local stepdelta = math.min(deltaTime, stepSize)
		predictedstate = SpatialBallSystem.SimulateStep(predictedstate, stepdelta)
		deltaTime = deltaTime - stepdelta
	end

	return predictedstate
end

return SpatialBallSystem
