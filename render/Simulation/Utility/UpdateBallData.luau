local BallData = require("../Data/BallData")
return function(ballModel, updates)
	local ballData = BallData[ballModel]
	if not ballData then
		return
	end

	for key, value in pairs(updates) do
		ballData[key] = value
	end
end
