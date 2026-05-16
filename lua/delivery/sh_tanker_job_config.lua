TANKER_CARGO = TANKER_CARGO or {

    ["diesel_tanker"] = {
        label = "Diesel",
        isLiquid = true,
        liters = 10000,
        densityKgPerLiter = 1,
        allowedTeams = { "TEAM_HEAVY_DUTY" },
    },

}

TANKER_NPCS = TANKER_NPCS or {

    ["tanker_refinery"] = {
        label = "Refinery Dispatcher",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {
            { item = "diesel_tanker", label = "Diesel", price = 4500 },
        },
        buys = {},
    },
    ["tanker_gas_station"] = {
        label = "Fuel Depot Manager",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {},
        buys = {
            { item = "diesel_tanker", label = "Diesel", price = 6000 },
        },
    },

}

DELIVERY_CARGO = DELIVERY_CARGO or {}
for key, data in pairs(TANKER_CARGO) do
    DELIVERY_CARGO[key] = data
end

DELIVERY_NPCS = DELIVERY_NPCS or {}
for key, data in pairs(TANKER_NPCS) do
    DELIVERY_NPCS[key] = data
end

