local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RequestStarterOptions = ReplicatedStorage.Remotes.RequestStarterOptions
local SelectStarterBrainrot = ReplicatedStorage.Remotes.SelectStarterBrainrot

local onboardingUI = playerGui:WaitForChild("OnboardingUI")
local list = onboardingUI.Container.BrainrotContainer.BrainrotList
local buttons = { list.BrainRotIcon_1, list.BrainRotIcon_2, list.BrainRotIcon_3 }
local confirmButton = onboardingUI.Container.BrainrotContainer.ConfirmButton

local selectedBrainrot = nil

for _, button in ipairs(buttons) do
	button:WaitForChild("CheckIcon").Visible = false
end

local success, options = pcall(function()
	return RequestStarterOptions:InvokeServer()
end)
if not success or not options then
	onboardingUI.Enabled = false
	return
end

for i, button in ipairs(buttons) do
	local brainrotData = options[i]
	if not brainrotData then continue end

	button:SetAttribute("BrainrotName", brainrotData.Id)
	button.BrainrotImage.Image = brainrotData.Icon
	button.TopFrame.StudFrame.BrainrotName.Text = brainrotData.Name

	button.MouseButton1Click:Connect(function()
		selectedBrainrot = brainrotData.Id
		for _, b in ipairs(buttons) do
			b.CheckIcon.Visible = false
		end
		button.CheckIcon.Visible = true
	end)
end

onboardingUI.Enabled = true

confirmButton.MouseButton1Click:Connect(function()
	if not selectedBrainrot then return end
	SelectStarterBrainrot:FireServer(selectedBrainrot)
	onboardingUI.Enabled = false
end)