local Glide = {}

local VALID_KEYS = {
	W = true,
	A = true,
	S = true,
	D = true,

	WA = true,
	WD = true,
	SA = true,
	SD = true,
}

local INVERT_FORWARD_BACK = true
local INVERT_LEFT_RIGHT = false

function Glide.GetKeys(Context)
	local UIS = Context.UserInputService

	local w = UIS:IsKeyDown(Enum.KeyCode.W)
	local a = UIS:IsKeyDown(Enum.KeyCode.A)
	local s = UIS:IsKeyDown(Enum.KeyCode.S)
	local d = UIS:IsKeyDown(Enum.KeyCode.D)

	if INVERT_FORWARD_BACK then
		w, s = s, w
	end

	if INVERT_LEFT_RIGHT then
		a, d = d, a
	end

	local keys = ""

	if w then
		keys ..= "W"
	end

	if s then
		keys ..= "S"
	end

	if a then
		keys ..= "A"
	end

	if d then
		keys ..= "D"
	end

	if VALID_KEYS[keys] then
		return keys
	end

	return ""
end

function Glide.Update(State, Context)
	if not State.Jumped then
		return
	end

	local character = State.Character
	if not character then
		return
	end

	local localValues = character:FindFirstChild("LocalValues")
	if not localValues then
		return
	end

	local glideKeys = localValues:FindFirstChild("GlideKeys")
	if not glideKeys then
		return
	end

	glideKeys.Value = Glide.GetKeys(Context)
end

function Glide.Clear(State)
	local character = State.Character
	if not character then
		return
	end

	local localValues = character:FindFirstChild("LocalValues")
	if not localValues then
		return
	end

	local glideKeys = localValues:FindFirstChild("GlideKeys")
	if glideKeys then
		glideKeys.Value = ""
	end
end

return Glide
