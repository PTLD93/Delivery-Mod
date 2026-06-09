GRAIN_CARGO = {

    ["wheat_grain"] = {
        label = "Wheat",
        isGrain = true,
        liters = 25000,
        densityKgPerLiter = 0.8, -- 800 kg per 1 m3
        --allowedTeams = { "TEAM_HEAVY_DUTY" },
    },
    ["corn_grain"] = {
        label = "Corn",
        isGrain = true,
        liters = 28571,
        densityKgPerLiter = 0.7, -- 700 kg per 1 m3
        --allowedTeams = { "TEAM_HEAVY_DUTY" },
    },
    ["soybean_grain"] = {
        label = "Soybeans",
        isGrain = true,
        liters = 26666,
        densityKgPerLiter = 0.75, -- 750 kg per 1 m3
        --allowedTeams = { "TEAM_HEAVY_DUTY" },
    },

}

GRAIN_NPCS = {

    ["grain_farm"] = {
        label = "Grain Operator",
        model = "models/humans/group01/male_08.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {
            { item = "wheat_grain", label = "Wheat", price = 3000 },
			{ item = "corn_grain", label = "Corn", price = 2500 },
			{ item = "soybean_grain", label = "Soybeans", price = 3500 },
        },
        buys = {},
    },
    ["grain_factory"] = {
        label = "Farmer Silo Operator",
        model = "models/humans/group01/male_09.mdl",
        spawnOffset = Vector(0, 40, 20),
        sells = {},
        buys = {
            { item = "wheat_grain", label = "Wheat", price = 9000 },
			{ item = "corn_grain", label = "Corn", price = 8500 },
			{ item = "soybean_grain", label = "Soybeans", price = 10000 },
        },
    },

}

DELIVERY_CARGO = DELIVERY_CARGO or {}
for key, data in pairs(GRAIN_CARGO) do
    DELIVERY_CARGO[key] = data
end

DELIVERY_NPCS = DELIVERY_NPCS or {}
for key, data in pairs(GRAIN_NPCS) do
    DELIVERY_NPCS[key] = data
end
