--[[ InventoryService (slot-based) ]]

local PlayerDataManager = require(game.ServerScriptService.Data.PlayerDataManager)
print("[InventoryService] Module loaded")

local InventoryService = {}

local TOTAL_EQUIPPED_SLOTS = 7

local function getPlayerData(player)
	local data = PlayerDataManager:Get(player)
	local tries = 0
	while not data and tries < 50 do
		task.wait(0.1)
		data = PlayerDataManager:Get(player)
		tries += 1
	end

	if not data then
		warn("[InventoryService] No data found for " .. player.Name)
		return nil
	end

	-- Ensure capacities exist.
	data.InventoryCapacity = data.InventoryCapacity or 50
	data.EquipCapacity = data.EquipCapacity or 3

	if data.EquipCapacity < 0 then
		data.EquipCapacity = 0
	end
	if data.EquipCapacity > TOTAL_EQUIPPED_SLOTS then
		data.EquipCapacity = TOTAL_EQUIPPED_SLOTS
	end

	-- Ensure slot arrays exist and are fixed-length using false for empty.
	data.InventorySlots = data.InventorySlots or {}
	data.EquippedSlots = data.EquippedSlots or {}

	local invCap = data.InventoryCapacity
	local eqUnlockedCap = data.EquipCapacity

	for i = 1, invCap do
		if data.InventorySlots[i] == nil then
			data.InventorySlots[i] = false
		end
	end

	-- Always maintain the full 7-slot array for equipped positions.
	for i = 1, TOTAL_EQUIPPED_SLOTS do
		if data.EquippedSlots[i] == nil then
			data.EquippedSlots[i] = false
		end
	end

	return data
end

function InventoryService:GetStorageCapacity(player)
	local data = getPlayerData(player)
	return data and data.InventoryCapacity or 50
end

function InventoryService:GetEquipCapacity(player)
	local data = getPlayerData(player)
	return data and data.EquipCapacity or 3
end

function InventoryService:GetInventorySlots(player)
	local data = getPlayerData(player)
	return data and data.InventorySlots or {}
end

function InventoryService:GetEquippedSlots(player)
	local data = getPlayerData(player)
	return data and data.EquippedSlots or {}
end

-- For legacy callers/UI: return compact lists of occupied ids.
function InventoryService:GetInventory(player)
	local slots = InventoryService:GetInventorySlots(player)
	local out = {}
	for i = 1, #slots do
		if slots[i] ~= false and slots[i] ~= nil then
			table.insert(out, slots[i])
		end
	end
	return out
end

function InventoryService:GetEquipped(player)
	local slots = InventoryService:GetEquippedSlots(player)
	local out = {}
	for i = 1, #slots do
		if slots[i] ~= false and slots[i] ~= nil then
			table.insert(out, slots[i])
		end
	end
	return out
end

function InventoryService:GetFullInventory(player)
	local data = getPlayerData(player)
	if not data then
		return {
			InventorySlots = {},
			EquippedSlots = {},
			InventoryCapacity = 50,
		EquipCapacity = 3,
		}
	end

	return {
		InventorySlots = data.InventorySlots,
		EquippedSlots = data.EquippedSlots,
		InventoryCapacity = data.InventoryCapacity,
		EquipCapacity = data.EquipCapacity,
	}
end

local function getSlotsByLocation(data, location)
	if location == "Storage" then
		return data.InventorySlots, data.InventoryCapacity
	elseif location == "Equipped" then
		-- Validation uses unlocked slots count; indexes above are locked.
		return data.EquippedSlots, data.EquipCapacity
	end
	return nil, nil
end

local function isOccupied(id)
	return id ~= nil and id ~= false and id ~= ""
end

-- Core: move/swap between fixed slots.
-- If target is occupied => swap.
-- If target is empty => move (clears source).
function InventoryService:MoveBrainrot(player, sourceLocation, sourceSlotIndex, targetLocation, targetSlotIndex)
	local data = getPlayerData(player)
	if not data then
		return false, "No player data"
	end

	sourceSlotIndex = tonumber(sourceSlotIndex)
	targetSlotIndex = tonumber(targetSlotIndex)
	if not sourceSlotIndex or not targetSlotIndex then
		return false, "Invalid slot index"
	end

	local sourceSlots, sourceCap = getSlotsByLocation(data, sourceLocation)
	local targetSlots, targetCap = getSlotsByLocation(data, targetLocation)
	if not sourceSlots or not targetSlots then
		return false, "Invalid location"
	end

	if sourceSlotIndex < 1 or sourceSlotIndex > sourceCap then
		return false, "Source slot out of range"
	end
	if targetSlotIndex < 1 or targetSlotIndex > targetCap then
		return false, "Target slot out of range"
	end

	local sourceId = sourceSlots[sourceSlotIndex]
	if not isOccupied(sourceId) then
		return false, "Source slot is empty"
	end

	local targetId = targetSlots[targetSlotIndex]
	if isOccupied(targetId) then
		-- Swap
		sourceSlots[sourceSlotIndex] = targetId
		targetSlots[targetSlotIndex] = sourceId
	else
		-- Move
		targetSlots[targetSlotIndex] = sourceId
		sourceSlots[sourceSlotIndex] = false
	end

	return true, "OK"
end

-- Adds to the first empty storage slot.
function InventoryService:AddBrainrot(player, brainrotName)
	local data = getPlayerData(player)
	if not data then
		return false, "No player data!"
	end

	for i = 1, data.InventoryCapacity do
		if not isOccupied(data.InventorySlots[i]) then
			data.InventorySlots[i] = brainrotName
			return true, "Added " .. tostring(brainrotName) .. "!"
		end
	end

	return false, "Inventory full!"
end

function InventoryService:RemoveBrainrot(player, brainrotName)
	local data = getPlayerData(player)
	if not data then
		return false, "No player data!"
	end

	for i = 1, data.InventoryCapacity do
		if data.InventorySlots[i] == brainrotName then
			data.InventorySlots[i] = false
			return true, "Removed " .. tostring(brainrotName) .. "!"
		end
	end
	return false, "Brainrot not found!"
end

-- Click-based equip/unequip wrappers (places into first empty slot).
function InventoryService:EquipBrainrot(player, brainrotName)
	local data = getPlayerData(player)
	if not data then
		return false, "No player data!"
	end

	-- Already equipped?
	for i = 1, data.EquipCapacity do
		if data.EquippedSlots[i] == brainrotName then
			return true, "Already equipped!"
		end
	end

	local sourceIndex = nil
	for i = 1, data.InventoryCapacity do
		if data.InventorySlots[i] == brainrotName then
			sourceIndex = i
			break
		end
	end

	if not sourceIndex then
		return false, "You don't own this brainrot!"
	end

	local targetIndex = nil
	for i = 1, data.EquipCapacity do
		if not isOccupied(data.EquippedSlots[i]) then
			targetIndex = i
			break
		end
	end

	if not targetIndex then
		return false, "No equipped slots available!"
	end

	return InventoryService:MoveBrainrot(player, "Storage", sourceIndex, "Equipped", targetIndex)
end

function InventoryService:UnequipBrainrot(player, brainrotName)
	local data = getPlayerData(player)
	if not data then
		return false, "No player data!"
	end

	local sourceIndex = nil
	for i = 1, data.EquipCapacity do
		if data.EquippedSlots[i] == brainrotName then
			sourceIndex = i
			break
		end
	end

	if not sourceIndex then
		return false, "Not equipped!"
	end

	local targetIndex = nil
	for i = 1, data.InventoryCapacity do
		if not isOccupied(data.InventorySlots[i]) then
			targetIndex = i
			break
		end
	end

	if not targetIndex then
		return false, "Inventory full!"
	end

	return InventoryService:MoveBrainrot(player, "Equipped", sourceIndex, "Storage", targetIndex)
end

return InventoryService