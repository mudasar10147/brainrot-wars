local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreHandler = require(script.Parent.Parent.Data.DataStoreServiceHandler)
local InventoryService = require(script.Parent.InventoryService)
local MergeMap = require(ReplicatedStorage.Config.MergeMap)

-- Create RemoteEvent for feedback (only once)
local MergeFeedback = ReplicatedStorage:FindFirstChild("MergeFeedback")
if not MergeFeedback then
	MergeFeedback = Instance.new("RemoteEvent")
	MergeFeedback.Name = "MergeFeedback"
	MergeFeedback.Parent = ReplicatedStorage
end

print("[MergeService] Module loaded")

local MergeService = {}

-- Find merge result for two brainrots
local function getMergeResult(brainrotA, brainrotB)
	for _, mapping in ipairs(MergeMap) do
		if (mapping.A == brainrotA and mapping.B == brainrotB) or
			(mapping.A == brainrotB and mapping.B == brainrotA) then
			return mapping.Result
		end
	end
	return nil
end

-- Check how many of a brainrot the player has
local function countBrainrot(inventory, brainrotName)
	local count = 0
	for _, name in ipairs(inventory) do
		if name == brainrotName then
			count += 1
		end
	end
	return count
end

-- Send feedback to player
local function sendFeedback(player, message)
	MergeFeedback:FireClient(player, message)
	print("[MergeFeedback] " .. player.Name .. ": " .. message)
end

function MergeService:Merge(player, brainrotA, brainrotB)
	print("[MergeService] " .. player.Name .. " requested merge: " .. brainrotA .. " + " .. brainrotB)

	local inventory = InventoryService:GetInventory(player)
	if not inventory then
		warn("[MergeService] No inventory for " .. player.Name)
		sendFeedback(player, "❌ **No Inventory!** Load your inventory first.")
		return false, "No inventory found"
	end

	-- Check if both brainrots are in inventory
	if brainrotA == brainrotB then
		-- Same brainrot — need at least 2
		if countBrainrot(inventory, brainrotA) < 2 then
			sendFeedback(player, "❌ **Not Enough!** You need **2 " .. brainrotA .. "** to merge!")
			return false, "You need 2 of the same brainrot to merge!"
		end
	else
		-- Different brainrots — need at least 1 of each
		if countBrainrot(inventory, brainrotA) < 1 then
			sendFeedback(player, "❌ **Missing!** You don't have **" .. brainrotA .. "**")
			return false, "You don't have " .. brainrotA
		end
		if countBrainrot(inventory, brainrotB) < 1 then
			sendFeedback(player, "❌ **Missing!** You don't have **" .. brainrotB .. "**")
			return false, "You don't have " .. brainrotB
		end
	end

	-- Get merge result
	local result = getMergeResult(brainrotA, brainrotB)
	if not result then
		sendFeedback(player, "❌ **No Merge!** **" .. brainrotA .. " + " .. brainrotB .. "** cannot be merged!")
		return false, "These brainrots cannot be merged!"
	end

	-- Remove both brainrots
	local removeA = InventoryService:RemoveBrainrot(player, brainrotA)
	if not removeA then
		sendFeedback(player, "❌ **Error!** Failed to remove " .. brainrotA)
		return false, "Failed to remove " .. brainrotA
	end

	local removeB = InventoryService:RemoveBrainrot(player, brainrotB)
	if not removeB then
		-- Rollback — add brainrotA back
		InventoryService:AddBrainrot(player, brainrotA)
		sendFeedback(player, "❌ **Error!** Failed to remove " .. brainrotB .. " (rolled back)")
		return false, "Failed to remove " .. brainrotB
	end

	-- Unequip if either was equipped
	InventoryService:UnequipBrainrot(player, brainrotA)
	InventoryService:UnequipBrainrot(player, brainrotB)

	-- Add merge result
	InventoryService:AddBrainrot(player, result)

	-- Save to DataStore
	DataStoreHandler:SaveData(player)

	-- SUCCESS FEEDBACK 🎉
	sendFeedback(player, "✅ **Merge Successful!** " .. brainrotA .. " + " .. brainrotB .. " = **" .. result .. "**!")

	print("[MergeService] Merge successful! " .. brainrotA .. " + " .. brainrotB .. " = " .. result)
	return true, result
end

return MergeService