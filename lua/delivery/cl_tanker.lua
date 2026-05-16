local TANKER_PROP_CLASSES = {
    prop_physics = true,
    primitive_shape = true,
}

local function TankerOwnedByLocalPlayer(ent)
    if not IsValid(ent) or not ent:GetNWBool("DeliveryIsTanker", false) then return false end

    local owner = ent:GetNWEntity("DeliveryTankerOwner")
    if IsValid(owner) then
        return owner == LocalPlayer()
    end

    local ownerId = ent:GetNWString("DeliveryTankerOwnerID", "")
    local steamID64 = LocalPlayer():SteamID64()
    return steamID64 ~= nil and steamID64 ~= "" and ownerId == steamID64
end

function Delivery_GetNearbyOwnedTankerCL(npcPos, liquidKey)
    local lp = LocalPlayer()
    if not IsValid(lp) then return nil end

    local maxDist = DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.searchRadius or 300
    local bestEnt, bestDist

    for className, _ in pairs(TANKER_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if TankerOwnedByLocalPlayer(ent) then
                local nearNPC = npcPos and ent:GetPos():Distance(npcPos) <= maxDist
                local nearPly = ent:GetPos():Distance(lp:GetPos()) <= maxDist
                if nearNPC or nearPly then
                    local currentLiquid = ent:GetNWString("DeliveryTankerLiquidKey", "")
                    local liters = ent:GetNWInt("DeliveryTankerLiquidLiters", 0)
                    if not liquidKey or (currentLiquid == liquidKey and liters > 0) then
                        local dist = math.min(
                            nearNPC and ent:GetPos():Distance(npcPos) or math.huge,
                            ent:GetPos():Distance(lp:GetPos())
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
