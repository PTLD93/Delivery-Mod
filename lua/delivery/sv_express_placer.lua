concommand.Add("express_place_npc", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Express] Admins only.")
        return
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        ply:ChatPrint("[Express] Look at a surface to place the NPC.")
        return
    end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)
    local map = game.GetMap()

    local id = ExpressDB_SaveNPC(map, pos, ang)
    if not id then
        ply:ChatPrint("[Express] Failed to save NPC.")
        return
    end

    Express_SpawnNPC(id, pos, ang)
    ply:ChatPrint("[Express] Express NPC placed (ID: " .. id .. ")")
end)

concommand.Add("express_remove_npc", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Express] Admins only.")
        return
    end

    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "sent_express_npc" then
        ply:ChatPrint("[Express] Look at an express NPC to remove it.")
        return
    end

    local id = ent:GetNWInt("ExpressNPCID", 0)
    if id ~= 0 then
        ExpressDB_DeleteNPC(id)
    end
    ent:Remove()
    ply:ChatPrint("[Express] Express NPC removed.")
end)

concommand.Add("express_place_dropoff", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Express] Admins only.")
        return
    end

    local addrRaw = table.concat(args, " ")
    if addrRaw == "" then
        ply:ChatPrint("[Express] Usage: express_place_dropoff <address>")
        ply:ChatPrint("[Express] Available addresses:")
        for i, addr in ipairs(EXPRESS_ADDRESSES) do
            ply:ChatPrint("  " .. i .. ". " .. addr)
        end
        return
    end

    local address = addrRaw
    local asNum   = tonumber(addrRaw)
    if asNum then
        address = EXPRESS_ADDRESSES[asNum]
        if not address then
            ply:ChatPrint("[Express] Invalid address index.")
            return
        end
    end

    local valid = false
    for _, a in ipairs(EXPRESS_ADDRESSES) do
        if a == address then valid = true; break end
    end
    if not valid then
        ply:ChatPrint("[Express] Unknown address: " .. address)
        return
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        ply:ChatPrint("[Express] Look at a surface to place the dropoff.")
        return
    end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)
    local map = game.GetMap()

    local id = ExpressDB_SaveDropoff(map, address, pos, ang)
    if not id then
        ply:ChatPrint("[Express] Failed to save dropoff.")
        return
    end

    Express_SpawnDropoff(id, address, pos, ang)
    ply:ChatPrint("[Express] Dropoff placed for: " .. address .. " (ID: " .. id .. ")")
end)

concommand.Add("express_remove_dropoff", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Express] Admins only.")
        return
    end

    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "sent_express_dropoff" then
        ply:ChatPrint("[Express] Look at a dropoff to remove it.")
        return
    end

    local id = ent:GetNWInt("ExpressDropoffID", 0)
    if id ~= 0 then
        ExpressDB_DeleteDropoff(id)
    end
    ent:Remove()
    ply:ChatPrint("[Express] Dropoff removed.")
end)

concommand.Add("express_export", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Express] Admins only.")
        return
    end

    local map      = game.GetMap()
    local npcs     = ents.FindByClass("sent_express_npc")
    local dropoffs = ents.FindByClass("sent_express_dropoff")

    print("[Express] === Export for map: " .. map .. " ===")

    if #npcs > 0 then
        print("-- Express NPCs:")
        for _, ent in ipairs(npcs) do
            if IsValid(ent) then
                local p = ent:GetPos()
                local a = ent:GetAngles()
                print(string.format('  Vector(%.2f, %.2f, %.2f)  Angle(%.2f, %.2f, %.2f)', p.x, p.y, p.z, a.p, a.y, a.r))
            end
        end
    end

    if #dropoffs > 0 then
        print("-- Express Dropoffs:")
        for _, ent in ipairs(dropoffs) do
            if IsValid(ent) then
                local p    = ent:GetPos()
                local a    = ent:GetAngles()
                local addr = ent:GetNWString("DropoffAddress", "?")
                print(string.format('  ["%s"]  Vector(%.2f, %.2f, %.2f)  Angle(%.2f, %.2f, %.2f)', addr, p.x, p.y, p.z, a.p, a.y, a.r))
            end
        end
    end

    print("[Express] === End export ===")
    ply:ChatPrint("[Express] Exported " .. #npcs .. " NPC(s) and " .. #dropoffs .. " dropoff(s) to console.")
end)

concommand.Add("express_reset", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Express] Admins only.")
        return
    end

    Express_SeedMap()
    ply:ChatPrint("[Express] Express entities reloaded from database.")
end)
