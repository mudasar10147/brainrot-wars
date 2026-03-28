-- World pickups under workspace.Valuables — same economy path as battle loot (CurrencyService + save).
-- On each valuable root (Part or Model), set:
--   LootKind = "Gold" | "Diamond"   (preferred; matches BattleRewardService)
--   Type = "Gold" | "Diamond"       (legacy alias)
--   LootAmount or Amount            (optional; defaults from GameConfig)

local ValuablesSystem = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local ValuablesService = require(script.Parent.Parent.Services.ValuablesService)
local CurrencyService = require(script.Parent.Parent.Services.CurrencyService)
local DataStoreHandler = require(script.Parent.Parent.Data.DataStoreServiceHandler)

local function getRemote(remotes, name, className)
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local function getKind(root)
	local k = root:GetAttribute("LootKind") or root:GetAttribute("Type")
	if type(k) == "string" then
		return k
	end
	return nil
end

local function getAmountForKind(root, kind)
	local attr = root:GetAttribute("LootAmount") or root:GetAttribute("Amount")
	local n = tonumber(attr)
	if n and n > 0 then
		return math.floor(n)
	end
	if kind == "Gold" then
		return math.max(0, math.floor(GameConfig.WorldValuableGoldAmount or 10))
	elseif kind == "Diamond" then
		return math.max(0, math.floor(GameConfig.WorldValuableDiamondAmount or 5))
	end
	return 0
end

local function getWorldPosition(root)
	if root:IsA("Model") then
		local ok, pivot = pcall(function()
			return root:GetPivot()
		end)
		if ok and pivot then
			return pivot.Position
		end
		local pp = root.PrimaryPart
		if pp then
			return pp.Position
		end
	end
	if root:IsA("BasePart") then
		return root.Position
	end
	return Vector3.zero
end

function ValuablesSystem.Init()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local UpdateCurrency = getRemote(Remotes, "UpdateCurrency", "RemoteEvent")
	local ValuableCollected = getRemote(Remotes, "ValuableCollected", "RemoteEvent")

	local okFolder, ValuablesFolder = pcall(function()
		return workspace:WaitForChild("Valuables", 15)
	end)
	if not okFolder or not ValuablesFolder then
		warn("[ValuablesSystem] workspace.Valuables not found; world valuables disabled.")
		return
	end

	local function connectValuableRoot(root)
		if root:GetAttribute("ValuableConnected") then
			return
		end
		root:SetAttribute("ValuableConnected", true)

		local collected = false

		local function onTouched(_hitPart, other)
			if collected then
				return
			end
			local char = other.Parent
			if not char or not char:IsA("Model") then
				return
			end
			local plr = Players:GetPlayerFromCharacter(char)
			if not plr then
				return
			end

			local kind = getKind(root)
			if kind ~= "Gold" and kind ~= "Diamond" then
				return
			end

			local amount = getAmountForKind(root, kind)
			if amount <= 0 then
				return
			end

			collected = true

			local pos = getWorldPosition(root)

			if kind == "Gold" then
				CurrencyService:AddGold(plr, amount)
			else
				CurrencyService:AddDiamonds(plr, amount)
			end

			ValuablesService.DestroyCoin(root)

			UpdateCurrency:FireClient(plr, CurrencyService:GetCurrency(plr))
			ValuableCollected:FireClient(plr, pos, kind, amount)

			DataStoreHandler:SaveData(plr)
		end

		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				d.Touched:Connect(function(other)
					onTouched(d, other)
				end)
			end
		end
	end

	for _, child in ValuablesFolder:GetChildren() do
		connectValuableRoot(child)
	end

	ValuablesFolder.ChildAdded:Connect(function(child)
		connectValuableRoot(child)
	end)
end

return ValuablesSystem
