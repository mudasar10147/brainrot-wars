local PlayerDataManager = {}

print("[PlayerDataManager] Module loaded")

local PlayerDataManager = {}

print("[PlayerDataManager] Module loaded")

PlayerDataManager.Template = {
	Inventory = {},
	-- Legacy (pre-slot system) list. Will be migrated to InventorySlots.
	InventoryCapacity = 50,
	-- Number of equipped slots unlocked (starting at 3, max 7).
	EquipCapacity = 3,
	TeamsCapacity = 3,
	Equipped = {},
	-- Legacy (pre-slot system) list. Will be migrated to EquippedSlots.
	InventorySlots = {},
	EquippedSlots = {},
	Gold = 0,
	Diamonds = 0,
	HasChosenStarter = false,
	Teams = {}
}

local sessionData = {}

function PlayerDataManager:Get(player)
	return sessionData[player]
end

function PlayerDataManager:Set(player, data)
	sessionData[player] = data
	print("[PlayerDataManager] Data set for " .. player.Name)
end

function PlayerDataManager:Remove(player)
	sessionData[player] = nil
	print("[PlayerDataManager] Data removed for " .. player.Name)
end

function PlayerDataManager:AddGold(player, amount)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data found for " .. player.Name)
		return false
	end

	data.Gold = data.Gold + amount
	print("[PlayerDataManager] Added " .. amount .. " gold to " .. player.Name .. ". Total: " .. data.Gold)
	return true
end

function PlayerDataManager:AddDiamonds(player, amount)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data found for " .. player.Name)
		return false
	end

	data.Diamonds = data.Diamonds + amount
	print("[PlayerDataManager] Added " .. amount .. " diamonds to " .. player.Name .. ". Total: " .. data.Diamonds)
	return true
end

function PlayerDataManager:RemoveGold(player, amount)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data found for " .. player.Name)
		return false
	end

	if data.Gold < amount then
		warn("[PlayerDataManager] Not enough gold for " .. player.Name)
		return false
	end

	data.Gold = data.Gold - amount
	print("[PlayerDataManager] Removed " .. amount .. " gold from " .. player.Name .. ". Total: " .. data.Gold)
	return true
end

function PlayerDataManager:RemoveDiamonds(player, amount)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data found for " .. player.Name)
		return false
	end

	if data.Diamonds < amount then
		warn("[PlayerDataManager] Not enough diamonds for " .. player.Name)
		return false
	end

	data.Diamonds = data.Diamonds - amount
	print("[PlayerDataManager] Removed " .. amount .. " diamonds from " .. player.Name .. ". Total: " .. data.Diamonds)
	return true
end

function PlayerDataManager:GetInventoryCapacity(player)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data for " .. player.Name)
		return nil
	end

	return data.InventoryCapacity
end

function PlayerDataManager:SetInventoryCapacity(player, value)
	local data = sessionData[player]
	if not data then return false end

	data.InventoryCapacity = value
	print(player.Name .. " InventoryCapacity set to " .. value)
	return true
end

function PlayerDataManager:IncreaseInventoryCapacity(player, amount)
	local data = sessionData[player]
	if not data then return false end

	data.InventoryCapacity += amount
	print(player.Name .. " InventoryCapacity increased to " .. data.InventoryCapacity)
	return true
end

function PlayerDataManager:GetEquipCapacity(player)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data for " .. player.Name)
		return nil
	end

	return data.EquipCapacity
end

function PlayerDataManager:SetEquipCapacity(player, value)
	local data = sessionData[player]
	if not data then return false end

	data.EquipCapacity = value
	print(player.Name .. " EquipCapacity set to " .. value)
	return true
end

function PlayerDataManager:IncreaseEquipCapacity(player, amount)
	local data = sessionData[player]
	if not data then return false end

	data.EquipCapacity += amount
	print(player.Name .. " EquipCapacity increased to " .. data.EquipCapacity)
	return true
end

function PlayerDataManager:GetTeamCapacity(player)
	local data = sessionData[player]
	if not data then
		warn("[PlayerDataManager] No data for " .. player.Name)
		return nil
	end

	return data.TeamsCapacity
end

function PlayerDataManager:SetTeamCapacity(player, value)
	local data = sessionData[player]
	if not data then return false end

	data.TeamsCapacity = value
	print(player.Name .. " TeamCapacity set to " .. value)
	return true
end

function PlayerDataManager:IncreaseTeamCapacity(player, amount)
	local data = sessionData[player]
	if not data then return false end

	data.TeamsCapacity += amount
	print(player.Name .. " TeamCapacity increased to " .. data.TeamsCapacity)
	return true
end

-- Normalizes old/new save formats so inventory doesn't "auto relocate".
-- After this, all inventory/equipped items live only in InventorySlots/EquippedSlots.
function PlayerDataManager:NormalizeData(data)
	if type(data) ~= "table" then
		return self.Template
	end

	local invCap = data.InventoryCapacity or self.Template.InventoryCapacity or 50

	-- Total equipped slots on the hotbar (3 unlocked by default + locked slots).
	local TOTAL_EQUIPPED_SLOTS = 7

	-- EquipCapacity is the number of *unlocked* equipped slots.
	local unlockedEquipCap = data.EquipCapacity or self.Template.EquipCapacity or 3
	if unlockedEquipCap < 0 then unlockedEquipCap = 0 end
	if unlockedEquipCap > TOTAL_EQUIPPED_SLOTS then unlockedEquipCap = TOTAL_EQUIPPED_SLOTS end

	data.InventoryCapacity = invCap
	data.EquipCapacity = unlockedEquipCap

	local function makeFalseSlots(capacity)
		local t = {}
		for i = 1, capacity do
			t[i] = false
		end
		return t
	end

	local hasAnySlotData =
		(type(data.InventorySlots) == "table" and next(data.InventorySlots) ~= nil)
		or (type(data.EquippedSlots) == "table" and next(data.EquippedSlots) ~= nil)

	-- Slot-based data already exists; just enforce correct lengths.
	if hasAnySlotData then
		local invSlots = makeFalseSlots(invCap)
		local eqSlots = makeFalseSlots(TOTAL_EQUIPPED_SLOTS)

		if type(data.InventorySlots) == "table" then
			for i = 1, invCap do
				local v = data.InventorySlots[i]
				if v ~= nil and v ~= false then
					invSlots[i] = v
				end
			end
		end

		if type(data.EquippedSlots) == "table" then
			for i = 1, TOTAL_EQUIPPED_SLOTS do
				local v = data.EquippedSlots[i]
				if i <= unlockedEquipCap then
					if v ~= nil and v ~= false then
						eqSlots[i] = v
					end
				end
			end
		end

		data.InventorySlots = invSlots
		data.EquippedSlots = eqSlots
		return data
	end

	-- Migration from legacy lists:
	-- Inventory may include equipped items; we must exclude equipped ones from storage.
	local invList = type(data.Inventory) == "table" and data.Inventory or {}
	local eqList = type(data.Equipped) == "table" and data.Equipped or {}

	local eqSet = {}
	for _, id in ipairs(eqList) do
		if id ~= nil then
			eqSet[id] = true
		end
	end

	local invSlots = makeFalseSlots(invCap)
	local invIdx = 1
	for _, id in ipairs(invList) do
		if id ~= nil and not eqSet[id] then
			if invIdx > invCap then
				break
			end
			invSlots[invIdx] = id
			invIdx += 1
		end
	end

	local eqSlots = makeFalseSlots(TOTAL_EQUIPPED_SLOTS)
	local eqIdx = 1
	for _, id in ipairs(eqList) do
		if id ~= nil then
			if eqIdx > unlockedEquipCap then
				break
			end
			eqSlots[eqIdx] = id
			eqIdx += 1
		end
	end

	data.InventorySlots = invSlots
	data.EquippedSlots = eqSlots
	return data
end

return PlayerDataManager