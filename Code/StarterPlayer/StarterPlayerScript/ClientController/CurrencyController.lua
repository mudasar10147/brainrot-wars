local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hud = playerGui:WaitForChild("HUD")
local container = hud:WaitForChild("Container")
local currencyContainer = container:WaitForChild("CurrencyContainer")
local goldAmount = currencyContainer:WaitForChild("Gold"):WaitForChild("GoldAmount")
local diamondAmount = currencyContainer:WaitForChild("Diamond"):WaitForChild("DiamondAmount")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateCurrency = Remotes:WaitForChild("UpdateCurrency")

print("[CurrencyController] Loaded")

local function updateHUD(currency)
	goldAmount.Text = tostring(currency.Gold or 0)
	diamondAmount.Text = tostring(currency.Diamonds or 0)
	print("[CurrencyController] Updated HUD — Gold: " .. tostring(currency.Gold) .. " Diamonds: " .. tostring(currency.Diamonds))
end

UpdateCurrency.OnClientEvent:Connect(function(currency)
	updateHUD(currency)
end)