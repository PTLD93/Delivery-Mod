local function SpawnTankerNPC(npcKey, pos, ang, spawnOffset)
    local data = TANKER_NPCS and TANKER_NPCS[npcKey]
    if not data then
        return nil, "[Delivery] Unknown tanker NPC key: " .. tostring(npcKey)
    end

    local npc = ents.Create("sent_delivery_npc")
    if not IsValid(npc) then
        return nil, "[Delivery] Failed to create tanker NPC entity."
    end

    npc:SetPos(pos)
    npc:SetAngles(ang)
    npc:SetDeliveryNPCKey(npcKey)
    npc:SetDeliveryNPCLabel(data.label)
    npc:SetDeliveryNPCID(0)

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

local function GetTankerMapOffset(npcKey, pos)
    local mapData = TANKER_NPC_MAPDATA and TANKER_NPC_MAPDATA[game.GetMap()]
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

function Delivery_SpawnAllTankerNPCs()
    local map = game.GetMap()
    local mapData = TANKER_NPC_MAPDATA and TANKER_NPC_MAPDATA[map]
    if not mapData then return end

    for _, entry in ipairs(mapData) do
        SpawnTankerNPC(entry.npc_key, entry.pos, entry.ang, entry.spawnOffset)
    end
end

hook.Add("InitPostEntity", "Delivery_LoadTankerNPCs", function()
    Delivery_SpawnAllTankerNPCs()
end)

concommand.Add("delivery_tanker_place", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    local npcKey = args[1]
    if not npcKey or npcKey == "" then
        ply:ChatPrint("[Delivery] Usage: delivery_tanker_place <npc_key>")
        return
    end

    if not TANKER_NPCS or not TANKER_NPCS[npcKey] then
        ply:ChatPrint("[Delivery] Unknown tanker NPC key: " .. tostring(npcKey))
        return
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        ply:ChatPrint("[Delivery] Look at a surface to place the tanker NPC.")
        return
    end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)
    local spawnOffset = GetTankerMapOffset(npcKey, pos) or TANKER_NPCS[npcKey].spawnOffset

    local npc, err = SpawnTankerNPC(npcKey, pos, ang, spawnOffset)
    if not IsValid(npc) then
        ply:ChatPrint(err or "[Delivery] Failed to place tanker NPC.")
        return
    end

    ply:ChatPrint("[Delivery] Placed tanker NPC: " .. TANKER_NPCS[npcKey].label)
end)

concommand.Add("delivery_tanker_remove", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    local trace = ply:GetEyeTrace()
    local ent = trace.Entity
    if not IsValid(ent) or ent:GetClass() ~= "sent_delivery_npc" then
        ply:ChatPrint("[Delivery] Look at a tanker NPC to remove it.")
        return
    end

    local npcKey = ent.GetDeliveryNPCKey and ent:GetDeliveryNPCKey() or ""
    if npcKey == "" or not (TANKER_NPCS and TANKER_NPCS[npcKey]) then
        ply:ChatPrint("[Delivery] That is not a tanker NPC.")
        return
    end

    ent:Remove()
    ply:ChatPrint("[Delivery] Removed tanker NPC from the world.")
end)

hook.Add("PlayerSay", "Delivery_SaveTankerNPCs", function(ply, text)
    if string.lower(text) ~= "!savetankernpcs" then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return ""
    end

    local npcs = ents.FindByClass("sent_delivery_npc")
    local found = 0

    print("[Delivery] === TANKER_NPC_MAPDATA entry for: " .. game.GetMap() .. " ===")
    print('TANKER_NPC_MAPDATA = TANKER_NPC_MAPDATA or {}')
    print('TANKER_NPC_MAPDATA["' .. game.GetMap() .. '"] = {')

    for _, ent in ipairs(npcs) do
        if IsValid(ent) and ent.GetDeliveryNPCKey then
            local key = ent:GetDeliveryNPCKey()
            if TANKER_NPCS and TANKER_NPCS[key] then
                local p = ent:GetPos()
                local a = ent:GetAngles()
                found = found + 1
                print(string.format(
                    '    { npc_key = "%s", pos = Vector( %.2f, %.2f, %.2f ), ang = Angle( %.2f, %.2f, %.2f ) },',
                    key, p.x, p.y, p.z, a.p, a.y, a.r
                ))
            end
        end
    end

    print("}")
    print("[Delivery] === end tanker export ===")

    ply:ChatPrint("[Delivery] Exported " .. found .. " tanker NPC(s) to server console for sv_mapdata.lua.")
    return ""
end)

