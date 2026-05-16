DELIVERY_REFRESHING = false

local function SpawnDeliveryNPC(id, npcKey, pos, ang, spawnOffset)
    local data = DELIVERY_NPCS[npcKey]
    if not data then
        print("[Delivery] Unknown NPC key: " .. npcKey)
        return
    end

    local npc = ents.Create("sent_delivery_npc")
    if not IsValid(npc) then return end

    npc:SetPos(pos)
    npc:SetAngles(ang)
    npc:SetDeliveryNPCKey(npcKey)
    npc:SetDeliveryNPCLabel(data.label)
    npc:SetDeliveryNPCID(id)

    if spawnOffset then
        npc:SetNWVector("CargoSpawnOffset", spawnOffset)
        npc:SetNWBool("HasCargoSpawnOffset", true)
    end

    npc:Spawn()
    npc:Activate()

    timer.Simple(0, function()
        if IsValid(npc) then
            npc:SetAngles(ang)
        end
    end)

    return npc
end

local function SeedMapData()
    local map = game.GetMap()
    local mapData = DELIVERY_MAPDATA and DELIVERY_MAPDATA[map]
    if not mapData then return false end

    print("[Delivery] Seeding NPCs from map data for: " .. map)

    for _, entry in ipairs(mapData) do
        local id = Delivery_SaveNPC(entry.npc_key, entry.pos, entry.ang)
        if id then
            SpawnDeliveryNPC(id, entry.npc_key, entry.pos, entry.ang, entry.spawnOffset)
        end
    end

    print("[Delivery] Seeded " .. #mapData .. " NPC(s) from map data.")
    return true
end

local function FindMapDataOffset(npcKey, pos)
    local mapData = DELIVERY_MAPDATA and DELIVERY_MAPDATA[game.GetMap()]
    if not mapData then return nil end

    local best, bestDist = nil, math.huge
    for _, entry in ipairs(mapData) do
        if entry.npc_key == npcKey and entry.spawnOffset then
            local dist = pos:Distance(entry.pos)
            if dist < bestDist then
                bestDist = dist
                best = entry.spawnOffset
            end
        end
    end

    return best
end

function Delivery_SpawnAllNPCs()
    local rows = Delivery_LoadAllNPCs()

    if not rows or #rows == 0 then
        print("[Delivery] No saved NPCs in database, checking map data...")
        SeedMapData()
        return
    end

    for _, row in ipairs(rows) do
        local pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z))
        local ang = Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r))
        local spawnOffset = FindMapDataOffset(row.npc_key, pos)
        SpawnDeliveryNPC(tonumber(row.id), row.npc_key, pos, ang, spawnOffset)
    end

    print("[Delivery] Spawned " .. #rows .. " NPC(s) from database.")
end

function Delivery_SpawnSingleNPC(id, npcKey, pos, ang, spawnOffset)
    return SpawnDeliveryNPC(id, npcKey, pos, ang, spawnOffset)
end

function Delivery_RefreshNPCs()
    if DELIVERY_REFRESHING then return end
    DELIVERY_REFRESHING = true

    print("[Delivery] Refreshing NPCs...")

    for _, ent in ipairs(ents.FindByClass("sent_delivery_npc")) do
        if IsValid(ent) then
            ent:Remove()
        end
    end

    timer.Simple(0.5, function()
        Delivery_SpawnAllNPCs()
        DELIVERY_REFRESHING = false
        print("[Delivery] NPC refresh complete.")
    end)
end

hook.Add("InitPostEntity", "Delivery_LoadNPCs", function()
    Delivery_SpawnAllNPCs()
end)