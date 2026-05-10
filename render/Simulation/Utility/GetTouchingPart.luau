return function(Part)
	local Connection = Part.Touched:Connect(function() end)
	local Results = Part:GetTouchingParts()
	Connection:Disconnect()
	return Results
end
