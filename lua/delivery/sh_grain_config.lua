DELIVERY_GRAIN_CONFIG = {
    minCapacityLiters = 5000,
    maxCapacityLiters = 100000,
    minEmptyMassKg = 500,
    maxEmptyMassKg = 3000,
    defaultDensityKgPerLiter = 0.75, -- Based on Soybeans
    searchRadius = 300,
    transferRateLitersPerSecond = 500, -- Slightly slower than liquid?
    transferTickSeconds = 0.1,
    fillSound = "ambient/machines/squeak_8.wav", -- Placeholder sound for grain
    emptySound = "ambient/machines/squeak_1.wav", -- Placeholder sound for grain
}

function Delivery_IsGrainCargo(cargoKeyOrData)
    local cargo = cargoKeyOrData
    if isstring(cargoKeyOrData) then
        cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKeyOrData]
    end

    return cargo and cargo.isGrain == true
end

function Delivery_GetGrainLiters(cargoKeyOrData)
    local cargo = cargoKeyOrData
    if isstring(cargoKeyOrData) then
        cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKeyOrData]
    end

    return cargo and math.max(0, math.floor(tonumber(cargo.liters) or 0)) or 0
end

function Delivery_GetGrainDensity(cargoKeyOrData)
    local cargo = cargoKeyOrData
    if isstring(cargoKeyOrData) then
        cargo = DELIVERY_CARGO and DELIVERY_CARGO[cargoKeyOrData]
    end

    local density = cargo and tonumber(cargo.densityKgPerLiter)
    return density and density > 0 and density or DELIVERY_GRAIN_CONFIG.defaultDensityKgPerLiter
end

function Delivery_GetGrainMassKg(cargoKeyOrData)
    return Delivery_GetGrainLiters(cargoKeyOrData) * Delivery_GetGrainDensity(cargoKeyOrData)
end

function Delivery_ClampGrainBedCapacity(capacityLiters)
    return math.Clamp(
        math.floor(tonumber(capacityLiters) or DELIVERY_GRAIN_CONFIG.minCapacityLiters),
        DELIVERY_GRAIN_CONFIG.minCapacityLiters,
        DELIVERY_GRAIN_CONFIG.maxCapacityLiters
    )
end

function Delivery_GetGrainBedEmptyMass(capacityLiters)
    local cfg = DELIVERY_GRAIN_CONFIG
    local capacity = Delivery_ClampGrainBedCapacity(capacityLiters)
    local range = cfg.maxCapacityLiters - cfg.minCapacityLiters
    if range <= 0 then return cfg.minEmptyMassKg end

    local frac = (capacity - cfg.minCapacityLiters) / range
    return cfg.minEmptyMassKg + frac * (cfg.maxEmptyMassKg - cfg.minEmptyMassKg)
end
