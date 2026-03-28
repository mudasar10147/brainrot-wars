local BattleResult = {}

BattleResult.ResultType = {
	Win = "Win",
	Lose = "Lose",
	Draw = "Draw"
}

function BattleResult.New(result, turnsPlayed, playerHP, enemyHP, rewards)
	return {
		Result = result,
		TurnsPlayed = turnsPlayed or 0,
		PlayerHP = playerHP or 0,
		EnemyHP = enemyHP or 0,
		Rewards = rewards or {},
		Timestamp = os.time()
	}
end

function BattleResult.IsWin(result)
	return result and result.Result == BattleResult.ResultType.Win
end

function BattleResult.IsLose(result)
	return result and result.Result == BattleResult.ResultType.Lose
end

function BattleResult.IsDraw(result)
	return result and result.Result == BattleResult.ResultType.Draw
end

function BattleResult.GetRewards(result)
	return result and result.Rewards or {}
end

function BattleResult.Format(result)
	if not result then return "No result" end
	
	return string.format(
		"%s after %d turns (Player HP: %d, Enemy HP: %d)",
		result.Result,
		result.TurnsPlayed,
		result.PlayerHP,
		result.EnemyHP
	)
end

return BattleResult