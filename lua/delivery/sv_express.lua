EXPRESS_ACTIVE_JOBS = EXPRESS_ACTIVE_JOBS or {}

local function GetJob(ply)
    return EXPRESS_ACTIVE_JOBS[ply:SteamID()]
end

local function SetJob(ply, job)
    EXPRESS_ACTIVE_JOBS[ply:SteamID()] = job
end

local function ClearJob(ply)
    EXPRESS_ACTIVE_JOBS[ply:SteamID()] = nil
end

local function CalcPayout(delivered, total, potentialPayout)
    if total <= 0 or delivered <= 0 then return 0 end
    return math.floor((delivered / total) * (potentialPayout or 0) / 10) * 10
end

local function SpawnPackages(ply, npcEnt, count, minModel, maxModel)
    local packages = {}

    local validDropoffAddresses = {}
    for _, ent in ipairs(ents.FindByClass("sent_express_dropoff")) do
        if IsValid(ent) then
            local addr = ent:GetNWString("DropoffAddress", "")
            if addr ~= "" then
                validDropoffAddresses[#validDropoffAddresses + 1] = addr
            end
        end
    end

    -- If no dropoffs exist on map, use the config list as fallback (though jobs won't be deliverable)
    local pool = #validDropoffAddresses > 0 and table.Copy(validDropoffAddresses) or table.Copy(EXPRESS_ADDRESSES)
    local currentPool = table.Copy(pool)

    local spawnBase = IsValid(npcEnt) and npcEnt:GetPos() or ply:GetPos()

    local modelCounts = {}
    for i = 1, #EXPRESS_BOX_MODELS do
        modelCounts[i] = 0
    end

    for i = 1, count do
        local addr
        if #currentPool == 0 then
            currentPool = table.Copy(pool)
        end
        
        local idx = math.random(#currentPool)
        addr = currentPool[idx]
        table.remove(currentPool, idx)

        local available = {}
        for idx = minModel, maxModel do
            local entry = EXPRESS_BOX_MODELS[idx]
            if entry and modelCounts[idx] < entry.limit then
                available[#available + 1] = idx
            end
        end
        if #available == 0 then
            for idx = minModel, maxModel do
                if EXPRESS_BOX_MODELS[idx] then
                    available[#available + 1] = idx
                end
            end
        end
        local chosenIdx = available[math.random(#available)]
        local chosenEntry = EXPRESS_BOX_MODELS[chosenIdx]
        modelCounts[chosenIdx] = modelCounts[chosenIdx] + 1

        local pkg = ents.Create("sent_express_package")
        if not IsValid(pkg) then continue end

        local offset = Vector(
            math.random(-80, 80),
            math.random(-80, 80),
            20 + (i - 1) * 5
        )
        pkg:SetPos(spawnBase + offset)
        pkg:SetAngles(Angle(0, math.random(0, 360), 0))
        pkg:SetNWString("ExpressModel", chosenEntry.model)
        pkg:SetNWInt("ExpressMass", chosenEntry.mass)
        pkg:Spawn()
        pkg:Activate()
        pkg:SetNWString("ExpressAddress", addr)
        pkg:SetNWEntity("ExpressOwner", ply)

        timer.Simple(0, function()
            if not IsValid(pkg) then return end
            pkg:CPPISetOwner(game.GetWorld())
        end)

        packages[#packages + 1] = pkg:EntIndex()
    end

    return packages
end

local function SendJobSync(ply)
    local job = GetJob(ply)
    if not job then return end

    net.Start("Express_SyncJob")
        net.WriteInt(job.total, 8)
        net.WriteInt(job.delivered, 8)
        net.WriteFloat(job.startTime)
        net.WriteBool(job.expired)
        net.WriteInt(job.timeLimit or EXPRESS_CONFIG.timeLimitLarge, 16)
    net.Send(ply)
end

local function ExpireJob(ply)
    local job = GetJob(ply)
    if not job then return end

    job.expired = true

    for _, idx in ipairs(job.packages) do
        local ent = ents.GetByIndex(idx)
        if IsValid(ent) and ent:GetClass() == "sent_express_package" then
            ent:SetNWBool("ExpressExpired", true)
        end
    end

    net.Start("Express_JobExpired")
    net.Send(ply)
end

local function FinishJob(ply, forceTurnIn)
    local job = GetJob(ply)
    if not job then return end

    local delivered = job.delivered
    local total     = job.total
    local payout    = CalcPayout(delivered, total, job.potentialPayout)

    for _, idx in ipairs(job.packages) do
        local ent = ents.GetByIndex(idx)
        if IsValid(ent) and ent:GetClass() == "sent_express_package" then
            ent:Remove()
        end
    end

    if payout > 0 then
        ply:addMoney(payout)
    end

    net.Start("Express_JobComplete")
        net.WriteInt(delivered, 8)
        net.WriteInt(total, 8)
        net.WriteInt(payout, 32)
    net.Send(ply)

    ClearJob(ply)
end

net.Receive("Express_StartJob", function(len, ply)
    if GetJob(ply) then
        ply:ChatPrint("[Express] You already have an active delivery job.")
        return
    end

    local npcEntIdx = net.ReadInt(16)
    local variantIdx = net.ReadInt(4)
    local npcEnt    = ents.GetByIndex(npcEntIdx)

    if not IsValid(npcEnt) or npcEnt:GetClass() ~= "sent_express_npc" then
        ply:ChatPrint("[Express] Invalid NPC.")
        return
    end

    local variant = EXPRESS_VARIANTS[variantIdx]
    if not variant then
        ply:ChatPrint("[Express] Invalid delivery option.")
        return
    end

    if ply:GetPos():Distance(npcEnt:GetPos()) > EXPRESS_CONFIG.pickupRadius then
        ply:ChatPrint("[Express] You are too far from the NPC.")
        return
    end

    local count     = math.random(variant.minPackages, variant.maxPackages)
    local packages  = SpawnPackages(ply, npcEnt, count, variant.minModels, variant.maxModels)
    
    -- Threshold logic for payout and time limit
    local potentialPayout = (count >= variant.threshold) and variant.maxSalary or variant.minSalary
    local timeLimit       = (count >= variant.threshold) and variant.maxTime or variant.minTime

    local job = {
        total           = count,
        delivered       = 0,
        startTime       = CurTime(),
        npcEntIdx       = npcEntIdx,
        packages        = packages,
        expired         = false,
        timeLimit       = timeLimit,
        potentialPayout = potentialPayout,
        variantName     = variant.name,
    }
    SetJob(ply, job)

    net.Start("Express_JobStarted")
        net.WriteInt(count, 8)
        net.WriteFloat(CurTime())
        net.WriteInt(timeLimit, 16)
    net.Send(ply)

    timer.Create("ExpressTimer_" .. ply:SteamID(), timeLimit, 1, function()
        if not IsValid(ply) then return end
        local j = GetJob(ply)
        if not j or j.expired then return end
        ExpireJob(ply)
    end)
end)

net.Receive("Express_TurnIn", function(len, ply)
    local job = GetJob(ply)
    if not job then
        ply:ChatPrint("[Express] You don't have an active job.")
        return
    end

    local npcEnt = ents.GetByIndex(job.npcEntIdx)
    if not IsValid(npcEnt) or npcEnt:GetClass() ~= "sent_express_npc" then
        local closest = nil
        local bestD   = math.huge
        for _, ent in ipairs(ents.FindByClass("sent_express_npc")) do
            local d = ent:GetPos():Distance(ply:GetPos())
            if d < bestD then bestD = d; closest = ent end
        end
        npcEnt = closest
    end

    if not IsValid(npcEnt) or npcEnt:GetPos():Distance(ply:GetPos()) > EXPRESS_CONFIG.pickupRadius then
        ply:ChatPrint("[Express] You must return to the express NPC to collect payment.")
        return
    end

    if not job.expired and job.delivered < job.total then
        ply:ChatPrint("[Express] You still have packages to deliver! Return here when done or when time runs out.")
        return
    end

    timer.Remove("ExpressTimer_" .. ply:SteamID())
    FinishJob(ply)
end)

net.Receive("Express_CancelJob", function(len, ply)
    local job = GetJob(ply)
    if not job then return end

    timer.Remove("ExpressTimer_" .. ply:SteamID())

    for _, idx in ipairs(job.packages) do
        local ent = ents.GetByIndex(idx)
        if IsValid(ent) and ent:GetClass() == "sent_express_package" then
            ent:Remove()
        end
    end

    ClearJob(ply)
    ply:ChatPrint("[Express] Job cancelled.")
end)

function Express_DeliverPackage(ply, pkg)
    local job = GetJob(ply)
    if not job then return false end

    local found = false
    for i, idx in ipairs(job.packages) do
        if idx == pkg:EntIndex() then
            table.remove(job.packages, i)
            found = true
            break
        end
    end
    if not found then return false end

    job.delivered = job.delivered + 1
    pkg:Remove()

    net.Start("Express_PackageDelivered")
        net.WriteInt(job.delivered, 8)
        net.WriteInt(job.total, 8)
    net.Send(ply)

    if job.delivered >= job.total then
        timer.Remove("ExpressTimer_" .. ply:SteamID())
        ply:ChatPrint("[Express] All packages delivered! Return to the express NPC to collect your payment.")
    end

    return true
end

hook.Add("PlayerDisconnected", "Express_Cleanup", function(ply)
    local job = GetJob(ply)
    if not job then return end
    timer.Remove("ExpressTimer_" .. ply:SteamID())
    for _, idx in ipairs(job.packages) do
        local ent = ents.GetByIndex(idx)
        if IsValid(ent) then ent:Remove() end
    end
    ClearJob(ply)
end)

function Express_SpawnNPC(id, pos, ang)
    local ent = ents.Create("sent_express_npc")
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ent:SetNWInt("ExpressNPCID", id)
end

function Express_SpawnDropoff(id, address, pos, ang)
    local ent = ents.Create("sent_express_dropoff")
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ent:SetNWInt("ExpressDropoffID", id)
    ent:SetNWString("DropoffAddress", address)
end

function Express_SeedMap()
    local map = game.GetMap()

    for _, ent in ipairs(ents.FindByClass("sent_express_npc")) do
        if IsValid(ent) then ent:Remove() end
    end
    for _, ent in ipairs(ents.FindByClass("sent_express_dropoff")) do
        if IsValid(ent) then ent:Remove() end
    end

    ExpressDB_ClearNPCs(map)
    ExpressDB_ClearDropoffs(map)

    local npcCount     = 0
    local dropoffCount = 0

    local npcMapData = EXPRESS_NPC_MAPDATA and EXPRESS_NPC_MAPDATA[map]
    if npcMapData and #npcMapData > 0 then
        for _, entry in ipairs(npcMapData) do
            local id = ExpressDB_SaveNPC(map, entry.pos, entry.ang)
            if id then
                Express_SpawnNPC(id, entry.pos, entry.ang)
                npcCount = npcCount + 1
            end
        end
    else
        local rows = ExpressDB_GetNPCs(map)
        for _, row in ipairs(rows) do
            Express_SpawnNPC(
                tonumber(row.id),
                Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z)),
                Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r))
            )
            npcCount = npcCount + 1
        end
    end

    local dropoffMapData = EXPRESS_DROPOFF_MAPDATA and EXPRESS_DROPOFF_MAPDATA[map]
    if dropoffMapData and #dropoffMapData > 0 then
        for _, entry in ipairs(dropoffMapData) do
            local id = ExpressDB_SaveDropoff(map, entry.address, entry.pos, entry.ang)
            if id then
                Express_SpawnDropoff(id, entry.address, entry.pos, entry.ang)
                dropoffCount = dropoffCount + 1
            end
        end
    else
        local rows = ExpressDB_GetDropoffs(map)
        for _, row in ipairs(rows) do
            Express_SpawnDropoff(
                tonumber(row.id),
                row.address,
                Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z)),
                Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r))
            )
            dropoffCount = dropoffCount + 1
        end
    end

    print("[Delivery] Express: spawned " .. npcCount .. " NPC(s), " .. dropoffCount .. " dropoff(s) for map: " .. map)
end

-- use a longer delay on multiplayer to ensure the server is fully ready
hook.Add("InitPostEntity", "Express_InitMap", function()
    local delay = game.SinglePlayer() and 1 or 5
    timer.Simple(delay, function()
        Express_SeedMap()
    end)
end)