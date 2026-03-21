local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreHandler = require(script.Parent.Data.DataStoreServiceHandler)
local PlayerDataManager = require(script.Parent.Data.PlayerDataManager)
local StarterService = require(script.Parent.Services.StarterService)
local ResetStarterService = require(script.Parent.Services.ResetStarterService)
local ValuablesSystem = require(script.Parent.Systems.ValuablesSystem)
local MergeService = require(script.Parent.Services.MergeService)
local CurrencyService = require(script.Parent.Services.CurrencyService)

-- Create UpdateCurrency remote
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateCurrency = Instance.new("RemoteEvent")
UpdateCurrency.Name = "UpdateCurrency"
UpdateCurrency.Parent = Remotes

print("[ServerMain] All services loaded successfully")

local SAVE_INTERVAL = 10
ValuablesSystem.Init()

Players.PlayerAdded:Connect(function(player)
	print("[ServerMain] Player joined: " .. player.Name)
	DataStoreHandler:LoadData(player)

	-- Send currency to client when data loads
	task.spawn(function()
		local attempts = 0
		local data
		repeat
			task.wait(0.5)
			attempts += 1
			data = PlayerDataManager:Get(player)
		until data or attempts >= 40
		if not data then return end
		local currency = CurrencyService:GetCurrency(player)
		UpdateCurrency:FireClient(player, currency)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	print("[ServerMain] Loading data for existing player: " .. player.Name)
	DataStoreHandler:LoadData(player)
end

Players.PlayerRemoving:Connect(function(player)
	print("[ServerMain] Player leaving: " .. player.Name)
	DataStoreHandler:SaveData(player)
	PlayerDataManager:Remove(player)
end)

task.spawn(function()
	while true do
		task.wait(SAVE_INTERVAL)
		print("[ServerMain] Auto-saving data for all players...")
		for _, player in ipairs(Players:GetPlayers()) do
			DataStoreHandler:SaveData(player)
		end
		print("[ServerMain] Auto-save complete")
	end
end)