local DamageFormula = require(script.Parent.DamageFormula)
local BattleResult = require(script.Parent.BattleResult)
local Moves = require(game.ReplicatedStorage.Config.Moves)

local BattleSystem = {}

BattleSystem.States = {
	PlayerTurn = "PlayerTurn",
	EnemyTurn = "EnemyTurn",
	Resolving = "Resolving",
	Win = "Win",
	Lose = "Lose",
	Draw = "Draw"
}

function BattleSystem.NewBattle(playerStats, enemyStats, playerMoves, enemyMoves)
	local battle = {
		PlayerStats = playerStats,
		EnemyStats = enemyStats,
		PlayerMoves = playerMoves or {},
		EnemyMoves = enemyMoves or {},
		CurrentState = BattleSystem.States.PlayerTurn,
		TurnCount = 0,
		PlayerCurrentHP = playerStats.Health,
		EnemyCurrentHP = enemyStats.Health,
		PlayerCurrentEndurance = playerStats.Endurance,
		EnemyCurrentEndurance = enemyStats.Endurance,
		BattleLog = {},
		Result = nil
	}
	
	BattleSystem.AddLog(battle, "Battle started!")
	return battle
end

function BattleSystem.GetState(battle)
	return battle.CurrentState
end

function BattleSystem.SetState(battle, newState)
	battle.CurrentState = newState
end

function BattleSystem.IsBattleOver(battle)
	local isOver = battle.CurrentState == BattleSystem.States.Win or
	       battle.CurrentState == BattleSystem.States.Lose or
	       battle.CurrentState == BattleSystem.States.Draw
	if isOver then
		print("[BattleSystem] IsBattleOver = true, CurrentState = " .. tostring(battle.CurrentState))
	end
	return isOver
end

function BattleSystem.GetResult(battle)
	print("[BattleSystem] GetResult called, Result = " .. tostring(battle.Result))
	if battle.Result then
		print("[BattleSystem] Result.Result = " .. tostring(battle.Result.Result))
	end
	return battle.Result
end

function BattleSystem.GetCombatantStatus(battle, isPlayer)
	if isPlayer then
		return {
			CurrentHP = battle.PlayerCurrentHP,
			MaxHP = battle.PlayerStats.Health,
			CurrentEndurance = battle.PlayerCurrentEndurance,
			MaxEndurance = battle.PlayerStats.Endurance,
			Moves = battle.PlayerMoves
		}
	else
		return {
			CurrentHP = battle.EnemyCurrentHP,
			MaxHP = battle.EnemyStats.Health,
			CurrentEndurance = battle.EnemyCurrentEndurance,
			MaxEndurance = battle.EnemyStats.Endurance,
			Moves = battle.EnemyMoves
		}
	end
end

function BattleSystem.GetLog(battle)
	return battle.BattleLog
end

function BattleSystem.AddLog(battle, entry)
	table.insert(battle.BattleLog, entry)
end

-- Endurance regeneration settings
local ENDURANCE_REGEN_PER_TURN = 10 -- Regenerate this much endurance each turn
local MIN_ENDURANCE_FLOOR = 15 -- Minimum endurance to prevent being stuck

function BattleSystem.ExecuteMove(battle, isPlayer, moveName)
	if BattleSystem.IsBattleOver(battle) then
		return false, "Battle is already over"
	end
	
	local expectedState = isPlayer and BattleSystem.States.PlayerTurn or BattleSystem.States.EnemyTurn
	if battle.CurrentState ~= expectedState then
		return false, "Not your turn"
	end
	
	local moveData = Moves[moveName]
	if not moveData then
		return false, "Move not found: " .. moveName
	end
	
	local attackerStats = isPlayer and battle.PlayerStats or battle.EnemyStats
	local defenderStats = isPlayer and battle.EnemyStats or battle.PlayerStats
	local attackerEndurance = isPlayer and battle.PlayerCurrentEndurance or battle.EnemyCurrentEndurance
	
	if attackerEndurance < moveData.EnduranceCost then
		return false, "Not enough endurance for " .. moveName
	end
	
	local availableMoves = isPlayer and battle.PlayerMoves or battle.EnemyMoves
	local moveAvailable = false
	for _, availableMove in ipairs(availableMoves) do
		if availableMove == moveName then
			moveAvailable = true
			break
		end
	end
	if not moveAvailable then
		return false, "Move not available: " .. moveName
	end
	
	battle.CurrentState = BattleSystem.States.Resolving
	
	if isPlayer then
		battle.PlayerCurrentEndurance = battle.PlayerCurrentEndurance - moveData.EnduranceCost
	else
		battle.EnemyCurrentEndurance = battle.EnemyCurrentEndurance - moveData.EnduranceCost
	end
	
	local damage = DamageFormula.CalculateDamage(
		attackerStats.Damage,
		defenderStats.Resistance,
		moveData.Power,
		attackerStats.Tier
	)
	
	if isPlayer then
		battle.EnemyCurrentHP = math.max(0, battle.EnemyCurrentHP - damage)
		BattleSystem.AddLog(battle, string.format("Player used %s and dealt %d damage!", moveName, damage))
	else
		battle.PlayerCurrentHP = math.max(0, battle.PlayerCurrentHP - damage)
		BattleSystem.AddLog(battle, string.format("Enemy used %s and dealt %d damage!", moveName, damage))
	end
	
	if battle.PlayerCurrentHP <= 0 and battle.EnemyCurrentHP <= 0 then
		battle.CurrentState = BattleSystem.States.Draw
		battle.Result = BattleResult.New(
			BattleResult.ResultType.Draw,
			battle.TurnCount,
			battle.PlayerCurrentHP,
			battle.EnemyCurrentHP
		)
		BattleSystem.AddLog(battle, "Battle ended in a draw!")
		return true
	elseif battle.EnemyCurrentHP <= 0 then
		-- Enemy HP is 0 - PLAYER WINS
		print("[BattleSystem] Enemy HP is 0! Player wins!")
		battle.CurrentState = BattleSystem.States.Win
		battle.Result = BattleResult.New(
			BattleResult.ResultType.Win,
			battle.TurnCount,
			battle.PlayerCurrentHP,
			battle.EnemyCurrentHP
		)
		print("[BattleSystem] Result created: " .. tostring(battle.Result) .. ", Result.Result = " .. tostring(battle.Result and battle.Result.Result))
		BattleSystem.AddLog(battle, "Player won! Enemy defeated!")
		return true
	elseif battle.PlayerCurrentHP <= 0 then
		-- Player HP is 0 - PLAYER LOSES
		battle.CurrentState = BattleSystem.States.Lose
		battle.Result = BattleResult.New(
			BattleResult.ResultType.Lose,
			battle.TurnCount,
			battle.PlayerCurrentHP,
			battle.EnemyCurrentHP
		)
		BattleSystem.AddLog(battle, "Player lost! Defeated by enemy!")
		return true
	end
	
	if isPlayer then
		battle.CurrentState = BattleSystem.States.EnemyTurn
		-- Regenerate endurance after player turn (partial regen)
		battle.PlayerCurrentEndurance = math.min(battle.PlayerStats.Endurance, battle.PlayerCurrentEndurance + ENDURANCE_REGEN_PER_TURN)
	else
		battle.CurrentState = BattleSystem.States.PlayerTurn
		battle.TurnCount = battle.TurnCount + 1
		-- Regenerate endurance after enemy turn
		battle.PlayerCurrentEndurance = math.min(battle.PlayerStats.Endurance, battle.PlayerCurrentEndurance + ENDURANCE_REGEN_PER_TURN)
		battle.EnemyCurrentEndurance = math.min(battle.EnemyStats.Endurance, battle.EnemyCurrentEndurance + ENDURANCE_REGEN_PER_TURN)
	end
	
	-- Ensure minimum endurance floor to prevent being stuck
	battle.PlayerCurrentEndurance = math.max(battle.PlayerCurrentEndurance, MIN_ENDURANCE_FLOOR)
	battle.EnemyCurrentEndurance = math.max(battle.EnemyCurrentEndurance, MIN_ENDURANCE_FLOOR)
	
	return true
end

function BattleSystem.GetTurnCount(battle)
	return battle.TurnCount
end

function BattleSystem.CheckEnduranceDraw(battle)
	-- Check if BOTH combatants have no endurance left (not just one)
	if battle.PlayerCurrentEndurance <= 0 and battle.EnemyCurrentEndurance <= 0 then
		battle.CurrentState = BattleSystem.States.Draw
		battle.Result = BattleResult.New(
			BattleResult.ResultType.Draw,
			battle.TurnCount,
			battle.PlayerCurrentHP,
			battle.EnemyCurrentHP
		)
		if battle.PlayerCurrentEndurance <= 0 and battle.EnemyCurrentEndurance <= 0 then
			BattleSystem.AddLog(battle, "Both combatants ran out of endurance! Battle ended in a draw!")
		elseif battle.PlayerCurrentEndurance <= 0 then
			BattleSystem.AddLog(battle, "You ran out of endurance! Battle ended in a draw!")
		else
			BattleSystem.AddLog(battle, "Enemy ran out of endurance! Battle ended in a draw!")
		end
		return true
	end
	return false
end

return BattleSystem