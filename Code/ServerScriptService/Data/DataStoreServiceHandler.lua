local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataManager = require(script.Parent.PlayerDataManager)

local DataStore = DataStoreService:GetDataStore("BrainrotPlayerData")

print("[DataStoreServiceHandler] Module loaded")

local saveDebounce = {}
local SAVE_COOLDOWN = 3
local AUTO_SAVE_INTERVAL = 30

-- Helper function to clone tables
local function cloneTable(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			new[k] = cloneTable(v)
		else
			new[k] = v
		end
	end
	return new
end

local DataStoreHandler = {}

-- Check if we can save (debounce)
local function canSave(player)
	local now = tick()
	local userId = player.UserId
	if not saveDebounce[userId] or now - saveDebounce[userId] >= SAVE_COOLDOWN then
		saveDebounce[userId] = now
		return true
	end
	return false
end

function DataStoreHandler:LoadData(player)
	print("[DataStoreServiceHandler] Loading data for " .. player.Name)

	local data

	local success, err = pcall(function()
		data = DataStore:GetAsync(player.UserId)
	end)

	if not success then
		warn("[DataStoreServiceHandler] Failed to load data for " .. player.Name .. ":" .. err)
	end

	if not data then
		print("[DataStoreServiceHandler] No data found, creating new data for " .. player.Name)
		data = cloneTable(PlayerDataManager.Template)
	else
		print("[DataStoreServiceHandler] Loaded existing data for " .. player.Name)
		print("[DataStoreServiceHandler] HasChosenStarter: " .. tostring(data.HasChosenStarter))
		print("[DataStoreServiceHandler] Gold: " .. tostring(data.Gold))
		print("[DataStoreServiceHandler] Inventory size: " .. tostring(#data.Inventory))
	end

	-- Ensure inventory is stored in fixed slots (prevents auto relocation).
	data = PlayerDataManager:NormalizeData(data)
	PlayerDataManager:Set(player, data)
end

function DataStoreHandler:SaveData(player)
	-- DEBOUNCE CHECK - NO MORE 20+ CALLS/SECOND!
	if not canSave(player) then
		return -- Skip save, too soon
	end

	print("[DataStoreServiceHandler] Saving data for " .. player.Name)

	local data = PlayerDataManager:Get(player)

	if not data then 
		warn("[DataStoreServiceHandler] No data to save for " .. player.Name)
		return 
	end

	print("[DataStoreServiceHandler] Saving data - HasChosenStarter: " .. tostring(data.HasChosenStarter))
	print("[DataStoreServiceHandler] Saving data - Gold: " .. tostring(data.Gold))
	print("[DataStoreServiceHandler] Saving data - Inventory size: " .. tostring(#data.Inventory))

	local success, err = pcall(function()
		DataStore:UpdateAsync(player.UserId, function(old)
			return data
		end)
	end)

	if not success then
		warn("[DataStoreServiceHandler] Failed to save data for " .. player.Name .. ":" .. err)
	else
		print("[DataStoreServiceHandler] Successfully saved data for " .. player.Name)
	end
end

-- AUTO-SAVE ALL PLAYERS (replaces ServerMain auto-save spam)
function DataStoreHandler:AutoSaveAll()
	for _, player in pairs(Players:GetPlayers()) do
		DataStoreHandler:SaveData(player)
	end
end

-- CLEANUP ON LEAVE
Players.PlayerRemoving:Connect(function(player)
	DataStoreHandler:SaveData(player) -- Force save on leave
	saveDebounce[player.UserId] = nil
end)

-- AUTO-SAVE LOOP (every 30 seconds)
spawn(function()
	while true do
		wait(AUTO_SAVE_INTERVAL)
		DataStoreHandler:AutoSaveAll()
	end
end)

return DataStoreHandler