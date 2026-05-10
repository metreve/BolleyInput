local ServerScriptService = game:GetService("ServerScriptService")

local Config = require("../Config")
local BallTypes = require("../BallTypes")

return function(BallData: BallTypes.BallData, Position)
	local isStill = false
	local DeltaPos: number = Position.Magnitude - BallData.OldPositionMagnitude
	if math.abs(DeltaPos) < Config.STILLNESS_THRESHOLD then
		isStill = true
	end
	if not isStill then
		BallData.StillTimer = os.clock()
	end
	BallData.OldPositionMagnitude = Position.Magnitude
	return (os.clock() - BallData.StillTimer) <= Config.STILLNESS_TIMEOUT
end
