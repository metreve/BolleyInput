local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local Context = {
	Players = Players,
	Player = Player,
	ReplicatedStorage = ReplicatedStorage,
	TweenService = TweenService,
	UserInputService = UserInputService,
	ContextActionService = ContextActionService,
	RunService = RunService,
	GuiService = GuiService,
	Workspace = Workspace,

	Remotes = ReplicatedStorage:WaitForChild("Remotes"),
	InputHandler = ReplicatedStorage:WaitForChild("InputHandler"),
	PickupsManager = ReplicatedStorage:WaitForChild("PickupsManager"),
	MacroEvent = ReplicatedStorage:WaitForChild("macroEvent"),
	Pickups = ReplicatedStorage:WaitForChild("Pickups"),
}

Context.ChangeStatus = ReplicatedStorage:WaitForChild("ChangeStatus")
Context.EffectHandler = Context.Remotes:WaitForChild("EffectHandler")
Context.PowerHandler = Context.Remotes:WaitForChild("PowerHandler")
Context.PlayerAction = Context.Remotes:WaitForChild("PlayerAction")

Context.Data = require(ReplicatedStorage.Modules.Data.DataController)
Context.Data:Init()
Context.PlayerGui = Player:WaitForChild("PlayerGui")

return Context
