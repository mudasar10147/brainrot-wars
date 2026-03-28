local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

local Brainrots = require(
	ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("Brainrots")
		:WaitForChild("Brainrots")
)

local hud = playerGui:WaitForChild("HUD")
local equippedContainer = hud:WaitForChild("Container"):WaitForChild("EquippedBrainrots")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventory = Remotes:WaitForChild("GetInventory")
local UnequipBrainrot = Remotes:WaitForChild("UnequipBrainrot")
local EquipBrainrot = Remotes:WaitForChild("EquipBrainrot")

print("[HotbarController] Loaded")

local slots = {
	equippedContainer:WaitForChild("BrainrotButton1"),
	equippedContainer:WaitForChild("BrainrotButton2"),
	equippedContainer:WaitForChild("BrainrotButton3")
}

local equippedData = {}
local activeSlot = nil

local function refreshHotbar()
	print("[HotbarController] Refreshing hotbar...")
	local success, data = pcall(function()
		return GetInventory:InvokeServer()
	end)

	if not success or not data then
		warn("[HotbarController] Failed to get inventory")
		return
	end

	print("[HotbarController] EquippedSlots:", data.EquippedSlots)
	local equipped = data.EquippedSlots or {}
	equippedData = {}
	equippedContainer.Visible = #equipped > 0
	print("[HotbarController] Visible set to:", equippedContainer.Visible)

	for i, slot in ipairs(slots) do
		local brainrotId = equipped[i]
		equippedData[i] = brainrotId

		print("[HotbarController] Slot", i, "brainrotId:", brainrotId, "Brainrots[brainrotId]:", Brainrots[brainrotId])

		local image = slot:FindFirstChild("BrainrotImage")
		local nameLabel = slot:FindFirstChild("BrainrotName")

		if brainrotId and Brainrots[brainrotId] then
			slot.Visible = true
			if image then image.Image = Brainrots[brainrotId].Icon end
			if nameLabel then nameLabel.Text = Brainrots[brainrotId].Name end
			print("[HotbarController] Slot", i, "set to visible with:", Brainrots[brainrotId].Name)
		else
			slot.Visible = false
			if image then image.Image = "" end
			if nameLabel then nameLabel.Text = "" end
			print("[HotbarController] Slot", i, "set to hidden")
		end
	end
end

local function equipSlot(index)
	local brainrotId = equippedData[index]
	if not brainrotId or not Brainrots[brainrotId] then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if activeSlot == index then
		humanoid:UnequipTools()
		activeSlot = nil
		return
	end

	local toolName = Brainrots[brainrotId].Model
	local backpack = player:FindFirstChild("Backpack")
	local tool = nil
	
	if backpack then
		tool = backpack:FindFirstChild(toolName)
	end
	
	if not tool then
		tool = character:FindFirstChild(toolName)
	end

	if tool and tool:IsA("Tool") then
		humanoid:EquipTool(tool)
		activeSlot = index
		print("[HotbarController] Equipped tool:", toolName)
	else
		warn("[HotbarController] Tool not found:", toolName)
	end
end

-- Keyboard 1/2/3
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Disable hotbar during battle
	local battleUI = playerGui:FindFirstChild("BattleUI")
	if battleUI and battleUI.Enabled then
		return
	end
	
	if input.KeyCode == Enum.KeyCode.One then
		equipSlot(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		equipSlot(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		equipSlot(3)
	end
end)

for i, slot in ipairs(slots) do
	slot.MouseButton1Click:Connect(function()
		equipSlot(i)
	end)
end

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	task.wait(1)
	refreshHotbar()
end)

-- Initial load
task.wait(1)
refreshHotbar()
_G.RefreshHotbar = refreshHotbar