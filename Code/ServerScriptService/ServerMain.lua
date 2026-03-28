local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreHandler = require(script.Parent.Data.DataStoreServiceHandler)
local PlayerDataManager = require(script.Parent.Data.PlayerDataManager)
local StarterService = require(script.Parent.Services.StarterService)
local ResetStarterService = require(script.Parent.Services.ResetStarterService)
local ValuablesSystem = require(script.Parent.Systems.ValuablesSystem)
local MergeService = require(script.Parent.Services.MergeService)
local CurrencyService = require(script.Parent.Services.CurrencyService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateCurrency = Remotes:FindFirstChild("UpdateCurrency")
if not UpdateCurrency then
	UpdateCurrency = Instance.new("RemoteEvent")
	UpdateCurrency.Name = "UpdateCurrency"
	UpdateCurrency.Parent = Remotes
end

local GetCurrency = Remotes:FindFirstChild("GetCurrency")
if not GetCurrency then
	GetCurrency = Instance.new("RemoteFunction")
	GetCurrency.Name = "GetCurrency"
	GetCurrency.Parent = Remotes
end
GetCurrency.OnServerInvoke = function(player)
	return CurrencyService:GetCurrency(player)
end

print("[ServerMain] All services loaded successfully")

local function syncCurrencyToClient(player)
	local currency = CurrencyService:GetCurrency(player)
	UpdateCurrency:FireClient(player, currency)
	print(
		string.format(
			"[ServerMain] Currency sync %s @%.2fs Gold=%s Diamonds=%s",
			player.Name,
			tick(),
			tostring(currency.Gold),
			tostring(currency.Diamonds)
		)
	)
end

local function loadDataAndPushCurrency(player)
	DataStoreHandler:LoadData(player)
	syncCurrencyToClient(player)
end

local SAVE_INTERVAL = 10
ValuablesSystem.Init()

Players.PlayerAdded:Connect(function(player)
	print("[ServerMain] Player joined: " .. player.Name)
	loadDataAndPushCurrency(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	print("[ServerMain] Loading data for existing player: " .. player.Name)
	loadDataAndPushCurrency(player)
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