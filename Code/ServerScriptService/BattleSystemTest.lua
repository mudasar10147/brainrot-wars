local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BattleSystem = require(ReplicatedStorage.Modules.BattleSystem)
local BrainrotStats = require(ReplicatedStorage.Config.BrainrotStats)
local Moves = require(ReplicatedStorage.Config.Moves)

print("=== Battle System Test Started ===")

print("\n--- Test 1: Basic Battle ---")

local playerStats = BrainrotStats.GetStats("Banana Dancana")
local enemyStats = BrainrotStats.GetStats("Pandaccini Bananini")

local playerMoves = {"Banana Slam"}
local enemyMoves = {"Bananini Spin"}

local battle = BattleSystem.NewBattle(playerStats, enemyStats, playerMoves, enemyMoves)

print("Player (Banana Dancana): HP=" .. playerStats.Health .. ", Damage=" .. playerStats.Damage .. ", Resistance=" .. playerStats.Resistance .. ", Endurance=" .. playerStats.Endurance)
print("Enemy (Pandaccini Bananini): HP=" .. enemyStats.Health .. ", Damage=" .. enemyStats.Damage .. ", Resistance=" .. enemyStats.Resistance .. ", Endurance=" .. enemyStats.Endurance)
print("Initial State: " .. BattleSystem.GetState(battle))

local success, errorMsg = BattleSystem.ExecuteMove(battle, true, "Banana Slam")
print("Player used Banana Slam: " .. tostring(success))
if not success then print("Error: " .. errorMsg) end
print("State after player move: " .. BattleSystem.GetState(battle))

success, errorMsg = BattleSystem.ExecuteMove(battle, false, "Bananini Spin")
print("Enemy used Bananini Spin: " .. tostring(success))
if not success then print("Error: " .. errorMsg) end
print("State after enemy move: " .. BattleSystem.GetState(battle))

local playerStatus = BattleSystem.GetCombatantStatus(battle, true)
local enemyStatus = BattleSystem.GetCombatantStatus(battle, false)
print("\nPlayer Status: HP=" .. playerStatus.CurrentHP .. "/" .. playerStatus.MaxHP .. ", Endurance=" .. playerStatus.CurrentEndurance .. "/" .. playerStatus.MaxEndurance)
print("Enemy Status: HP=" .. enemyStatus.CurrentHP .. "/" .. enemyStatus.MaxHP .. ", Endurance=" .. enemyStatus.CurrentEndurance .. "/" .. enemyStatus.MaxEndurance)

print("\n--- Test 2: Insufficient Endurance ---")

local battle2 = BattleSystem.NewBattle(
	{Health = 100, Damage = 20, Resistance = 5, Endurance = 5},
	{Health = 100, Damage = 20, Resistance = 5, Endurance = 50},
	{"Banana Slam"},
	{"Bananini Spin"}
)

success, errorMsg = BattleSystem.ExecuteMove(battle2, true, "Banana Slam")
print("Player tried to use Banana Slam with 5 endurance (cost 10): " .. tostring(success))
if not success then print("Expected error: " .. errorMsg) end

print("\n--- Test 3: Battle to Completion ---")

local battle3 = BattleSystem.NewBattle(
	{Health = 50, Damage = 30, Resistance = 5, Endurance = 100},
	{Health = 100, Damage = 10, Resistance = 5, Endurance = 100},
	{"Banana Slam"},
	{"Bananini Spin"}
)

print("Starting battle simulation...")

while not BattleSystem.IsBattleOver(battle3) do
	local pSuccess, pError = BattleSystem.ExecuteMove(battle3, true, "Banana Slam")
	if not pSuccess then
		print("Player error: " .. pError)
		break
	end
	
	if BattleSystem.IsBattleOver(battle3) then break end
	
	local eSuccess, eError = BattleSystem.ExecuteMove(battle3, false, "Bananini Spin")
	if not eSuccess then
		print("Enemy error: " .. eError)
		break
	end
end

print("Battle ended! State: " .. BattleSystem.GetState(battle3))

local result = BattleSystem.GetResult(battle3)
if result then
	print("Result: " .. result.Result)
	print("Turns Played: " .. result.TurnsPlayed)
	print("Player HP: " .. result.PlayerHP)
	print("Enemy HP: " .. result.EnemyHP)
end

print("\nBattle Log:")
for i, entry in ipairs(BattleSystem.GetLog(battle3)) do
	print(i .. ". " .. entry)
end

print("\n--- Test 4: Damage Formula Verification ---")

local DamageFormula = require(ReplicatedStorage.Modules.DamageFormula)

local damage1 = DamageFormula.CalculateDamage(20, 5, 1.2)
print("Damage 20, Resistance 5, Power 1.2: " .. damage1 .. " (expected: 19)")

local damage2 = DamageFormula.CalculateDamage(10, 15, 1.0)
print("Damage 10, Resistance 15, Power 1.0: " .. damage2 .. " (expected: 1, minimum)")

local damage3 = DamageFormula.CalculateDamage(30, 10, 1.5)
print("Damage 30, Resistance 10, Power 1.5: " .. damage3 .. " (expected: 35)")

print("\n=== Battle System Test Completed ===")