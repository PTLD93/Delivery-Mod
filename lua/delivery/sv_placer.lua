concommand.Add("delivery_place", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    local npcKey = args[1]
    if not npcKey or npcKey == "" then
        ply:ChatPrint("[Delivery] Usage: delivery_place <npc_key>")
        return
    end

    if not DELIVERY_NPCS[npcKey] then
        ply:ChatPrint("[Delivery] Unknown NPC key: " .. npcKey)
        return
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        ply:ChatPrint("[Delivery] Look at a surface to place the NPC.")
        return
    end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)

    local id = Delivery_SaveNPC(npcKey, pos, ang)
    if not id then
        ply:ChatPrint("[Delivery] Failed to save NPC to database.")
        return
    end

    Delivery_SpawnSingleNPC(id, npcKey, pos, ang)
    ply:ChatPrint("[Delivery] Placed " .. DELIVERY_NPCS[npcKey].label .. " (ID: " .. id .. ")")
end)

concommand.Add("delivery_remove", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    local trace = ply:GetEyeTrace()
    local ent = trace.Entity
    if not IsValid(ent) then
        ply:ChatPrint("[Delivery] Look at a delivery NPC to remove it.")
        return
    end

    -- check both NetworkVar and NWString since entity uses NetworkVar
    local npcKey = ""
    if ent.GetDeliveryNPCKey then
        npcKey = ent:GetDeliveryNPCKey()
    else
        npcKey = ent:GetNWString("DeliveryNPCKey", "")
    end

    if npcKey == "" then
        ply:ChatPrint("[Delivery] That is not a delivery NPC.")
        return
    end

    local id = 0
    if ent.GetDeliveryNPCID then
        id = ent:GetDeliveryNPCID()
    else
        id = ent:GetNWInt("DeliveryNPCID", 0)
    end

    if id ~= 0 then
        Delivery_DeleteNPC(id)
        ply:ChatPrint("[Delivery] Removed NPC ID " .. id .. " from database and world.")
    else
        ply:ChatPrint("[Delivery] Removed NPC from world only (no database ID).")
    end

    ent:Remove()
end)

hook.Add("PlayerSay", "Delivery_ResetNPCs", function(ply, text)
    if string.lower(text) ~= "!resetnpcs" then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return ""
    end

    local map         = game.GetMap()
    local mapData     = DELIVERY_MAPDATA and DELIVERY_MAPDATA[map]
    local rankMapData = RANK_NPC_MAPDATA and RANK_NPC_MAPDATA[map]

    DELIVERY_REFRESHING   = true
    RANK_NPC_REFRESHING   = true

    for _, ent in ipairs(ents.FindByClass("sent_delivery_npc")) do
        if IsValid(ent) then ent:Remove() end
    end
    for _, ent in ipairs(ents.FindByClass("sent_rank_npc")) do
        if IsValid(ent) then ent:Remove() end
    end

    Delivery_ClearAllNPCs()
    RankNPC_ClearAll()

    local deliveryCount = 0
    if mapData and #mapData > 0 then
        for _, entry in ipairs(mapData) do
            local id = Delivery_SaveNPC(entry.npc_key, entry.pos, entry.ang)
            if id then
                Delivery_SpawnSingleNPC(id, entry.npc_key, entry.pos, entry.ang, entry.spawnOffset)
                deliveryCount = deliveryCount + 1
            end
        end
    end

    local rankCount = 0
    if rankMapData and #rankMapData > 0 then
        for _, entry in ipairs(rankMapData) do
            local id = RankNPC_Save(entry.pos, entry.ang)
            if id then
                RankNPC_SpawnSingle(id, entry.pos, entry.ang)
                rankCount = rankCount + 1
            end
        end
    end

    DELIVERY_REFRESHING = false
    RANK_NPC_REFRESHING = false

    ply:ChatPrint("[Delivery] Reset complete. Spawned " .. deliveryCount .. " delivery NPC(s) and " .. rankCount .. " rank NPC(s).")
    print("[Delivery] Reset complete for: " .. map .. " (" .. deliveryCount .. " delivery, " .. rankCount .. " rank)")
    return ""
end)

hook.Add("PlayerSay", "Delivery_RefreshConfig", function(ply, text)
    if string.lower(text) ~= "!deliveryrefresh" then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return ""
    end

    -- Server side refresh
    include("delivery/sh_config.lua")
    include("delivery/sh_tanker_config.lua")
    include("delivery/sh_tanker_job_config.lua")
    include("delivery/sh_grain_config.lua")
    include("delivery/sh_grain_job_config.lua")
    
    -- Network to clients to refresh their side
    net.Start("Delivery_RefreshConfig")
    net.Broadcast()

    ply:ChatPrint("[Delivery] Configuration refreshed. Cargo and NPC data updated.")
    return ""
end)

hook.Add("PlayerSay", "Delivery_ExportNPCs", function(ply, text)
    if string.lower(text) ~= "!exportnpcs" then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return ""
    end

    local map      = game.GetMap()
    local npcs     = ents.FindByClass("sent_delivery_npc")
    local rankNpcs = ents.FindByClass("sent_rank_npc")

    if #npcs == 0 and #rankNpcs == 0 then
        ply:ChatPrint("[Delivery] No delivery or rank NPCs found in the world.")
        return ""
    end

    print("[Delivery] === sv_mapdata.lua export for: " .. map .. " ===")

    -- Delivery NPCs block
    if #npcs > 0 then
        print("-- DELIVERY_MAPDATA entry:")
        print('    ["' .. map .. '"] = {')
        for _, ent in ipairs(npcs) do
            if IsValid(ent) and ent.GetDeliveryNPCKey then
                local key = ent:GetDeliveryNPCKey()
                local p   = ent:GetPos()
                local a   = ent:GetAngles()
                if key ~= "" then
                    print(string.format(
                        '        { npc_key = "%s", pos = Vector( %.2f, %.2f, %.2f ), ang = Angle( %.2f, %.2f, %.2f ) },',
                        key, p.x, p.y, p.z, a.p, a.y, a.r
                    ))
                end
            end
        end
        print("    },")
    end

    -- Rank NPCs block
    if #rankNpcs > 0 then
        print("-- RANK_NPC_MAPDATA entry:")
        print('    ["' .. map .. '"] = {')
        for _, ent in ipairs(rankNpcs) do
            if IsValid(ent) then
                local p = ent:GetPos()
                local a = ent:GetAngles()
                print(string.format(
                    '        { pos = Vector( %.2f, %.2f, %.2f ), ang = Angle( %.2f, %.2f, %.2f ) },',
                    p.x, p.y, p.z, a.p, a.y, a.r
                ))
            end
        end
        print("    },")
    end

    print("[Delivery] === end export ===")

    ply:ChatPrint("[Delivery] Exported " .. #npcs .. " delivery NPC(s) and " .. #rankNpcs .. " rank NPC(s) to server console.")
    return ""
end)

hook.Add("PlayerSay", "Delivery_SaveNPCs", function(ply, text)
    if string.lower(text) ~= "!savenpcs" then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return ""
    end

    local npcs     = ents.FindByClass("sent_delivery_npc")
    local rankNpcs = ents.FindByClass("sent_rank_npc")

    if #npcs == 0 and #rankNpcs == 0 then
        ply:ChatPrint("[Delivery] No delivery or rank NPCs found in the world.")
        return ""
    end

    -- Save delivery NPCs
    Delivery_ClearAllNPCs()
    local count = 0
    for _, ent in ipairs(npcs) do
        if IsValid(ent) and ent.GetDeliveryNPCKey then
            local npcKey = ent:GetDeliveryNPCKey()
            if npcKey ~= "" then
                local id = Delivery_SaveNPC(npcKey, ent:GetPos(), ent:GetAngles())
                if id then
                    ent:SetDeliveryNPCID(id)
                    count = count + 1
                end
            end
        end
    end

    -- Save rank NPCs
    RankNPC_ClearAll()
    local rankCount = 0
    for _, ent in ipairs(rankNpcs) do
        if IsValid(ent) then
            local id = RankNPC_Save(ent:GetPos(), ent:GetAngles())
            if id then
                ent:SetNWInt("RankNPCID", id)
                rankCount = rankCount + 1
            end
        end
    end

    ply:ChatPrint("[Delivery] Saved " .. count .. " delivery NPC(s) and " .. rankCount .. " rank NPC(s) to the database.")
    print("[Delivery] " .. ply:Nick() .. " saved " .. count .. " delivery + " .. rankCount .. " rank NPC(s) via !savenpcs.")
    return ""
end)

concommand.Add("delivery_list", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    ply:ChatPrint("=== Delivery NPC Types ===")
    for k, v in pairs(DELIVERY_NPCS) do
        ply:ChatPrint("  " .. k .. " — " .. v.label)
    end
end)