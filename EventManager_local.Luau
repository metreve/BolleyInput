local EventManager = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TeamsService = game:GetService("Teams")
local ScriptContext = game:GetService("ScriptContext")

local LocalPlayer = Players.LocalPlayer

local Events = {
	Players = {
		PlayerAdded = {},
		PlayerRemoving = {},
		CharacterAdded = {},
		CharacterRemoving = {},
	},

	UserInputService = {
		InputBegan = {},
		InputEnded = {},
		InputChanged = {},
	},

	RunService = {
		RenderStepped = {},
		Heartbeat = {},
		PreRender = {},
	},

	GuiService = {
		MenuOpened = {},
		MenuClosed = {},
	},

	Teams = {
		ChildAdded = {},
		ChildRemoved = {},
	},

	ScriptContext = {
		Error = {},
	},
}

local Sources = {
	UserInputService = UserInputService,
	RunService = RunService,
	GuiService = GuiService,
	Teams = TeamsService,
	ScriptContext = ScriptContext,
}

local function fireCallbacks(callbacks, ...)
	for _, callback in pairs(callbacks) do
		task.spawn(function(...)
			local success, err = pcall(callback, ...)
			if not success then
				warn("[EventManager_Local]:", err)
			end
		end, ...)
	end
end

local function getEventTable(path)
	local current = Events

	for _, key in ipairs(path) do
		current = current[key]

		if not current then
			warn("[EventManager_Local] Invalid path key:", key)
			return nil
		end
	end

	return current
end

function EventManager.Subscribe(func, path, name)
	local eventTable = getEventTable(path)
	if not eventTable then
		return
	end

	eventTable[name] = func

	return {
		Disconnect = function()
			eventTable[name] = nil
		end,
	}
end

function EventManager.Unsubscribe(path, name)
	local eventTable = getEventTable(path)
	if not eventTable then
		return
	end

	eventTable[name] = nil
end

local function connectNormalEvents()
	for sourceName, sourceEvents in pairs(Events) do
		local source = Sources[sourceName]
		if not source then
			continue
		end

		for eventName, callbacks in pairs(sourceEvents) do
			local signal = source[eventName]

			if typeof(signal) == "RBXScriptSignal" then
				signal:Connect(function(...)
					fireCallbacks(callbacks, ...)
				end)
			end
		end
	end
end

local function connectPlayerEvents()
	if LocalPlayer.Character then
		task.defer(function()
			fireCallbacks(Events.Players.CharacterAdded, LocalPlayer.Character)
		end)
	end

	LocalPlayer.CharacterAdded:Connect(function(character)
		fireCallbacks(Events.Players.CharacterAdded, character)
	end)

	LocalPlayer.CharacterRemoving:Connect(function(character)
		fireCallbacks(Events.Players.CharacterRemoving, character)
	end)
end

connectNormalEvents()
connectPlayerEvents()

return EventManager
