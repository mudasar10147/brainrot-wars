local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
local PlayerDataManager = require(game.ServerScriptService.Data.PlayerDataManager)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remote setup
local GetInventory = Instance.new("RemoteFunction")
GetInventory.Name = "GetInventory"
GetInventory.Parent = Remotes

-- Slot-based move/swap used by drag & drop.
local MoveBrainrot = Instance.new("RemoteFunction")
MoveBrainrot.Name = "MoveBrainrot"
MoveBrainrot.Parent = Remotes

local EquipBrainrot = Instance.new("RemoteEvent")
EquipBrainrot.Name = "EquipBrainrot"
EquipBrainrot.Parent = Remotes

local UnequipBrainrot = Instance.new("RemoteEvent")
UnequipBrainrot.Name = "UnequipBrainrot"
UnequipBrainrot.Parent = Remotes

-- Unlock one additional equipped slot (up to 7 total).
local PurchaseSlot = Instance.new("RemoteEvent")
PurchaseSlot.Name = "PurchaseSlot"
PurchaseSlot.Parent = Remotes

local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)

-- Reverse lookup: tool model name -> brainrot id
local modelToBrainrotId = {}
for brainrotId, brainrotData in pairs(Brainrots) do
	local modelName = brainrotData and brainrotData.Model or brainrotId
	modelToBrainrotId[modelName] = brainrotId
end

-- === Helper Functions ===
local function giveToolToPlayer(player, brainrotId)
	local character = player.Character
	if not character then
		warn("[InventoryHandler] No character for " .. player.Name)
		return false
	end

	local brainrotData = Brainrots[brainrotId]
	local modelName = brainrotData and brainrotData.Model or brainrotId
	local tool = ReplicatedStorage.Items:FindFirstChild(modelName)
	if not tool then
		warn("[InventoryHandler] Tool not found for: " .. modelName)
		return false
	end

	-- Prevent duplicates
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if (backpack and backpack:FindFirstChild(modelName)) or (character:FindFirstChild(modelName)) then
		return true
	end

	local toolClone = tool:Clone()
	toolClone:SetAttribute("IsBrainrot", true)
	toolClone.Parent = backpack
	print("[InventoryHandler] Gave tool " .. brainrotId .. " to " .. player.Name)
	return true
end

local function removeToolFromPlayer(player, brainrotId)
	local brainrotData = Brainrots[brainrotId]
	local modelName = brainrotData and brainrotData.Model or brainrotId

	local character = player.Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == modelName then
				tool:Destroy()
			end
		end
	end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == modelName then
				tool:Destroy()
			end
		end
	end

	print("[InventoryHandler] Removed tool " .. modelName .. " from " .. player.Name)
end

local function syncEquippedTools(player)
	local equippedSlots = InventoryService:GetEquippedSlots(player) or {}

	-- Build equipped set for quick checks.
	local equippedSet = {}
	for i = 1, #equippedSlots do
		local id = equippedSlots[i]
		if id ~= false and id ~= nil and id ~= "" then
			equippedSet[id] = true
		end
	end

	-- Build allowed tool name set (prevents reverse-lookup mismatch bugs).
	local allowedToolNames = {}
	for brainrotId in pairs(equippedSet) do
		local brainrotData = Brainrots[brainrotId]
		local modelName = brainrotData and brainrotData.Model or brainrotId
		allowedToolNames[modelName] = true
	end

	local function removeUnequippedTools(container)
		if not container then return end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("IsBrainrot") then
				if not allowedToolNames[tool.Name] then
					tool:Destroy()
				end
			end
		end
	end

	removeUnequippedTools(player.Character)
	removeUnequippedTools(player:FindFirstChild("Backpack"))

	-- Ensure all equipped items have tools.
	for brainrotId, _ in pairs(equippedSet) do
		giveToolToPlayer(player, brainrotId)
	end
end

-- === Purchase/unlock equip slot ===
PurchaseSlot.OnServerEvent:Connect(function(player)
	local data = PlayerDataManager:Get(player)
	if not data then return end

	local TOTAL_EQUIPPED_SLOTS = 7
	local current = InventoryService:GetEquipCapacity(player) or data.EquipCapacity or 3
	if current >= TOTAL_EQUIPPED_SLOTS then
		return
	end

	PlayerDataManager:SetEquipCapacity(player, math.min(TOTAL_EQUIPPED_SLOTS, current + 1))
	syncEquippedTools(player)
end)

-- === Auto Equip on Join ===
local function autoEquipOnJoin(player)
	local data
	local attempts = 0
	repeat
		task.wait(0.5)
		attempts += 1
		data = PlayerDataManager:Get(player)
	until data or attempts >= 40

	if not data or not data.EquippedSlots or #data.EquippedSlots == 0 then
		print("[InventoryHandler] No equipped items to restore for " .. player.Name)
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(1)

	print("[InventoryHandler] Restoring equipped tools for " .. player.Name)
	for _, brainrotId in ipairs(data.EquippedSlots) do
		if brainrotId ~= false and brainrotId ~= nil and brainrotId ~= "" then
			print("[InventoryHandler] Auto-equipping: " .. tostring(brainrotId))
			giveToolToPlayer(player, brainrotId)
		end
	end
end

-- === Player Added ===
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		autoEquipOnJoin(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		autoEquipOnJoin(player)
	end)
end

-- === Inventory Remote Functions ===
GetInventory.OnServerInvoke = function(player)
	return {
		InventorySlots = InventoryService:GetInventorySlots(player) or {},
		EquippedSlots = InventoryService:GetEquippedSlots(player) or {},
		InventoryCapacity = InventoryService:GetStorageCapacity(player) or 50,
		EquipCapacity = InventoryService:GetEquipCapacity(player) or 3
	}
end

-- === MoveBrainrot (slot based) ===
MoveBrainrot.OnServerInvoke = function(player, sourceLocation, sourceSlotIndex, targetLocation, targetSlotIndex)
	local success, msg = InventoryService:MoveBrainrot(player, sourceLocation, sourceSlotIndex, targetLocation, targetSlotIndex)
	if success then
		syncEquippedTools(player)
	end
	return success, msg
end

-- === Equip Brainrot ===
EquipBrainrot.OnServerEvent:Connect(function(player, brainrotId)
	local success = InventoryService:EquipBrainrot(player, brainrotId)
	if success then
		syncEquippedTools(player)
	end
end)

-- === Unequip Brainrot ===
UnequipBrainrot.OnServerEvent:Connect(function(player, brainrotId)
	InventoryService:UnequipBrainrot(player, brainrotId)
	syncEquippedTools(player)
end)