local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Connect currency updates BEFORE waiting on HUD so early server pushes are not dropped.
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateCurrency = Remotes:WaitForChild("UpdateCurrency")
local GetCurrency = Remotes:WaitForChild("GetCurrency", 15)

local lastCurrency = { Gold = 0, Diamonds = 0 }
local goldAmount, diamondAmount

local function applyToLabels()
	if not goldAmount or not diamondAmount then
		return
	end
	goldAmount.Text = tostring(lastCurrency.Gold or 0)
	diamondAmount.Text = tostring(lastCurrency.Diamonds or 0)
end

UpdateCurrency.OnClientEvent:Connect(function(currency)
	if type(currency) ~= "table" then
		return
	end
	lastCurrency = {
		Gold = currency.Gold or 0,
		Diamonds = currency.Diamonds or 0,
	}
	applyToLabels()
end)

local hud = playerGui:WaitForChild("HUD", 60)
if not hud then
	warn("[CurrencyController] PlayerGui.HUD not found after 60s; currency labels unavailable.")
	return
end

local container = hud:WaitForChild("Container", 15)
if not container then
	warn("[CurrencyController] HUD.Container not found.")
	return
end

local currencyContainer = container:WaitForChild("CurrencyContainer", 15)
if not currencyContainer then
	warn("[CurrencyController] CurrencyContainer not found under HUD.")
	return
end

local goldBlock = currencyContainer:WaitForChild("Gold", 15)
local diamondBlock = currencyContainer:WaitForChild("Diamond", 15)
if not goldBlock or not diamondBlock then
	warn("[CurrencyController] Gold/Diamond block missing in CurrencyContainer.")
	return
end

goldAmount = goldBlock:WaitForChild("GoldAmount", 10)
diamondAmount = diamondBlock:WaitForChild("DiamondAmount", 10)
if not goldAmount or not diamondAmount then
	warn("[CurrencyController] GoldAmount/DiamondAmount labels missing.")
	return
end

-- Authoritative pull after HUD bind (covers rare race if server fired before this listener existed).
if GetCurrency then
	local ok, serverCurrency = pcall(function()
		return GetCurrency:InvokeServer()
	end)
	if ok and type(serverCurrency) == "table" then
		lastCurrency = {
			Gold = serverCurrency.Gold or 0,
			Diamonds = serverCurrency.Diamonds or 0,
		}
	end
end

applyToLabels()
print(
	string.format(
		"[CurrencyController] HUD bound @%.2fs Gold=%s Diamonds=%s",
		tick(),
		tostring(lastCurrency.Gold),
		tostring(lastCurrency.Diamonds)
	)
)
