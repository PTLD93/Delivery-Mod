local GRAIN_PROP_CLASSES = {
    prop_physics = true,
    primitive_shape = true,
}

local function GrainBedOwnedByLocalPlayer(ent)
    if not IsValid(ent) or not ent:GetNWBool("DeliveryIsGrainBed", false) then return false end

    local owner = ent:GetNWEntity("DeliveryGrainBedOwner")
    if IsValid(owner) then
        return owner == LocalPlayer()
    end

    local ownerId = ent:GetNWString("DeliveryGrainBedOwnerID", "")
    local steamID64 = LocalPlayer():SteamID64()
    return steamID64 ~= nil and steamID64 ~= "" and ownerId == steamID64
end

function Delivery_GetNearbyOwnedGrainBedsCL(npcPos, cargoKey)
    local lp = LocalPlayer()
    if not IsValid(lp) then return {} end

    local maxDist = DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.searchRadius or 300
    local foundBeds = {}

    for className, _ in pairs(GRAIN_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if GrainBedOwnedByLocalPlayer(ent) then
                local nearNPC = npcPos and ent:GetPos():Distance(npcPos) <= maxDist
                local nearPly = ent:GetPos():Distance(lp:GetPos()) <= maxDist
                if nearNPC or nearPly then
                    local currentCargo = ent:GetNWString("DeliveryGrainBedCargoKey", "")
                    local liters = ent:GetNWInt("DeliveryGrainBedLiters", 0)
                    if not cargoKey or (currentCargo == cargoKey and liters > 0) then
                        table.insert(foundBeds, ent)
                    end
                end
            end
        end
    end

    return foundBeds
end
