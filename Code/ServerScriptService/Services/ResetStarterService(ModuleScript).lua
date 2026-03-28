local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PlayerDataManager = require(script.Parent.Parent.Data.PlayerDataManager)
local DataStoreServiceHandler = require(script.Parent.Parent.Data.DataStoreServiceHandler)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remote if it doesn't exist
local ResetPlayer = Remotes:FindFirstChild("ResetPlayer")
if not ResetPlayer then
	ResetPlayer = Instance.new("RemoteEvent")
	ResetPlayer.Name = "ResetPlayer"
	ResetPlayer.Parent = Remotes
end

local ResetPlayer = Remotes:WaitForChild("ResetPlayer")

local DataStore = DataStoreService:GetDataStore("BrainrotPlayerData")

print("[ResetStarterService] Module loaded")

local ResetStarterService = {}

function ResetStarterService:ResetPlayerData(player)
	print("[ResetStarterService] " .. player.Name .. " requested starter reset")

	-- Delete the player's DataStore entry
	local success, err = pcall(function()
		DataStore:RemoveAsync(player.UserId)
	end)

	if not success then
		warn("[ResetStarterService] Failed to delete DataStore for " .. player.Name .. ": " .. err)
		ResetPlayer:FireClient(player, false)
		return false
	end

	print("[ResetStarterService] Deleted DataStore entry for " .. player.Name)

	-- Reset in-memory data to fresh template
	local template = {
		Inventory = {},
		Equipped = {},
		Gold = 0,
		Diamonds = 0,
		HasChosenStarter = false
	}
	PlayerDataManager:Set(player, template)

	print("[ResetStarterService] Successfully reset all data for " .. player.Name)
	ResetPlayer:FireClient(player, true)
	return true
end

-- Listen for ResetPlayer RemoteEvent from client
ResetPlayer.OnServerEvent:Connect(function(player)
	ResetStarterService:ResetPlayerData(player)
end)

return ResetStarterService