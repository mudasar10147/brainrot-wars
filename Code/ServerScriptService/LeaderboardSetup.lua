local Players = game:GetService("Players")
local PlayerDataManager = require(game.ServerScriptService.Data.PlayerDataManager)
local RunService = game:GetService("RunService")

print("[LeaderboardSetup] Module loaded")

-- DEBOUNCE SYSTEM (STOPS SPAM)
local updateDebounce = {} -- player.UserId -> last update time
local UPDATE_COOLDOWN = 2 -- Update max every 2 seconds

local function canUpdate(player)
	local now = tick()
	local userId = player.UserId
	if not updateDebounce[userId] or now - updateDebounce[userId] >= UPDATE_COOLDOWN then
		updateDebounce[userId] = now
		return true
	end
	return false
end

local function updateLeaderboard(player)
	-- 🛡️ DEBOUNCE CHECK - NO MORE SPAM!
	if not canUpdate(player) then
		return
	end

	local data = PlayerDataManager:Get(player)
	if not data then
		warn("[LeaderboardSetup] No data found for " .. player.Name)
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local function getStat(name, class)
		local stat = leaderstats:FindFirstChild(name)
		if not stat then
			stat = Instance.new(class)
			stat.Name = name
			stat.Parent = leaderstats
		end
		return stat
	end

	-- Safe nil checks
	getStat("Gold",         "IntValue").Value  = data.Gold or 0
	getStat("Diamonds",     "IntValue").Value  = data.Diamonds or 0
	getStat("Inventory",    "IntValue").Value  = data.Inventory and #data.Inventory or 0
	getStat("Equipped",     "IntValue").Value  = data.Equipped and #data.Equipped or 0
	getStat("StarterChosen","BoolValue").Value = data.HasChosenStarter or false

	-- 🛡️ REDUCE LOG SPAM - Only log on significant changes
	local gold = data.Gold or 0
	local invSize = data.Inventory and #data.Inventory or 0
	print("[LeaderboardSetup] Updated stats for " .. player.Name ..
		" | Gold:" .. gold ..
		" | Inv:" .. invSize ..
		" | Starter:" .. tostring(data.HasChosenStarter))
end

local function setupLeaderboard(player)
	-- Initial setup only
	if player:FindFirstChild("leaderstats") then return end

	player.CharacterAdded:Connect(function()
		task.wait(1)
		updateLeaderboard(player)
	end)
end

local heartbeatConnection
heartbeatConnection = RunService.Heartbeat:Connect(function()
	for _, player in pairs(Players:GetPlayers()) do
		if PlayerDataManager:Get(player) then
			updateLeaderboard(player) -- Debounced inside function
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	print("[LeaderboardSetup] " .. player.Name .. " joined")

	local data
	local attempts = 0
	repeat
		task.wait(0.5)
		attempts += 1
		data = PlayerDataManager:Get(player)
	until data or attempts >= 40

	if not data then
		warn("[LeaderboardSetup] Data never loaded for " .. player.Name)
		return
	end

	print("[LeaderboardSetup] Data ready for " .. player.Name)
	setupLeaderboard(player)
	updateLeaderboard(player) -- Initial update

	player.CharacterAdded:Wait()
	task.wait(0.5)
	updateLeaderboard(player)
end)

-- Cleanup existing players
for _, player in pairs(Players:GetPlayers()) do
	setupLeaderboard(player)
	updateLeaderboard(player)
end

-- CLEANUP ON PLAYER LEAVE
Players.PlayerRemoving:Connect(function(player)
	updateDebounce[player.UserId] = nil
end)

-- CLEANUP ON SCRIPT END
game:BindToClose(function()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
	end
end)