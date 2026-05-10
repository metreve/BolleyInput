local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Cleaner = require("../Packages/Cleanup")
local Rendering = require("./Rendering")
local SpatialBall = require("./SpatialBall")
local BallCompactor = require(ReplicatedStorage.Modules.Packages.BallCompactor)

export type Ball = Rendering.Ball

local function CheckIfNeedsUpdate(inputData, oldData, timediff)
	local simulatedNextState = inputData -- SpatialBall.SimulateStep(inputData, timediff )

	if (simulatedNextState[1] - oldData[1]).Magnitude > 1 then
		return true
	end

	if (simulatedNextState[2] - oldData[2]).Magnitude > 1 then
		return true
	end
end

return function(Model: Model)
	local BallCleaner = Cleaner(function() end)
	local ReceivingUnreliable = Model:WaitForChild("Render") :: RemoteEvent
	local Received = ReceivingUnreliable.OnClientEvent:Wait()
	local lastSent = os.clock()
	local VirtualBall = Rendering.NewBall(Model, Received)

	BallCleaner["PhysicsRollback"] = ReceivingUnreliable.OnClientEvent:Connect(function(inputData, Extra)
		inputData = inputData
		local newSend = os.clock()
		if CheckIfNeedsUpdate(inputData, VirtualBall.CurrentState, newSend - lastSent) then
			Rendering.UpdateBallRealValues(VirtualBall, inputData, Extra)
			lastSent = newSend
			--			BallCleaner["PhysicsRollback"]:Disconnect()
		end
	end)

	BallCleaner["Rendering"] = RunService.PreRender:Connect(function(deltaTime)
		--		if new >= 1/60 then
		--			Rendering.Renderer(VirtualBall,new)
		--			t = 0
		--		else
		--			t = new
		--		end

		Rendering.Renderer(VirtualBall, deltaTime)
	end)

	return BallCleaner, VirtualBall
end
