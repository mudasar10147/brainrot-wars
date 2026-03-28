local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Inventory / HUD
local hud = playerGui:WaitForChild("InventoryUI")
local container = hud:WaitForChild("Container")
local inventoryContainer = container:WaitForChild("InventoryContainer")
local teamsButton = inventoryContainer:WaitForChild("TeamsButton")
local teamsFrame = inventoryContainer:WaitForChild("TeamsFrame")

local teamTemplate = teamsFrame:WaitForChild("TeamTemplate")
local createNewTeamButton = teamsFrame:WaitForChild("CreateNewTeamButton")
local sortByContainer = inventoryContainer:WaitForChild("SortByContainer")
local sortByText = inventoryContainer:WaitForChild("SortByText")
local inventoryList = inventoryContainer:WaitForChild("InventoryList")
local searchFrame = inventoryContainer:WaitForChild("SearchFrame")
local equippedBrainrots = inventoryContainer:WaitForChild("EquippedBrainrots")
local divider = inventoryContainer:FindFirstChild("Divider")
local teamsText = teamsButton:WaitForChild("StudFrame"):WaitForChild("TeamsText")

local hudUI = playerGui:WaitForChild("HUD")
local hudContainer = hudUI:WaitForChild("Container")
local inventoryButtonFrame = hudContainer:WaitForChild("InventoryButtonFrame")
local inventoryButton = inventoryButtonFrame:WaitForChild("InventoryButton")
local inventoryUI = playerGui:WaitForChild("InventoryUI")
local mergeUI = playerGui:WaitForChild("MergeBrainrotsUI")

-- Team system UI
local chooseBrainrotTeamUI = playerGui:WaitForChild("ChooseBrainrotTeamUI")

-- Hide initially
teamsFrame.Visible = false
teamTemplate.Visible = false
createNewTeamButton.Visible = true

-- Toggle Teams Panel
teamsButton.MouseButton1Click:Connect(function()
	local isTeamsMode = not teamsFrame.Visible

	teamsFrame.Visible = isTeamsMode
	sortByContainer.Visible = not isTeamsMode
	sortByText.Visible = not isTeamsMode
	inventoryList.Visible = not isTeamsMode
	searchFrame.Visible = not isTeamsMode
	equippedBrainrots.Visible = not isTeamsMode
	if divider then divider.Visible = not isTeamsMode end
	teamsText.Text = isTeamsMode and "Inventory" or "Teams"
end)

-- Toggle Inventory UI
inventoryButton.MouseButton1Click:Connect(function()
	if mergeUI and mergeUI.Enabled then return end
	inventoryUI.Enabled = not inventoryUI.Enabled
	if inventoryUI.Enabled and _G.PopulateInventory then
		_G.PopulateInventory()
	end
end)

-- Open ChooseBrainrotTeamUI on Create New Team
createNewTeamButton.MouseButton1Click:Connect(function()
	print("[Teams] Opening ChooseBrainrotTeamUI")
	chooseBrainrotTeamUI.Enabled = true
	inventoryUI.Enabled = false
end)
