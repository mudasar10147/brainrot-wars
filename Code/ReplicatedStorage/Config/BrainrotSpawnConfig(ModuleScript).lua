local BrainrotSpawnConfig = {}

-- Spawn settings
BrainrotSpawnConfig.Settings = {
    SpawnCheckInterval = 10,
    MaxSpawnedBrainrots = 5,
    InteractDistance = 15,
    DespawnDistance = 100,
}

-- Define brainrots that can spawn on the map
BrainrotSpawnConfig.SpawnList = {
    -- Common tier
    {Name = "Banana Dancana", Tier = "Common", SpawnDuration = 60},
    {Name = "Pandaccini Bananini", Tier = "Common", SpawnDuration = 60},
    {Name = "Nyannini Cattalini", Tier = "Common", SpawnDuration = 60},
    {Name = "Pipi Potato", Tier = "Common", SpawnDuration = 60},
    {Name = "Tim Cheese", Tier = "Common", SpawnDuration = 60},
    {Name = "Chillin Chili", Tier = "Common", SpawnDuration = 60},
    
    -- Uncommon tier
    {Name = "Bananaccini Supremo", Tier = "Uncommon", SpawnDuration = 45},
    {Name = "Banana Nyaneroni", Tier = "Uncommon", SpawnDuration = 45},
    {Name = "Bananito Potatino", Tier = "Uncommon", SpawnDuration = 45},
    {Name = "Pandaccini Formaggi", Tier = "Uncommon", SpawnDuration = 45},
    {Name = "Cattalini Chilini", Tier = "Uncommon", SpawnDuration = 45},
    {Name = "Chillin Formaggino", Tier = "Uncommon", SpawnDuration = 45},
    
    -- Gold tier
    {Name = "Gold Banana Dancana", Tier = "Gold", SpawnDuration = 30},
    {Name = "Gold Pandaccini Bananini", Tier = "Gold", SpawnDuration = 30},
    {Name = "Gold Nyannini Cattalini", Tier = "Gold", SpawnDuration = 30},
    {Name = "Gold Pipi Potato", Tier = "Gold", SpawnDuration = 30},
    {Name = "Gold Tim Cheese", Tier = "Gold", SpawnDuration = 30},
    {Name = "Gold Chillin Chili", Tier = "Gold", SpawnDuration = 30},
}

BrainrotSpawnConfig.TierWeights = {
    ["Common"] = 60,
    ["Uncommon"] = 30,
    ["Gold"] = 10,
}

function BrainrotSpawnConfig.GetRandomSpawn()
    local totalWeight = 0
    for _, spawnData in ipairs(BrainrotSpawnConfig.SpawnList) do
        local weight = BrainrotSpawnConfig.TierWeights[spawnData.Tier] or 1
        totalWeight = totalWeight + weight
    end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for _, spawnData in ipairs(BrainrotSpawnConfig.SpawnList) do
        local weight = BrainrotSpawnConfig.TierWeights[spawnData.Tier] or 1
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return spawnData
        end
    end
    
    return BrainrotSpawnConfig.SpawnList[1]
end

function BrainrotSpawnConfig.GetByTier(tier)
    local result = {}
    for _, spawnData in ipairs(BrainrotSpawnConfig.SpawnList) do
        if spawnData.Tier == tier then
            table.insert(result, spawnData)
        end
    end
    return result
end

function BrainrotSpawnConfig.GetByName(name)
    for _, spawnData in ipairs(BrainrotSpawnConfig.SpawnList) do
        if spawnData.Name == name then
            return spawnData
        end
    end
    return nil
end

return BrainrotSpawnConfig