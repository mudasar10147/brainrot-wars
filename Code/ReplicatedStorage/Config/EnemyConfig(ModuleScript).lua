local EnemyConfig = {
	-- Default enemy configuration
	Default = {
		Health = 90,
		Damage = 20,
		Resistance = 4,
		Endurance = 60,
		Tier = "Common",
		Moves = {"Banana Slam", "Bananini Spin"},
	},

	-- Common enemies
	["Banana Dancana"] = {
		Health = 100,
		Damage = 15,
		Resistance = 5,
		Endurance = 50,
		Tier = "Common",
		Moves = {"Banana Slam", "Quick Jab"},
	},
	["Pandaccini Bananini"] = {
		Health = 120,
		Damage = 18,
		Resistance = 6,
		Endurance = 55,
		Tier = "Common",
		Moves = {"Bananini Spin", "Heavy Hit"},
	},
	["Nyannini Cattalini"] = {
		Health = 90,
		Damage = 20,
		Resistance = 4,
		Endurance = 60,
		Tier = "Common",
		Moves = {"Cat Scratch", "Swift Attack"},
	},
	["Pipi Potato"] = {
		Health = 130,
		Damage = 12,
		Resistance = 8,
		Endurance = 45,
		Tier = "Common",
		Moves = {"Potato Smash", "Power Slam"},
	},
	["Tim Cheese"] = {
		Health = 110,
		Damage = 17,
		Resistance = 7,
		Endurance = 52,
		Tier = "Common",
		Moves = {"Cheese Throw", "Cheesy Blast"},
	},
	["Chillin Chili"] = {
		Health = 140,
		Damage = 22,
		Resistance = 9,
		Endurance = 48,
		Tier = "Common",
		Moves = {"Chili Burn", "Fire Breath"},
	},

	-- Uncommon enemies
	["Bananaccini Supremo"] = {
		Health = 200,
		Damage = 30,
		Resistance = 12,
		Endurance = 80,
		Tier = "Uncommon",
		Moves = {"Banana Slam", "Bananini Spin", "Heavy Hit"},
	},
	["Banana Nyaneroni"] = {
		Health = 185,
		Damage = 32,
		Resistance = 11,
		Endurance = 78,
		Tier = "Uncommon",
		Moves = {"Banana Slam", "Cat Scratch", "Swift Attack"},
	},
	["Bananito Potatino"] = {
		Health = 210,
		Damage = 25,
		Resistance = 14,
		Endurance = 75,
		Tier = "Uncommon",
		Moves = {"Potato Smash", "Power Slam", "Heavy Hit"},
	},
	["Pandaccini Formaggi"] = {
		Health = 195,
		Damage = 28,
		Resistance = 13,
		Endurance = 82,
		Tier = "Uncommon",
		Moves = {"Bananini Spin", "Cheese Throw", "Cheesy Blast"},
	},
	["Cattalini Chilini"] = {
		Health = 190,
		Damage = 35,
		Resistance = 10,
		Endurance = 85,
		Tier = "Uncommon",
		Moves = {"Cat Scratch", "Chili Burn", "Fire Breath"},
	},
	["Chillin Formaggino"] = {
		Health = 220,
		Damage = 33,
		Resistance = 15,
		Endurance = 80,
		Tier = "Uncommon",
		Moves = {"Chili Burn", "Cheese Throw", "Heavy Hit"},
	},

	-- Gold enemies
	["Gold Banana Dancana"] = {
		Health = 180,
		Damage = 28,
		Resistance = 10,
		Endurance = 75,
		Tier = "Gold",
		Moves = {"Banana Slam", "Quick Jab", "Heavy Hit"},
	},
	["Gold Pandaccini Bananini"] = {
		Health = 200,
		Damage = 30,
		Resistance = 11,
		Endurance = 80,
		Tier = "Gold",
		Moves = {"Bananini Spin", "Heavy Hit", "Swift Attack"},
	},
	["Gold Nyannini Cattalini"] = {
		Health = 170,
		Damage = 35,
		Resistance = 9,
		Endurance = 85,
		Tier = "Gold",
		Moves = {"Cat Scratch", "Swift Attack", "Fire Breath"},
	},
	["Gold Pipi Potato"] = {
		Health = 210,
		Damage = 22,
		Resistance = 14,
		Endurance = 70,
		Tier = "Gold",
		Moves = {"Potato Smash", "Power Slam", "Heavy Hit"},
	},
	["Gold Tim Cheese"] = {
		Health = 190,
		Damage = 30,
		Resistance = 13,
		Endurance = 78,
		Tier = "Gold",
		Moves = {"Cheese Throw", "Cheesy Blast", "Swift Attack"},
	},
	["Gold Chillin Chili"] = {
		Health = 220,
		Damage = 38,
		Resistance = 16,
		Endurance = 72,
		Tier = "Gold",
		Moves = {"Chili Burn", "Fire Breath", "Heavy Hit"},
	},
}

function EnemyConfig.GetEnemyConfig(enemyName)
	local config = EnemyConfig[enemyName]
	if not config then
		-- Return default config if enemy not found
		return EnemyConfig.Default
	end
	return config
end

function EnemyConfig.GetEnemyStats(enemyName)
	local config = EnemyConfig.GetEnemyConfig(enemyName)
	return {
		Health = config.Health,
		Damage = config.Damage,
		Resistance = config.Resistance,
		Endurance = config.Endurance,
		Tier = config.Tier,
	}
end

function EnemyConfig.GetEnemyMoves(enemyName)
	local config = EnemyConfig.GetEnemyConfig(enemyName)
	return config.Moves
end

return EnemyConfig