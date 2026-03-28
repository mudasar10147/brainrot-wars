-- Win rewards: scatter gold/diamond pickups in arena; grant brainrot after all collected.
-- Entry: BattleRewardService.StartWinRewardPhase(player, battleData, onArenaExitComplete)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattleConfig = require(ReplicatedStorage.Config.BattleConfig)
local Brainrots = require(ReplicatedStorage.Modules.Brainrots.Brainrots)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local DataStoreHandler = require(script.Parent.Parent.Data.DataStoreServiceHandler)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getRemote(name, className)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = Remotes
	end
	return r
end

local UpdateCurrency = getRemote("UpdateCurrency", "RemoteEvent")
local BattleRewardsSummary = getRemote("BattleRewardsSummary", "RemoteEvent")

local BattleRewardService = {}

local pendingByPlayer = {}
local lootPartsByUserId = {}

local function getResultSettings()
	local cat = BattleConfig.GetCategory("Result")
	return cat or {}
end

local function getOrCreateLootFolder()
	local f = workspace:FindFirstChild("BattleLoot")
	if not f then
		f = Instance.new("Folder")
		f.Name = "BattleLoot"
		f.Parent = workspace
	end
	return f
end

local function splitAmount(total, pieces)
	local out = {}
	if pieces <= 0 or total <= 0 then
		return out
	end
	local base = math.floor(total / pieces)
	local rem = total - base * pieces
	for i = 1, pieces do
		local n = base + (i <= rem and 1 or 0)
		if n > 0 then
			table.insert(out, n)
		end
	end
	return out
end

local function pickBrainrotId(settings, enemyBrainrotName)
	local raw = nil
	if settings.UseEnemyBrainrotForDrop and enemyBrainrotName and enemyBrainrotName ~= "" then
		raw = enemyBrainrotName
	else
		local pool = settings.BrainrotDropPool
		if type(pool) == "table" and #pool > 0 then
			raw = pool[math.random(1, #pool)]
		elseif enemyBrainrotName and enemyBrainrotName ~= "" then
			raw = enemyBrainrotName
		end
	end
	if not raw or raw == "" then
		return nil
	end
	local resolved = Brainrots.ResolveInventoryId(raw)
	if resolved then
		return resolved
	end
	warn("[BattleRewardService] No Brainrots catalog match for capture id: " .. tostring(raw))
	return nil
end

local function computeBrainrotRoll(settings, battleData)
	local enemyName = battleData and battleData.EnemyBrainrotName or nil
	local brainrotId = pickBrainrotId(settings, enemyName)
	local chance = tonumber(settings.BrainrotDropChance) or 0
	local rollSuccess = chance > 0 and math.random() < chance and brainrotId ~= nil
	return rollSuccess, brainrotId
end

local function tryGrantRolledBrainrot(player, rollSuccess, brainrotId)
	local granted, invFull = false, false
	if rollSuccess and brainrotId then
		local ok, msg = InventoryService:AddBrainrot(player, brainrotId)
		granted = ok and true or false
		if not ok and msg == "Inventory full!" then
			invFull = true
		end
	end
	return granted, invFull
end

local function sendBattleRewardsSummary(player, goldTotal, diaTotal, rollSuccess, brainrotId, granted, invFull)
	DataStoreHandler:SaveData(player)
	UpdateCurrency:FireClient(player, CurrencyService:GetCurrency(player))
	local dropEligible = brainrotId ~= nil
	BattleRewardsSummary:FireClient(player, {
		Gold = goldTotal,
		Diamonds = diaTotal,
		BrainrotId = rollSuccess and brainrotId or nil,
		BrainrotGranted = granted,
		InventoryFull = invFull,
		RollSucceeded = rollSuccess,
		DropEligible = dropEligible,
	})
end

-- Clones ReplicatedStorage.Valuables.GoldValuable / DiamondValuable (Part or Model).
local function getValuableTemplates()
	local folder = ReplicatedStorage:FindFirstChild("Valuables")
	if not folder then
		return nil, nil
	end
	return folder:FindFirstChild("GoldValuable"), folder:FindFirstChild("DiamondValuable")
end

local function applyLootAttributes(root, owner, kind, amount)
	root:SetAttribute("BattleLoot", true)
	root:SetAttribute("OwnerUserId", owner.UserId)
	root:SetAttribute("LootKind", kind)
	root:SetAttribute("LootAmount", amount)
end

local function positionValuableClone(clone, position)
	if clone:IsA("Model") then
		local ok = pcall(function()
			clone:PivotTo(CFrame.new(position))
		end)
		if not ok and clone.PrimaryPart then
			clone:SetPrimaryPartCFrame(CFrame.new(position))
		end
	elseif clone:IsA("BasePart") then
		clone.Position = position
	end
end

local function prepareClonePhysics(clone)
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = true
		end
	end
end

--- Returns the loot root (clone) to track and destroy.
local function createPickupFromValuableTemplate(owner, position, kind, amount, goldTemplate, diamondTemplate)
	local template = (kind == "Diamond") and diamondTemplate or goldTemplate
	if not template then
		return nil
	end

	local clone = template:Clone()
	clone.Name = "BattleLoot_" .. kind .. "_" .. tostring(amount)
	applyLootAttributes(clone, owner, kind, amount)
	prepareClonePhysics(clone)
	positionValuableClone(clone, position)
	clone.Parent = getOrCreateLootFolder()
	return clone
end

local function createFallbackPickupPart(owner, position, kind, amount)
	local p = Instance.new("Part")
	p.Name = "BattleLootPickup"
	p.Size = Vector3.new(1.4, 0.45, 1.4)
	p.Anchored = false
	p.CanCollide = true
	p.Material = Enum.Material.Neon
	if kind == "Diamond" then
		p.Color = Color3.fromRGB(120, 200, 255)
	else
		p.Color = Color3.fromRGB(255, 215, 80)
	end
	applyLootAttributes(p, owner, kind, amount)
	p.Position = position
	p.Parent = getOrCreateLootFolder()
	return p
end

local function findLootRootFromTouchedPart(hitPart)
	local current = hitPart
	while current do
		if current:GetAttribute("BattleLoot") then
			return current
		end
		current = current.Parent
	end
	return nil
end

function BattleRewardService.ClearPlayerLoot(player)
	local uid = player.UserId
	local list = lootPartsByUserId[uid]
	if list then
		for _, inst in ipairs(list) do
			if inst and inst.Parent then
				inst:Destroy()
			end
		end
	end
	lootPartsByUserId[uid] = nil
	pendingByPlayer[player] = nil
end

function BattleRewardService.StartWinRewardPhase(player, battleData, onArenaExitComplete)
	local settings = getResultSettings()
	if not settings.RewardsEnabled then
		local goldTotal = math.max(0, math.floor(settings.WinGold or 0))
		local diaTotal = math.max(0, math.floor(settings.WinDiamonds or 0))
		if goldTotal > 0 then
			CurrencyService:AddGold(player, goldTotal)
		end
		if diaTotal > 0 then
			CurrencyService:AddDiamonds(player, diaTotal)
		end
		local rollSuccess, brainrotId = computeBrainrotRoll(settings, battleData)
		local granted, invFull = tryGrantRolledBrainrot(player, rollSuccess, brainrotId)
		sendBattleRewardsSummary(player, goldTotal, diaTotal, rollSuccess, brainrotId, granted, invFull)
		onArenaExitComplete(player)
		return
	end

	local goldTotal = math.max(0, math.floor(settings.WinGold or 0))
	local diaTotal = math.max(0, math.floor(settings.WinDiamonds or 0))
	local rollSuccess, brainrotId = computeBrainrotRoll(settings, battleData)

	local battleSpawn = workspace:FindFirstChild("BattleSpawn")
	if not battleSpawn or not battleSpawn:IsA("BasePart") then
		warn("[BattleRewardService] No BattleSpawn; granting win currency + brainrot roll without scatter.")
		if goldTotal > 0 then
			CurrencyService:AddGold(player, goldTotal)
		end
		if diaTotal > 0 then
			CurrencyService:AddDiamonds(player, diaTotal)
		end
		local granted, invFull = tryGrantRolledBrainrot(player, rollSuccess, brainrotId)
		sendBattleRewardsSummary(player, goldTotal, diaTotal, rollSuccess, brainrotId, granted, invFull)
		onArenaExitComplete(player)
		return
	end

	local goldPieces = math.max(1, math.floor(settings.GoldPickupCount or 8))
	local diaPieces = math.max(1, math.floor(settings.DiamondPickupCount or 3))
	local radius = settings.LootScatterRadius or 12
	local yOff = settings.LootHeightOffset or 2

	local goldSplits = splitAmount(goldTotal, goldPieces)
	local diaSplits = splitAmount(diaTotal, diaPieces)

	local pickupsRemaining = #goldSplits + #diaSplits

	local function grantBrainrotAndNotify(pend)
		local granted, invFull = tryGrantRolledBrainrot(player, pend.RollSuccess, pend.BrainrotId)
		sendBattleRewardsSummary(player, pend.GoldTotal, pend.DiamondTotal, pend.RollSuccess, pend.BrainrotId, granted, invFull)
	end

	if pickupsRemaining == 0 then
		if goldTotal > 0 then
			CurrencyService:AddGold(player, goldTotal)
		end
		if diaTotal > 0 then
			CurrencyService:AddDiamonds(player, diaTotal)
		end
		grantBrainrotAndNotify({
			RollSuccess = rollSuccess,
			BrainrotId = brainrotId,
			GoldTotal = goldTotal,
			DiamondTotal = diaTotal,
		})
		onArenaExitComplete(player)
		return
	end

	lootPartsByUserId[player.UserId] = {}
	local center = battleSpawn.Position + Vector3.new(0, yOff, 0)

	local function scatterPos(i, n)
		local ang = (i / math.max(n, 1)) * math.pi * 2 + math.random() * 0.25
		local r = radius * (0.45 + math.random() * 0.55)
		return center + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
	end

	local goldTemplate, diamondTemplate = getValuableTemplates()
	if not goldTemplate or not diamondTemplate then
		warn("[BattleRewardService] Missing ReplicatedStorage.Valuables.GoldValuable and/or DiamondValuable; using fallback Parts.")
	end

	local idx = 0
	local totalN = #goldSplits + #diaSplits
	for _, amt in ipairs(goldSplits) do
		idx += 1
		local pos = scatterPos(idx, totalN)
		local root = createPickupFromValuableTemplate(player, pos, "Gold", amt, goldTemplate, diamondTemplate)
			or createFallbackPickupPart(player, pos, "Gold", amt)
		table.insert(lootPartsByUserId[player.UserId], root)
	end
	for _, amt in ipairs(diaSplits) do
		idx += 1
		local pos = scatterPos(idx, totalN)
		local root = createPickupFromValuableTemplate(player, pos, "Diamond", amt, goldTemplate, diamondTemplate)
			or createFallbackPickupPart(player, pos, "Diamond", amt)
		table.insert(lootPartsByUserId[player.UserId], root)
	end

	local pend = {
		Remaining = pickupsRemaining,
		RollSuccess = rollSuccess,
		BrainrotId = brainrotId,
		GoldTotal = goldTotal,
		DiamondTotal = diaTotal,
		OnExit = onArenaExitComplete,
	}
	pendingByPlayer[player] = pend

	local touchDebounce = {}

	local function tryCollect(lootRoot, other)
		if not lootRoot or not lootRoot.Parent then
			return
		end
		local char = other.Parent
		if not char or not char:IsA("Model") then
			return
		end
		local plr = Players:GetPlayerFromCharacter(char)
		if plr ~= player then
			return
		end
		if lootRoot:GetAttribute("OwnerUserId") ~= player.UserId then
			return
		end
		if not lootRoot:GetAttribute("BattleLoot") then
			return
		end

		local now = tick()
		local last = touchDebounce[lootRoot]
		if last and now - last < 0.35 then
			return
		end
		touchDebounce[lootRoot] = now

		local p = pendingByPlayer[player]
		if not p then
			return
		end

		local kind = lootRoot:GetAttribute("LootKind")
		local amount = tonumber(lootRoot:GetAttribute("LootAmount")) or 0
		if amount <= 0 then
			return
		end

		if kind == "Gold" then
			CurrencyService:AddGold(player, amount)
		elseif kind == "Diamond" then
			CurrencyService:AddDiamonds(player, amount)
		end

		UpdateCurrency:FireClient(player, CurrencyService:GetCurrency(player))
		lootRoot:Destroy()

		p.Remaining -= 1
		DataStoreHandler:SaveData(player)

		if p.Remaining > 0 then
			return
		end

		grantBrainrotAndNotify(p)
		BattleRewardService.ClearPlayerLoot(player)
		local exitCb = p.OnExit
		pendingByPlayer[player] = nil
		if exitCb then
			exitCb(player)
		end
	end

	local function hookTouches(root)
		local function onTouched(hitPart, other)
			local lootRoot = findLootRootFromTouchedPart(hitPart)
			if lootRoot then
				tryCollect(lootRoot, other)
			end
		end
		if root:IsA("BasePart") then
			root.Touched:Connect(function(other)
				onTouched(root, other)
			end)
		else
			for _, d in root:GetDescendants() do
				if d:IsA("BasePart") then
					d.Touched:Connect(function(other)
						onTouched(d, other)
					end)
				end
			end
		end
	end

	for _, root in ipairs(lootPartsByUserId[player.UserId]) do
		hookTouches(root)
	end
end

Players.PlayerRemoving:Connect(function(player)
	BattleRewardService.ClearPlayerLoot(player)
end)

return BattleRewardService
