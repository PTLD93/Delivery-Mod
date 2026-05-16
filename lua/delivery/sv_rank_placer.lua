concommand.Add("delivery_resetranks", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[Rank] Admins only.")
        return
    end

    local target = table.concat(args, " ")
    if not target or target == "" then
        local msg = "[Rank] Usage: delivery_resetranks <name, steamid, or 'all'>"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end

    if target == "all" then
        sql.Query("DELETE FROM rank_purchases")
        for _, p in ipairs(player.GetAll()) do
            game.ConsoleCommand('ulx setdonator "' .. p:Nick() .. '" 0\n')
            net.Start("RankNPC_SyncOwned")
                net.WriteUInt(0, 8)
            net.Send(p)
        end
        local msg = "[Rank] Reset all player rank purchases and set donator level to 0."
        if IsValid(ply) then ply:ChatPrint(msg) end
        print(msg)
        return
    end

    local found = nil
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID() == target or string.lower(p:Nick()) == string.lower(target) then
            found = p
            break
        end
    end

    if IsValid(found) then
        Rank_ResetPlayer(found:SteamID())
        game.ConsoleCommand('ulx setdonator "' .. found:Nick() .. '" 0\n')
        net.Start("RankNPC_SyncOwned")
            net.WriteUInt(0, 8)
        net.Send(found)
        local msg = "[Rank] Reset ranks for " .. found:Nick() .. " (" .. found:SteamID() .. ") and set donator level to 0."
        if IsValid(ply) then ply:ChatPrint(msg) end
        print(msg)
    else
        Rank_ResetPlayer(target)
        local msg = "[Rank] Reset rank purchases for steamid: " .. target .. " (player not online, donator level not reset via ULX)."
        if IsValid(ply) then ply:ChatPrint(msg) end
        print(msg)
    end
end)

concommand.Add("delivery_place_rank", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        ply:ChatPrint("[Delivery] Look at a surface to place the Rank NPC.")
        return
    end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)

    local id = RankNPC_Save(pos, ang)
    if not id then
        ply:ChatPrint("[Delivery] Failed to save Rank NPC to database.")
        return
    end

    RankNPC_SpawnSingle(id, pos, ang)
    ply:ChatPrint("[Delivery] Placed Rank Vendor (ID: " .. id .. ")")
end)

concommand.Add("delivery_remove_rank", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Delivery] Admins only.")
        return
    end

    local trace = ply:GetEyeTrace()
    local ent   = trace.Entity

    if not IsValid(ent) or ent:GetClass() ~= "sent_rank_npc" then
        ply:ChatPrint("[Delivery] Look at a Rank Vendor NPC to remove it.")
        return
    end

    local id = ent:GetNWInt("RankNPCID", 0)
    if id ~= 0 then
        RankNPC_Delete(id)
        ply:ChatPrint("[Delivery] Removed Rank Vendor ID " .. id .. " from database and world.")
    else
        ply:ChatPrint("[Delivery] Removed Rank Vendor from world only (no database ID).")
    end

    ent:Remove()
end)
