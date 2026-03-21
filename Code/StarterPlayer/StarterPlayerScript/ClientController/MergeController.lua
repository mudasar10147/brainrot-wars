--[[ MergeController.lua
    This is the client controller for the merge system.
    It is responsible for the client side of the merge system.
    It is responsible for the client side of the merge system.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)
local MergeMap = require(ReplicatedStorage.Config.MergeMap)
local Events = ReplicatedStorage:WaitForChild("Events")
local OpenMergeUIEvent = Events:WaitForChild("OpenMergeUI")

local mergeUI = playerGui:WaitForChild("MergeBrainrotsUI")
local container = mergeUI:WaitForChild("Container")
local mergeContainer = container:WaitForChild("MergeContainer")

local selectBrainrot1 = mergeContainer:WaitForChild("SelectBrainrot1")
local selectBrainrot2 = mergeContainer:WaitForChild("SelectBrainrot2")
local newBrainrot = mergeContainer:WaitForChild("NewBrainrot")

local mergeButton = container:WaitForChild("MergeButton")
local mergeText = mergeButton:WaitForChild("StudFrame"):WaitForChild("MergeText")
local closeButton = container:WaitForChild("TopFrame"):WaitForChild("CloseButton")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MergeRequest = Remotes:WaitForChild("MergeRequest")
local MergeComplete = Remotes:WaitForChild("MergeComplete")
local MergeFeedback = ReplicatedStorage:WaitForChild("MergeFeedback")

local inventoryUI = playerGui:WaitForChild("InventoryUI")

print("[MergeController] Loaded (Drag & Drop Version)")

------------------------------------------------
-- STATE
------------------------------------------------
local selectedBrainrot1 = nil
local selectedBrainrot2 = nil
local mergeDebounce = false

------------------------------------------------
-- UI HELPERS
------------------------------------------------
local function showFeedback(msg)
	print("🎉 " .. msg)
	mergeText.Text = msg
	task.delay(2, function()
		if mergeText then
			mergeText.Text = "MERGE"
		end
	end)
end

local function clearSlot(slot)
	local questionMark = slot:FindFirstChild("QuestionMark")
	local checkered = slot:FindFirstChild("CheckeredBackground")

	if questionMark then
		questionMark.Visible = true
	end
	if checkered then
		checkered.Image = ""
		checkered.Visible = false
	end
end

local function setSlotImage(slot, brainrotId)
	local brainrotData = Brainrots[brainrotId]
	if not brainrotData then return end

	local questionMark = slot:FindFirstChild("QuestionMark")
	local checkered = slot:FindFirstChild("CheckeredBackground")

	if questionMark then
		questionMark.Visible = false
	end
	if checkered then
		checkered.Image = brainrotData.Icon
		checkered.Visible = true
	end
end

local function clearAll()
	selectedBrainrot1 = nil
	selectedBrainrot2 = nil

	clearSlot(selectBrainrot1)
	clearSlot(selectBrainrot2)
	clearSlot(newBrainrot)
end

------------------------------------------------
-- CORE: OPEN MERGE UI FROM DRAG
------------------------------------------------
OpenMergeUIEvent.Event:Connect(function(sourceId, targetId)
	print("[MergeUI] Opened with:", sourceId, targetId)

	inventoryUI.Enabled = false
	mergeUI.Enabled = true

	selectedBrainrot1 = sourceId
	selectedBrainrot2 = targetId

	setSlotImage(selectBrainrot1, sourceId)
	setSlotImage(selectBrainrot2, targetId)

	local found = false

	for _, mapping in ipairs(MergeMap) do
		if (mapping.A == sourceId and mapping.B == targetId) or
			(mapping.A == targetId and mapping.B == sourceId) then
			setSlotImage(newBrainrot, mapping.Result)
			found = true
			break
		end
	end

	if not found then
		clearSlot(newBrainrot)
		showFeedback(" Invalid merge")
	end
end)

------------------------------------------------
-- MERGE BUTTON
------------------------------------------------
mergeButton.MouseButton1Click:Connect(function()
	if mergeDebounce then return end

	if not selectedBrainrot1 or not selectedBrainrot2 then
		showFeedback("❌ Select 2 brainrots first!")
		return
	end

	mergeDebounce = true
	mergeText.Text = "Merging..."

	MergeRequest:FireServer(selectedBrainrot1, selectedBrainrot2)
end)

------------------------------------------------
-- CLOSE BUTTON
------------------------------------------------
closeButton.MouseButton1Click:Connect(function()
	mergeUI.Enabled = false
	inventoryUI.Enabled = true
	clearAll()
end)

------------------------------------------------
-- SERVER RESPONSE
------------------------------------------------
MergeComplete.OnClientEvent:Connect(function(success, result, data)
	mergeText.Text = "MERGE"

	if success then
		showFeedback("✅ Got: " .. tostring(result))

		setSlotImage(newBrainrot, result)

		if _G.RefreshHotbar then
			_G.RefreshHotbar()
		end

		if _G.PopulateInventory then
			_G.PopulateInventory()
		end

		task.delay(2, function()
			mergeUI.Enabled = false
			inventoryUI.Enabled = true
			clearAll()
		end)
	else
		showFeedback("❌ " .. tostring(data))
	end

	mergeDebounce = false
end)

------------------------------------------------
-- OPTIONAL FEEDBACK EVENT
------------------------------------------------
MergeFeedback.OnClientEvent:Connect(showFeedback)

------------------------------------------------
-- INITIAL CLEAR
------------------------------------------------
clearAll()