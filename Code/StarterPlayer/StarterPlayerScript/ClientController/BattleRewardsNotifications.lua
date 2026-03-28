-- Server → BattleRewardsSummary: show capture / inventory full / optional "no drop".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BattleRewardsSummary = Remotes:WaitForChild("BattleRewardsSummary")

local function displayNameForId(id)
	if not id then
		return nil
	end
	local data = Brainrots[id]
	if data and data.Name then
		return data.Name
	end
	return id
end

local function notify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5,
		})
	end)
end

BattleRewardsSummary.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	if data.BrainrotGranted and data.BrainrotId then
		local name = displayNameForId(data.BrainrotId)
		notify("Brainrot captured!", tostring(name) .. " was added to your inventory.")
		if _G.PopulateInventory then
			_G.PopulateInventory()
		end
		return
	end

	if data.RollSucceeded and data.InventoryFull and data.BrainrotId then
		local name = displayNameForId(data.BrainrotId)
		notify("Inventory full", "Couldn't store " .. tostring(name) .. ". Make space and win again!")
		return
	end

	if data.DropEligible and data.RollSucceeded == false then
		notify("Battle bonus", "No brainrot drop this time.")
	end
end)
