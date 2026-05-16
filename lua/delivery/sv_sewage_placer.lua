local function SpawnSewageNPC(pos, ang, id)
    local npc = ents.Create("sent_sewage_npc")
    if not IsValid(npc) then return nil end

    npc:SetPos(pos)
    npc:SetAngles(ang)
    npc:SetNWInt("SewageNPCID", id or 0)
    npc:Spawn()
    npc:Activate()

    timer.Simple(0, function()
        if IsValid(npc) then npc:SetAngles(ang) end
    end)

    return npc
end

local function SpawnManhole(pos, ang, address, id)
    local ent = ents.Create("sent_manhole")
    if not IsValid(ent) then return nil end

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ent:SetNWInt("ManholeID", id or 0)

    timer.Simple(0, function()
        if IsValid(ent) then
            ent:SetAngles(ang)
            ent:SetNWString("ManholeAddress", address or "Unnamed Manhole")
        end
    end)

    return ent
end

local function SpawnSewageDropoff(pos, ang, id)
    local ent = ents.Create("sent_sewage_dropoff")
    if not IsValid(ent) then return nil end

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetNWInt("SewageDropoffID", id or 0)
    ent:Spawn()
    ent:Activate()

    timer.Simple(0, function()
        if IsValid(ent) then ent:SetAngles(ang) end
    end)

    return ent
end

function Sewage_SeedMap()
    local map = game.GetMap()

    for _, ent in ipairs(ents.FindByClass("sent_sewage_npc")) do ent:Remove() end
    for _, ent in ipairs(ents.FindByClass("sent_manhole"))     do ent:Remove() end
    for _, ent in ipairs(ents.FindByClass("sent_sewage_dropoff")) do ent:Remove() end

    local npcData     = SEWAGE_NPC_MAPDATA     and SEWAGE_NPC_MAPDATA[map]
    local manholeData = SEWAGE_MANHOLE_MAPDATA  and SEWAGE_MANHOLE_MAPDATA[map]
    local dropoffData = SEWAGE_DROPOFF_MAPDATA  and SEWAGE_DROPOFF_MAPDATA[map]

    if npcData then
        for i, entry in ipairs(npcData) do
            SpawnSewageNPC(entry.pos, entry.ang, i)
        end
        print("[Sewage] Spawned " .. #npcData .. " sewage NPC(s) for " .. map)
    end

    if manholeData then
        for i, entry in ipairs(manholeData) do
            SpawnManhole(entry.pos, entry.ang, entry.address, i)
        end
        print("[Sewage] Spawned " .. #manholeData .. " manhole(s) for " .. map)
    end

    if dropoffData then
        for i, entry in ipairs(dropoffData) do
            SpawnSewageDropoff(entry.pos, entry.ang, i)
        end
        print("[Sewage] Spawned " .. #dropoffData .. " sewage dropoff(s) for " .. map)
    end
end

hook.Add("InitPostEntity", "Sewage_LoadMap", function()
    Sewage_SeedMap()
end)

concommand.Add("sewage_place_npc", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then ply:ChatPrint("[Sewage] Look at a surface.") return end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)
    SpawnSewageNPC(pos, ang, 0)
    ply:ChatPrint("[Sewage] Placed sewage NPC. Use sewage_export to save positions.")
end)

concommand.Add("sewage_remove_npc", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "sent_sewage_npc" then
        ply:ChatPrint("[Sewage] Look at a sewage NPC to remove it.")
        return
    end
    ent:Remove()
    ply:ChatPrint("[Sewage] Sewage NPC removed.")
end)

concommand.Add("sewage_place_manhole", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local addrRaw = table.concat(args, " ")
    if addrRaw == "" then
        ply:ChatPrint("[Sewage] Usage: sewage_place_manhole <address>")
        ply:ChatPrint("[Sewage] Suggested addresses:")
        for i, addr in ipairs(SEWAGE_MANHOLE_ADDRESSES or {}) do
            ply:ChatPrint("  " .. i .. ". " .. addr)
        end
        return
    end

    local address = addrRaw
    local asNum   = tonumber(addrRaw)
    if asNum and SEWAGE_MANHOLE_ADDRESSES and SEWAGE_MANHOLE_ADDRESSES[asNum] then
        address = SEWAGE_MANHOLE_ADDRESSES[asNum]
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then ply:ChatPrint("[Sewage] Look at a surface.") return end

    local pos = trace.HitPos + trace.HitNormal * 2
    local ang = Angle(0, ply:GetAngles().y, 0)
    SpawnManhole(pos, ang, address, 0)
    ply:ChatPrint("[Sewage] Placed manhole: " .. address)
end)

concommand.Add("sewage_remove_manhole", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "sent_manhole" then
        ply:ChatPrint("[Sewage] Look at a manhole to remove it.")
        return
    end
    local addr = ent:GetNWString("ManholeAddress", "?")
    ent:Remove()
    ply:ChatPrint("[Sewage] Manhole removed: " .. addr)
end)

concommand.Add("sewage_place_dropoff", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then ply:ChatPrint("[Sewage] Look at a surface.") return end

    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:GetAngles().y + 180, 0)
    SpawnSewageDropoff(pos, ang, 0)
    ply:ChatPrint("[Sewage] Placed sewage dropoff. Use sewage_export to save positions.")
end)

concommand.Add("sewage_remove_dropoff", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "sent_sewage_dropoff" then
        ply:ChatPrint("[Sewage] Look at a sewage dropoff to remove it.")
        return
    end
    ent:Remove()
    ply:ChatPrint("[Sewage] Sewage dropoff removed.")
end)

concommand.Add("sewage_export", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    local map      = game.GetMap()
    local npcs     = ents.FindByClass("sent_sewage_npc")
    local manholes = ents.FindByClass("sent_manhole")
    local dropoffs = ents.FindByClass("sent_sewage_dropoff")

    print("[Sewage] === Export for map: " .. map .. " ===")

    if #npcs > 0 then
        print("SEWAGE_NPC_MAPDATA[\"" .. map .. "\"] = {")
        for _, ent in ipairs(npcs) do
            if IsValid(ent) then
                local p = ent:GetPos()
                local a = ent:GetAngles()
                print(string.format("    { pos = Vector( %.2f, %.2f, %.2f ), ang = Angle( %.2f, %.2f, %.2f ) },", p.x, p.y, p.z, a.p, a.y, a.r))
            end
        end
        print("}")
    end

    if #manholes > 0 then
        print("SEWAGE_MANHOLE_MAPDATA[\"" .. map .. "\"] = {")
        for _, ent in ipairs(manholes) do
            if IsValid(ent) then
                local p    = ent:GetPos()
                local a    = ent:GetAngles()
                local addr = ent:GetNWString("ManholeAddress", "?")
                print(string.format("    { address = \"%s\", pos = Vector( %.2f, %.2f, %.2f ), ang = Angle( %.2f, %.2f, %.2f ) },", addr, p.x, p.y, p.z, a.p, a.y, a.r))
            end
        end
        print("}")
    end

    if #dropoffs > 0 then
        print("SEWAGE_DROPOFF_MAPDATA[\"" .. map .. "\"] = {")
        for _, ent in ipairs(dropoffs) do
            if IsValid(ent) then
                local p = ent:GetPos()
                local a = ent:GetAngles()
                print(string.format("    { pos = Vector( %.2f, %.2f, %.2f ), ang = Angle( %.2f, %.2f, %.2f ) },", p.x, p.y, p.z, a.p, a.y, a.r))
            end
        end
        print("}")
    end

    print("[Sewage] === End export ===")
    ply:ChatPrint("[Sewage] Exported " .. #npcs .. " NPC(s), " .. #manholes .. " manhole(s), " .. #dropoffs .. " dropoff(s) to console.")
end)

concommand.Add("sewage_reset", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Sewage] Admins only.") return end

    Sewage_SeedMap()
    ply:ChatPrint("[Sewage] Sewage entities reloaded from mapdata.")
end)
