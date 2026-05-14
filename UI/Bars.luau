local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventManager = require(ReplicatedStorage.Modules.EventManager_Local)

local Bars = {}

local ENERGY_FILL_DIRECTION = "X"
local POWER_FILL_DIRECTION = "X"

local DEFAULT_STAMINA_COLOR = "0.262745,0.262745,0.262745"
local DEFAULT_SPIKE_COLOR = "0.976471,0,0"
local DEFAULT_BLOCK_COLOR = "0,0,1"
local DEFAULT_SET_COLOR = "0.462745,0.713725,0.470588"

local function stringToColor3(str)
	if typeof(str) == "Color3" then
		return str
	end

	if typeof(str) ~= "string" then
		return Color3.new(1, 1, 1)
	end

	local values = string.split(str, ",")
	local r = tonumber(values[1]) or 1
	local g = tonumber(values[2]) or 1
	local b = tonumber(values[3]) or 1

	return Color3.new(r, g, b)
end

local function getMainFrame(Context)
	local playerGui = Context.Player:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	local mainGui = playerGui:FindFirstChild("MainGui")
	if not mainGui then
		return nil
	end

	return mainGui:FindFirstChild("Main")
end

local function getBar(Context, name)
	local main = getMainFrame(Context)
	if not main then
		return nil, nil
	end

	local container = main:FindFirstChild(name)
	if not container then
		return nil, nil
	end

	local fill = container:FindFirstChild("Frame")
	if not fill or not fill:IsA("Frame") then
		return container, nil
	end

	return container, fill
end

local function getLabel(Context, name)
	local main = getMainFrame(Context)
	if not main then
		return nil
	end

	local label = main:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		return label
	end

	return nil
end

local function setFill(fill, alpha, direction)
	alpha = math.clamp(alpha, 0, 1)

	if direction == "Y" then
		fill.Size = UDim2.new(fill.Size.X.Scale, fill.Size.X.Offset, alpha, 0)
	else
		fill.Size = UDim2.new(alpha, 0, fill.Size.Y.Scale, fill.Size.Y.Offset)
	end
end

local function getPowerValue(State)
	local character = State.Character
	if not character then
		return 0
	end

	local power = character:FindFirstChild("Power")
	if power and power:IsA("NumberValue") then
		return power.Value
	end

	return State.Power or 0
end

local function getMaxPower(Context)
	local stats = Context.Player:FindFirstChild("Stats")
	if stats then
		return stats:GetAttribute("MaxPower") or 15
	end

	return 15
end

local function getMaxStamina(State, Context)
	if State.MaxStamina then
		return State.MaxStamina
	end

	local stamina = 10
	local physical = Context.Data:Get("Physical", "")
	local technical = Context.Data:Get("Technical", "")

	if physical == "Big Lungs" then
		stamina += 3
	elseif physical == "Athletic" then
		stamina += 1
	elseif physical == "All-Rounder" then
		stamina += 1
	end

	if technical == "Breathing Control" then
		stamina += 0
	end

	return stamina
end

local function getStaminaValue(State, Context)
	if State.Stamina ~= nil then
		return State.Stamina
	end

	local character = State.Character

	local possibleContainers = {
		character,
		character and character:FindFirstChild("LocalValues"),
		Context.Player,
		Context.Player:FindFirstChild("Stats"),
	}

	for _, container in ipairs(possibleContainers) do
		if container then
			for _, name in ipairs({ "Stamina", "stamina", "Energy", "energy" }) do
				local value = container:FindFirstChild(name)

				if value and value:IsA("NumberValue") then
					return value.Value
				end
			end
		end
	end

	return getMaxStamina(State, Context)
end

local function getJumpModeText(State)
	if State.SetMode then
		return "SET"
	end

	if State.JumpMode == false then
		return "BLOCK"
	end

	return "SPIKE"
end

local function getJumpModeColor(State, Context)
	if State.SetMode then
		return stringToColor3(Context.Data:Get("SetModeColor", DEFAULT_SET_COLOR))
	end

	if State.JumpMode == false then
		return stringToColor3(Context.Data:Get("BlockColor", DEFAULT_BLOCK_COLOR))
	end

	return stringToColor3(Context.Data:Get("SpikeColor", DEFAULT_SPIKE_COLOR))
end

function Bars.UpdateStamina(State, Context)
	local energy, fill = getBar(Context, "Energy")
	if not fill then
		return
	end

	local stamina = State.Energy or 0
	local maxStamina = State.MaxEnergy or 10

	setFill(fill, stamina / maxStamina, ENERGY_FILL_DIRECTION)

	local textLabel = energy and energy:FindFirstChild("TextLabel")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = string.format("%d/%d", stamina, maxStamina)
	end
end

function Bars.UpdatePower(State, Context)
	local powerBar, fill = getBar(Context, "Power")
	if not fill then
		return
	end

	local power = getPowerValue(State)
	local maxPower = getMaxPower(Context)

	setFill(fill, power / maxPower, POWER_FILL_DIRECTION)

	local textLabel = powerBar and powerBar:FindFirstChild("TextLabel")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = string.format("%d/%d", math.floor(power + 0.5), maxPower)
	end
end

function Bars.UpdateColors(State, Context)
	local _, energyFill = getBar(Context, "Energy")
	local _, powerFill = getBar(Context, "Power")

	if energyFill then
		energyFill.BackgroundColor3 = stringToColor3(Context.Data:Get("StaminaColor", DEFAULT_STAMINA_COLOR))
	end

	local modeColor = getJumpModeColor(State, Context)

	if powerFill then
		powerFill.BackgroundColor3 = modeColor
	end

	local jumpmodeLabel = getLabel(Context, "JumpmodeLabel")
	if jumpmodeLabel then
		jumpmodeLabel.Text = getJumpModeText(State)
		jumpmodeLabel.TextColor3 = modeColor
	end
end

function Bars.Update(State, Context)
	Bars.UpdateColors(State, Context)
	Bars.UpdateStamina(State, Context)
	Bars.UpdatePower(State, Context)
end

function Bars.Init(State, Context)
	local data = Context.Data

	local function update()
		Bars.Update(State, Context)
	end

	data:Changed("SpikeColor", update)
	data:Changed("BlockColor", update)
	data:Changed("SetModeColor", update)
	data:Changed("StaminaColor", update)
	data:Changed("Physical", update)
	data:Changed("Technical", update)

	if State.BarsConnection then
		State.BarsConnection:Disconnect()
		State.BarsConnection = nil
	end

	State.BarsConnection = EventManager.Subscribe(function()
		Bars.UpdateStamina(State, Context)
		Bars.UpdatePower(State, Context)
	end, { "RunService", "RenderStepped" }, "Input_Bars_" .. Context.Player.UserId)

	local character = State.Character
	if character then
		local power = character:FindFirstChild("Power")
		if power and power:IsA("NumberValue") then
			power:GetPropertyChangedSignal("Value"):Connect(function()
				Bars.UpdatePower(State, Context)
			end)
		end
	end

	update()
end

return Bars
