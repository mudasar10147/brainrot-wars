local BattleConfig = {}

BattleConfig.Settings = {
	Endurance = {
		RefillOnTurnEnd = true,
		RefillAmount = 10,
		MinimumCost = 5,
		MaximumCost = 50,
		MinimumFloor = 15, -- Minimum endurance to prevent being stuck
	},
	
	Damage = {
		MinimumDamage = 1,
		ResistanceEffectiveness = 1.0,
		CriticalHitChance = 0.0,
		CriticalHitMultiplier = 1.5,
	},
	
	Turn = {
		MaximumTurns = 100,
		TurnTimeout = 30,
	},
	
	Result = {
		RewardsEnabled = true,
		WinGold = 40,
		WinDiamonds = 3,
		GoldPickupCount = 8,
		DiamondPickupCount = 3,
		LootScatterRadius = 12,
		LootHeightOffset = 2,
		BrainrotDropChance = 0.25,
		BrainrotDropPool = {},
		UseEnemyBrainrotForDrop = true,
		DefaultWinRewards = {},
		DefaultLoseRewards = {},
	},
}

function BattleConfig.GetSetting(category, key)
	if BattleConfig.Settings[category] then
		return BattleConfig.Settings[category][key]
	end
	return nil
end

function BattleConfig.GetCategory(category)
	return BattleConfig.Settings[category]
end

function BattleConfig.GetAllSettings()
	return BattleConfig.Settings
end

function BattleConfig.SetSetting(category, key, value)
	if BattleConfig.Settings[category] then
		BattleConfig.Settings[category][key] = value
	end
end

return BattleConfig