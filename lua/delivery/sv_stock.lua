-- server side stock table, resets on restart
DELIVERY_STOCK = DELIVERY_STOCK or {}

local function NormalizeRequires(req)
    if not req then return nil end
    if req.item then return { req } end
    return req
end

local function GetStockOwnerId(ply)
    if not IsValid(ply) then return nil end

    local steamID64 = ply:SteamID64()
    if steamID64 and steamID64 ~= "" then
        return steamID64
    end

    return "uid_" .. ply:UserID()
end

function Delivery_GetStockState(ply, create)
    local ownerId = GetStockOwnerId(ply)
    if not ownerId then return nil end

    local state = DELIVERY_STOCK[ownerId]
    if not state and create then
        state = {
            stock = {},
            counters = {},
        }
        DELIVERY_STOCK[ownerId] = state
    end

    return state
end

function Delivery_GetStock(ply, cargoKey)
    local state = Delivery_GetStockState(ply, false)
    if not state then return 0 end
    return state.stock[cargoKey] or 0
end

function Delivery_AddStock(ply, cargoKey, amount)
    local state = Delivery_GetStockState(ply, true)
    state.stock[cargoKey] = (state.stock[cargoKey] or 0) + (amount or 1)
    Delivery_SyncStock(ply)
end

function Delivery_DeductStock(ply, cargoKey, amount)
    local state = Delivery_GetStockState(ply, true)
    local current = state.stock[cargoKey] or 0
    state.stock[cargoKey] = math.max(0, current - (amount or 1))
    Delivery_SyncStock(ply)
end

function Delivery_HasStock(ply, cargoKey)
    local cargo = DELIVERY_CARGO[cargoKey]
    if not cargo then return false end
    local reqs = NormalizeRequires(cargo.requires)
    if not reqs then return true end
    return Delivery_GetStock(ply, cargoKey) > 0
end

function Delivery_GetRequires(cargoKey)
    local cargo = DELIVERY_CARGO[cargoKey]
    if not cargo then return nil end
    return NormalizeRequires(cargo.requires)
end

function Delivery_SyncStock(ply)
    if not IsValid(ply) then return end

    local state = Delivery_GetStockState(ply, false)
    local stockData = {}
    for k, v in pairs(state and state.stock or {}) do
        stockData[#stockData + 1] = k .. "=" .. v
    end

    net.Start("Delivery_SyncStock")
        net.WriteString(table.concat(stockData, ","))
    net.Send(ply)
end

-- sync stock to a specific player when they join
hook.Add("PlayerInitialSpawn", "Delivery_StockSync", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        Delivery_SyncStock(ply)
    end)
end)
