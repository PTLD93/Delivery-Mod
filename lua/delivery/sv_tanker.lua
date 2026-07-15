local TANKER_PROP_CLASSES = {
    prop_physics = true,
    primitive_shape = true,
}

local function IsSupportedTankerClass(ent)
    return IsValid(ent) and TANKER_PROP_CLASSES[ent:GetClass()] == true
end

do
    local soundPath = DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.transferLoopSound
    if soundPath and soundPath ~= "" then
        util.PrecacheSound(soundPath)
        resource.AddSingleFile("sound/" .. soundPath)
    end
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

local function GetTankerCurrentLiters(ent)
    return ent:GetNWFloat("DeliveryTankerLiquidLitersFloat", ent:GetNWInt("DeliveryTankerLiquidLiters", 0))
end

local function SetTankerLiquidState(ent, cargoKey, liters)
    liters = math.max(0, tonumber(liters) or 0)
    cargoKey = liters > 0 and (cargoKey or "") or ""

    ent:SetNWString("DeliveryTankerLiquidKey", cargoKey)
    ent:SetNWFloat("DeliveryTankerLiquidLitersFloat", liters)
    ent:SetNWInt("DeliveryTankerLiquidLiters", math.floor(liters + 0.5))

    local mass = ent:GetNWFloat("DeliveryTankerEmptyMass", 0)
    local nerfed = ent:GetNWBool("DeliveryTankerNerfed", false)
    if not nerfed and cargoKey ~= "" and liters > 0 then
        mass = mass + (liters * Delivery_GetLiquidDensity(cargoKey))
    end

    SetPropMass(ent, mass)
end

local function StoreTankerModifier(ent)
    duplicator.StoreEntityModifier(ent, "delivery_tanker", {
        capacityLiters = ent:GetNWInt("DeliveryTankerCapacity", 0),
        originalMassKg = ent:GetNWFloat("DeliveryTankerOriginalMass", 50),
        nerfed = ent:GetNWBool("DeliveryTankerNerfed", false),
    })
end

local function ClearTankerModifier(ent)
    if ent.EntityMods then
        ent.EntityMods.delivery_tanker = nil
        if table.IsEmpty(ent.EntityMods) then
            ent.EntityMods = nil
        end
    end
end

local function StopTransferSound(ent, soundPath)
    if not IsValid(ent) then return end

    ent.DeliveryTankerTransferSound = nil

    if not soundPath or soundPath == "" then
        soundPath = DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.transferLoopSound
    end
    if not soundPath or soundPath == "" then return end

    -- stop on correct channel
    ent:StopSound(soundPath)
end

local function StartTransferSound(ent, soundPath)
    StopTransferSound(ent, soundPath)

    if not soundPath or soundPath == "" then
        soundPath = DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.transferLoopSound
    end
    if not soundPath or soundPath == "" then return end

    -- proper attached looping 3D sound
    ent:EmitSound(
        soundPath,
        75,        -- level
        100,       -- pitch
        1,         -- volume
        CHAN_STATIC,
        SND_LOOPING
    )

    -- store marker so we can manage it later if needed
    ent.DeliveryTankerTransferSound = true
end

local function ApplyTankerMetadata(ent, ownerId, ownerEnt, capacity, originalMass, emptyMass, nerfed)
    ent:SetNWBool("DeliveryIsTanker", true)
    ent:SetNWString("DeliveryTankerOwnerID", ownerId or "")
    ent:SetNWEntity("DeliveryTankerOwner", ownerEnt or NULL)
    ent:SetNWInt("DeliveryTankerCapacity", capacity)
    ent:SetNWFloat("DeliveryTankerOriginalMass", originalMass)
    ent:SetNWFloat("DeliveryTankerEmptyMass", emptyMass)
    ent:SetNWBool("DeliveryTankerBusy", false)
    ent:SetNWBool("DeliveryTankerNerfed", nerfed and true or false)
    ent:SetNWString("DeliveryTankerLiquidKey", "")
    ent:SetNWFloat("DeliveryTankerLiquidLitersFloat", 0)
    ent:SetNWInt("DeliveryTankerLiquidLiters", 0)
end

duplicator.RegisterEntityModifier("delivery_tanker", function(ply, ent, data)
    if not IsSupportedTankerClass(ent) or IsValid(ent:GetParent()) then return end

    local capacity = Delivery_ClampTankerCapacity(data and data.capacityLiters)
    local originalMass = tonumber(data and data.originalMassKg) or 50
    local emptyMass = Delivery_GetTankerEmptyMass(capacity)
    local nerfed = data and data.nerfed and true or false

    ApplyTankerMetadata(
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

function Delivery_IsTankerProp(ent)
    return IsSupportedTankerClass(ent) and ent:GetNWBool("DeliveryIsTanker", false)
end

function Delivery_FindPlayerTanker(ply, npcPos, liquidKey, requireFilled)
    if not IsValid(ply) then return nil end

    local maxDist = DELIVERY_TANKER_CONFIG.searchRadius
    local ownerId = ply:SteamID64() or ""
    local bestEnt, bestDist

    for className, _ in pairs(TANKER_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if Delivery_IsTankerProp(ent) and ent:GetNWString("DeliveryTankerOwnerID", "") == ownerId and not IsValid(ent:GetParent()) then
                local nearNPC = npcPos and ent:GetPos():Distance(npcPos) <= maxDist
                local nearPly = ent:GetPos():Distance(ply:GetPos()) <= maxDist
                if nearNPC or nearPly then
                    local currentLiquid = ent:GetNWString("DeliveryTankerLiquidKey", "")
                    local liters = GetTankerCurrentLiters(ent)
                    if not requireFilled or (currentLiquid == liquidKey and liters > 0) then
                        local dist = math.min(
                            nearNPC and ent:GetPos():Distance(npcPos) or math.huge,
                            ent:GetPos():Distance(ply:GetPos())
                        )
                        if not bestDist or dist < bestDist then
                            bestEnt = ent
                            bestDist = dist
                        end
                    end
                end
            end
        end
    end

    return bestEnt
end

function Delivery_PlayerHasTanker(ply)
    if not IsValid(ply) then return false end

    local ownerId = ply:SteamID64() or ""
    for className, _ in pairs(TANKER_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if Delivery_IsTankerProp(ent) and ent:GetNWString("DeliveryTankerOwnerID", "") == ownerId then
                return true
            end
        end
    end

    return false
end

DELIVERY_TANKER_TRANSFERS = DELIVERY_TANKER_TRANSFERS or {}

local function StopTankerTransfer(ply, reason)
    if not IsValid(ply) then return end

    local transfer = DELIVERY_TANKER_TRANSFERS[ply]
    if not transfer then return end

    if IsValid(transfer.tanker) then
        transfer.tanker:SetNWBool("DeliveryTankerBusy", false)
        local soundPath = transfer.mode == "fill"
            and (DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.fillSound)
            or (DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.emptySound)
        StopTransferSound(transfer.tanker, soundPath)
    end

    DELIVERY_TANKER_TRANSFERS[ply] = nil

    if reason then
        ply:ChatPrint("[Delivery] " .. reason)
    end
end

local function FinishFillTransfer(transfer)
    local ply = transfer.ply
    if not IsValid(ply) or not IsValid(transfer.tanker) then
        StopTankerTransfer(ply)
        return
    end

    if ply:getDarkRPVar("money") < transfer.price then
        StopTankerTransfer(ply, "You no longer have enough money to finish filling the tanker.")
        return
    end

    if transfer.cargo.requires then
        if not Delivery_HasStock(ply, transfer.cargoKey) then
            StopTankerTransfer(ply, (transfer.cargo.label or transfer.cargoKey) .. " is no longer in stock.")
            return
        end
        Delivery_DeductStock(ply, transfer.cargoKey)
    end

    ply:addMoney(-transfer.price)
    StopTankerTransfer(ply, "Filled tanker with " .. (transfer.cargo.label or transfer.cargoKey) .. " for $" .. transfer.price .. ".")
end

local function FinishDrainTransfer(transfer)
    local ply = transfer.ply
    if not IsValid(ply) then
        StopTankerTransfer(ply)
        return
    end

    local price = transfer.price
    local nerfed = IsValid(transfer.tanker) and transfer.tanker:GetNWBool("DeliveryTankerNerfed", false)
    if nerfed then
        price = math.floor(price * 0.5)
    end

    ply:addMoney(price)

    local soldCargoData = transfer.cargo
    if soldCargoData and soldCargoData.produces then
        local announcedProduced = {}
        local stockState = Delivery_GetStockState(ply, true)
        local counters = stockState.counters
        for _, production in ipairs(soldCargoData.produces) do
            local counterKey = "counter_" .. transfer.cargoKey .. "_to_" .. production.item
            counters[counterKey] = (counters[counterKey] or 0) + 1

            while counters[counterKey] >= production.ratio do
                counters[counterKey] = counters[counterKey] - production.ratio
                local wasAvailable = Delivery_GetStock(ply, production.item) > 0
                Delivery_AddStock(ply, production.item, 1)
                if not wasAvailable and not announcedProduced[production.item] then
                    announcedProduced[production.item] = true
                    local producedCargo = DELIVERY_CARGO[production.item]
                    ply:ChatPrint("[Delivery] " .. (producedCargo and producedCargo.label or production.item) .. " is now available to buy!")
                end
            end
        end
    end

    StopTankerTransfer(ply, "Sold " .. (transfer.cargo.label or transfer.cargoKey) .. " for $" .. price .. (nerfed and " (NERFED, -50%)" or "") .. ".")
end

function Delivery_StartTankerTransfer(ply, npcPos, cargoKey, mode, price, overrideLiters)
    local cargo = DELIVERY_CARGO[cargoKey]
    if not IsValid(ply) or not Delivery_IsLiquidCargo(cargo) then
        return false, "That cargo is not a liquid tanker job."
    end

    if DELIVERY_TANKER_TRANSFERS[ply] then
        return false, "You are already filling or emptying a tanker."
    end

    local requireFilled = mode == "drain"
    local tanker = Delivery_FindPlayerTanker(ply, npcPos, requireFilled and cargoKey or nil, requireFilled)
    if not IsValid(tanker) then
        return false, mode == "fill"
            and "Bring your marked tanker close to the NPC first."
            or "Bring the filled tanker close to the buyer NPC first."
    end

    if tanker:GetNWBool("DeliveryTankerBusy", false) then
        return false, "That tanker is already being used."
    end

    local targetLiters = overrideLiters or Delivery_GetLiquidLiters(cargo)
    local currentLiquid = tanker:GetNWString("DeliveryTankerLiquidKey", "")
    local currentLiters = GetTankerCurrentLiters(tanker)

    if mode == "fill" then
        local capacity = tanker:GetNWInt("DeliveryTankerCapacity", 0)
        if targetLiters <= 0 then
            return false, "This liquid cargo is missing a valid liter amount."
        end
        if capacity < targetLiters then
            return false, "Your tanker is too small for this load."
        end
        if currentLiquid ~= "" and currentLiquid ~= cargoKey then
            return false, "Your tanker contains a different liquid."
        end
        if currentLiters >= targetLiters then
            return false, "Your tanker is already filled."
        end
        if ply:getDarkRPVar("money") < price then
            return false, "You don't have enough money!"
        end
        if currentLiters <= 0 then
            SetTankerLiquidState(tanker, cargoKey, 0)
        end
    else
        if currentLiquid ~= cargoKey or currentLiters <= 0 then
            return false, "That tanker does not contain the required liquid."
        end
    end

    DELIVERY_TANKER_TRANSFERS[ply] = {
        ply = ply,
        tanker = tanker,
        cargo = cargo,
        cargoKey = cargoKey,
        npcPos = npcPos,
        mode = mode,
        price = price,
        targetLiters = targetLiters,
    }

    tanker:SetNWBool("DeliveryTankerBusy", true)

    local soundPath = mode == "fill"
        and (DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.fillSound)
        or (DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.emptySound)
    StartTransferSound(tanker, soundPath)

    return true, mode == "fill"
        and "Started filling. Stay close to the NPC until the tanker is full."
        or "Started emptying. Stay close to the NPC until the tanker is empty."
end

timer.Remove("Delivery_TankerTransferTick")
local transferTickSeconds = tonumber(DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.transferTickSeconds) or 0.1
local transferRateLitersPerSecond = tonumber(DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.transferRateLitersPerSecond) or 300

timer.Create("Delivery_TankerTransferTick", transferTickSeconds, 0, function()
    local delta = transferRateLitersPerSecond * transferTickSeconds

    for ply, transfer in pairs(DELIVERY_TANKER_TRANSFERS) do
        if not IsValid(ply) or not IsValid(transfer.tanker) then
            StopTankerTransfer(ply)
            continue
        end

        if transfer.npcPos and transfer.tanker:GetPos():Distance(transfer.npcPos) > DELIVERY_TANKER_CONFIG.searchRadius then
            StopTankerTransfer(ply, "You must be close to the NPC in order to fill or empty the tanker.")
            continue
        end

        local currentLiters = GetTankerCurrentLiters(transfer.tanker)
        if transfer.mode == "fill" then
            local newLiters = math.min(transfer.targetLiters, currentLiters + delta)
            SetTankerLiquidState(transfer.tanker, transfer.cargoKey, newLiters)
            if newLiters >= transfer.targetLiters then
                FinishFillTransfer(transfer)
            end
        else
            local newLiters = math.max(0, currentLiters - delta)
            SetTankerLiquidState(transfer.tanker, transfer.cargoKey, newLiters)
            if newLiters <= 0 then
                FinishDrainTransfer(transfer)
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "Delivery_StopTankerTransferOnLeave", function(ply)
    StopTankerTransfer(ply)
end)

function Delivery_MarkTankerProp(ply, ent, capacityLiters, nerfed)
    if not IsValid(ply) or not IsSupportedTankerClass(ent) then
        return false, "Look at a valid physics prop."
    end

    if IsValid(ent:GetParent()) then
        return false, "You cannot mark a prop that is parented."
    end

    if Delivery_IsTankerProp(ent) then
        return false, "This prop is already marked as a tanker."
    end

    if Delivery_PlayerHasTanker(ply) then
        return false, "You already have a tanker marked."
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then
        return false, "This prop has no valid physics object."
    end

    local capacity = Delivery_ClampTankerCapacity(capacityLiters)
    local originalMass = phys:GetMass()
    local emptyMass = Delivery_GetTankerEmptyMass(capacity)
    nerfed = nerfed and true or false

    ApplyTankerMetadata(ent, ply:SteamID64() or "", ply, capacity, originalMass, emptyMass, nerfed)

    StoreTankerModifier(ent)
    SetPropMass(ent, emptyMass)

    return true, string.format(
        "Marked tanker at %s L capacity.%s",
        Delivery_FormatLiters(capacity),
        nerfed and " (NERFED: weight will not change and sell price is halved)" or ""
    )
end

function Delivery_UnmarkTankerProp(ply, ent)
    if not Delivery_IsTankerProp(ent) then
        return false, "That prop is not marked as a tanker."
    end

    if ent:GetNWBool("DeliveryTankerBusy", false) then
        return false, "You cannot unmark a tanker while it is filling or emptying."
    end

    local ownerId = ent:GetNWString("DeliveryTankerOwnerID", "")
    if IsValid(ply) and ownerId ~= "" and ownerId ~= (ply:SteamID64() or "") then
        return false, "That tanker belongs to another player."
    end

    local originalMass = ent:GetNWFloat("DeliveryTankerOriginalMass", 50)

    ent:SetNWBool("DeliveryIsTanker", false)
    ent:SetNWString("DeliveryTankerOwnerID", "")
    ent:SetNWEntity("DeliveryTankerOwner", NULL)
    ent:SetNWInt("DeliveryTankerCapacity", 0)
    ent:SetNWFloat("DeliveryTankerOriginalMass", 0)
    ent:SetNWFloat("DeliveryTankerEmptyMass", 0)
    ent:SetNWBool("DeliveryTankerBusy", false)
    ent:SetNWBool("DeliveryTankerNerfed", false)
    ent:SetNWString("DeliveryTankerLiquidKey", "")
    ent:SetNWFloat("DeliveryTankerLiquidLitersFloat", 0)
    ent:SetNWInt("DeliveryTankerLiquidLiters", 0)

    ClearTankerModifier(ent)
    StopTransferSound(ent)
    SetPropMass(ent, originalMass)

    return true, "Removed tanker mark and restored the original weight."
end

timer.Create("Delivery_TankerParentCheck", 2, 0, function()
    for _, className in ipairs(table.GetKeys(TANKER_PROP_CLASSES)) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if Delivery_IsTankerProp(ent) and IsValid(ent:GetParent()) then
                local owner = ent:GetNWEntity("DeliveryTankerOwner")
                Delivery_UnmarkTankerProp(owner, ent)
                if IsValid(owner) then
                    owner:ChatPrint("[Delivery] Your tanker was unmarked because it was parented.")
                end
            end
        end
    end
end)
