local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for BattleUI
local battleUI
repeat
	battleUI = playerGui:FindFirstChild("BattleUI")
	task.wait(0.1)
until battleUI

print("[BattleUIController] BattleUI found!")

-- Initially hide the BattleUI
battleUI.Enabled = false
print("[BattleUIController] BattleUI hidden initially")

local container = battleUI:WaitForChild("Container")

-- UI Elements
local playerBrainrotContainer = container:WaitForChild("PlayerBrainrotContainer")
local enemyBrainrotContainer = container:WaitForChild("EnemyBrainrotContainer")
local playerBrainrotInfo = playerBrainrotContainer:WaitForChild("PlayerBrainrotInfo")
local enemyBrainrotInfo = enemyBrainrotContainer:WaitForChild("EnemyBrainrotInfo")
local movesContainer = container:WaitForChild("MovesContainer")
local eventsContainer = container:WaitForChild("EventsContainer")
local playerTurnStroke = container:WaitForChild("PlayerTurnStroke")
local enemyTurnStroke = container:WaitForChild("EnemyTurnStroke")
local timerFrame = container:WaitForChild("TimerFrame")

-- Result Frames
local wonFrame = container:WaitForChild("Won")
local lostFrame = container:WaitForChild("Lost")
local drawFrame = container:WaitForChild("Draw")

-- Event UI
local yourTurnUI = eventsContainer:FindFirstChild("YourTurn")
local enemyTurnUI = eventsContainer:FindFirstChild("EnemyTurn")
local enemyUsedMoveUI = eventsContainer:FindFirstChild("EnemyUsedMove")

-- HUD
local hudGui = playerGui:FindFirstChild("HUD")

-- RemoteEvents
local ExecuteMove = ReplicatedStorage.Remotes.ExecuteMove
local BattleUpdate = ReplicatedStorage.Remotes.BattleUpdate
local BattleEnd = ReplicatedStorage.Remotes.BattleEnd
local BattleError = ReplicatedStorage.Remotes.BattleError

-- Config
local Moves = require(ReplicatedStorage.Config.Moves)

-- State
local currentBattleData = nil
local isBattleActive = false
local isFirstUpdate = true
local previousState = nil
local playerTurnDelayTask = nil
local enemyTurnDelayTask = nil
local enemyMoveDelayTask = nil

-- Hide all result frames initially
wonFrame.Visible = false
lostFrame.Visible = false
drawFrame.Visible = false

--------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------

local function hideBattleUIElements()
	-- Hide all battle UI elements except result frames
	playerBrainrotContainer.Visible = false
	enemyBrainrotContainer.Visible = false
	movesContainer.Visible = false
	eventsContainer.Visible = false
	timerFrame.Visible = false
	if playerTurnStroke:IsA("UIStroke") then
		pcall(function() playerTurnStroke.Enabled = false end)
	end
	if enemyTurnStroke:IsA("UIStroke") then
		pcall(function() enemyTurnStroke.Enabled = false end)
	end
end

local function showBattleUIElements()
	-- Show all battle UI elements
	playerBrainrotContainer.Visible = true
	enemyBrainrotContainer.Visible = true
	movesContainer.Visible = true
	eventsContainer.Visible = true
	timerFrame.Visible = true
end

local function animateResultFrame(frame)
	-- Bounce animation for result frames
	local studFrame = frame:FindFirstChild("StudFrame")
	
	-- Start small
	if studFrame then
		studFrame.Size = UDim2.new(0, 0, 0, 0)
		studFrame.Visible = true
	end
	
	frame.Visible = true
	frame.BackgroundTransparency = 0.3
	
	-- Bounce animation
	local tweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)
	
	-- Animate StudFrame size
	if studFrame then
		local sizeTween = TweenService:Create(studFrame, tweenInfo, {
			Size = UDim2.new(1, 0, 0.94, 0)
		})
		sizeTween:Play()
	end
	
	-- Fade in background
	local fadeTween = TweenService:Create(frame, TweenInfo.new(0.3), {
		BackgroundTransparency = 0
	})
	fadeTween:Play()
end

--------------------------------------------------
-- UI HELPERS
--------------------------------------------------

local function updateHPBar(infoFrame, currentHP, maxHP)
	-- Debug prints removed for performance
	-- print("[updateHPBar] Updating HP bar: " .. currentHP .. "/" .. maxHP)
	local healthFrame = infoFrame.StudFrame.BrainrotConditionInfo.Health
	if healthFrame then
		local hpBar = healthFrame:FindFirstChild("HealthBar")
		local hpNumber = healthFrame:FindFirstChild("HealthNumber")
		if hpBar then
			local hpFill = hpBar:FindFirstChild("Heath")
			if hpFill then
				local percent = math.clamp(currentHP / maxHP, 0, 1)
				-- print("[updateHPBar] Setting HP bar size to: " .. percent)
				hpFill.Size = UDim2.new(percent, 0, 1, 0)
			else
				warn("[updateHPBar] hpFill not found!")
			end
		else
			warn("[updateHPBar] hpBar not found!")
		end
		if hpNumber then
			local label = hpNumber:FindFirstChild("HealthAmount")
			if label then
				label.Text = currentHP .. "/" .. maxHP
			end
		end
	else
		warn("[updateHPBar] healthFrame not found!")
	end
end

local function updateEnduranceBar(infoFrame, current, max)
	local frame = infoFrame.StudFrame.BrainrotConditionInfo.Endurance
	if frame then
		local bar = frame:FindFirstChild("EnduranceBar")
		local number = frame:FindFirstChild("EnduranceNumber")
		if bar then
			local fill = bar:FindFirstChild("Heath")
			if fill then
				local percent = math.clamp(current / max, 0, 1)
				fill.Size = UDim2.new(percent, 0, 1, 0)
			end
		end
		if number then
			local label = number:FindFirstChild("EnduranceAmount")
			if label then
				label.Text = current .. "/" .. max
			end
		end
	end
end

local function updateBrainrotName(infoFrame, name)
	local label = infoFrame.StudFrame.BrainrotNameInfo:FindFirstChild("BrainrotName")
	if label then
		label.Text = name
	end
end

local function updateBrainrotMutation(infoFrame, mutation)
	local mutationLabel = infoFrame.StudFrame:FindFirstChild("BrainrotNameInfo")
	if mutationLabel then
		local childLabel = mutationLabel:FindFirstChild("BrainrotMutation")
		if childLabel then
			childLabel.Text = mutation or ""
		end
	end
end

local function updateTimer(timeRemaining)
	if not timerFrame then return end
	
	local timerLabel = timerFrame.StudFrame:FindFirstChild("Timer")
	if timerLabel then
		local minutes = math.floor(timeRemaining / 60)
		local seconds = math.floor(timeRemaining % 60)
		timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
	end
end

local function updateMoveButtons(moves)
	for i = 1, 4 do
		local container = movesContainer:FindFirstChild("Move" .. i .. "Container")
		if container then
			local button = container:FindFirstChildOfClass("ImageButton")
			if button then
				if moves[i] then
					button.Visible = true
					local label = button.StudFrame:FindFirstChild("MoveName")
					if label then
						label.Text = moves[i]
					end
					-- Update cost amount
					local moveCostFrame = button.StudFrame:FindFirstChild("MoveCost")
					if moveCostFrame then
						local costAmountLabel = moveCostFrame:FindFirstChild("CostAmount")
						if costAmountLabel then
							local moveData = Moves[moves[i]]
							if moveData and moveData.EnduranceCost then
								costAmountLabel.Text = moveData.EnduranceCost
							end
						end
					end
				else
					button.Visible = false
				end
			end
		end
	end
end

--------------------------------------------------
-- TURN + EVENTS UI
--------------------------------------------------

local function showTurnIndicator(state)
	-- Cancel any pending delays
	if playerTurnDelayTask then
		task.cancel(playerTurnDelayTask)
		playerTurnDelayTask = nil
	end
	if enemyTurnDelayTask then
		task.cancel(enemyTurnDelayTask)
		enemyTurnDelayTask = nil
	end
	
	-- Hide all turn indicators immediately when state changes
	if yourTurnUI then
		yourTurnUI.Visible = false
	end
	if enemyTurnUI then
		enemyTurnUI.Visible = false
	end
	
	-- Don't show turn indicators during Resolving state
	if state == "Resolving" then
		return
	end
	
	if playerTurnStroke:IsA("UIStroke") then
		pcall(function() playerTurnStroke.Enabled = (state == "PlayerTurn") end)
	end
	if enemyTurnStroke:IsA("UIStroke") then
		pcall(function() enemyTurnStroke.Enabled = (state == "EnemyTurn") end)
	end

	if yourTurnUI and state == "PlayerTurn" then
		yourTurnUI.Visible = true
		playerTurnDelayTask = task.delay(0.15, function() 
			yourTurnUI.Visible = false
			playerTurnDelayTask = nil
		end)
	end

	if enemyTurnUI and state == "EnemyTurn" then
		enemyTurnUI.Visible = true
		enemyTurnDelayTask = task.delay(0.15, function() 
			enemyTurnUI.Visible = false
			enemyTurnDelayTask = nil
		end)
	end
end

local function showEnemyMove(log)
	if not enemyUsedMoveUI or not log or #log == 0 then return end
	local last = log[#log]
	if string.find(last, "Enemy") and string.find(last, "used") then
		-- Cancel any pending delay
		if enemyMoveDelayTask then
			task.cancel(enemyMoveDelayTask)
			enemyMoveDelayTask = nil
		end
		
		enemyUsedMoveUI.Text = last
		enemyUsedMoveUI.Visible = true
		enemyMoveDelayTask = task.delay(1.5, function() 
			enemyUsedMoveUI.Visible = false
			enemyMoveDelayTask = nil
		end)
	end
end

--------------------------------------------------
-- REMOTE HANDLERS
--------------------------------------------------

BattleUpdate.OnClientEvent:Connect(function(data)
	-- Debug prints removed for performance
	-- print("[BattleUIController] Received battle update!")
	-- print("  PlayerHP: " .. data.PlayerHP .. "/" .. data.PlayerMaxHP)
	-- print("  EnemyHP: " .. data.EnemyHP .. "/" .. data.EnemyMaxHP)
	-- print("  State: " .. data.State)

	currentBattleData = data
	isBattleActive = true
	battleUI.Enabled = true
	-- print("[BattleUIController] BattleUI enabled!")
	
	-- Unequip any tools when battle starts
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end
	
	-- Hide HUD when battle starts
	if hudGui then
		hudGui.Enabled = false
	end
	
	-- Hide all result frames when battle starts
	wonFrame.Visible = false
	lostFrame.Visible = false
	drawFrame.Visible = false
	
	-- Show all battle UI elements when battle starts
	showBattleUIElements()

	-- HP & Endurance
	updateHPBar(playerBrainrotInfo, data.PlayerHP, data.PlayerMaxHP)
	updateHPBar(enemyBrainrotInfo, data.EnemyHP, data.EnemyMaxHP)
	updateEnduranceBar(playerBrainrotInfo, data.PlayerEndurance, data.PlayerMaxEndurance)
	updateEnduranceBar(enemyBrainrotInfo, data.EnemyEndurance, data.EnemyMaxEndurance)

	-- Names
	updateBrainrotName(playerBrainrotInfo, data.PlayerBrainrotName)
	updateBrainrotName(enemyBrainrotInfo, data.EnemyBrainrotName)

	-- Mutation (Tier)
	updateBrainrotMutation(playerBrainrotInfo, data.PlayerBrainrotMutation)
	updateBrainrotMutation(enemyBrainrotInfo, data.EnemyBrainrotMutation)

	-- Moves
	updateMoveButtons(data.PlayerMoves)

	-- Timer
	if data.TimeRemaining then
		updateTimer(data.TimeRemaining)
	end

	-- Turn & Enemy Moves (skip on first update to prevent popups)
	if not isFirstUpdate then
		-- Only show turn indicator when state actually changes
		if data.State ~= previousState then
			showTurnIndicator(data.State)
		end
		showEnemyMove(data.Log)
	end
	
	-- Fallback: Show result frame if battle state is Win/Lose/Draw
	-- This handles cases where BattleEnd event might be missed
	if data.State == "Win" or data.State == "Lose" or data.State == "Draw" then
		print("[BattleUIController] Battle state is " .. data.State .. " - showing result frame")
		
		-- Hide all battle UI elements except result frames
		hideBattleUIElements()
		
		-- Show HUD when battle ends
		if hudGui then
			hudGui.Enabled = true
		end
		
		if data.State == "Win" then
			lostFrame.Visible = false
			drawFrame.Visible = false
			animateResultFrame(wonFrame)
		elseif data.State == "Lose" then
			wonFrame.Visible = false
			drawFrame.Visible = false
			animateResultFrame(lostFrame)
		elseif data.State == "Draw" then
			wonFrame.Visible = false
			lostFrame.Visible = false
			animateResultFrame(drawFrame)
		end
		
		-- Hide battle UI and result frames after 3 seconds
		task.delay(3, function() 
			battleUI.Enabled = false
			wonFrame.Visible = false
			lostFrame.Visible = false
			drawFrame.Visible = false
		end)
	end
	
	previousState = data.State
	isFirstUpdate = false
end)

BattleEnd.OnClientEvent:Connect(function(data)
	print("[BattleUIController] BattleEnd received! data.Result = " .. tostring(data and data.Result))
	isBattleActive = false
	isFirstUpdate = true -- Reset for next battle
	previousState = nil -- Reset state tracking
	
	-- Cancel all pending delays
	if playerTurnDelayTask then
		task.cancel(playerTurnDelayTask)
		playerTurnDelayTask = nil
	end
	if enemyTurnDelayTask then
		task.cancel(enemyTurnDelayTask)
		enemyTurnDelayTask = nil
	end
	if enemyMoveDelayTask then
		task.cancel(enemyMoveDelayTask)
		enemyMoveDelayTask = nil
	end
	
	-- Hide all turn indicators
	if playerTurnStroke:IsA("UIStroke") then
		pcall(function() playerTurnStroke.Enabled = false end)
	end
	if enemyTurnStroke:IsA("UIStroke") then
		pcall(function() enemyTurnStroke.Enabled = false end)
	end
	if yourTurnUI then
		yourTurnUI.Visible = false
	end
	if enemyTurnUI then
		enemyTurnUI.Visible = false
	end
	if enemyUsedMoveUI then
		enemyUsedMoveUI.Visible = false
	end
	
	-- Hide all battle UI elements except result frames
	hideBattleUIElements()
	
	-- Show result frame based on outcome
	print("[BattleUIController] Checking result type...")
	print("[BattleUIController] wonFrame exists: " .. tostring(wonFrame ~= nil))
	print("[BattleUIController] wonFrame.Visible before: " .. tostring(wonFrame and wonFrame.Visible))
	
	if data.Result == "Win" then
		print("[BattleUIController] WIN detected! Showing wonFrame...")
		if data.AwaitingLootCollection then
			print("[BattleUIController] Collect all gold and diamond pickups in the arena before you return!")
		end
		lostFrame.Visible = false
		drawFrame.Visible = false
		animateResultFrame(wonFrame)
	elseif data.Result == "Lose" then
		print("You lost!")
		wonFrame.Visible = false
		drawFrame.Visible = false
		animateResultFrame(lostFrame)
	else
		print("Draw!")
		wonFrame.Visible = false
		lostFrame.Visible = false
		animateResultFrame(drawFrame)
	end
	
	-- Show HUD when battle ends
	if hudGui then
		hudGui.Enabled = true
	end
	
	-- Hide battle UI and result frames after 3 seconds
	task.delay(3, function() 
		battleUI.Enabled = false
		-- Hide all result frames after battle UI closes
		wonFrame.Visible = false
		lostFrame.Visible = false
		drawFrame.Visible = false
	end)
end)

BattleError.OnClientEvent:Connect(function(msg)
	warn("Battle Error:", msg)
end)

--------------------------------------------------
-- MOVE BUTTON INPUT
--------------------------------------------------

for i = 1, 4 do
	local container = movesContainer:FindFirstChild("Move" .. i .. "Container")
	if container then
		local button = container:FindFirstChildOfClass("ImageButton")
		if button then
			button.MouseButton1Click:Connect(function()
				-- Debug prints removed for performance
				-- print("[BattleUIController] Move button clicked!")
				-- print("[BattleUIController] isBattleActive:", isBattleActive)
				-- print("[BattleUIController] currentBattleData:", currentBattleData)
				if currentBattleData then
					-- print("[BattleUIController] currentBattleData.State:", currentBattleData.State)
				end
				if not isBattleActive or not currentBattleData then 
					-- print("[BattleUIController] Click rejected - battle not active or no data")
					return 
				end
				if currentBattleData.State ~= "PlayerTurn" then 
					-- print("[BattleUIController] Click rejected - not player's turn, state is:", currentBattleData.State)
					return 
				end
				local moveName = button.StudFrame:FindFirstChild("MoveName")
				if moveName then
					-- print("[BattleUIController] Firing ExecuteMove for:", moveName.Text)
					ExecuteMove:FireServer(moveName.Text)
				end
			end)
		end
	end
end