TANKER_CARGO = TANKER_CARGO or {

    ["diesel"] = {
        label = "Diesel",
        isLiquid = true,
        liters = 10000,
        densityKgPerLiter = 1,
        --allowedTeams = { "TEAM_HEAVY_DUTY" },
    },
	["gasoline"] = {
        label = "Gasoline",
        isLiquid = true,
        liters = 10000,
        densityKgPerLiter = 1,
        --allowedTeams = { "TEAM_HEAVY_DUTY" },
    },

}

TANKER_NPCS = TANKER_NPCS or {

    ["tanker_refinery"] = {
        label = "Refinery Dispatcher",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {
            { item = "diesel", label = "Diesel", price = 5000 },
			{ item = "gasoline", label = "Gasoline", price = 5500 },
        },
        buys = {},
    },
    ["tanker_gas_station_tnf"] = {
        label = "Gas Station TNF",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {},
        buys = {
            { item = "diesel", label = "Diesel", price = 7000 },
			{ item = "gasoline", label = "Gasoline", price = 7700 },
        },
    },
	["tanker_gas_station_hwy"] = {
        label = "Gas Station BerBait",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {},
        buys = {
            { item = "diesel", label = "Diesel", price = 7000 },
			{ item = "gasoline", label = "Gasoline", price = 7700 },
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

