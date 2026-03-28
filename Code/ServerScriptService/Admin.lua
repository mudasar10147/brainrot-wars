local Players = game:GetService("Players")
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
local PlayerDataManager = require(game.ServerScriptService.Data.PlayerDataManager)

local ADMIN_ID = 3732228634

local function waitForPlayerData(player)
	local data
	repeat
		data = PlayerDataManager:Get(player)
		task.wait(0.1)
	until data
	return data
end

Players.PlayerAdded:Connect(function(player)
	if player.UserId == ADMIN_ID then
		local data = waitForPlayerData(player)

		-- Give one of each brainrot for testing
		InventoryService:AddBrainrot(player, "BananaDancana")
		InventoryService:AddBrainrot(player, "PandacciniBananini")
		InventoryService:AddBrainrot(player, "NyanniniCattalini")
		InventoryService:AddBrainrot(player, "PipiPotato")
		InventoryService:AddBrainrot(player, "TimCheese")
		InventoryService:AddBrainrot(player, "ChillinChili")
		print("[AdminScript] Gave test brainrots to " .. player.Name)
	end
end)