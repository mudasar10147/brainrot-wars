local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UIs
local chooseTeamUI = playerGui:WaitForChild("ChooseBrainrotTeamUI")
local inventoryUI = playerGui:WaitForChild("InventoryUI")

-- ChooseBrainrotTeamUI structure
local container = chooseTeamUI:WaitForChild("Container")
local inventoryContainer = container:WaitForChild("InventoryContainer")
local inventoryList = inventoryContainer:WaitForChild("InventoryList")
local closeButton = container:WaitForChild("TopFrame"):WaitForChild("CloseButton")
local teamsButton = inventoryContainer:WaitForChild("TeamsButton")

-- Template (cloned before any children are added)
local template = inventoryList:WaitForChild("BrainrotButtonContainer"):Clone()
template.Parent = nil

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetInventory = Remotes:WaitForChild("GetInventory")

-- Brainrot data
local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)

-- InventoryUI structure (for switching to teams mode after save)
local invContainer = inventoryUI:WaitForChild("Container"):WaitForChild("InventoryContainer")
local invList = invContainer:WaitForChild("InventoryList")
local equippedBrainrots = invContainer:WaitForChild("EquippedBrainrots")
local searchFrame = invContainer:WaitForChild("SearchFrame")
local sortByContainer = invContainer:WaitForChild("SortByContainer")
local sortByText = invContainer:WaitForChild("SortByText")
local divider = invContainer:FindFirstChild("Divider")
local teamsFrame = invContainer:WaitForChild("TeamsFrame")
local teamTemplate = teamsFrame:WaitForChild("TeamTemplate")
local createNewTeamButton = teamsFrame:WaitForChild("CreateNewTeamButton")
local teamsText = invContainer:WaitForChild("TeamsButton"):WaitForChild("StudFrame"):WaitForChild("TeamsText")

-- State
-- Each entry: { brainrotId = string, button = GuiObject }
-- Order in this table = order brainrots appear in the created team
local selectedOrder = {}
local equipCapacity = 3
local editingTeam = nil  -- set when editing an existing team, nil when creating new

------------------------------------------------
-- HELPERS
------------------------------------------------
local function clearList()
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child.Name == "BrainrotButtonContainer" then
			child:Destroy()
		end
	end
end

-- Switch InventoryUI into teams mode and close this UI
local function showTeamsMode()
	chooseTeamUI.Enabled = false
	inventoryUI.Enabled = true

	invList.Visible = false
	equippedBrainrots.Visible = false
	searchFrame.Visible = false
	sortByContainer.Visible = false
	sortByText.Visible = false
	if divider then divider.Visible = false end

	teamsFrame.Visible = true
	teamsText.Text = "Inventory"

	-- Show "Create New Team" only while fewer than 3 teams exist
	local currentTeams = 0
	for _, child in ipairs(teamsFrame:GetChildren()) do
		if child.Name:match("^Team_") then
			currentTeams += 1
		end
	end
	createNewTeamButton.Visible = currentTeams < 3
end

------------------------------------------------
-- TEAM HELPERS
------------------------------------------------
local TOTAL_TEAM_SLOTS = 7

-- Read brainrotIds stored as attributes on existing filled slots, in layout order
local function getTeamBrainrotIds(teamFrame)
	local savedBrainrots = teamFrame:FindFirstChild("SavedBrainrots")
	if not savedBrainrots then return {} end

	local slots = {}
	for _, child in ipairs(savedBrainrots:GetChildren()) do
		if child:IsA("ImageButton") and child.Name == "BrainrotButton" then
			table.insert(slots, child)
		end
	end
	table.sort(slots, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

	local ids = {}
	for _, slot in ipairs(slots) do
		local id = slot:GetAttribute("BrainrotId")
		if id and id ~= "" then
			table.insert(ids, id)
		end
	end
	return ids
end

-- brainrotIds: ordered array of brainrot id strings to place in the team
-- cap: equipCapacity to use for this render
local function fillTeamSlots(teamFrame, brainrotIds, cap)
	local savedBrainrots = teamFrame:FindFirstChild("SavedBrainrots")
	if not savedBrainrots then return end

	-- Clear all existing slots
	for _, child in ipairs(savedBrainrots:GetChildren()) do
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local baseSlot   = teamTemplate:FindFirstChild("SavedBrainrots"):FindFirstChild("BrainrotButton")
	local lockedSlot = teamTemplate:FindFirstChild("SavedBrainrots"):FindFirstChild("LockedButton")
	if not baseSlot then return end

	for i = 1, TOTAL_TEAM_SLOTS do
		if i <= cap then
			local slot = baseSlot:Clone()
			slot.LayoutOrder = i
			slot.Parent = savedBrainrots

			local brainrotId = brainrotIds[i]
			if brainrotId then
				slot:SetAttribute("BrainrotId", brainrotId)
				local brainrotData = Brainrots[brainrotId]
				if brainrotData then
					local nameLabel = slot:FindFirstChild("BrainrotName")
					local image = slot:FindFirstChild("BrainrotImage")
					if nameLabel then nameLabel.Text = brainrotData.Name end
					if image then image.Image = brainrotData.Icon end
				end
			else
				slot:SetAttribute("BrainrotId", "")
			end
		else
			if lockedSlot then
				local locked = lockedSlot:Clone()
				locked.LayoutOrder = i
				locked.Parent = savedBrainrots

				locked.MouseButton1Click:Connect(function()
					local confirmationUI = playerGui:FindFirstChild("Confirmation")
					if confirmationUI then
						_G.RequestSlotPurchase = true
						inventoryUI.Enabled = false
						confirmationUI.Enabled = true
					end
				end)
			end
		end
	end
end

-- Re-renders every existing team frame with a new capacity, preserving their brainrots
_G.RefreshAllTeams = function(newCapacity)
	equipCapacity = newCapacity or equipCapacity
	for _, child in ipairs(teamsFrame:GetChildren()) do
		if child.Name:match("^Team_") then
			local ids = getTeamBrainrotIds(child)
			fillTeamSlots(child, ids, equipCapacity)
		end
	end
	-- Update Create New Team button visibility
	local currentTeams = 0
	for _, child in ipairs(teamsFrame:GetChildren()) do
		if child.Name:match("^Team_") then currentTeams += 1 end
	end
	createNewTeamButton.Visible = currentTeams < 3
end

local setupTeamButtons  -- forward declare so fillTeamSlots can reference it if needed

setupTeamButtons = function(teamFrame)
	local deleteButton = teamFrame:FindFirstChild("DeleteButton")
	local editButton = teamFrame:FindFirstChild("EditButton")

	if deleteButton then
		deleteButton.MouseButton1Click:Connect(function()
			teamFrame:Destroy()
		end)
	end

	if editButton then
		editButton.MouseButton1Click:Connect(function()
			editingTeam = teamFrame
			chooseTeamUI.Enabled = true
			inventoryUI.Enabled = false
		end)
	end
end

------------------------------------------------
-- POPULATE
------------------------------------------------
local function populateUI()
	clearList()
	selectedOrder = {}

	local inventoryData = GetInventory:InvokeServer()
	if not inventoryData then return end

	equipCapacity = inventoryData.EquipCapacity or 3

	-- Combine inventory + equipped into one ordered list
	local allBrainrots = {}
	for _, id in ipairs(inventoryData.InventorySlots or {}) do
		if id and id ~= false and id ~= "" then
			table.insert(allBrainrots, id)
		end
	end
	for _, id in ipairs(inventoryData.EquippedSlots or {}) do
		if id and id ~= false and id ~= "" then
			table.insert(allBrainrots, id)
		end
	end

	for _, brainrotId in ipairs(allBrainrots) do
		local brainrotData = Brainrots[brainrotId]
		if not brainrotData then continue end

		local newContainer = template:Clone()
		newContainer.Name = "BrainrotButtonContainer"
		newContainer.Visible = true
		newContainer.Parent = inventoryList

		local button = newContainer:FindFirstChild("BrainrotButton")
		if not button then continue end

		-- Set visuals
		local nameLabel = button:FindFirstChild("BrainrotName")
		local mutationLabel = button:FindFirstChild("MutationName")
		local imageLabel = button:FindFirstChild("BrainrotImage")
		local checkIcon = button:FindFirstChild("CheckIcon")

		if nameLabel then nameLabel.Text = brainrotData.Name end
		if mutationLabel then mutationLabel.Text = brainrotData.Tier end
		if imageLabel then imageLabel.Image = brainrotData.Icon end
		if checkIcon then checkIcon.Visible = false end

		-- Click: toggle selection
		button.MouseButton1Click:Connect(function()
			-- Find if this exact button instance is already selected
			local foundIndex = nil
			for i, entry in ipairs(selectedOrder) do
				if entry.button == button then
					foundIndex = i
					break
				end
			end

			if foundIndex then
				-- Deselect
				table.remove(selectedOrder, foundIndex)
				if checkIcon then checkIcon.Visible = false end
			else
				-- Select only if under capacity
				if #selectedOrder >= equipCapacity then return end
				table.insert(selectedOrder, { brainrotId = brainrotId, button = button })
				if checkIcon then checkIcon.Visible = true end
			end
		end)
	end
end

------------------------------------------------
-- SAVE BUTTON
------------------------------------------------
teamsButton.MouseButton1Click:Connect(function()
	if #selectedOrder == 0 then
		warn("[TeamUI] No brainrots selected!")
		return
	end

	local ids = {}
	for _, entry in ipairs(selectedOrder) do
		table.insert(ids, entry.brainrotId)
	end

	if editingTeam then
		fillTeamSlots(editingTeam, ids, equipCapacity)
		editingTeam = nil
	else
		local currentTeams = 0
		for _, child in ipairs(teamsFrame:GetChildren()) do
			if child.Name:match("^Team_") then
				currentTeams += 1
			end
		end
		if currentTeams >= 3 then
			warn("[TeamUI] Maximum of 3 teams reached!")
			return
		end

		local newTeam = teamTemplate:Clone()
		newTeam.Name = "Team_" .. tick()
		newTeam.Visible = true
		newTeam.Parent = teamsFrame

		fillTeamSlots(newTeam, ids, equipCapacity)
		setupTeamButtons(newTeam)
	end

	selectedOrder = {}
	showTeamsMode()
end)

------------------------------------------------
-- CLOSE BUTTON
------------------------------------------------
closeButton.MouseButton1Click:Connect(function()
	chooseTeamUI.Enabled = false
	selectedOrder = {}
	editingTeam = nil
end)

------------------------------------------------
-- POPULATE WHEN UI OPENS
------------------------------------------------
chooseTeamUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	if chooseTeamUI.Enabled then
		populateUI()
	end
end)

_G.RefreshTeamUI = populateUI
