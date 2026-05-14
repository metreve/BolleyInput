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
local Click = require(script.Parent.Actions.Click)
local PowerPreset = require(script.Parent.Actions.PowerPreset)
local Stamina = require(script.Parent.Actions.Stamina)

local Input = {}

local function runStage(name, callback)
	print("[Input] Starting:", name)

	local success, result = pcall(callback)

	if not success then
		warn("[Input] Failed at:", name, result)
		return false
	end

	print("[Input] Finished:", name)
	return true
end

function Input.Start()
	workspace.Gravity = 50

	if not runStage("Character.Init", function()
		Character.Init(State, Context)
	end) then
		return
	end

	if not runStage("Stamina.Init", function()
		Stamina.Init(State, Context)
	end) then
		return
	end

	if not runStage("Bars.Init", function()
		Bars.Init(State, Context)
	end) then
		return
	end

	if not runStage("Stamina.StartRegen", function()
		Stamina.StartRegen(State, Context, Bars)
	end) then
		return
	end

	if not runStage("Serve.Init", function()
		Serve.Init(State, Context)
	end) then
		return
	end

	print("[Input] Building actions")

	local actions = {
		SpawnBall = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				SpawnBall.Start(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		PowerUp = function(_, inputState)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end

			if State.PowerCooldown then
				return Enum.ContextActionResult.Sink
			end

			if State.PowerChangeable == false then
				return Enum.ContextActionResult.Sink
			end

			State.PowerCooldown = true

			Context.PowerHandler:FireServer("P", 1)

			task.delay(State.PowerCooldownTime or 0.12, function()
				State.PowerCooldown = false
			end)

			return Enum.ContextActionResult.Sink
		end,

		PowerDown = function(_, inputState)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end

			if State.PowerCooldown then
				return Enum.ContextActionResult.Sink
			end

			if State.PowerChangeable == false then
				return Enum.ContextActionResult.Sink
			end

			State.PowerCooldown = true

			Context.PowerHandler:FireServer("P", -1)

			task.delay(State.PowerCooldownTime or 0.12, function()
				State.PowerCooldown = false
			end)

			return Enum.ContextActionResult.Sink
		end,

		PowerSet1 = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				PowerPreset.Set(State, Context, "PowerSet1")
			end

			return Enum.ContextActionResult.Sink
		end,

		PowerSet2 = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				PowerPreset.Set(State, Context, "PowerSet2")
			end

			return Enum.ContextActionResult.Sink
		end,

		PowerSet3 = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				PowerPreset.Set(State, Context, "PowerSet3")
			end

			return Enum.ContextActionResult.Sink
		end,

		Click = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				Click.Start(State, Context)
			end

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
				Bars.UpdatePower(State, Context)
			end

			return Enum.ContextActionResult.Sink
		end,

		SetMode = function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				JumpMode.SetMode(State, Context)
				Bars.UpdateColors(State, Context)
				Bars.UpdatePower(State, Context)
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
				Jump.Begin(State, Context)
			elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
				Jump.End(State, Context)
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

	print("[Input] Binding actions")
	Binder.Bind(actions)
	print("[Input] Actions bound")

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

	Context.Data:Changed("Height", function()
		Stamina.RefreshMax(State, Context)
		Bars.UpdateStamina(State, Context)
	end)

	Context.Data:Changed("Physical", function()
		Stamina.RefreshMax(State, Context)
		Bars.UpdateStamina(State, Context)
	end)

	EventManager.Subscribe(function(character)
		Character.OnCharacterAdded(State, Context, character)
	end, { "Players", "CharacterAdded" }, "Input_CharacterAdded")
end

function Input.Stop()
	Binder.UnbindAll()
end

return Input
