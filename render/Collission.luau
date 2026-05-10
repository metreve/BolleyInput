return function(spherePosition, sphereRadius, boxCFrame, boxSize)
	local localSpherePos = boxCFrame:PointToObjectSpace(spherePosition)
	local halfSize = boxSize * 0.5

	local closestPoint = Vector3.new(
		math.clamp(localSpherePos.X, -halfSize.X, halfSize.X),
		math.clamp(localSpherePos.Y, -halfSize.Y, halfSize.Y),
		math.clamp(localSpherePos.Z, -halfSize.Z, halfSize.Z)
	)

	local distance = (localSpherePos - closestPoint).Magnitude

	return distance <= sphereRadius
end
