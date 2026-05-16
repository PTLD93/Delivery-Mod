local function StartFishing(rod)
    if not IsValid(rod) then return end
    if rod:GetBait() <= 0 then return end
    if rod:GetFishing() then return end
    if rod:GetHasFish() then return end

    rod:SetFishing(true)

    local biteTime = math.random(FISHING_CONFIG.biteTimeMin, FISHING_CONFIG.biteTimeMax)

    timer.Create("FishingBite_" .. rod:EntIndex(), biteTime, 1, function()
        if not IsValid(rod) then return end
        if not rod:GetFishing() then return end

        local fish = FISHING_GetRandomFish()

        rod:SetFishing(false)
        rod:SetHasFish(true)
        rod:SetFishLabel(fish.label)
        rod:SetBait(rod:GetBait() - 1)

        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():Distance(rod:GetPos()) < 500 then
                ply:ChatPrint("[Fishing] A " .. fish.label .. " was caught on a nearby rod!")
            end
        end
    end)
end

net.Receive("Fishing_AddBait", function(len, ply)
    local rod    = net.ReadEntity()
    local amount = net.ReadInt(8)

    if not IsValid(rod) then return end
    if rod:GetClass() ~= "sent_fishing_rod" then return end

    local cost = amount * FISHING_CONFIG.baitPrice
    if ply:getDarkRPVar("money") < cost then
        ply:ChatPrint("[Fishing] You need $" .. cost .. " for " .. amount .. " bait.")
        return
    end

    local newBait = rod:GetBait() + amount
    if newBait > FISHING_CONFIG.maxBait then
        ply:ChatPrint("[Fishing] This rod can only hold " .. FISHING_CONFIG.maxBait .. " bait!")
        return
    end

    ply:addMoney(-cost)
    rod:SetBait(newBait)
    ply:ChatPrint("[Fishing] Added " .. amount .. " bait. Rod now has " .. newBait .. " bait.")

    StartFishing(rod)
end)

net.Receive("Fishing_CollectFish", function(len, ply)
    local rod = net.ReadEntity()

    if not IsValid(rod) then return end
    if rod:GetClass() ~= "sent_fishing_rod" then return end
    if not rod:GetHasFish() then
        ply:ChatPrint("[Fishing] No fish to collect!")
        return
    end

    local fishLabel = rod:GetFishLabel()
    local fishData  = nil

    for _, f in ipairs(FISHING_FISH) do
        if f.label == fishLabel then
            fishData = f
            break
        end
    end

    if not fishData then return end

    local fish = ents.Create("sent_fish")
    if not IsValid(fish) then return end

    fish:SetPos(ply:GetPos() + ply:GetForward() * 40 + Vector(0, 0, 10))
    fish:SetFishLabel(fishData.label)
    fish:SetFishValue(fishData.value)
    fish:SetOwnerPlayer(ply)
    fish:Spawn()
    fish:Activate()

    rod:SetHasFish(false)
    rod:SetFishLabel("")

    ply:ChatPrint("[Fishing] Collected a " .. fishData.label .. " worth $" .. fishData.value .. "!")

    if rod:GetBait() > 0 then
        StartFishing(rod)
    else
        ply:ChatPrint("[Fishing] Rod is out of bait!")
    end
end)

hook.Add("PlayerDisconnected", "Fishing_Cleanup", function(ply)
    for _, ent in ipairs(ents.GetAll()) do
        local class = ent:GetClass()
        if class == "sent_fishing_rod" or class == "sent_fish" then
            if ent.GetOwnerPlayer and ent:GetOwnerPlayer() == ply then
                ent:Remove()
            end
        end
    end
end)