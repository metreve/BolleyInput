local Tables = require("../Data/Tables")
local BallTypes = require("../BallTypes")

return function(RayOrigin: Vector3, RayDirection: Vector3, Whitelist: { Instance }): (Instance?, Vector3?, Vector3?)
	local _RaycastParameters = RaycastParams.new()
	_RaycastParameters.FilterType = Enum.RaycastFilterType.Include
	_RaycastParameters.FilterDescendantsInstances = Whitelist

	local RayResult = workspace:Raycast(RayOrigin, RayDirection, _RaycastParameters)
	if not RayResult then
		return nil, nil, nil
	end

	return RayResult.Instance, RayResult.Position, RayResult.Normal
end
