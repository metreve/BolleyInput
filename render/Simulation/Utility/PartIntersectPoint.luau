return function(Part: Part, Point: Vector3, Shape: Enum.PartType): boolean?
	local Delta = Part.CFrame:PointToObjectSpace(Point)
	Delta = Vector3.new(math.abs(Delta.X), math.abs(Delta.Y), math.abs(Delta.Z))
	local HalfSize = Part.Size / 2

	if Shape == Enum.PartType.Block then
		local inX = Delta.X <= HalfSize.X
		local inY = Delta.Y <= HalfSize.Y
		local inZ = Delta.Z <= HalfSize.Z
		return inX and inY and inZ
	elseif Shape == Enum.PartType.Ball then
		return Delta.Magnitude <= HalfSize.X
	end
	return nil
end
