local function SanitizeName(name)
    return string.gsub(name, '[\\"]', "")
end

local function SendOwnedLevels(ply)
    local owned = Rank_GetOwned(ply)
    local bits = 0
    for level, _ in pairs(owned) do
        bits = bits + bit.lshift(1, level - 1)
    end

    net.Start("RankNPC_SyncOwned")
        net.WriteUInt(bits, 8)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "RankNPC_SyncOnJoin", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            SendOwnedLevels(ply)
        end
    end)
end)

net.Receive("RankNPC_Buy", function(len, ply)
    local level = net.ReadUInt(4)
    local data  = RANK_LEVELS[level]
    if not data then return end

    if Rank_HasPurchased(ply, level) then
        ply:ChatPrint("[Rank] You already own " .. data.label .. "!")
        return
    end

    if level > 1 and not Rank_HasPurchased(ply, level - 1) then
        local prev = RANK_LEVELS[level - 1]
        ply:ChatPrint("[Rank] You must own " .. prev.label .. " before purchasing " .. data.label .. ".")
        return
    end

    if ply:getDarkRPVar("money") < data.price then
        ply:ChatPrint("[Rank] You need $" .. data.price .. " to purchase " .. data.label .. ".")
        return
    end

    ply:addMoney(-data.price)
    Rank_SavePurchase(ply, level)

    game.ConsoleCommand('ulx setdonator "' .. SanitizeName(ply:Nick()) .. '" ' .. level .. '\n')

    ply:ChatPrint("[Rank] You purchased " .. data.label .. "! Your rank has been set.")
    print("[Rank] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") purchased Donator Level " .. level)

    SendOwnedLevels(ply)
end)

net.Receive("RankNPC_Apply", function(len, ply)
    local level = net.ReadUInt(4)
    local data  = RANK_LEVELS[level]
    if not data then return end

    if not Rank_HasPurchased(ply, level) then
        ply:ChatPrint("[Rank] You have not purchased Level " .. level .. ".")
        return
    end

    game.ConsoleCommand('ulx setdonator "' .. SanitizeName(ply:Nick()) .. '" ' .. level .. '\n')
    ply:ChatPrint("[Rank] " .. data.label .. " has been re-applied.")
end)