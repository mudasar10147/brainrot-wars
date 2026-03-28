local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataManager = require(game.ServerScriptService.Data.PlayerDataManager)
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)

local SelectStarterEvent = ReplicatedStorage.Remotes.SelectStarterBrainrot
local RequestStarterOptions = ReplicatedStorage.Remotes.RequestStarterOptions

-- DataStore for persistence
local InventoryStore = DataStoreService:GetDataStore("PlayerInventory")

local StarterService = {}

-- Function to get 3 random starter brainrots
function StarterService:GetRandomStarters()
	local pool = {}
	for id, data in pairs(Brainrots) do
		if type(data) == "table" and data.Tier == "Common" and data.IsStarter then
			table.insert(pool, {
				Id = id,
				Name = data.Name,
				Icon = data.Icon,
			})
		end
	end

	local result = {}
	for i = 1,3 do
		if #pool == 0 then break end
		local index = math.random(1,#pool)
		table.insert(result, pool[index])
		table.remove(pool,index)
	end
	return result
end

-- Give the client starter options
RequestStarterOptions.OnServerInvoke = function(player)
	local data = PlayerDataManager:Get(player)
	if not data or data.HasChosenStarter then return nil end
	return StarterService:GetRandomStarters()
end

-- Handle starter selection
SelectStarterEvent.OnServerEvent:Connect(function(player, brainrotId)
	local data = PlayerDataManager:Get(player)
	if not data or data.HasChosenStarter then return end

	if not Brainrots[brainrotId] then return end -- invalid brainrot

	-- Add to inventory
	InventoryService:AddBrainrot(player, brainrotId)

	-- Auto-equip (use EquippedSlots to match InventoryService)
	data.EquippedSlots = data.EquippedSlots or {}
	data.EquippedSlots[1] = brainrotId
	data.HasChosenStarter = true

	-- Save to DataStore
	local success, err = pcall(function()
		InventoryStore:SetAsync(player.UserId, data)
	end)
	if not success then warn("Failed to save inventory for "..player.Name..": "..tostring(err)) end

	print("[StarterService] "..player.Name.." selected and equipped "..brainrotId)
end)

-- Load inventory on player join
Players.PlayerAdded:Connect(function(player)
	local success, data = pcall(function()
		return InventoryStore:GetAsync(player.UserId)
	end)
	if success and data then
		PlayerDataManager:Set(player, data) -- assume PlayerDataManager can set loaded data
	end
end)

-- Save inventory on leave
Players.PlayerRemoving:Connect(function(player)
	local data = PlayerDataManager:Get(player)
	if data then
		local success, err = pcall(function()
			InventoryStore:SetAsync(player.UserId, data)
		end)
		if not success then warn("Failed to save inventory for "..player.Name..": "..tostring(err)) end
	end
end)

return StarterService