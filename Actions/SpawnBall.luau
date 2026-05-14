local SpawnBall = {}

function SpawnBall.Start(State, Context)
	local rootPart = State.RootPart
	if not rootPart then
		return
	end

	if not State.Ready then
		return
	end
	if State.Spawned then
		return
	end
	if rootPart.Position.Y > 15 then
		return
	end

	State.Spawned = true
	Context.InputHandler:FireServer("G")

	task.delay(2, function()
		State.Spawned = false
	end)
end

return SpawnBall
