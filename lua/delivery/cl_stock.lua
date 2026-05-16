-- client side stock table synced from server
DELIVERY_STOCK_CL = DELIVERY_STOCK_CL or {}

net.Receive("Delivery_SyncStock", function()
    local raw = net.ReadString()
    DELIVERY_STOCK_CL = {}

    if raw == "" then return end

    for _, pair in ipairs(string.Explode(",", raw)) do
        local parts = string.Explode("=", pair)
        if parts[1] and parts[2] then
            DELIVERY_STOCK_CL[parts[1]] = tonumber(parts[2]) or 0
        end
    end
end)

function Delivery_GetStockCL(cargoKey)
    return DELIVERY_STOCK_CL[cargoKey] or 0
end

function Delivery_HasStockCL(cargoKey)
    local cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKey]
    if not cargo then return false end
    if not cargo.requires then return true end
    return (DELIVERY_STOCK_CL[cargoKey] or 0) > 0
end
