DELIVERY_TANKER_CONFIG = DELIVERY_TANKER_CONFIG or {
    minCapacityLiters = 5000,
    maxCapacityLiters = 30000,
    minEmptyMassKg = 500,
    maxEmptyMassKg = 3000,
    defaultDensityKgPerLiter = 1,
    searchRadius = 300,
    transferRateLitersPerSecond = 750,
    transferTickSeconds = 0.1,
    fillSound = "tanker/shit_hose_suction.wav",
    emptySound = "tanker/shit_pour.wav",
}

function Delivery_IsLiquidCargo(cargoKeyOrData)
    local cargo = cargoKeyOrData
    if isstring(cargoKeyOrData) then
        cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKeyOrData]
    end

    return cargo and cargo.isLiquid == true
end

function Delivery_GetLiquidLiters(cargoKeyOrData)
    local cargo = cargoKeyOrData
    if isstring(cargoKeyOrData) then
        cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKeyOrData]
    end

    return cargo and math.max(0, math.floor(tonumber(cargo.liters) or 0)) or 0
end

function Delivery_GetLiquidDensity(cargoKeyOrData)
    local cargo = cargoKeyOrData
    if isstring(cargoKeyOrData) then
        cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKeyOrData]
    end

    local density = cargo and tonumber(cargo.densityKgPerLiter)
    return density and density > 0 and density or DELIVERY_TANKER_CONFIG.defaultDensityKgPerLiter
end

function Delivery_GetLiquidMassKg(cargoKeyOrData)
    return Delivery_GetLiquidLiters(cargoKeyOrData) * Delivery_GetLiquidDensity(cargoKeyOrData)
end

function Delivery_ClampTankerCapacity(capacityLiters)
    return math.Clamp(
        math.floor(tonumber(capacityLiters) or DELIVERY_TANKER_CONFIG.minCapacityLiters),
        DELIVERY_TANKER_CONFIG.minCapacityLiters,
        DELIVERY_TANKER_CONFIG.maxCapacityLiters
    )
end

function Delivery_GetTankerEmptyMass(capacityLiters)
    local cfg = DELIVERY_TANKER_CONFIG
    local capacity = Delivery_ClampTankerCapacity(capacityLiters)
    local range = cfg.maxCapacityLiters - cfg.minCapacityLiters
    if range <= 0 then return cfg.minEmptyMassKg end

    local frac = (capacity - cfg.minCapacityLiters) / range
    return cfg.minEmptyMassKg + frac * (cfg.maxEmptyMassKg - cfg.minEmptyMassKg)
end

function Delivery_FormatLiters(liters)
    local str = tostring(math.floor(tonumber(liters) or 0))
    return string.Comma(str)
end

function Delivery_FormatTonsFromKg(massKg)
    local tons = (tonumber(massKg) or 0) / 1000
    if math.abs(tons - math.Round(tons)) < 0.001 then
        return tostring(math.Round(tons))
    end
    return string.format("%.1f", tons)
end
