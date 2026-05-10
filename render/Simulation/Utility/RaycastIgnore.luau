local Tables = require("../Data/Tables")
local BallTypes = require("../BallTypes")
return function(
	BallData: BallTypes.BallData,
	RayOrigin: Vector3,
	RayDirection: Vector3
): (Instance?, Vector3?, Vector3?)
	local whitelistWithIgnored = { table.unpack(Tables["RayWhitelist"]) }

	-- Convert IgnoreList to set for O(1) lookup
	local ignoreSet = {}
	for _, obj in pairs(BallData.IgnoreList) do
		ignoreSet[obj] = true
	end

	local filteredWhitelist = {}
	for _, obj in pairs(whitelistWithIgnored) do
		if not ignoreSet[obj] then
			table.insert(filteredWhitelist, obj)
		end
	end

	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterDescendantsInstances = filteredWhitelist
	RaycastParameters.FilterType = Enum.RaycastFilterType.Include

	local RayResult = workspace:Raycast(RayOrigin, RayDirection, RaycastParameters)
	if not RayResult then
		return nil, nil, nil
	end
	return RayResult.Instance, RayResult.Position, RayResult.Normal
end
