-- =================================
-- Made by 🎓Cecle Dev and MajorVox
-- =================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)
local MergeMap = require(ReplicatedStorage.Config.MergeMap)
local BrainrotStats = require(ReplicatedStorage.Config.BrainrotStats)

local Events = ReplicatedStorage:WaitForChild("Events")
local OpenMergeUIEvent = Events:WaitForChild("OpenMergeUI")

local inventoryUI = playerGui:WaitForChild("InventoryUI")
local container = inventoryUI:WaitForChild("Container")
local inventoryContainer = container:WaitForChild("InventoryContainer")
local inventoryList = inventoryContainer:WaitForChild("InventoryList")
local equippedBrainrots = inventoryContainer:WaitForChild("EquippedBrainrots")
local closeButton = container:WaitForChild("TopFrame"):WaitForChild("CloseButton")

local confirmationUI = playerGui:WaitForChild("Confirmation")
local confirmationContainer = confirmationUI:WaitForChild("Container")
local purchaseContainer = confirmationContainer:WaitForChild("PurchaseContainer")
local buttonsContainer = purchaseContainer:WaitForChild("ButtonsContainer")
local buyButton = buttonsContainer:WaitForChild("BuyButton")
local cancelButton = buttonsContainer:WaitForChild("CancelButton")

confirmationUI.Enabled = false

-- ===============================
-- Track manually unlocked slots
-- ===============================
local manuallyUnlockedSlots = {}

local searchInput = inventoryContainer:WaitForChild("SearchFrame"):WaitForChild("StudFrame"):WaitForChild("SearchInput")
local currentSearchQuery = ""

local buttonTemplate = inventoryList:FindFirstChild("BrainrotButtonContainer"):Clone()
local equippedTemplate = equippedBrainrots:FindFirstChildWhichIsA("ImageButton"):Clone()
local lockedTemplate = equippedBrainrots:FindFirstChild("LockedButton"):Clone()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventory = Remotes:WaitForChild("GetInventory")
local MoveBrainrot = Remotes:WaitForChild("MoveBrainrot")
local EquipBrainrot = Remotes:WaitForChild("EquipBrainrot")
local UnequipBrainrot = Remotes:WaitForChild("UnequipBrainrot")
local PurchaseSlot = Remotes:WaitForChild("PurchaseSlot")

print("[InventoryController] Loaded")

player.CharacterAdded:Connect(function(newChar)
	character = newChar
end)

local debounce = false

------------------------------------------------
-- SEARCH FUNCTIONALITY
------------------------------------------------
local function filterInventory(query)
	query = query:lower()
	currentSearchQuery = query

	for _, containerFrame in ipairs(inventoryList:GetChildren()) do
		if containerFrame.Name == "BrainrotButtonContainer" then
			local button = containerFrame:FindFirstChild("BrainrotButton")
			if button then
				local nameLabel = button:FindFirstChild("BrainrotName")
				local mutationLabel = button:FindFirstChild("MutationName")
				local matches = false
				if nameLabel and string.find(nameLabel.Text:lower(), query) then
					matches = true
				elseif mutationLabel and string.find(mutationLabel.Text:lower(), query) then
					matches = true
				end
				containerFrame.Visible = matches or query == ""
			end
		end
	end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	filterInventory(searchInput.Text)
end)

------------------------------------------------
-- SERVER REFRESH
------------------------------------------------
local function refreshInventory()
	local data = GetInventory:InvokeServer()
	if data then
		return data.InventorySlots or {}, data.EquippedSlots or {}, data.InventoryCapacity or 50, data.EquipCapacity or 3
	end
	return {}, {}, 50, 3
end

------------------------------------------------
-- CLEAR FUNCTIONS
------------------------------------------------
local function clearInventoryList()
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child.Name == "BrainrotButtonContainer" then
			child:Destroy()
		end
	end
end

local function clearEquipped()
	for _, child in ipairs(equippedBrainrots:GetChildren()) do
		if child.Name == "BrainrotButton" or child.Name == "LockedButton" then
			child:Destroy()
		end
	end
end

------------------------------------------------
-- DEBUG DRAG + DROP + MERGE SYSTEM
------------------------------------------------

local currentDragState = {
	dragging = false,
	button = nil,
	dragClone = nil,
	originalPosition = nil,
	dragStartPos = nil,
	offsetFromMouse = Vector2.new(0, 0),
	hasMoved = false,
	justDragged = false,
	dragParentAbs = nil,
	hoveredSlot = nil
}

------------------------------------------------
-- DRAG START
------------------------------------------------
local function startDrag(button, input)
	print("[DRAG START] Triggered")
	if not input or not input.Position then
		warn("[DRAG START] Missing input.Position")
		return
	end

	currentDragState.dragging = true
	currentDragState.button = button
	currentDragState.originalPosition = button.Position
	currentDragState.dragStartPos = Vector2.new(input.Position.X, input.Position.Y)

	print("StartPos:", currentDragState.dragStartPos)

	local clone = button:Clone()
	clone.Name = "DragClone"
	clone.AnchorPoint = Vector2.new(0, 0)
	clone.ZIndex = 1000
	clone.BackgroundTransparency = 0.5
	clone.Size = UDim2.fromOffset(button.AbsoluteSize.X, button.AbsoluteSize.Y)
	clone.Position = UDim2.fromOffset(
		button.AbsolutePosition.X - inventoryUI.AbsolutePosition.X,
		button.AbsolutePosition.Y - inventoryUI.AbsolutePosition.Y
	)
	-- Parent the drag clone to PlayerGui so UI layout in your inventory frames doesn't reflow.
	currentDragState.dragParentAbs = inventoryUI.AbsolutePosition
	clone.Parent = inventoryUI

	print("Clone created at:", clone.Position)

	-- Avoid UI reflow: don't set Visible=false if using GridLayout.
	-- Instead, make original button transparent and non-interactive.
	currentDragState.originalButtonActive = button.Active
	currentDragState.originalBackgroundTransparency = button.BackgroundTransparency
	if button:IsA("ImageButton") then
		currentDragState.originalImageTransparency = button.ImageTransparency
	else
		currentDragState.originalImageTransparency = nil
	end
	button.Active = false
	button.BackgroundTransparency = 1
	if button:IsA("ImageButton") then
		button.ImageTransparency = 1
	end

	currentDragState.dragClone = clone
	local mousePos = Vector2.new(input.Position.X, input.Position.Y)
	currentDragState.offsetFromMouse = button.AbsolutePosition - mousePos

	print("Offset:", currentDragState.offsetFromMouse)
end

local function getAllSlots()
	local slots = {}

	for _, v in ipairs(equippedBrainrots:GetChildren()) do
		if v:IsA("ImageButton") then
			table.insert(slots, v)
		end
	end

	for _, v in ipairs(inventoryList:GetDescendants()) do
		if v:IsA("ImageButton") and v.Name == "BrainrotButton" then
			table.insert(slots, v)
		end
	end

	return slots
end

------------------------------------------------
-- DRAG MOVE
------------------------------------------------
UserInputService.InputChanged:Connect(function(input)
	if not currentDragState.dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	if not input.Position then return end

	-- Guard against nil drag state (prevents Vector2 math crashes).
	if not currentDragState.dragStartPos
		or not currentDragState.offsetFromMouse
		or not currentDragState.dragParentAbs
		or not currentDragState.dragClone
	then
		return
	end

	local mousePos = Vector2.new(input.Position.X, input.Position.Y)

	-- Detect movement
	local distance = (mousePos - currentDragState.dragStartPos).Magnitude
	if distance > 5 then
		currentDragState.hasMoved = true
		currentDragState.justDragged = true
	end

	-- print("[DRAG MOVE] Mouse:", mousePos, "Distance:", distance, "Moved:", currentDragState.hasMoved)

	-- Move clone
	local newPos = mousePos + currentDragState.offsetFromMouse - currentDragState.dragParentAbs
	currentDragState.dragClone.Position = UDim2.fromOffset(newPos.X, newPos.Y)

	-- Detect hovered slot
	local hovered = nil
	for _, slot in ipairs(getAllSlots()) do
		if slot:IsA("GuiObject") then
			local pos = slot.AbsolutePosition
			local size = slot.AbsoluteSize

			if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and
				mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
				hovered = slot
				print("[HOVER] Hovering over slot:", slot.Name)
				break
			end
		end
	end

	if not hovered then
		print("[HOVER] No slot detected")
	end

	currentDragState.hoveredSlot = hovered
end)

------------------------------------------------
-- DROP LOGIC
------------------------------------------------
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not currentDragState.dragging then return end

	print("[DROP] Mouse released")

	local button = currentDragState.button
	local hoveredSlot = currentDragState.hoveredSlot

	-- Ensure we always get the actual button
	if hoveredSlot and hoveredSlot.Name ~= "BrainrotButton" then
		local buttonChild = hoveredSlot:FindFirstChild("BrainrotButton")
		if buttonChild then
			hoveredSlot = buttonChild
		end
	end

	print("HoveredSlot:", hoveredSlot)
	print("HasMoved:", currentDragState.hasMoved)

	-- MOVE / MERGE LOGIC
	if hoveredSlot and currentDragState.hasMoved then
		local sourceId = button:GetAttribute("BrainrotId")
		local sourceLocation = button:GetAttribute("SlotType") -- "Storage" or "Equipped"
		local sourceIndex = button:GetAttribute("SlotIndex")

		local targetId = hoveredSlot:GetAttribute("BrainrotId")
		local targetLocation = hoveredSlot:GetAttribute("SlotType")
		local targetIndex = hoveredSlot:GetAttribute("SlotIndex")

		print("Source:", sourceLocation, sourceIndex, "Id:", sourceId)
		print("Target:", targetLocation, targetIndex, "Id:", targetId)

		local function isOccupied(id)
			return id ~= nil and id ~= false and id ~= ""
		end

		if not sourceLocation or not sourceIndex or not targetLocation or not targetIndex then
			warn("[DROP FAILED] Missing slot info")
		elseif targetLocation == "Locked" then
			print("[DROP] Locked slot - ignoring")
		elseif sourceLocation == "Storage" and targetLocation == "Storage" then
			-- Storage->Storage:
			-- - occupied target => merge UI
			-- - empty target => move/swap via server
			if isOccupied(targetId) then
				-- Prevent merging when dropping onto the same slot/brainrot.
				local sIdx = tonumber(sourceIndex)
				local tIdx = tonumber(targetIndex)
				if (sIdx and tIdx and sIdx == tIdx) or (sourceId ~= nil and sourceId == targetId) then
					print("[DROP] Storage->Storage same slot/no-op")
				else
					local isValidMerge = false
					for _, mapping in ipairs(MergeMap) do
						if (mapping.A == sourceId and mapping.B == targetId) or (mapping.A == targetId and mapping.B == sourceId) then
							isValidMerge = true
							break
						end
					end

					if isValidMerge then
						OpenMergeUIEvent:Fire(sourceId, targetId)
					else
						print("[DROP] Invalid merge")
					end
				end
			else
				local success, msg, updatedData = MoveBrainrot:InvokeServer(sourceLocation, sourceIndex, targetLocation, targetIndex)
				if not success then
					warn("[DROP] Move failed:", msg)
				else
					local inv = updatedData and updatedData.InventorySlots or {}
					local eq = updatedData and updatedData.EquippedSlots or {}
					local invCap = updatedData and updatedData.InventoryCapacity or 50
					local eqCap = updatedData and updatedData.EquipCapacity or 3
					populateInventory(inv, eq, invCap, eqCap)
					if _G.RefreshHotbar then _G.RefreshHotbar() end
				end
			end
		else
			-- All other combinations are slot moves/swaps via the server.
			if not isOccupied(targetId) then
				local success, msg, updatedData = MoveBrainrot:InvokeServer(sourceLocation, sourceIndex, targetLocation, targetIndex)
				if success then
					local inv = updatedData and updatedData.InventorySlots or {}
					local eq = updatedData and updatedData.EquippedSlots or {}
					local invCap = updatedData and updatedData.InventoryCapacity or 50
					local eqCap = updatedData and updatedData.EquipCapacity or 3
					populateInventory(inv, eq, invCap, eqCap)
					if _G.RefreshHotbar then _G.RefreshHotbar() end
				end
			end
		end
	else
		warn("[DROP FAILED] No hoveredSlot or not moved")
	end

	-- CLEANUP
	local originalButton = currentDragState.button
	local originalActive = currentDragState.originalButtonActive
	local originalBackgroundTransparency = currentDragState.originalBackgroundTransparency
	local originalImageTransparency = currentDragState.originalImageTransparency

	if currentDragState.dragClone then
		currentDragState.dragClone:Destroy()
	end

	print("[CLEANUP DONE]")

	currentDragState.dragging = false
	currentDragState.button = nil
	currentDragState.dragClone = nil
	currentDragState.originalPosition = nil
	currentDragState.dragStartPos = nil
	currentDragState.offsetFromMouse = Vector2.new(0, 0)
	currentDragState.hasMoved = false
	currentDragState.hoveredSlot = nil
	-- Keep justDragged true briefly so click handlers don't run on the same release.
	task.delay(0.05, function()
		if not currentDragState.dragging then
			currentDragState.justDragged = false
		end
	end)

	-- Restore original slot visuals (do this even if UI re-rendered).
	if originalButton and originalButton.Parent then
		if originalActive ~= nil then originalButton.Active = originalActive end
		if originalBackgroundTransparency ~= nil then originalButton.BackgroundTransparency = originalBackgroundTransparency end
		if originalImageTransparency ~= nil and originalButton:IsA("ImageButton") then
			originalButton.ImageTransparency = originalImageTransparency
		end
	end
end)

------------------------------------------------
-- ENABLE DRAG FOR BUTTON
------------------------------------------------
local function enableButtonDrag(button)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			print("[INPUT] Mouse down on:", button.Name)
			startDrag(button, input)
		end
	end)
end



------------------------------------------------
-- Resolve catalog row for UI (handles legacy slots saved as Model/Name string).
------------------------------------------------
local function getBrainrotDisplayContext(storedId)
	if not storedId or storedId == "" then
		return nil, nil
	end
	local data = Brainrots[storedId]
	if data then
		return data, storedId
	end
	if Brainrots.ResolveInventoryId then
		local resolved = Brainrots.ResolveInventoryId(storedId)
		if resolved and Brainrots[resolved] then
			return Brainrots[resolved], resolved
		end
	end
	return nil, nil
end

------------------------------------------------
-- POPULATE INVENTORY
------------------------------------------------
function populateInventory(inventorySlots, equippedSlots, storageCapacity, equipCapacity)
	storageCapacity = storageCapacity or 50
	equipCapacity = equipCapacity or 3

	clearInventoryList()
	clearEquipped()

	local sortByText = inventoryContainer:WaitForChild("SortByText")
	local occupiedInventoryCount = 0
	for i = 1, storageCapacity do
		local id = inventorySlots[i]
		if id ~= false and id ~= nil and id ~= "" then
			occupiedInventoryCount += 1
		end
	end
	sortByText.Text = occupiedInventoryCount .. "/" .. storageCapacity .. " Storage"

	-- Storage slots
	for i = 1, storageCapacity do
		local brainrotId = inventorySlots[i]

		local newContainer = buttonTemplate:Clone()
		newContainer.Parent = inventoryList

		local button = newContainer:FindFirstChild("BrainrotButton")
		if not button then continue end

		button:SetAttribute("SlotType", "Storage")
		button:SetAttribute("SlotIndex", i)

		local nameLabel = button:FindFirstChild("BrainrotName")
		local mutationLabel = button:FindFirstChild("MutationName")
		local image = button:FindFirstChild("BrainrotImage")

		if brainrotId ~= false and brainrotId ~= nil and brainrotId ~= "" then
			button:SetAttribute("BrainrotId", brainrotId)
			local brainrotData, statsId = getBrainrotDisplayContext(brainrotId)
			if brainrotData then
				if nameLabel then nameLabel.Text = brainrotData.Name end
				if mutationLabel then
					local stats = BrainrotStats.GetStats(statsId)
					if stats and stats.Tier then
						mutationLabel.Text = stats.Tier
					else
						mutationLabel.Text = brainrotData.Rarity or "Unknown"
					end
				end
				if image then image.Image = brainrotData.Icon end
			end
			button.AutoButtonColor = true

			enableButtonDrag(button)
		else
			button.AutoButtonColor = false
			button:SetAttribute("BrainrotId", "")
			if nameLabel then nameLabel.Text = "" end
			if mutationLabel then mutationLabel.Text = "" end
			if image then image.Image = "" end
		end
	end

	-- Equipped slots (7 total; first `equipCapacity` are unlocked, rest show as locked)
	local TOTAL_EQUIPPED_SLOTS = 7
	for i = 1, TOTAL_EQUIPPED_SLOTS do
		if i <= equipCapacity then
			local equippedId = equippedSlots[i]

			local newEquipped = equippedTemplate:Clone()
			newEquipped.Name = "BrainrotButton"
			newEquipped.Parent = equippedBrainrots

			newEquipped:SetAttribute("SlotType", "Equipped")
			newEquipped:SetAttribute("SlotIndex", i)

			local nameLabel = newEquipped:FindFirstChild("BrainrotName")
			local mutationLabel = newEquipped:FindFirstChild("MutationName")
			local image = newEquipped:FindFirstChild("BrainrotImage")

			if equippedId ~= false and equippedId ~= nil and equippedId ~= "" then
				newEquipped:SetAttribute("BrainrotId", equippedId)

				local brainrotData, statsId = getBrainrotDisplayContext(equippedId)
				if brainrotData then
					if nameLabel then nameLabel.Text = brainrotData.Name end
					if mutationLabel then
						local stats = BrainrotStats.GetStats(statsId)
						if stats and stats.Tier then
							mutationLabel.Text = stats.Tier
						else
							mutationLabel.Text = brainrotData.Rarity or "Unknown"
						end
					end
					if image then image.Image = brainrotData.Icon end
				end

				enableButtonDrag(newEquipped)
			else
				newEquipped:SetAttribute("BrainrotId", "")
				if nameLabel then nameLabel.Text = "" end
				if mutationLabel then mutationLabel.Text = "" end
				if image then image.Image = "" end
			end
		else
			local lockedSlot = lockedTemplate:Clone()
			lockedSlot.Name = "LockedButton"
			lockedSlot.Parent = equippedBrainrots

			lockedSlot:SetAttribute("SlotType", "Locked")
			lockedSlot:SetAttribute("SlotIndex", i)
			lockedSlot:SetAttribute("BrainrotId", "")
			local mutationLabel = lockedSlot:FindFirstChild("MutationName")
			if mutationLabel then mutationLabel.Text = "" end

			lockedSlot.MouseButton1Click:Connect(function()
				selectedLockedButton = lockedSlot
				inventoryUI.Enabled = false
				confirmationUI.Enabled = true
			end)
		end
	end
end

-- ===============================
-- CancelButton click handler
-- ===============================
cancelButton.MouseButton1Click:Connect(function()
	confirmationUI.Enabled = false
	inventoryUI.Enabled = true
	selectedLockedButton = nil
	_G.RequestSlotPurchase = false
end)

-- ===============================
-- BuyButton click handler
-- ===============================
buyButton.MouseButton1Click:Connect(function()
	if not selectedLockedButton and not _G.RequestSlotPurchase then return end

	confirmationUI.Enabled = false
	inventoryUI.Enabled = true

	local ok = PurchaseSlot:InvokeServer()
	if not ok then
		warn("[InventoryController] PurchaseSlot failed or already at max")
	end

	selectedLockedButton = nil
	_G.RequestSlotPurchase = false
	if _G.PopulateInventory then _G.PopulateInventory() end
end)

------------------------------------------------
-- GLOBAL REFRESH
------------------------------------------------
_G.PopulateInventory = function()
	local inv, eq, invCap, eqCap = refreshInventory()
	populateInventory(inv, eq, invCap, eqCap)
	if _G.RefreshAllTeams then _G.RefreshAllTeams(eqCap) end
end

------------------------------------------------
-- CLOSE BUTTON
------------------------------------------------
closeButton.MouseButton1Click:Connect(function()
	inventoryUI.Enabled = false
end)

-- Initial load
task.wait(1)
_G.PopulateInventory()