local ServerScriptService = game:GetService("ServerScriptService")

local Config = require("../Config")

return function(Pos1: Vector3, Pos2: Vector3, VY: number)
	local Distance = (Pos1 - Pos2).Magnitude
	local Time = VY / Config.GRAVITY_VECTOR.Y + (Pos1.Y - 1) / Config.GRAVITY_VECTOR.Y / 4
	local Velocity = Distance / Time

	return CFrame.new(Pos2, Pos1).LookVector * Velocity * 0.5 + Vector3.new(0, VY, 0)
end
