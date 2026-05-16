local SEWAGE_PROP_CLASSES = {
    prop_physics = true,
    primitive_shape = true,
}

local function SewageTankerOwnedByLocalPlayer(ent)
    if not IsValid(ent) or not ent:GetNWBool("SewageIsTanker", false) then return false end

    local owner = ent:GetNWEntity("SewageTankerOwner")
    if IsValid(owner) then
        return owner == LocalPlayer()
    end

    local ownerId = ent:GetNWString("SewageTankerOwnerID", "")
    local steamID64 = LocalPlayer():SteamID64()
    return steamID64 ~= nil and steamID64 ~= "" and ownerId == steamID64
end

function Sewage_GetNearbyOwnedTankerCL(npcPos, requireSpace)
    local lp = LocalPlayer()
    if not IsValid(lp) then return nil end

    local maxDist = SEWAGE_CONFIG and SEWAGE_CONFIG.collectRadius or 350
    local bestEnt, bestDist

    for className, _ in pairs(SEWAGE_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if SewageTankerOwnedByLocalPlayer(ent) then
                local nearNPC = npcPos and ent:GetPos():Distance(npcPos) <= maxDist
                local nearPly = ent:GetPos():Distance(lp:GetPos()) <= maxDist
                if nearNPC or nearPly then
                    if requireSpace then
                        local liters = ent:GetNWFloat("SewageTankerLitersFloat", 0)
                        local capacity = ent:GetNWInt("SewageTankerCapacity", 0)
                        if liters >= capacity then continue end
                    end

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

    return bestEnt
end

function Sewage_GetOwnedTankerCL(requireSpace)
    local lp = LocalPlayer()
    if not IsValid(lp) then return nil end

    for className, _ in pairs(SEWAGE_PROP_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if SewageTankerOwnedByLocalPlayer(ent) then
                if requireSpace then
                    local liters = ent:GetNWFloat("SewageTankerLitersFloat", 0)
                    local capacity = ent:GetNWInt("SewageTankerCapacity", 0)
                    if liters >= capacity then continue end
                end
                return ent
            end
        end
    end

    return nil
end

hook.Add("HUDPaint", "Sewage_DrawHUD", function()
    if not Sewage_IsJobActive() then return end

    local jobManholes = Sewage_GetJobManholes()
    local collected = Sewage_GetJobCollected()
    local total = #jobManholes
    local drained = Sewage_IsJobDrained()

    local x, y = ScrW() - 250, 100
    local w, h = 230, 80

    draw.RoundedBox(8, x, y, w, h, Color(30, 30, 30, 200))
    draw.RoundedBox(8, x, y, w, 25, Color(40, 120, 40, 200))
    
    draw.SimpleText("Sewage Job", "DermaDefaultBold", x + w/2, y + 12, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local progressText = "Manholes: " .. collected .. "/" .. total
    draw.SimpleText(progressText, "DermaDefault", x + 10, y + 35, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    local tanker = Sewage_GetOwnedTankerCL(false)
    if IsValid(tanker) then
        local liters = tanker:GetNWFloat("SewageTankerLitersFloat", 0)
        local capacity = tanker:GetNWInt("SewageTankerCapacity", 0)
        local percent = capacity > 0 and (liters / capacity * 100) or 0
        
        draw.SimpleText("Tanker: " .. math.floor(liters) .. "L / " .. capacity .. "L (" .. math.floor(percent) .. "%)", "DermaDefault", x + 10, y + 50, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("You dont have a sewage tanker marked!", "DermaDefault", x + 10, y + 50, Color(255, 100, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end)

hook.Add("PostDrawOpaqueRenderables", "Sewage_DrawHighlights", function()
    if not Sewage_IsJobActive() then return end

    local jobManholes = Sewage_GetJobManholes()
    local collectedIndices = {}

    for _, ent in ipairs(ents.FindByClass("sent_manhole")) do
        if IsValid(ent) then
            local address = ent:GetNWString("ManholeAddress", "")
            local isJobTarget = false
            local isCollected = false

            for i, addr in ipairs(jobManholes) do
                if addr == address then
                    isJobTarget = true
                    isCollected = SEWAGE_JOB_COLLECTED_INDICES[ent:EntIndex()] or false
                    break
                end
            end

            if isJobTarget and not isCollected then
                local pos = ent:GetPos() + Vector(0, 0, 30)
                local color = Color(0, 255, 0, 150)

                render.SetColorMaterial()
                render.DrawSphere(pos, 20, 16, 8, color)

                cam.Start3D2D(pos + Vector(0, 0, 10), Angle(0, EyeAngles().y - 90, 90), 0.1)
                    draw.SimpleText(address, "ChatFont", 0, 0, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            end
        end
    end

    for _, ent in ipairs(ents.FindByClass("sent_sewage_dropoff")) do
        if IsValid(ent) and Sewage_GetJobCollected() == #jobManholes and not Sewage_IsJobDrained() then
            local pos = ent:GetPos() + Vector(0, 0, 30)
            local color = Color(255, 200, 0, 150)
            
            render.SetColorMaterial()
            render.DrawSphere(pos, 25, 16, 8, color)
            
            cam.Start3D2D(pos + Vector(0, 0, 15), Angle(0, EyeAngles().y - 90, 90), 0.15)
                draw.SimpleText("DROPOFF", "ChatFont", 0, 0, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end)
