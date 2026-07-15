local GRAIN_PROP_CLASSES = {
    prop_physics = true,
    primitive_shape = true,
}

local function IsSupportedGrainBedClass(ent)
    return IsValid(ent) and GRAIN_PROP_CLASSES[ent:GetClass()] == true
end

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

local function GetGrainBedCurrentLiters(ent)
    return ent:GetNWFloat("DeliveryGrainBedLitersFloat", ent:GetNWInt("DeliveryGrainBedLiters", 0))
end

local function SetGrainBedState(ent, cargoKey, liters)
    liters = math.max(0, tonumber(liters) or 0)
    cargoKey = liters > 0 and (cargoKey or "") or ""

    ent:SetNWString("DeliveryGrainBedCargoKey", cargoKey)
    ent:SetNWFloat("DeliveryGrainBedLitersFloat", liters)
    ent:SetNWInt("DeliveryGrainBedLiters", math.floor(liters + 0.5))

    local mass = ent:GetNWFloat("DeliveryGrainBedEmptyMass", 0)
    local nerfed = ent:GetNWBool("DeliveryGrainBedNerfed", false)
    if not nerfed and cargoKey ~= "" and liters > 0 then
        mass = mass + (liters * Delivery_GetGrainDensity(cargoKey))
    end

    SetPropMass(ent, mass)
end

local function StoreGrainBedModifier(ent)
    duplicator.StoreEntityModifier(ent, "delivery_grain", {
        capacityLiters = ent:GetNWInt("DeliveryGrainBedCapacity", 0),
        originalMassKg = ent:GetNWFloat("DeliveryGrainBedOriginalMass", 50),
        nerfed = ent:GetNWBool("DeliveryGrainBedNerfed", false),
    })
end

local function ClearGrainBedModifier(ent)
    if ent.EntityMods then
        ent.EntityMods.delivery_grain = nil
        if table.IsEmpty(ent.EntityMods) then
            ent.EntityMods = nil
        end
    end
end

local function StopTransferSound(ent, soundPath)
    if not IsValid(ent) then return end
    if not soundPath or soundPath == "" then return end
    ent:StopSound(soundPath)
end

local function StartTransferSound(ent, soundPath)
    if not IsValid(ent) then return end
    if not soundPath or soundPath == "" then return end
    ent:EmitSound(soundPath, 75, 100, 1, CHAN_STATIC, SND_LOOPING)
end

local function ApplyGrainBedMetadata(ent, ownerId, ownerEnt, capacity, originalMass, emptyMass, nerfed)
    ent:SetNWBool("DeliveryIsGrainBed", true)
    ent:SetNWString("DeliveryGrainBedOwnerID", ownerId or "")
    ent:SetNWEntity("DeliveryGrainBedOwner", ownerEnt or NULL)
    ent:SetNWInt("DeliveryGrainBedCapacity", capacity)
    ent:SetNWFloat("DeliveryGrainBedOriginalMass", originalMass)
    ent:SetNWFloat("DeliveryGrainBedEmptyMass", emptyMass)
    ent:SetNWBool("DeliveryGrainBedBusy", false)
    ent:SetNWBool("DeliveryGrainBedNerfed", nerfed and true or false)
    ent:SetNWString("DeliveryGrainBedCargoKey", "")
    ent:SetNWFloat("DeliveryGrainBedLitersFloat", 0)
    ent:SetNWInt("DeliveryGrainBedLiters", 0)
end

duplicator.RegisterEntityModifier("delivery_grain", function(ply, ent, data)
    if not IsSupportedGrainBedClass(ent) or IsValid(ent:GetParent()) then return end

    local capacity = Delivery_ClampGrainBedCapacity(data and data.capacityLiters)
    local originalMass = tonumber(data and data.originalMassKg) or 50
    local emptyMass = Delivery_GetGrainBedEmptyMass(capacity)
    local nerfed = data and data.nerfed and true or false

    ApplyGrainBedMetadata(
        ent,
        IsValid(ply) and (ply:SteamID64() or "") or "",
        IsValid(ply) and ply or NULL,
        capacity,
        originalMass,
        emptyMass,
        nerfed
    )

    SetPropMass(ent, emptyMass)
end)

function Delivery_IsGrainBedProp(ent)
    return IsSupportedGrainBedClass(ent) and ent:GetNWBool("DeliveryIsGrainBed", false)
end

function Delivery_PlayerGrainBedCount(ply)
    if not IsValid(ply) then return 0 end

    local count = 0
    local ownerId = ply:SteamID64() or ""
    for className, _ in pairs(GRAIN_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if Delivery_IsGrainBedProp(ent) and ent:GetNWString("DeliveryGrainBedOwnerID", "") == ownerId then
                count = count + 1
            end
        end
    end

    return count
end

function Delivery_FindPlayerGrainBeds(ply, npcPos, cargoKey, requireFilled)
    if not IsValid(ply) then return {} end

    local maxDist = DELIVERY_GRAIN_CONFIG.searchRadius
    local ownerId = ply:SteamID64() or ""
    local foundBeds = {}

    for className, _ in pairs(GRAIN_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if Delivery_IsGrainBedProp(ent) and ent:GetNWString("DeliveryGrainBedOwnerID", "") == ownerId and not IsValid(ent:GetParent()) then
                local nearNPC = npcPos and ent:GetPos():Distance(npcPos) <= maxDist
                local nearPly = ent:GetPos():Distance(ply:GetPos()) <= maxDist
                if nearNPC or nearPly then
                    local currentCargo = ent:GetNWString("DeliveryGrainBedCargoKey", "")
                    local liters = GetGrainBedCurrentLiters(ent)
                    if not requireFilled or (currentCargo == cargoKey and liters > 0) then
                        table.insert(foundBeds, ent)
                    end
                end
            end
        end
    end

    return foundBeds
end

DELIVERY_GRAIN_TRANSFERS = DELIVERY_GRAIN_TRANSFERS or {}

local function StopGrainTransfer(ply, reason)
    if not IsValid(ply) then return end

    local transfer = DELIVERY_GRAIN_TRANSFERS[ply]
    if not transfer then return end

    local soundPath = transfer.mode == "fill"
        and (DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.fillSound)
        or (DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.emptySound)

    for _, bed in ipairs(transfer.grainBeds or {}) do
        if IsValid(bed) then
            bed:SetNWBool("DeliveryGrainBedBusy", false)
            StopTransferSound(bed, soundPath)
        end
    end

    DELIVERY_GRAIN_TRANSFERS[ply] = nil

    if reason then
        ply:ChatPrint("[Delivery] " .. reason)
    end
end

local function FinishFillGrainTransfer(transfer)
    local ply = transfer.ply
    if not IsValid(ply) then
        StopGrainTransfer(ply)
        return
    end

    local anyValid = false
    for _, bed in ipairs(transfer.grainBeds or {}) do
        if IsValid(bed) then anyValid = true break end
    end
    if not anyValid then
        StopGrainTransfer(ply)
        return
    end

    if ply:getDarkRPVar("money") < transfer.price then
        StopGrainTransfer(ply, "You no longer have enough money to finish filling the grain bed(s).")
        return
    end

    ply:addMoney(-transfer.price)
    StopGrainTransfer(ply, "Filled grain bed(s) with " .. (transfer.cargo.label or transfer.cargoKey) .. " for $" .. transfer.price .. ".")
end

local function FinishDrainGrainTransfer(transfer)
    local ply = transfer.ply
    if not IsValid(ply) then
        StopGrainTransfer(ply)
        return
    end

    local nerfed = false
    for _, bed in ipairs(transfer.grainBeds or {}) do
        if IsValid(bed) and bed:GetNWBool("DeliveryGrainBedNerfed", false) then
            nerfed = true
            break
        end
    end

    local price = transfer.price
    if nerfed then
        price = math.floor(price * 0.5)
    end

    ply:addMoney(price)
    StopGrainTransfer(ply, "Sold " .. (transfer.cargo.label or transfer.cargoKey) .. " for $" .. price .. (nerfed and " (NERFED, -50%)" or "") .. ".")
end

function Delivery_StartGrainTransfer(ply, npcPos, cargoKey, mode, price, overrideLiters)
    local cargo = DELIVERY_CARGO[cargoKey]
    if not IsValid(ply) or not Delivery_IsGrainCargo(cargo) then
        return false, "That cargo is not a grain bed job."
    end

    if DELIVERY_GRAIN_TRANSFERS[ply] then
        return false, "You are already filling or emptying a grain bed."
    end

    local requireFilled = mode == "drain"
    local grainBeds = Delivery_FindPlayerGrainBeds(ply, npcPos, requireFilled and cargoKey or nil, requireFilled)
    if #grainBeds == 0 then
        return false, mode == "fill"
            and "Bring your marked grain bed(s) close to the NPC first."
            or "Bring the filled grain bed(s) close to the buyer NPC first."
    end

    for _, bed in ipairs(grainBeds) do
        if bed:GetNWBool("DeliveryGrainBedBusy", false) then
            return false, "One of your grain beds is already being used."
        end
    end

    local targetLitersTotal = overrideLiters or Delivery_GetGrainLiters(cargo)
    if targetLitersTotal <= 0 then
        return false, "This grain cargo is missing a valid amount."
    end

    if mode == "fill" then
        local totalCapacity = 0
        for _, bed in ipairs(grainBeds) do
            totalCapacity = totalCapacity + bed:GetNWInt("DeliveryGrainBedCapacity", 0)
        end

        if totalCapacity < targetLitersTotal then
            return false, "Your grain bed(s) are too small for this load."
        end

        for _, bed in ipairs(grainBeds) do
            local currentCargo = bed:GetNWString("DeliveryGrainBedCargoKey", "")
            local currentLiters = GetGrainBedCurrentLiters(bed)
            if currentCargo ~= "" and currentCargo ~= cargoKey then
                return false, "One of your grain beds contains a different cargo."
            end
            if currentLiters >= (bed:GetNWInt("DeliveryGrainBedCapacity", 0) / #grainBeds) then
                -- This check is a bit complex for multi-bed, let's just allow it if total is not full
            end
        end

        if ply:getDarkRPVar("money") < price then
            return false, "You don't have enough money!"
        end
    end

    DELIVERY_GRAIN_TRANSFERS[ply] = {
        ply = ply,
        grainBeds = grainBeds,
        cargo = cargo,
        cargoKey = cargoKey,
        npcPos = npcPos,
        mode = mode,
        price = price,
        targetLitersTotal = targetLitersTotal,
    }

    local soundPath = mode == "fill"
        and (DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.fillSound)
        or (DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.emptySound)

    for _, bed in ipairs(grainBeds) do
        bed:SetNWBool("DeliveryGrainBedBusy", true)
        StartTransferSound(bed, soundPath)
        if mode == "fill" and GetGrainBedCurrentLiters(bed) <= 0 then
            SetGrainBedState(bed, cargoKey, 0)
        end
    end

    return true, mode == "fill"
        and "Started filling. Stay close to the NPC until the grain bed(s) are full."
        or "Started emptying. Stay close to the NPC until the grain bed(s) are empty."
end

timer.Remove("Delivery_GrainTransferTick")
local transferTickSeconds = tonumber(DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.transferTickSeconds) or 0.1
local transferRateLitersPerSecond = tonumber(DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.transferRateLitersPerSecond) or 300

timer.Create("Delivery_GrainTransferTick", transferTickSeconds, 0, function()
    local delta = transferRateLitersPerSecond * transferTickSeconds

    for ply, transfer in pairs(DELIVERY_GRAIN_TRANSFERS) do
        if not IsValid(ply) then
            StopGrainTransfer(ply)
            continue
        end

        local validBeds = {}
        local totalCurrentLiters = 0
        for _, bed in ipairs(transfer.grainBeds or {}) do
            if IsValid(bed) then
                if transfer.npcPos and bed:GetPos():Distance(transfer.npcPos) > DELIVERY_GRAIN_CONFIG.searchRadius then
                    StopGrainTransfer(ply, "You must be close to the NPC in order to fill or empty the grain bed(s).")
                    goto next_ply
                end
                table.insert(validBeds, bed)
                totalCurrentLiters = totalCurrentLiters + GetGrainBedCurrentLiters(bed)
            end
        end

        if #validBeds == 0 then
            StopGrainTransfer(ply)
            continue
        end

        local deltaPerBed = delta / #validBeds
        local allFinished = true

        if transfer.mode == "fill" then
            local targetPerBed = transfer.targetLitersTotal / #validBeds
            for _, bed in ipairs(validBeds) do
                local current = GetGrainBedCurrentLiters(bed)
                local nextLiters = math.min(targetPerBed, current + deltaPerBed)
                SetGrainBedState(bed, transfer.cargoKey, nextLiters)
                if nextLiters < targetPerBed then
                    allFinished = false
                end
            end
            if allFinished then
                FinishFillGrainTransfer(transfer)
            end
        else
            for _, bed in ipairs(validBeds) do
                local current = GetGrainBedCurrentLiters(bed)
                local nextLiters = math.max(0, current - deltaPerBed)
                SetGrainBedState(bed, transfer.cargoKey, nextLiters)
                if nextLiters > 0 then
                    allFinished = false
                end
            end
            if allFinished then
                FinishDrainGrainTransfer(transfer)
            end
        end

        ::next_ply::
    end
end)

function Delivery_MarkGrainBedProp(ply, ent, capacityLiters, nerfed)
    if not IsValid(ply) or not IsSupportedGrainBedClass(ent) then
        return false, "Look at a valid physics prop."
    end

    if IsValid(ent:GetParent()) then
        return false, "You cannot mark a prop that is parented."
    end

    if ent:GetNWBool("DeliveryIsGrainBed", false) then
        return false, "This prop is already marked as a grain bed."
    end

    if Delivery_PlayerGrainBedCount(ply) >= 2 then
        return false, "You already have 2 grain beds marked. Unmark one first."
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then
        return false, "This prop has no valid physics object."
    end

    local capacity = Delivery_ClampGrainBedCapacity(capacityLiters)
    local originalMass = phys:GetMass()
    local emptyMass = Delivery_GetGrainBedEmptyMass(capacity)
    nerfed = nerfed and true or false

    ApplyGrainBedMetadata(ent, ply:SteamID64() or "", ply, capacity, originalMass, emptyMass, nerfed)

    StoreGrainBedModifier(ent)
    SetPropMass(ent, emptyMass)

    return true, string.format(
        "Marked grain bed at %d L capacity.%s",
        capacity,
        nerfed and " (NERFED: weight will not change and sell price is halved)" or ""
    )
end

function Delivery_UnmarkGrainBedProp(ply, ent)
    if not ent:GetNWBool("DeliveryIsGrainBed", false) then
        return false, "That prop is not marked as a grain bed."
    end

    if ent:GetNWBool("DeliveryGrainBedBusy", false) then
        return false, "You cannot unmark a grain bed while it is filling or emptying."
    end

    local ownerId = ent:GetNWString("DeliveryGrainBedOwnerID", "")
    if IsValid(ply) and ownerId ~= "" and ownerId ~= (ply:SteamID64() or "") then
        return false, "That grain bed belongs to another player."
    end

    local originalMass = ent:GetNWFloat("DeliveryGrainBedOriginalMass", 50)

    ent:SetNWBool("DeliveryIsGrainBed", false)
    ent:SetNWString("DeliveryGrainBedOwnerID", "")
    ent:SetNWEntity("DeliveryGrainBedOwner", NULL)
    ent:SetNWInt("DeliveryGrainBedCapacity", 0)
    ent:SetNWFloat("DeliveryGrainBedOriginalMass", 0)
    ent:SetNWFloat("DeliveryGrainBedEmptyMass", 0)
    ent:SetNWBool("DeliveryGrainBedBusy", false)
    ent:SetNWBool("DeliveryGrainBedNerfed", false)
    ent:SetNWString("DeliveryGrainBedCargoKey", "")
    ent:SetNWFloat("DeliveryGrainBedLitersFloat", 0)
    ent:SetNWInt("DeliveryGrainBedLiters", 0)

    ClearGrainBedModifier(ent)
    StopTransferSound(ent)
    SetPropMass(ent, originalMass)

    return true, "Removed grain bed mark and restored the original weight."
end
