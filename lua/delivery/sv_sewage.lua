SEWAGE_ACTIVE_JOBS    = SEWAGE_ACTIVE_JOBS    or {}
SEWAGE_TANKER_TRANSFERS = SEWAGE_TANKER_TRANSFERS or {}

local SUPPORTED_CLASSES = { prop_physics = true, primitive_shape = true }

local function SetPropMass(ent, mass)
    if not IsValid(ent) then return end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(mass)
        phys:Wake()
        return
    end

    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local delayedPhys = ent:GetPhysicsObject()
        if IsValid(delayedPhys) then
            delayedPhys:SetMass(mass)
            delayedPhys:Wake()
        end
    end)
end

local function StoreSewageTankerModifier(ent)
    duplicator.StoreEntityModifier(ent, "sewage_tanker", {
        capacity = ent:GetNWInt("SewageTankerCapacity", 0),
        originalMass = ent:GetNWFloat("SewageTankerOriginalMass", 50),
        nerfed = ent:GetNWBool("SewageTankerNerfed", false),
    })
end

local function ClearSewageTankerModifier(ent)
    if ent.EntityMods then
        ent.EntityMods.sewage_tanker = nil
        if table.IsEmpty(ent.EntityMods) then
            ent.EntityMods = nil
        end
    end
end

local function GetJob(ply)
    return SEWAGE_ACTIVE_JOBS[ply:SteamID()]
end

local function SetJob(ply, job)
    SEWAGE_ACTIVE_JOBS[ply:SteamID()] = job
end

local function ClearJob(ply)
    SEWAGE_ACTIVE_JOBS[ply:SteamID()] = nil
end

local function GetSewageTankerLiters(ent)
    return ent:GetNWFloat("SewageTankerLitersFloat", ent:GetNWInt("SewageTankerLiters", 0))
end

local function SetSewageTankerLiters(ent, liters)
    liters = math.max(0, tonumber(liters) or 0)
    ent:SetNWFloat("SewageTankerLitersFloat", liters)
    ent:SetNWInt("SewageTankerLiters", math.floor(liters + 0.5))

    local emptyMass = ent:GetNWFloat("SewageTankerEmptyMass", SEWAGE_CONFIG.tankerEmptyMass)
    local nerfed = ent:GetNWBool("SewageTankerNerfed", false)
    local totalMass = nerfed and emptyMass or (emptyMass + liters * SEWAGE_CONFIG.tankerFullMassPerLiter)
    SetPropMass(ent, totalMass)

    if WireLib and ent.Outputs then
        WireLib.TriggerOutput(ent, "Liters", liters)
    end
end

function Delivery_IsSewageTanker(ent)
    return IsValid(ent) and ent:GetNWBool("SewageIsTanker", false)
end

function Delivery_PlayerHasSewageTanker(ply)
    local ownerID = ply:SteamID64() or ""
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetNWBool("SewageIsTanker", false) and ent:GetNWString("SewageTankerOwnerID", "") == ownerID then
            return true
        end
    end
    return false
end

function Delivery_FindPlayerSewageTanker(ply, nearPos, requireSpace)
    local ownerID = ply:SteamID64() or ""
    local best, bestDist = nil, math.huge

    for _, ent in ipairs(ents.GetAll()) do
        if not ent:GetNWBool("SewageIsTanker", false) or IsValid(ent:GetParent()) then continue end
        if ent:GetNWString("SewageTankerOwnerID", "") ~= ownerID then continue end

        if requireSpace then
            local liters = GetSewageTankerLiters(ent)
            local cap    = ent:GetNWInt("SewageTankerCapacity", 0)
            if liters >= cap then continue end
        end

        local dist = nearPos and ent:GetPos():Distance(nearPos) or 0
        if not nearPos or dist < bestDist then
            bestDist = dist
            best     = ent
        end
    end

    return best
end

function Delivery_MarkSewageTanker(ply, ent, customCapacity, nerfed)
    if not IsValid(ply) then return false, "Invalid player." end
    if not IsValid(ent) or not SUPPORTED_CLASSES[ent:GetClass()] then
        return false, "Look at a valid physics prop."
    end
    if IsValid(ent:GetParent()) then
        return false, "You cannot mark a prop that is parented."
    end
    if ent:GetNWBool("SewageIsTanker", false) then
        return false, "Already marked as a sewage tanker."
    end
    if ent:GetNWBool("DeliveryIsTanker", false) then
        return false, "Already marked as a delivery tanker."
    end
    if Delivery_PlayerHasSewageTanker(ply) then
        return false, "You already have a sewage tanker marked."
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return false, "This prop has no valid physics object." end

    local capacity    = customCapacity or SEWAGE_CONFIG.tankerCapacity
    local originalMass = phys:GetMass()
    local emptyMass   = capacity / 10
    nerfed = nerfed and true or false

    ent:SetNWBool("SewageIsTanker", true)
    ent:SetNWString("SewageTankerOwnerID", ply:SteamID64() or "")
    ent:SetNWEntity("SewageTankerOwner", ply)
    ent:SetNWInt("SewageTankerCapacity", capacity)
    ent:SetNWFloat("SewageTankerEmptyMass", emptyMass)
    ent:SetNWFloat("SewageTankerOriginalMass", originalMass)
    ent:SetNWBool("SewageTankerBusy", false)
    ent:SetNWBool("SewageTankerNerfed", nerfed)
    ent:SetNWFloat("SewageTankerLitersFloat", 0)
    ent:SetNWInt("SewageTankerLiters", 0)

    StoreSewageTankerModifier(ent)
    SetPropMass(ent, emptyMass)

    if WireLib then
        ent.Outputs = WireLib.CreateOutputs(ent, {"Capacity", "Liters"}, {"Measures the capacity", "Measures how many liters the tank has"})
        WireLib.TriggerOutput(ent, "Capacity", capacity)
        WireLib.TriggerOutput(ent, "Liters", 0)
    end

    return true, string.format(
        "Marked as sewage tanker (%dL capacity).%s",
        capacity,
        nerfed and " (NERFED: weight will not change and payout is halved)" or ""
    )
end

function Delivery_UnmarkSewageTanker(ply, ent)
    if not IsValid(ent) or not ent:GetNWBool("SewageIsTanker", false) then
        return false, "That prop is not marked as a sewage tanker."
    end
    if ent:GetNWBool("SewageTankerBusy", false) then
        return false, "Cannot unmark while transferring."
    end

    local ownerID = ent:GetNWString("SewageTankerOwnerID", "")
    if IsValid(ply) and ownerID ~= "" and ownerID ~= (ply:SteamID64() or "") and not ply:IsAdmin() then
        return false, "That sewage tanker belongs to another player."
    end

    local originalMass = ent:GetNWFloat("SewageTankerOriginalMass", 50)

    ent:SetNWBool("SewageIsTanker", false)
    ent:SetNWString("SewageTankerOwnerID", "")
    ent:SetNWEntity("SewageTankerOwner", NULL)
    ent:SetNWInt("SewageTankerCapacity", 0)
    ent:SetNWFloat("SewageTankerEmptyMass", 0)
    ent:SetNWFloat("SewageTankerOriginalMass", 0)
    ent:SetNWBool("SewageTankerBusy", false)
    ent:SetNWBool("SewageTankerNerfed", false)
    ent:SetNWFloat("SewageTankerLitersFloat", 0)
    ent:SetNWInt("SewageTankerLiters", 0)

    ClearSewageTankerModifier(ent)
    SetPropMass(ent, originalMass)

    if WireLib then
        WireLib.Remove(ent)
    end

    return true, "Removed sewage tanker mark and restored original weight."
end

duplicator.RegisterEntityModifier("sewage_tanker", function(ply, ent, data)
    if not IsValid(ent) or not SUPPORTED_CLASSES[ent:GetClass()] or IsValid(ent:GetParent()) then return end

    local capacity = tonumber(data and data.capacity) or SEWAGE_CONFIG.tankerCapacity
    local originalMass = tonumber(data and data.originalMass) or 50
    local emptyMass = capacity / 10
    local nerfed = data and data.nerfed and true or false

    ent:SetNWBool("SewageIsTanker", true)
    ent:SetNWString("SewageTankerOwnerID", IsValid(ply) and (ply:SteamID64() or "") or "")
    ent:SetNWEntity("SewageTankerOwner", IsValid(ply) and ply or NULL)
    ent:SetNWInt("SewageTankerCapacity", capacity)
    ent:SetNWFloat("SewageTankerEmptyMass", emptyMass)
    ent:SetNWFloat("SewageTankerOriginalMass", originalMass)
    ent:SetNWBool("SewageTankerBusy", false)
    ent:SetNWBool("SewageTankerNerfed", nerfed)
    ent:SetNWFloat("SewageTankerLitersFloat", 0)
    ent:SetNWInt("SewageTankerLiters", 0)

    SetPropMass(ent, emptyMass)
end)

timer.Create("Delivery_SewageTankerParentCheck", 2, 0, function()
    for className, _ in pairs(SUPPORTED_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if Delivery_IsSewageTanker(ent) and IsValid(ent:GetParent()) then
                local owner = ent:GetNWEntity("SewageTankerOwner")
                Delivery_UnmarkSewageTanker(owner, ent)
                if IsValid(owner) then
                    owner:ChatPrint("[Sewage] Your sewage tanker was unmarked because it was parented.")
                end
            end
        end
    end
end)

local function SendJobSync(ply)
    local job = GetJob(ply)
    net.Start("Sewage_SyncJob")
    if job then
        net.WriteBool(true)
        net.WriteInt(#job.manholes, 8)
        for _, addr in ipairs(job.manholes) do
            net.WriteString(addr)
        end
        net.WriteInt(job.collected, 8)

        local collectedEntIndices = {}
        for entIdx, _ in pairs(job.collectedIndices) do
            table.insert(collectedEntIndices, entIdx)
        end
        net.WriteInt(#collectedEntIndices, 16)
        for _, entIdx in ipairs(collectedEntIndices) do
            net.WriteInt(entIdx, 16)
        end

        net.WriteBool(job.drained)
        net.WriteBool(job.paid)
    else
        net.WriteBool(false)
    end
    net.Send(ply)
end

local function SendClearJob(ply)
    net.Start("Sewage_ClearJob")
    net.Send(ply)
end

local function StopSewageTransfer(ply, msg)
    local transfer = SEWAGE_TANKER_TRANSFERS[ply]
    if not transfer then return end

    if IsValid(transfer.tanker) then
        transfer.tanker:SetNWBool("SewageTankerBusy", false)
        transfer.tanker:StopSound("tanker/shit_hose_suction.wav")
        transfer.tanker:StopSound("tanker/shit_pour.wav")
    end

    SEWAGE_TANKER_TRANSFERS[ply] = nil

    if IsValid(ply) and msg then
        ply:ChatPrint("[Sewage] " .. msg)
    end
end

timer.Remove("Delivery_SewageTankerTick")
timer.Create("Delivery_SewageTankerTick", SEWAGE_CONFIG.transferTick, 0, function()
    for ply, transfer in pairs(SEWAGE_TANKER_TRANSFERS) do
        if not IsValid(ply) or not IsValid(transfer.tanker) then
            StopSewageTransfer(ply)
            continue
        end

        local refPos = transfer.refPos
        if refPos and transfer.tanker:GetPos():Distance(refPos) > SEWAGE_CONFIG.collectRadius then
            StopSewageTransfer(ply, "You moved too far away. Transfer stopped.")
            continue
        end

        local currentLiters = GetSewageTankerLiters(transfer.tanker)

        if transfer.mode == "fill" then
            local delta = SEWAGE_CONFIG.fillRate * SEWAGE_CONFIG.transferTick
            local newLiters = math.min(transfer.targetLiters, currentLiters + delta)
            SetSewageTankerLiters(transfer.tanker, newLiters)

            if newLiters >= transfer.targetLiters then
                StopSewageTransfer(ply)

                local job = GetJob(ply)
                if job then
                    job.collectedIndices[transfer.manholeEntIdx] = true
                    job.collected = job.collected + 1
                    SendJobSync(ply)

                    if job.collected >= #job.manholes then
                        ply:ChatPrint("[Sewage] All manholes collected! Drive to the sewage dropoff to empty your tanker.")
                    else
                        ply:ChatPrint("[Sewage] Manhole collected! (" .. job.collected .. "/" .. #job.manholes .. ")")
                    end
                end
            end

        elseif transfer.mode == "drain" then
            local delta = SEWAGE_CONFIG.emptyRate * SEWAGE_CONFIG.transferTick
            local newLiters = math.max(0, currentLiters - delta)
            SetSewageTankerLiters(transfer.tanker, newLiters)

            if newLiters <= 0 then
                local nerfed = transfer.tanker:GetNWBool("SewageTankerNerfed", false)
                StopSewageTransfer(ply)

                local job = GetJob(ply)
                if job then
                    job.drained = true
                    job.nerfed = nerfed
                    SendJobSync(ply)
                    ply:ChatPrint("[Sewage] Tanker emptied. Return to the sewage NPC to collect your payment." .. (nerfed and " (NERFED: payout will be halved)" or ""))
                end
            end
        end
    end
end)

net.Receive("Sewage_RequestStart", function(len, ply)
    if not IsValid(ply) then return end

    --if ply:Team() ~= TEAM_HEAVY_DUTY then
        --ply:ChatPrint("[Sewage] You must be a Heavy Duty worker to start a sewage job.")
        --return
    --end

    if GetJob(ply) then
        ply:ChatPrint("[Sewage] You already have an active sewage job.")
        return
    end

    local npcIdx = net.ReadInt(16)
    local npcEnt = ents.GetByIndex(npcIdx)

    local manholeEnts = ents.FindByClass("sent_manhole")
    if #manholeEnts == 0 then
        ply:ChatPrint("[Sewage] No manholes placed on this map.")
        return
    end

    local shuffled = table.Copy(manholeEnts)
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local count       = math.min(SEWAGE_CONFIG.manholesPerJob, #shuffled)
    local manholeAddrs = {}
    local manholeEntIdx = {}

    for i = 1, count do
        local mh  = shuffled[i]
        local addr = mh:GetNWString("ManholeAddress", "Manhole " .. i)
        manholeAddrs[#manholeAddrs + 1] = addr
        manholeEntIdx[mh:EntIndex()]    = true
    end

    local job = {
        manholes        = manholeAddrs,
        manholeEntIdx   = manholeEntIdx,
        collected       = 0,
        collectedIndices = {},
        drained         = false,
        paid            = false,
        npcEntIndex     = IsValid(npcEnt) and npcEnt:EntIndex() or 0,
    }

    SetJob(ply, job)
    SendJobSync(ply)

    ply:ChatPrint("[Sewage] Job started! Collect sewage from " .. count .. " manholes.")
    for i, addr in ipairs(manholeAddrs) do
        ply:ChatPrint("[Sewage] " .. i .. ". " .. addr)
    end
end)

net.Receive("Sewage_RequestPayment", function(len, ply)
    if not IsValid(ply) then return end

    local job = GetJob(ply)
    if not job then
        ply:ChatPrint("[Sewage] No active sewage job.")
        return
    end

    if not job.drained then
        ply:ChatPrint("[Sewage] Empty your tanker at the sewage dropoff first.")
        return
    end

    if job.paid then
        ply:ChatPrint("[Sewage] Already collected payment.")
        return
    end

    local total     = #job.manholes
    local collected = job.collected
    local payout    = total > 0 and math.floor((collected / total) * SEWAGE_CONFIG.fullPayout / 10) * 10 or 0

    if job.nerfed then
        payout = math.floor(payout * 0.5)
    end

    if payout > 0 then
        ply:addMoney(payout)
        ply:ChatPrint("[Sewage] Paid $" .. payout .. " for " .. collected .. "/" .. total .. " manholes collected." .. (job.nerfed and " (NERFED, -50%)" or ""))
    else
        ply:ChatPrint("[Sewage] No manholes collected - no payment.")
    end

    job.paid = true
    ClearJob(ply)
    SendClearJob(ply)
end)

net.Receive("Sewage_CancelJob", function(len, ply)
    if not IsValid(ply) then return end

    local job = GetJob(ply)
    if not job then
        ply:ChatPrint("[Sewage] No active sewage job to cancel.")
        return
    end

    StopSewageTransfer(ply)
    ClearJob(ply)
    SendClearJob(ply)
    ply:ChatPrint("[Sewage] Job cancelled.")
end)

function Sewage_PlayerUseManhole(ply, manholeEnt)
    if not IsValid(ply) or not IsValid(manholeEnt) then return end

    local job = GetJob(ply)
    if not job then
        return
    end

    if job.drained then
        ply:ChatPrint("[Sewage] Tanker already emptied. Cannot collect more sewage.")
        return
    end

    if not job.manholeEntIdx[manholeEnt:EntIndex()] then
        return
    end

    if job.collectedIndices[manholeEnt:EntIndex()] then
        ply:ChatPrint("[Sewage] Already collected from this manhole.")
        return
    end

    if SEWAGE_TANKER_TRANSFERS[ply] then
        ply:ChatPrint("[Sewage] Transfer already in progress. Please wait.")
        return
    end

    local tanker = Delivery_FindPlayerSewageTanker(ply, manholeEnt:GetPos(), true)
    if not IsValid(tanker) then
        ply:ChatPrint("[Sewage] Bring your sewage tanker close to the manhole first.")
        return
    end

    if tanker:GetPos():Distance(manholeEnt:GetPos()) > SEWAGE_CONFIG.collectRadius then
        ply:ChatPrint("[Sewage] Your sewage tanker is not close enough to the manhole.")
        return
    end

    if tanker:GetNWBool("SewageTankerBusy", false) then
        ply:ChatPrint("[Sewage] Your sewage tanker is busy.")
        return
    end

    local currentLiters  = GetSewageTankerLiters(tanker)
    local capacity       = tanker:GetNWInt("SewageTankerCapacity", 0)
    local targetLiters   = math.min(capacity, currentLiters + SEWAGE_CONFIG.litersPerManhole)

    if currentLiters >= capacity then
        ply:ChatPrint("[Sewage] Your sewage tanker is full!")
        return
    end

    tanker:SetNWBool("SewageTankerBusy", true)

    SEWAGE_TANKER_TRANSFERS[ply] = {
        ply           = ply,
        tanker        = tanker,
        manholeEntIdx = manholeEnt:EntIndex(),
        refPos        = manholeEnt:GetPos(),
        mode          = "fill",
        targetLiters  = targetLiters,
    }

    tanker:EmitSound("tanker/shit_hose_suction.wav", 75, 100, 1, CHAN_STATIC, SND_LOOPING)
    ply:ChatPrint("[Sewage] Collecting sewage... Stay close to the manhole.")
end

function Sewage_PlayerUseSewageDropoff(ply, dropoffEnt)
    if not IsValid(ply) or not IsValid(dropoffEnt) then return end

    local job = GetJob(ply)
    if not job then
        ply:ChatPrint("[Sewage] You don't have an active sewage job.")
        return
    end

    if job.drained then
        ply:ChatPrint("[Sewage] Tanker already emptied. Return to the sewage NPC for payment.")
        return
    end

    if job.collected == 0 then
        ply:ChatPrint("[Sewage] Collect sewage from manholes first.")
        return
    end

    if SEWAGE_TANKER_TRANSFERS[ply] then
        ply:ChatPrint("[Sewage] Transfer already in progress. Please wait.")
        return
    end

    local tanker = Delivery_FindPlayerSewageTanker(ply, dropoffEnt:GetPos(), false)
    if not IsValid(tanker) then
        ply:ChatPrint("[Sewage] Bring your sewage tanker close to the dropoff first.")
        return
    end

    if tanker:GetPos():Distance(dropoffEnt:GetPos()) > SEWAGE_CONFIG.drainRadius then
        ply:ChatPrint("[Sewage] Your sewage tanker is not close enough to the dropoff.")
        return
    end

    local currentLiters = GetSewageTankerLiters(tanker)
    if currentLiters <= 0 then
        ply:ChatPrint("[Sewage] Your sewage tanker is already empty.")
        return
    end

    if tanker:GetNWBool("SewageTankerBusy", false) then
        ply:ChatPrint("[Sewage] Your sewage tanker is busy.")
        return
    end

    tanker:SetNWBool("SewageTankerBusy", true)

    SEWAGE_TANKER_TRANSFERS[ply] = {
        ply          = ply,
        tanker       = tanker,
        refPos       = dropoffEnt:GetPos(),
        mode         = "drain",
        targetLiters = 0,
    }

    tanker:EmitSound("tanker/shit_pour.wav", 75, 100, 1, CHAN_STATIC, SND_LOOPING)
    ply:ChatPrint("[Sewage] Emptying sewage tanker... Stay close to the dropoff.")
end

net.Receive("Sewage_MarkTanker", function(len, ply)
    if not IsValid(ply) then return end
    
    local ent = ply:GetEyeTrace().Entity
    local success, message = Delivery_MarkSewageTanker(ply, ent)
    ply:ChatPrint("[Sewage] " .. message)
end)

net.Receive("Sewage_UnmarkTanker", function(len, ply)
    if not IsValid(ply) then return end
    
    local ent = ply:GetEyeTrace().Entity
    local success, message = Delivery_UnmarkSewageTanker(ply, ent)
    ply:ChatPrint("[Sewage] " .. message)
end)

hook.Add("PlayerDisconnected", "Delivery_ClearSewageJobOnLeave", function(ply)
    StopSewageTransfer(ply)
    ClearJob(ply)
end)
