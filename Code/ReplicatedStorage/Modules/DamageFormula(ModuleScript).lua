local DamageFormula = {}

local Config = {
	MinimumDamage = 1,
	ResistanceEffectiveness = 1.0,
}

-- Tier-based damage multipliers (higher tier = more damage)
local TierMultipliers = {
	["Common"] = 0.30,
	["Uncommon"] = 0.45,
	["Gold"] = 0.60,
	["Boss"] = 1.00,
}

function DamageFormula.CalculateDamage(attackerDamage, defenderResistance, movePower, attackerTier)
	attackerDamage = attackerDamage or 0
	defenderResistance = defenderResistance or 0
	movePower = movePower or 1.0
	attackerTier = attackerTier or "Common"
	
	local tierMultiplier = TierMultipliers[attackerTier] or TierMultipliers["Common"]
	
	local baseDamage = attackerDamage * movePower
	local damageAfterResistance = baseDamage - (defenderResistance * Config.ResistanceEffectiveness)
	local scaledDamage = damageAfterResistance * tierMultiplier
	local finalDamage = math.max(Config.MinimumDamage, scaledDamage)
	
	return math.round(finalDamage)
end

function DamageFormula.GetTierMultiplier(tier)
	return TierMultipliers[tier] or TierMultipliers["Common"]
end

function DamageFormula.GetFormulaDescription()
	return "Damage = max(1, ((AttackerDamage × MovePower) - DefenderResistance) × TierMultiplier)"
end

function DamageFormula.GetConfig()
	return table.clone(Config)
end

return DamageFormula