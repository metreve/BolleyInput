local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataController = {}

local data = {}
local initialized = false
local loaded = false

local changedCallbacks = {}
local loadedCallbacks = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dataReplication = remotes:FindFirstChild("DataReplication")

local getDataRemote = dataReplication and dataReplication:FindFirstChild("GetData")
local changedRemote = dataReplication and dataReplication:FindFirstChild("changed")

local function fireChanged(key, value)
	local callbacks = changedCallbacks[key]
	if not callbacks then
		return
	end

	for _, callback in ipairs(callbacks) do
		task.spawn(callback, value)
	end
end

local function fireLoaded()
	for _, callback in ipairs(loadedCallbacks) do
		task.spawn(callback, data)
	end
end

local function applyFullSync(newData)
	data = newData or {}
	loaded = data.Loaded == true

	fireLoaded()

	for key, value in pairs(data) do
		fireChanged(key, value)
	end
end

function DataController:Init()
	if initialized then
		return
	end

	initialized = true

	-- Do NOT block input startup on server data.
	task.spawn(function()
		if getDataRemote then
			local success, result = pcall(function()
				return getDataRemote:InvokeServer()
			end)

			if success and typeof(result) == "table" then
				applyFullSync(result)
			else
				warn("[DataController] GetData failed:", result)
			end
		else
			warn("[DataController] Missing DataReplication.GetData")
		end
	end)

	if changedRemote then
		changedRemote.OnClientEvent:Connect(function(key, value)
			if key == "__FULL_SYNC" then
				applyFullSync(value)
				return
			end

			if key == "__PATCH" then
				for changedKey, changedValue in pairs(value) do
					data[changedKey] = changedValue
					fireChanged(changedKey, changedValue)
				end

				return
			end

			data[key] = value
			fireChanged(key, value)
		end)
	else
		warn("[DataController] Missing DataReplication.Changed")
	end
end

function DataController:Get(key, defaultValue)
	local value = data[key]

	if value == nil then
		return defaultValue
	end

	return value
end

function DataController:GetAll()
	return data
end

function DataController:IsLoaded()
	return loaded
end

function DataController:Changed(key, callback)
	if not changedCallbacks[key] then
		changedCallbacks[key] = {}
	end

	table.insert(changedCallbacks[key], callback)

	return {
		Disconnect = function()
			local callbacks = changedCallbacks[key]
			if not callbacks then
				return
			end

			local index = table.find(callbacks, callback)
			if index then
				table.remove(callbacks, index)
			end
		end,
	}
end

function DataController:OnLoaded(callback)
	table.insert(loadedCallbacks, callback)

	if loaded then
		task.spawn(callback, data)
	end

	return {
		Disconnect = function()
			local index = table.find(loadedCallbacks, callback)
			if index then
				table.remove(loadedCallbacks, index)
			end
		end,
	}
end

function DataController:WaitForLoaded(timeout)
	local started = os.clock()

	while not loaded do
		if timeout and os.clock() - started >= timeout then
			return false
		end

		task.wait()
	end

	return true
end

return DataController
