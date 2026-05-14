local Character = {}

function Character.OnCharacterAdded(State, Context, character)
	State.ResetForCharacter(character)

	local rootPart = State.RootPart
	local humanoid = State.Humanoid

	rootPart.CanTouch = true
	rootPart.CustomPhysicalProperties = PhysicalProperties.new(3, 2, 0.5)

	if State.TouchConnections.BackrowBool then
		State.TouchConnections.BackrowBool:Disconnect()
		State.TouchConnections.BackrowBool = nil
	end

	State.TouchConnections.BackrowBool = rootPart.Touched:Connect(function(hit)
		if hit.Name == "BR" then
			character.inBr.Value = true
		elseif hit.Name == "FR" then
			character.inBr.Value = false
		end
	end)

	local oldBlockGui = rootPart:FindFirstChild("BlockGui")
	if oldBlockGui then
		oldBlockGui:Destroy()
	end

	if game.StarterPlayer:FindFirstChild("BlockGui") then
		State.BlockGui = game.StarterPlayer.BlockGui:Clone()
		State.BlockGui.Parent = rootPart
	end
end

function Character.Init(State, Context)
	local player = Context.Player

	if player.Character then
		Character.OnCharacterAdded(State, Context, player.Character)
	end
end

return Character
