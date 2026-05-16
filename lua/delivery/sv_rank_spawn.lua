RANK_NPC_REFRESHING = false

local function SpawnRankNPC(id, pos, ang)
    local npc = ents.Create("sent_rank_npc")
    if not IsValid(npc) then return end

    npc:SetPos(pos)
    npc:SetAngles(ang)
    npc:SetNWInt("RankNPCID", id)
    npc:Spawn()
    npc:Activate()

    timer.Simple(0, function()
        if IsValid(npc) then
            npc:SetAngles(ang)
        end
    end)

    return npc
end

local function SeedRankMapData()
    local map     = game.GetMap()
    local mapData = RANK_NPC_MAPDATA and RANK_NPC_MAPDATA[map]
    if not mapData or #mapData == 0 then return false end

    print("[Delivery] Seeding Rank NPCs from map data for: " .. map)
    for _, entry in ipairs(mapData) do
        local id = RankNPC_Save(entry.pos, entry.ang)
        if id then
            SpawnRankNPC(id, entry.pos, entry.ang)
        end
    end
    print("[Delivery] Seeded " .. #mapData .. " Rank NPC(s) from map data.")
    return true
end

function RankNPC_SpawnAll()
    local rows = RankNPC_LoadAll()

    if not rows or #rows == 0 then
        print("[Delivery] No saved Rank NPCs found for this map, checking map data...")
        SeedRankMapData()
        return
    end

    for _, row in ipairs(rows) do
        local pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z))
        local ang = Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r))
        SpawnRankNPC(tonumber(row.id), pos, ang)
    end

    print("[Delivery] Spawned " .. #rows .. " Rank NPC(s) from database.")
end

function RankNPC_SpawnSingle(id, pos, ang)
    return SpawnRankNPC(id, pos, ang)
end

function RankNPC_RefreshAll()
    if RANK_NPC_REFRESHING then return end
    RANK_NPC_REFRESHING = true

    print("[Delivery] Refreshing Rank NPCs...")

    for _, ent in ipairs(ents.FindByClass("sent_rank_npc")) do
        if IsValid(ent) then ent:Remove() end
    end

    timer.Simple(0.5, function()
        RankNPC_SpawnAll()
        RANK_NPC_REFRESHING = false
        print("[Delivery] Rank NPC refresh complete.")
    end)
end

hook.Add("InitPostEntity", "RankNPC_LoadOnStart", function()
    RankNPC_SpawnAll()
end)
