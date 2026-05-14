local CharacterMovement = {}

function CharacterMovement.Reset(State, oldWalkSpeed)
	local humanoid = State.Humanoid
	local rootPart = State.RootPart

	if humanoid and humanoid.Parent then
		humanoid.AutoRotate = true
		humanoid.WalkSpeed = oldWalkSpeed or State.LastWalkSpeed or 16
		humanoid.JumpPower = 0
	end

	if rootPart and rootPart.Parent then
		local tilt = rootPart:FindFirstChild("Tilt")
		if tilt then
			tilt:Destroy()
		end

		local jumpMovement = rootPart:FindFirstChild("JumpMovement")
		if jumpMovement then
			jumpMovement:Destroy()
		end

		local diveMovement = rootPart:FindFirstChild("DiveMovement")
		if diveMovement then
			diveMovement:Destroy()
		end
	end
end

return CharacterMovement
