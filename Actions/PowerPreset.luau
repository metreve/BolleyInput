local PowerPreset = {}

local PRESET_TO_KEY_ATTRIBUTE = {
	PowerSet1 = "PowerKey1",
	PowerSet2 = "PowerKey2",
	PowerSet3 = "PowerKey3",
}

local function fireControlDisplay(Context, text)
	local misc = Context.Player.PlayerGui:FindFirstChild("Misc")
	if misc and misc:FindFirstChild("ControlDisplay") then
		misc.ControlDisplay.Event:Fire(text)
	end
end

local function getKeybinds(Context)
	return Context.Player:FindFirstChild("Keybinds")
end

local function getPowerHandler(Context)
	if Context.Remotes then
		return Context.Remotes:FindFirstChild("PowerHandler")
	end

	return nil
end

function PowerPreset.Set(State, Context, presetName)
	if State.PowerChangeable == false then
		return
	end

	local keyAttribute = PRESET_TO_KEY_ATTRIBUTE[presetName]
	if not keyAttribute then
		warn("[PowerPreset] Invalid preset:", presetName)
		return
	end

	local keybinds = getKeybinds(Context)
	if not keybinds then
		warn("[PowerPreset] Missing Player.Keybinds")
		return
	end

	local powerHandler = getPowerHandler(Context)
	if not powerHandler then
		warn("[PowerPreset] Missing Remotes.PowerHandler")
		return
	end

	local serverKey = keybinds:GetAttribute(keyAttribute)
	if serverKey == nil then
		warn("[PowerPreset] Missing keybind attribute:", keyAttribute)
		return
	end

	powerHandler:FireServer(serverKey)

	fireControlDisplay(Context, presetName)
end

return PowerPreset
