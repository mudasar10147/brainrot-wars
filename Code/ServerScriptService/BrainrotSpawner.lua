local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local brainrotModels = ReplicatedStorage:FindFirstChild("BrainrotModels")
local battleSpawn = workspace:FindFirstChild("BattleSpawn")
local npcSpawn = workspace:FindFirstChild("NPC Spawn")
local brainrotSpawnFolder = workspace:FindFirstChild("BrainrotsSpawn")
local dummyTemplate = ReplicatedStorage:FindFirstChild("Dummy")
local BrainrotStats = require(ReplicatedStorage.Config.BrainrotStats)
local BattleSystem = require(ReplicatedStorage.Modules.BattleSystem)
local BattleResult = require(ReplicatedStorage.Modules.BattleResult)
local Moves = require(ReplicatedStorage.Config.Moves)
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local BrainrotSpawnConfig = require(ReplicatedStorage.Config.BrainrotSpawnConfig)

-- RemoteEvents
local ExecuteMove = ReplicatedStorage.Remotes.ExecuteMove
local BattleUpdate = ReplicatedStorage.Remotes.BattleUpdate
local BattleEnd = ReplicatedStorage.Remotes.BattleEnd
local BattleError = ReplicatedStorage.Remotes.BattleError

-- Config
local SPAWN_RADIUS = 50 -- Distance from player to spawn brainrots
local MAX_WILD_BRAINROTS = 5 -- Maximum wild brainrots at once
local SPAWN_INTERVAL = 5 -- Seconds between spawn checks
local DESPAWN_DISTANCE = 100 -- Distance at which brainrots despawn
local INTERACT_DISTANCE = 15 -- Distance to interact with brainrot

-- Store battle states for active players
local activeBattles = {}
local BATTLE_DURATION = 180 -- 3 minutes per battle
local BATTLE_UPDATE_INTERVAL = 0.3

-- Track wild brainrots
local wildBrainrots = {}
local battleModePlayers = {}

-- Store player original positions for navigation back after battle
local playerOriginalPositions = {}

-- Track spawned models for cleanup
local spawnedModels = {}

-- Get all brainrot model names
local brainrotModelList = {}
for _, model in brainrotModels:GetChildren() do
	if model:IsA("Model") then
		table.insert(brainrotModelList, model.Name)
	end
end

print("[WildBrainrot] Found " .. #brainrotModelList .. " brainrot models")

--------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------

local function getRandomBrainrotModel()
	local randomIndex = math.random(1, #brainrotModelList)
	local modelName = brainrotModelList[randomIndex]
	return brainrotModels:FindFirstChild(modelName)
end

local function getMovesForBrainrot(brainrotName)
	local moves = {}
	for moveName, moveData in pairs(Moves) do
		if moveData.Brainrot == brainrotName then
			table.insert(moves, moveName)
		end
	end
	return moves
end

local function unfreezePlayer(battleData)
	if not battleData then return end
	
	local character = battleData.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		print("[Battle] Player unfrozen")
	end
	
	local player = battleData.Player
	if player then
		battleModePlayers[player] = nil
	end
end

local function endBattle(player, battleData, resultType)
	print("[Battle] endBattle called with resultType: " .. tostring(resultType))
	
	-- Clean up spawned models
	if battleData.Character and spawnedModels[battleData.Character] then
		for _, model in spawnedModels[battleData.Character] do
			if model and model.Parent then
				model:Destroy()
			end
		end
		spawnedModels[battleData.Character] = nil
	end
	
	unfreezePlayer(battleData)
	
	-- Teleport player back to original position
	local originalPos = playerOriginalPositions[player]
	if originalPos and battleData.Character then
		local humanoidRootPart = battleData.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = originalPos
			print("[Battle] Teleported player back to original position")
		end
		playerOriginalPositions[player] = nil
	end
	
	BattleEnd:FireClient(player, {
		Result = resultType
	})
	
	activeBattles[player] = nil
	print("[Battle] Battle ended! Result: " .. tostring(resultType))
end

local function getBrainrotModelByName(brainrotId)
	-- First try to find by exact name
	for _, child in brainrotModels:GetChildren() do
		if child:IsA("Model") and child.Name == brainrotId then
			return child
		end
	end
	
	-- If not found, try to find by brainrot data
	local brainrotData = Brainrots[brainrotId]
	if brainrotData and brainrotData.Model then
		for _, child in brainrotModels:GetChildren() do
			if child:IsA("Model") and child.Name == brainrotData.Model then
				return child
			end
		end
	end
	
	return nil
end

local function spawnBattleModels(character, playerBrainrotId, enemyBrainrotName)
	-- Clean up previously spawned models for this player
	if spawnedModels[character] then
		for _, model in spawnedModels[character] do
			if model and model.Parent then
				model:Destroy()
			end
		end
	end
	spawnedModels[character] = {}

	-- Get player's brainrot model
	local playerModelTemplate = getBrainrotModelByName(playerBrainrotId)
	if playerModelTemplate and battleSpawn then
		local playerModel = playerModelTemplate:Clone()
		-- Force all parts to have zero rotation
		for _, part in playerModel:GetDescendants() do
			if part:IsA("BasePart") then
				part.Orientation = Vector3.new(0, 0, 0)
			end
		end
		
		-- Position player brainrot next to BattleSpawn, facing the enemy
		local playerSpawnPos = battleSpawn.Position + (battleSpawn.CFrame.RightVector * 5) + Vector3.new(0, 4, 0)
		playerModel:PivotTo(CFrame.lookAt(playerSpawnPos, playerSpawnPos + battleSpawn.CFrame.LookVector))
		playerModel.Parent = workspace
		table.insert(spawnedModels[character], playerModel)
	end

	-- Spawn enemy brainrot at NPC Spawn location
	local enemyModelTemplate = getBrainrotModelByName(enemyBrainrotName)
	if enemyModelTemplate and npcSpawn then
		local enemyModel = enemyModelTemplate:Clone()
		-- Force all parts to have zero rotation
		for _, part in enemyModel:GetDescendants() do
			if part:IsA("BasePart") then
				part.Orientation = Vector3.new(0, 0, 0)
			end
		end
		
		-- Position enemy next to NPC Spawn, facing the player
		local npcSpawnPos = npcSpawn.Position + (npcSpawn.CFrame.RightVector * 5) + Vector3.new(0, 4, 0)
		enemyModel:PivotTo(CFrame.lookAt(npcSpawnPos, npcSpawnPos - npcSpawn.CFrame.LookVector))
		enemyModel.Parent = workspace
		table.insert(spawnedModels[character], enemyModel)
	end
end

local function sendBattleUpdate(player, battle)
	local playerStatus = BattleSystem.GetCombatantStatus(battle, true)
	local enemyStatus = BattleSystem.GetCombatantStatus(battle, false)

	local battleData = activeBattles[player]
	local playerBrainrotName = battleData and battleData.ToolName or "Unknown"
	local enemyBrainrotName = battleData and battleData.EnemyBrainrotName or "Unknown"

	local playerStats = BrainrotStats.GetStats(playerBrainrotName)
	local enemyStats = EnemyConfig.GetEnemyStats(enemyBrainrotName)

	local timeRemaining = BATTLE_DURATION
	if battleData and battleData.StartTime then
		timeRemaining = math.max(0, BATTLE_DURATION - (os.clock() - battleData.StartTime))
	end

	BattleUpdate:FireClient(player, {
		PlayerHP = playerStatus.CurrentHP,
		PlayerMaxHP = playerStatus.MaxHP,
		EnemyHP = enemyStatus.CurrentHP,
		EnemyMaxHP = enemyStatus.MaxHP,
		PlayerEndurance = playerStatus.CurrentEndurance,
		PlayerMaxEndurance = playerStatus.MaxEndurance,
		EnemyEndurance = enemyStatus.CurrentEndurance,
		EnemyMaxEndurance = enemyStatus.MaxEndurance,
		PlayerMoves = playerStatus.Moves,
		State = BattleSystem.GetState(battle),
		Log = BattleSystem.GetLog(battle),
		PlayerBrainrotName = playerBrainrotName,
		EnemyBrainrotName = enemyBrainrotName,
		PlayerBrainrotMutation = playerStats and playerStats.Tier or "Common",
		EnemyBrainrotMutation = enemyStats and enemyStats.Tier or "Common",
		TimeRemaining = timeRemaining
	})
end

--------------------------------------------------
-- BATTLE SYSTEM
--------------------------------------------------

local function startBattleWithWild(player, wildBrainrotData)
	print("[WildBrainrot] startBattleWithWild called by " .. player.Name)
	
	local character = player.Character
	if not character then
		warn("[WildBrainrot] No character found")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoidRootPart or not humanoid then
		warn("[WildBrainrot] No HumanoidRootPart or Humanoid")
		return
	end

	-- Get equipped brainrot
	local equippedBrainrot = nil
	local equippedList = InventoryService:GetEquipped(player)
	
	if equippedList and #equippedList > 0 then
		for _, brainrotId in ipairs(equippedList) do
			if brainrotId and brainrotId ~= false then
				equippedBrainrot = brainrotId
				break
			end
		end
	end
	
	if not equippedBrainrot then
		warn("[WildBrainrot] No equipped brainrot found for player: " .. player.Name)
		return
	end
	
	print("[WildBrainrot] Player has equipped: " .. tostring(equippedBrainrot))

	-- Get enemy brainrot name
	local enemyBrainrotName = wildBrainrotData.ModelName
	print("[WildBrainrot] Enemy brainrot: " .. enemyBrainrotName)

	-- Store player's original position before teleporting
	playerOriginalPositions[player] = humanoidRootPart.CFrame
	print("[WildBrainrot] Stored player original position")

	-- Teleport player to battle spawn
	local spawnCFrame = battleSpawn.CFrame * CFrame.new(0, battleSpawn.Size.Y / 2 + 3, 0)
	humanoidRootPart.CFrame = spawnCFrame

	-- Spawn brainrot models in battle arena
	spawnBattleModels(character, equippedBrainrot, enemyBrainrotName)

	-- Remove the wild brainrot
	if wildBrainrotData.Model and wildBrainrotData.Model.Parent then
		wildBrainrotData.Model:Destroy()
		print("[WildBrainrot] Removed wild brainrot from world")
	end

	-- Remove from wild brainrots list
	for i, data in ipairs(wildBrainrots) do
		if data == wildBrainrotData then
			table.remove(wildBrainrots, i)
			break
		end
	end

	-- Freeze player
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Get player stats
	local playerStats = BrainrotStats.GetStats(equippedBrainrot)
	if not playerStats then
		local brainrotData = Brainrots[equippedBrainrot]
		if brainrotData and brainrotData.Name then
			playerStats = BrainrotStats.GetStats(brainrotData.Name)
		end
	end
	
	if not playerStats then
		warn("[WildBrainrot] No stats found for brainrot: " .. equippedBrainrot)
		return
	end

	-- Get enemy stats from EnemyConfig
	local enemyStats = EnemyConfig.GetEnemyStats(enemyBrainrotName)
	print("[WildBrainrot] Enemy stats loaded - HP: " .. enemyStats.Health .. ", DMG: " .. enemyStats.Damage)

	-- Get moves
	local playerMoves = getMovesForBrainrot(equippedBrainrot)
	if #playerMoves == 0 then
		local brainrotData = Brainrots[equippedBrainrot]
		if brainrotData and brainrotData.Name then
			playerMoves = getMovesForBrainrot(brainrotData.Name)
		end
	end

	-- Get enemy moves from EnemyConfig
	local enemyMoves = EnemyConfig.GetEnemyMoves(enemyBrainrotName)
	print("[WildBrainrot] Enemy moves: " .. table.concat(enemyMoves, ", "))

	print("[WildBrainrot] Player moves: " .. table.concat(playerMoves, ", "))

	-- Create battle
	local battle = BattleSystem.NewBattle(playerStats, enemyStats, playerMoves, enemyMoves)

	battleModePlayers[player] = true

	activeBattles[player] = {
		Battle = battle,
		Character = character,
		Humanoid = humanoid,
		ToolName = equippedBrainrot,
		EnemyBrainrotName = enemyBrainrotName,
		PlayerMoves = playerMoves,
		EnemyMoves = enemyMoves,
		StartTime = os.clock(),
		Player = player
	}

	-- Start battle timer
	task.spawn(function()
		local lastUpdateTime = 0
		while activeBattles[player] and not BattleSystem.IsBattleOver(battle) do
			local elapsed = os.clock() - activeBattles[player].StartTime
			local timeRemaining = BATTLE_DURATION - elapsed

			if elapsed - lastUpdateTime >= BATTLE_UPDATE_INTERVAL then
				sendBattleUpdate(player, battle)
				lastUpdateTime = elapsed
			end

			if timeRemaining <= 0 then
				local playerHP = battle.PlayerCurrentHP
				local enemyHP = battle.EnemyCurrentHP
				
				local resultType
				if playerHP > enemyHP then
					resultType = "Win"
				elseif enemyHP > playerHP then
					resultType = "Lose"
				else
					resultType = "Draw"
				end
				
				if resultType == "Win" then
					battle.CurrentState = BattleSystem.States.Win
				elseif resultType == "Lose" then
					battle.CurrentState = BattleSystem.States.Lose
				else
					battle.CurrentState = BattleSystem.States.Draw
				end
				
				battle.Result = BattleResult.New(resultType, battle.TurnCount, battle.PlayerCurrentHP, battle.EnemyCurrentHP)
				endBattle(player, activeBattles[player], resultType)
				return
			end

			task.wait(0.05)
		end
	end)

	print("[WildBrainrot] Battle started with " .. enemyBrainrotName)
	sendBattleUpdate(player, battle)
end

local function handleExecuteMove(player, moveName)
	local battleData = activeBattles[player]
	if not battleData then
		BattleError:FireClient(player, "No active battle found")
		return
	end

	local battle = battleData.Battle
	if not battle then
		BattleError:FireClient(player, "Battle data corrupted")
		return
	end

	local currentState = BattleSystem.GetState(battle)
	if currentState ~= BattleSystem.States.PlayerTurn then
		BattleError:FireClient(player, "Not your turn")
		return
	end

	local success, errorMsg = BattleSystem.ExecuteMove(battle, true, moveName)
	if not success then
		BattleError:FireClient(player, errorMsg)
		return
	end

	if BattleSystem.CheckEnduranceDraw(battle) then
		sendBattleUpdate(player, battle)
		local result = BattleSystem.GetResult(battle)
		endBattle(player, battleData, result.Result)
		return
	end

	sendBattleUpdate(player, battle)

	if BattleSystem.IsBattleOver(battle) then
		local result = BattleSystem.GetResult(battle)
		endBattle(player, battleData, result.Result)
		return
	end

	task.wait(0.3)

	local enemyMoves = battleData.EnemyMoves
	if #enemyMoves > 0 then
		local randomMove = enemyMoves[math.random(1, #enemyMoves)]
		local success, errorMsg = BattleSystem.ExecuteMove(battle, false, randomMove)
		if not success then
			BattleSystem.SetState(battle, BattleSystem.States.PlayerTurn)
			sendBattleUpdate(player, battle)
			return
		end
	else
		BattleSystem.SetState(battle, BattleSystem.States.PlayerTurn)
		sendBattleUpdate(player, battle)
		return
	end

	if not BattleSystem.IsBattleOver(battle) then
		BattleSystem.SetState(battle, BattleSystem.States.PlayerTurn)
	end

	if BattleSystem.CheckEnduranceDraw(battle) then
		sendBattleUpdate(player, battle)
		local result = BattleSystem.GetResult(battle)
		endBattle(player, battleData, result.Result)
		return
	end

	sendBattleUpdate(player, battle)

	if BattleSystem.IsBattleOver(battle) then
		local result = BattleSystem.GetResult(battle)
		endBattle(player, battleData, result.Result)
		return
	end

	sendBattleUpdate(player, battle)
end

ExecuteMove.OnServerEvent:Connect(handleExecuteMove)

--------------------------------------------------
-- SPAWN SYSTEM
--------------------------------------------------

local function createWildBrainrot(position, spawnData)
	local modelName = spawnData.Name
	local modelTemplate = brainrotModels:FindFirstChild(modelName)
	if not modelTemplate then
		warn("[WildBrainrot] Model not found: " .. modelName)
		return nil
	end

	local wildBrainrot = modelTemplate:Clone()
	wildBrainrot.Name = "WildBrainrot_" .. modelName
	wildBrainrot:SetAttribute("BrainrotName", modelName)
	wildBrainrot:SetAttribute("IsWild", true)
	wildBrainrot:SetAttribute("Tier", spawnData.Tier)

	-- Add ProximityPrompt
	local promptParent = wildBrainrot.PrimaryPart or wildBrainrot:FindFirstChildWhichIsA("BasePart")
	print("[WildBrainrot] Prompt parent for " .. modelName .. ": " .. tostring(promptParent))
	
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "InteractPrompt"
	proximityPrompt.ActionText = "Battle"
	proximityPrompt.ObjectText = modelName
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	proximityPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	proximityPrompt.HoldDuration = 3 -- Instant interaction
	proximityPrompt.MaxActivationDistance = INTERACT_DISTANCE
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = promptParent

	-- Add BillboardGui for name display
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "NameTag"
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Adornee = wildBrainrot.PrimaryPart or wildBrainrot:FindFirstChildWhichIsA("BasePart")
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = wildBrainrot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = modelName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.Parent = billboardGui

	-- Position the brainrot
	wildBrainrot:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	wildBrainrot.Parent = workspace

	-- Make sure all parts are anchored
	for _, part in wildBrainrot:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = true
		end
	end

	print("[WildBrainrot] Spawned " .. modelName .. " at " .. tostring(position))
	
	-- Connect proximity prompt
	local prompt = wildBrainrot:FindFirstChild("InteractPrompt", true)
	print("[WildBrainrot] Found prompt: " .. tostring(prompt))
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(player)
			print("[WildBrainrot] Prompt triggered by " .. player.Name)
			-- Find this brainrot's data and start battle
			for _, data in ipairs(wildBrainrots) do
				if data.Model == wildBrainrot then
					print("[WildBrainrot] Found brainrot data, starting battle")
					startBattleWithWild(player, data)
					break
				end
			end
		end)
		print("[WildBrainrot] Prompt connected for " .. modelName)
	end
	
	return wildBrainrot
end

local function spawnNearPlayer(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Check if player is in battle
	if activeBattles[player] then return end

	-- Pick a random spawn location from BrainrotsSpawn folder
	local spawnPos = Vector3.new(0, 4, 0) -- fallback
	if brainrotSpawnFolder then
		local spawnLocations = brainrotSpawnFolder:GetChildren()
		if #spawnLocations > 0 then
			local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
			spawnPos = randomSpawn.Position + Vector3.new(0, 4, 0)
		end
	end

	-- Get random brainrot from spawn config
	local spawnData = BrainrotSpawnConfig.GetRandomSpawn()
	local wildBrainrot = createWildBrainrot(spawnPos, spawnData)

	if wildBrainrot then
		table.insert(wildBrainrots, {
			Model = wildBrainrot,
			ModelName = spawnData.Name,
			SpawnTime = os.clock(),
			SpawnPosition = spawnPos,
			SpawnDuration = spawnData.SpawnDuration,
			Tier = spawnData.Tier
		})
	end
end

local function cleanupWildBrainrots()
	for i = #wildBrainrots, 1, -1 do
		local data = wildBrainrots[i]
		if not data.Model or not data.Model.Parent then
			table.remove(wildBrainrots, i)
		end
	end
end

local function despawnFarBrainrots()
	for i = #wildBrainrots, 1, -1 do
		local data = wildBrainrots[i]
		if data.Model and data.Model.Parent then
			-- Check if spawn duration has expired
			local timeAlive = os.clock() - data.SpawnTime
			local spawnDuration = data.SpawnDuration or 60 -- Default to 60 seconds
			
			if timeAlive > spawnDuration then
				data.Model:Destroy()
				table.remove(wildBrainrots, i)
				print("[WildBrainrot] Despawned " .. data.ModelName .. " (time expired)")
			else
				-- Check distance from all players
				local closestDistance = math.huge
				for _, player in Players:GetPlayers() do
					if player.Character then
						local hrp = player.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local distance = (data.Model:GetPivot().Position - hrp.Position).Magnitude
							if distance < closestDistance then
								closestDistance = distance
							end
						end
					end
				end

				if closestDistance > DESPAWN_DISTANCE then
					data.Model:Destroy()
					table.remove(wildBrainrots, i)
					print("[WildBrainrot] Despawned " .. data.ModelName .. " (too far)")
				end
			end
		end
	end
end

--------------------------------------------------
-- SPAWN LOOP
--------------------------------------------------

task.spawn(function()
	while true do
		task.wait(SPAWN_INTERVAL)

		-- Clean up invalid brainrots
		cleanupWildBrainrots()

		-- Despawn far brainrots
		despawnFarBrainrots()

		-- Spawn new brainrots if needed
		for _, player in Players:GetPlayers() do
			if not activeBattles[player] and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Count brainrots near this player
				local nearbyCount = 0
				for _, data in ipairs(wildBrainrots) do
					if data.Model and data.Model.Parent then
						local distance = (data.Model:GetPivot().Position - player.Character.HumanoidRootPart.Position).Magnitude
						if distance < SPAWN_RADIUS * 1.5 then
							nearbyCount = nearbyCount + 1
						end
					end
				end

				-- Spawn if below max
				if nearbyCount < MAX_WILD_BRAINROTS and #wildBrainrots < MAX_WILD_BRAINROTS * 2 then
					spawnNearPlayer(player)
				end
			end
		end
	end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	local battleData = activeBattles[player]
	if battleData then
		-- Clean up spawned models
		if battleData.Character and spawnedModels[battleData.Character] then
			for _, model in spawnedModels[battleData.Character] do
				if model and model.Parent then
					model:Destroy()
				end
			end
			spawnedModels[battleData.Character] = nil
		end
		unfreezePlayer(battleData)
		activeBattles[player] = nil
	end
	
	-- Clean up stored position
	playerOriginalPositions[player] = nil
end)

-- Handle player joining - spawn initial brainrots
Players.PlayerAdded:Connect(function(player)
	task.wait(3) -- Wait for character to load
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		for i = 1, 3 do
			spawnNearPlayer(player)
		end
		print("[WildBrainrot] Spawned initial brainrots for " .. player.Name)
	end
end)

-- Spawn initial brainrots for players already in game
for _, player in Players:GetPlayers() do
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		for i = 1, 3 do
			spawnNearPlayer(player)
		end
		print("[WildBrainrot] Spawned initial brainrots for " .. player.Name)
	end
end

print("[WildBrainrot] System initialized!")