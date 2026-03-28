local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MergeService = require(game.ServerScriptService.Services.MergeService)
local InventoryService = require(game.ServerScriptService.Services.InventoryService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MergeRequest = Instance.new("RemoteEvent")
MergeRequest.Name = "MergeRequest"
MergeRequest.Parent = Remotes

local MergeComplete = Instance.new("RemoteEvent")
MergeComplete.Name = "MergeComplete"
MergeComplete.Parent = Remotes

print("[MergeHandler] Loaded")

MergeRequest.OnServerEvent:Connect(function(player, brainrotA, brainrotB)
	print("[MergeHandler] Merge request from " .. player.Name .. ": " .. tostring(brainrotA) .. " + " .. tostring(brainrotB))

	if not brainrotA or not brainrotB then
		MergeComplete:FireClient(player, false, nil, "Invalid brainrots selected!")
		return
	end

	local success, resultOrError = MergeService:Merge(player, brainrotA, brainrotB)

	if success then
		local updatedInventory = InventoryService:GetInventory(player)
		local updatedEquipped = InventoryService:GetEquipped(player)
		MergeComplete:FireClient(player, true, resultOrError, {
			Inventory = updatedInventory,
			Equipped = updatedEquipped
		})
	else
		MergeComplete:FireClient(player, false, nil, resultOrError)
	end
end)