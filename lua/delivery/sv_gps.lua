local function GetPlayerCargo(ply)
    local cargo = {}
    for _, ent in ipairs(ents.FindByClass("sent_cargo")) do
        if ent:GetNWEntity("CargoOwner") == ply then
            table.insert(cargo, ent)
        end
    end
    return cargo
end

local function FindNPCBuyingItem(itemKey)
    for npcKey, data in pairs(DELIVERY_NPCS) do
        for _, buyData in ipairs(data.buys) do
            if buyData.item == itemKey then
                -- Find spawned NPC of this type
                for _, npcEnt in ipairs(ents.FindByClass("sent_delivery_npc")) do
                    if npcEnt:GetDeliveryNPCKey() == npcKey then
                        return npcEnt:GetPos(), data.label
                    end
                end
                
                -- Fallback to map data if NPC not spawned
                local map = game.GetMap()
                if DELIVERY_MAPDATA[map] then
                    for _, entry in ipairs(DELIVERY_MAPDATA[map]) do
                        if entry.npc_key == npcKey then
                            return entry.pos, data.label
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

net.Receive("GPS_SelectAddress", function(len, ply)
    local type = net.ReadString()
    local addr = net.ReadString()
    
    local pos = nil
    local map = game.GetMap()
    
    if type == "Express" then
        if addr == "Express NPC" then
            local job = EXPRESS_ACTIVE_JOBS[ply:SteamID()]
            if job and IsValid(ents.GetByIndex(job.npcEntIdx)) then
                pos = ents.GetByIndex(job.npcEntIdx):GetPos()
            end
        elseif EXPRESS_DROPOFF_MAPDATA[map] then
            for _, data in ipairs(EXPRESS_DROPOFF_MAPDATA[map]) do
                if data.address == addr then
                    pos = data.pos
                    break
                end
            end
        end
    elseif type == "Sewage" then
        if addr == "Sewage NPC" then
            local job = SEWAGE_ACTIVE_JOBS[ply:SteamID()]
            if job and IsValid(ents.GetByIndex(job.npcEntIndex)) then
                pos = ents.GetByIndex(job.npcEntIndex):GetPos()
            end
        elseif addr == "Sewage Dropoff" then
            local dropoff = ents.FindByClass("sent_sewage_dropoff")[1]
            if IsValid(dropoff) then
                pos = dropoff:GetPos()
            end
        elseif SEWAGE_MANHOLE_MAPDATA[map] then
            for _, data in ipairs(SEWAGE_MANHOLE_MAPDATA[map]) do
                if data.address == addr then
                    pos = data.pos
                    break
                end
            end
        end
    elseif type == "Delivery" then
        -- Find the NPC position for this buyer label
        for npcKey, data in pairs(DELIVERY_NPCS) do
            if data.label == addr then
                -- Try to find spawned NPC first
                for _, npcEnt in ipairs(ents.FindByClass("sent_delivery_npc")) do
                    if npcEnt:GetDeliveryNPCKey() == npcKey then
                        pos = npcEnt:GetPos()
                        break
                    end
                end
                
                if pos then break end

                -- Fallback to map data
                if DELIVERY_MAPDATA[map] then
                    for _, entry in ipairs(DELIVERY_MAPDATA[map]) do
                        if entry.npc_key == npcKey then
                            pos = entry.pos
                            break
                        end
                    end
                end
                break
            end
        end
    end
    
    if pos then
        net.Start("GPS_SetWaypoint")
        net.WriteVector(pos)
        net.WriteString(addr)
        net.Send(ply)
    end
end)

-- Function to handle delivery GPS logic (automatic detection)
function Delivery_GPS_Detect(ply)
    local cargos = GetPlayerCargo(ply)
    if #cargos == 0 then
        ply:ChatPrint("[GPS] You don't own any cargo to track.")
        return
    end
    
    local uniqueBuyers = {}
    local buyerNames = {}
    
    for _, cargo in ipairs(cargos) do
        local itemKey = cargo:GetCargoKey()
        local pos, npcName = FindNPCBuyingItem(itemKey)
        
        if pos and npcName and not uniqueBuyers[npcName] then
            uniqueBuyers[npcName] = pos
            table.insert(buyerNames, npcName)
        end
    end
    
    if #buyerNames == 0 then
        ply:ChatPrint("[GPS] Could not find any buyers for your cargo.")
        return
    elseif #buyerNames == 1 then
        -- Only one buyer, track automatically
        local npcName = buyerNames[1]
        local pos = uniqueBuyers[npcName]
        
        net.Start("GPS_SetWaypoint")
        net.WriteVector(pos)
        net.WriteString(npcName)
        net.Send(ply)
    else
        -- Multiple buyers, open menu
        net.Start("GPS_OpenMenu")
        net.WriteString("Delivery")
        net.WriteInt(#buyerNames, 8)
        for _, name in ipairs(buyerNames) do
            net.WriteString(name)
        end
        net.Send(ply)
    end
end
