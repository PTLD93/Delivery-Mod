FISHING_CONFIG = {
    biteTimeMin   = 15,   -- minimum seconds to wait for a bite
    biteTimeMax   = 60,   -- maximum seconds to wait for a bite
    baitPrice     = 10,   -- cost of one bait from the NPC
    rodPrice      = 100,  -- cost of the fishing rod from the NPC
    maxBait       = 5,    -- max bait slots on a rod at once
}

FISHING_FISH = {
    { label = "Carp",        model = "models/props/CS_militia/fishriver01.mdl", rarity = 40, value = 20  },
    { label = "Perch",       model = "models/props/CS_militia/fishriver01.mdl", rarity = 30, value = 25  },
    { label = "Bass",        model = "models/props/CS_militia/fishriver01.mdl", rarity = 15, value = 60  },
    { label = "Trout",       model = "models/props/CS_militia/fishriver01.mdl", rarity = 10, value = 80  },
    { label = "Salmon",      model = "models/props/CS_militia/fishriver01.mdl", rarity = 3,  value = 150 },
    { label = "Pike",        model = "models/props/CS_militia/fishriver01.mdl", rarity = 2,  value = 200 },
    { label = "Golden Fish", model = "models/props/CS_militia/fishriver01.mdl", rarity = 1,  value = 500 },
}

-- weighted random fish picker
function FISHING_GetRandomFish()
    local totalWeight = 0
    for _, fish in ipairs(FISHING_FISH) do
        totalWeight = totalWeight + fish.rarity
    end

    local roll = math.random(1, totalWeight)
    local current = 0
    for _, fish in ipairs(FISHING_FISH) do
        current = current + fish.rarity
        if roll <= current then
            return fish
        end
    end

    return FISHING_FISH[1]
end