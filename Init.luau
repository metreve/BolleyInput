local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventManager = require(ReplicatedStorage.Modules.EventManager_Local)

local State = require(script.Parent.State)
local Context = require(script.Parent.Context)
local Binder = require(script.Parent.Binder)

local Character = require(script.Parent.Character)
local Bars = require(script.Parent.UI.Bars)
local MobileButtons = require(script.Parent.UI.MobileButtons)

local SpawnBall = require(script.Parent.Actions.SpawnBall)
local Power = require(script.Parent.Actions.Power)
local Sprint = require(script.Parent.Actions.Sprint)
local Dive = require(script.Parent.Actions.Dive)
local Serve = require(script.Parent.Actions.Serve)
local Set = require(script.Parent.Actions.Set)
local Tilt = require(script.Parent.Actions.Tilt)
local JumpMode = require(script.Parent.Actions.JumpMode)
local Jump = require(script.Parent.Actions.Jump)

local Input = {}

function Input.Start()
	workspace.Gravity = 50
	Character.Init(State, Context)
	Bars.Init(State, Context)

	local actions = {
		SpawnBall = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				SpawnBall.Start(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		PowerUp = function(_, inputState)
			Power.Handle(State, Context, "Increase", inputState)
			return Enum.ContextActionResult.Sink
		end,

		PowerDown = function(_, inputState)
			Power.Handle(State, Context, "Decrease", inputState)
			return Enum.ContextActionResult.Sink
		end,

		Sprint = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Sprint.Start(State, Context)
			elseif inputState == Enum.UserInputState.End then
				Sprint.End(State, Context)
			end

			return Enum.ContextActionResult.Pass
		end,

		Dive = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Dive.Start(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		Serve = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Serve.Start(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		JumpMode = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				JumpMode.Toggle(State, Context)
				Bars.UpdateColors(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		SetMode = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				JumpMode.SetMode(State, Context)
				Bars.UpdateColors(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		FrontSet = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Set.Front(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		Jump = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Jump.Start(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		BackSet = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Set.Back(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		Dump = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Set.Dump(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		TiltForward = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Tilt.Apply(State, Context, "Forward")
			end

			return Enum.ContextActionResult.Pass
		end,

		TiltLeft = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Tilt.Apply(State, Context, "Left")
			end

			return Enum.ContextActionResult.Pass
		end,

		TiltBack = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Tilt.Apply(State, Context, "Back")
			end

			return Enum.ContextActionResult.Pass
		end,

		TiltRight = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Tilt.Apply(State, Context, "Right")
			end

			return Enum.ContextActionResult.Pass
		end,
	}

	Binder.Bind(actions)

	EventManager.Subscribe(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if input.KeyCode == Enum.KeyCode.W then
			Tilt.Apply(State, Context, "Forward")
		elseif input.KeyCode == Enum.KeyCode.A then
			Tilt.Apply(State, Context, "Left")
		elseif input.KeyCode == Enum.KeyCode.S then
			Tilt.Apply(State, Context, "Back")
		elseif input.KeyCode == Enum.KeyCode.D then
			Tilt.Apply(State, Context, "Right")
		end
	end, { "UserInputService", "InputBegan" }, "Input_TiltKeys")

	MobileButtons.Init(State, Context, actions)

	EventManager.Subscribe(function(character)
		Character.OnCharacterAdded(State, Context, character)
	end, { "Players", "CharacterAdded" }, "Input_CharacterAdded")
end

function Input.Stop()
	Binder.UnbindAll()
end

return Input
