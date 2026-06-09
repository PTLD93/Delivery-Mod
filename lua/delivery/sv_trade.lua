hook.Add("CPPICanSetOwner", "Cargo_WorldOwned", function(ent, ply)
    if ent:GetClass() == "sent_cargo" then
        return false
    end
end)

local function FormatRequirementText(req, separator)
    if not req then return nil end

    local reqs = req.item and { req } or req
    local parts = {}
    for _, entry in ipairs(reqs) do
        local reqCargo = DELIVERY_CARGO[entry.item]
        parts[#parts + 1] = (entry.ratio or 1) .. "x " .. (reqCargo and reqCargo.label or entry.item)
    end

    return #parts > 0 and table.concat(parts, separator or ", ") or nil
end

net.Receive("DeliveryNPC_Buy", function(len, ply)
    local npcKey  = net.ReadString()
    local item    = net.ReadString()
    local npcPos  = net.ReadVector()
    local cargoEntry = DELIVERY_CARGO[item]
    local requestedLiters = nil
    if cargoEntry and Delivery_IsGrainCargo and Delivery_IsGrainCargo(cargoEntry) then
        requestedLiters = net.ReadUInt(32)
    end

    local npcData = DELIVERY_NPCS[npcKey]
    if not npcData then return end

    --if not Delivery_IsAllowedJob(ply) and not ply:IsAdmin() then
    --    ply:ChatPrint("[Delivery] You must be a delivery worker to buy cargo.")
    --    return
    --end

    if not Delivery_CanBuyCargo(ply, item) then
        ply:ChatPrint("[Delivery] Your current job cannot purchase this cargo.")
        return
    end

    -- check supply chain stock
    if not Delivery_HasStock(ply, item) then
        local cargo = DELIVERY_CARGO[item]
        local req   = cargo and cargo.requires
        if req then
            local reqText = FormatRequirementText(req, " or ")
            ply:ChatPrint("[Delivery] " .. (cargo.label or item) .. " is out of stock! Deliver " .. (reqText or "the required cargo") .. " to produce more.")
        else
            ply:ChatPrint("[Delivery] " .. (DELIVERY_CARGO[item] and DELIVERY_CARGO[item].label or item) .. " is out of stock!")
        end
        return
    end

    -- check per-type cargo limit
    local cargoData = DELIVERY_CARGO[item]
    if cargoData and not Delivery_IsLiquidCargo(cargoData) then
        local typeLimit = cargoData.limit or DELIVERY_CONFIG.cargoLimit
        local carried = 0
        for _, ent in ipairs(ents.FindByClass("sent_cargo")) do
            if ent:GetCargoKey() == item and ent:GetNWEntity("CargoOwner") == ply then
                carried = carried + 1
            end
        end
        if carried >= typeLimit then
            ply:ChatPrint("[Delivery] You are already carrying too many " .. cargoData.label .. "s!")
            return
        end
    end

    -- find item in NPC sell list
    local itemData = nil
    for _, v in ipairs(npcData.sells) do
        if v.item == item then
            itemData = v
            break
        end
    end

    if not itemData then return end

    -- handle fishing rod separately
    if item == "sent_fishing_rod" then
        if ply:getDarkRPVar("money") < itemData.price then
            ply:ChatPrint("[Delivery] You don't have enough money!")
            return
        end

        ply:addMoney(-itemData.price)

        local rod = ents.Create("sent_fishing_rod")
        if not IsValid(rod) then return end

        rod:SetPos(ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 20))
        rod:Spawn()
        rod:Activate()

        ply:ChatPrint("[Delivery] You bought a " .. itemData.label .. " for $" .. itemData.price)
        return
    end

    if not DELIVERY_CARGO[item] then
        ply:ChatPrint("[Delivery] Unknown cargo type!")
        return
    end

    if ply:getDarkRPVar("money") < itemData.price then
        ply:ChatPrint("[Delivery] You don't have enough money!")
        return
    end

    if Delivery_IsLiquidCargo(DELIVERY_CARGO[item]) then
        local ok, msg = Delivery_StartTankerTransfer(ply, npcPos, item, "fill", itemData.price)
        if not ok then
            ply:ChatPrint("[Delivery] " .. msg)
            return
        end

        ply:ChatPrint("[Delivery] " .. msg)
        return
    end

    if Delivery_IsGrainCargo and Delivery_IsGrainCargo(DELIVERY_CARGO[item]) then
        local basePrice = itemData.price
        local baseLiters = Delivery_GetGrainLiters(DELIVERY_CARGO[item])
        local finalPrice = basePrice
        local finalLiters = baseLiters

        if requestedLiters and requestedLiters > 0 and baseLiters > 0 then
            finalLiters = requestedLiters
            finalPrice = math.ceil((requestedLiters / baseLiters) * basePrice)
        end

        local ok, msg = Delivery_StartGrainTransfer(ply, npcPos, item, "fill", finalPrice, finalLiters)
        if not ok then
            ply:ChatPrint("[Delivery] " .. msg)
            return
        end

        ply:ChatPrint("[Delivery] " .. msg)
        return
    end

    ply:addMoney(-itemData.price)

    -- deduct stock if this cargo has a supply chain requirement
    if DELIVERY_CARGO[item] and DELIVERY_CARGO[item].requires then
        Delivery_DeductStock(ply, item)
    end

    local npcEnt, bestDist = nil, math.huge
    for _, ent in ipairs(ents.FindByClass("sent_delivery_npc")) do
        if ent:GetDeliveryNPCKey() == npcKey then
            local dist = ent:GetPos():Distance(npcPos)
            if dist < bestDist then
                bestDist = dist
                npcEnt   = ent
            end
        end
    end

    local cargo = ents.Create("sent_cargo")
    if not IsValid(cargo) then return end

    local spawnPos
    if IsValid(npcEnt) then
        local offset
        if npcEnt:GetNWBool("HasCargoSpawnOffset", false) then
            offset = npcEnt:GetNWVector("CargoSpawnOffset", Vector( 50, 0, 20 ))
        else
            offset = npcData.spawnOffset or Vector( 50, 0, 20 )
        end
        local fwd   = npcEnt:GetForward()
        local right = npcEnt:GetRight()
        spawnPos = npcEnt:GetPos() + fwd * offset.x + right * offset.y + Vector( 0, 0, offset.z )
    else
        spawnPos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 20)
    end

    cargo:SetPos(spawnPos)
    cargo:Spawn()
    cargo:Activate()
    cargo:SetupCargo(item)
    cargo:SetNWEntity("CargoOwner", ply)

    timer.Simple(0, function()
        if not IsValid(cargo) then return end
        cargo:CPPISetOwner(game.GetWorld())
    end)

    ply:ChatPrint("[Delivery] You bought a " .. itemData.label .. " for $" .. itemData.price)
end)

net.Receive("DeliveryNPC_Sell", function(len, ply)
    local npcKey  = net.ReadString()
    local item    = net.ReadString()
    local npcData = DELIVERY_NPCS[npcKey]
    if not npcData then return end

    -- handle fish separately
    if item == "sent_fish" then
        local fish = nil
        for _, ent in ipairs(ents.FindByClass("sent_fish")) do
            if ent:GetNWEntity("FishOwner") == ply then
                fish = ent
                break
            end
        end

        if not IsValid(fish) then
            ply:ChatPrint("[Delivery] You don't have any fish to sell!")
            return
        end

        local price = fish:GetFishValue()
        local label = fish:GetFishLabel()
        fish:Remove()
        ply:addMoney(price)
        ply:ChatPrint("[Delivery] You sold a " .. label .. " for $" .. price)
        return
    end

    -- find item in NPC buy list
    local itemData = nil
    for _, v in ipairs(npcData.buys) do
        if v.item == item then
            itemData = v
            break
        end
    end

    if not itemData then
        ply:ChatPrint("[Delivery] This NPC does not buy that item.")
        return
    end

    local npcEnt = nil
    for _, ent in ipairs(ents.GetAll()) do
        if ent.GetDeliveryNPCKey and ent:GetDeliveryNPCKey() == npcKey then
            npcEnt = ent
            break
        end
    end

    if Delivery_IsLiquidCargo(DELIVERY_CARGO[item]) then
        local ok, tankerOrMsg = Delivery_StartTankerTransfer(ply, IsValid(npcEnt) and npcEnt:GetPos() or nil, item, "drain", itemData.price)
        if not ok then
            ply:ChatPrint("[Delivery] " .. tankerOrMsg)
            return
        end

        ply:ChatPrint("[Delivery] " .. tankerOrMsg)
        return
    end

    if Delivery_IsGrainCargo and Delivery_IsGrainCargo(DELIVERY_CARGO[item]) then
        local ok, msg = Delivery_StartGrainTransfer(ply, IsValid(npcEnt) and npcEnt:GetPos() or nil, item, "drain", itemData.price)
        if not ok then
            ply:ChatPrint("[Delivery] " .. msg)
            return
        end

        ply:ChatPrint("[Delivery] " .. msg)
        return
    end

    local toSell = {}
    for _, ent in ipairs(ents.FindByClass("sent_cargo")) do
        if ent:GetCargoKey() == item then
            local owner      = ent:GetNWEntity("CargoOwner")
            if IsValid(owner) and owner ~= ply then continue end

            local nearPlayer = ent:GetPos():Distance(ply:GetPos()) < 1000
            local nearNPC    = IsValid(npcEnt) and ent:GetPos():Distance(npcEnt:GetPos()) < 1000

            if nearPlayer or nearNPC then
                toSell[#toSell + 1] = ent
            end
        end
    end

    if #toSell == 0 then
        ply:ChatPrint("[Delivery] No " .. itemData.label .. " found nearby that belongs to you!")
        return
    end

    local totalPrice = 0
    for _, cargo in ipairs(toSell) do
        local p = cargo:GetCargoValue()
        if p <= 0 then p = itemData.price end
        totalPrice = totalPrice + p
        cargo:Remove()
    end

    ply:addMoney(totalPrice)
    ply:ChatPrint("[Delivery] You sold " .. #toSell .. "x " .. itemData.label .. " for $" .. totalPrice .. " total.")

    -- check if this delivery produces stock for another cargo
    local soldCargoData = DELIVERY_CARGO[item]
    if soldCargoData and soldCargoData.produces then
        local announcedProduced = {}
        local stockState = Delivery_GetStockState(ply, true)
        local counters = stockState.counters
        for _, production in ipairs(soldCargoData.produces) do
            local counterKey = "counter_" .. item .. "_to_" .. production.item
            counters[counterKey] = (counters[counterKey] or 0) + #toSell

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
end)
