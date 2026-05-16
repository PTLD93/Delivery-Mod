EXPRESS_CONFIG = {
    minPackages    = 6,
    maxPackages    = 20,
    timeLimitSmall = 2100,
    timeLimitLarge = 2400,
    maxPayout      = 15000,
    pickupRadius   = 350,
    deliverRadius  = 180,
}

EXPRESS_ADDRESSES = {
    -- Main St
    "1 Main St",
    "5 Main St",
    "9 Main St",
    "14 Main St",
    "22 Main St",
    -- River Rd (4 houses, left column)
    "2 River Rd",
    "4 River Rd",
    "6 River Rd",
    "8 River Rd",
    -- River Rd apartment block (8 units, near Main St)
    "10 River Rd #1",
    "10 River Rd #2",
    "10 River Rd #3",
    "10 River Rd #4",
    "10 River Rd #5",
    "10 River Rd #6",
    "10 River Rd #7",
    "10 River Rd #8",
    -- Spruce Cres inner (4 houses, middle column)
    "1 Spruce Cres",
    "3 Spruce Cres",
    "5 Spruce Cres",
    "7 Spruce Cres",
    -- Spruce Cres outer (4 houses, right column toward Main St)
    "2 Spruce Cres",
    "4 Spruce Cres",
    "6 Spruce Cres",
    "8 Spruce Cres",
    -- Main St businesses
    "Mountainside Auto Sales",
    "Blu Cinema",
    "Mexigrill",
    "Kappels",
    "Main Street Grocery",
    "Mels Diner",
    -- Railway Ave businesses
    "Chads Autobody",
    -- Railway Ave houses
    "4 Railway Ave",
    "6 Railway Ave",
    "8 Railway Ave",
    "10 Railway Ave",
    "12 Railway Ave",
    "14 Railway Ave",
    "16 Railway Ave",
    "18 Railway Ave",
    -- Valley Dr (2 houses)
    "3 Valley Dr",
	"6 Valley Dr",
    -- E Slide Rd (1 house)
    "3 E Slide Rd",
    -- Pine Dr (1 house)
    "4 Pine Dr",
    -- Granite Hill Rd (3 houses)
    "2 Granite Hill Rd",
	"6 Granite Hill Rd",
    "9 Granite Lake Rd",
    -- Beach Rd (2 houses near Granite Lake)
    "3 Beach Rd",
    "8 Beach Rd",
    -- Hwy 3 residences
    "2 Hwy 3",
    "6 Hwy 3",
    "10 Hwy 3",
    -- Hwy 3 businesses
    "Richardson Hauling",
    "Northern Steel",
    "Metro Intl.",
}

EXPRESS_BOX_MODELS = {
    { model = "models/cargo/box01.mdl", mass = 5,   limit = 8 },
    { model = "models/cargo/box02.mdl", mass = 10,  limit = 7 },
    { model = "models/cargo/box03.mdl", mass = 15,  limit = 6 },
    { model = "models/cargo/box04.mdl", mass = 20,  limit = 5 },
    { model = "models/cargo/box05.mdl", mass = 25,  limit = 4 },
    { model = "models/cargo/box06.mdl", mass = 35,  limit = 4 },
    { model = "models/cargo/box07.mdl", mass = 50,  limit = 3 },
    { model = "models/cargo/box08.mdl", mass = 75,  limit = 2 },
    { model = "models/cargo/box09.mdl", mass = 100, limit = 2 },
    { model = "models/cargo/box10.mdl", mass = 225, limit = 1 },
}
