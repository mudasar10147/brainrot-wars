local PlayerDataManager = require(game.ServerScriptService.Data.PlayerDataManager)

print("[CurrencyService] Module loaded")

local CurrencyService = {}

function CurrencyService:AddGold(player, amount)
	local data = PlayerDataManager:Get(player)
	if not data then
		warn("[CurrencyService] No data for " .. player.Name)
		return false
	end
	data.Gold = (data.Gold or 0) + amount
	print("[CurrencyService] Added " .. amount .. " gold to " .. player.Name .. " Total: " .. data.Gold)
	return true
end

function CurrencyService:AddDiamonds(player, amount)
	local data = PlayerDataManager:Get(player)
	if not data then
		warn("[CurrencyService] No data for " .. player.Name)
		return false
	end
	data.Diamonds = (data.Diamonds or 0) + amount
	print("[CurrencyService] Added " .. amount .. " diamonds to " .. player.Name .. " Total: " .. data.Diamonds)
	return true
end

function CurrencyService:GetCurrency(player)
	local data = PlayerDataManager:Get(player)
	if not data then return {Gold = 0, Diamonds = 0} end
	return {
		Gold = data.Gold or 0,
		Diamonds = data.Diamonds or 0
	}
end

return CurrencyService