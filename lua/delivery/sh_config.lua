--[[
    SUPPLY CHAIN EXAMPLE (remove the -- to use):

    ["coal"] = {
        label = "Coal",
        model = "models/props_junk/wood_crate001a.mdl",
        mass  = 60,
        limit = 10,
        -- Every 2 coal delivered produces 1 steel available to buy
        produces = {
            { item = "steel", ratio = 2 },
        },
    },
    ["steel"] = {
        label    = "Steel",
        model    = "models/props_junk/metal_paintcan001a.mdl",
        mass     = 80,
        limit    = 5,
        -- This cargo requires coal to be delivered before it becomes available
        -- Shows greyed out with "Requires: 2x Coal delivery" when out of stock
        requires = { item = "coal", ratio = 2 },
    },
--]]

DELIVERY_CARGO = {
    ["news_paper"] = {
        label       = "News Paper",
        model       = "models/props_junk/garbage_newspaper001a.mdl",
        mass        = 1,
        limit       = 10,
    },
    ["pills"] = {
        label       = "Illegal Pills",
        model       = "models/props_lab/jar01a.mdl",
        mass        = 5,
        limit       = 14,
		--allowedTeam = "TEAM_SMALL_PICKUP",
        --produces = {
            --{ item = "small_car", ratio = 4 },
            --{ item = "big_car", ratio = 6 },
        --},
        
    },
	["iron_pipes"] = {
        label       = "Iron Pipes",
        model       = "models/cargo/iron_pipes.mdl",
        mass        = 9114,
        limit       = 2,
		--allowedTeam = "TEAM_HEAVY_DUTY",
        --requires = { item = "ores", ratio = 3 },
    },
	["large_tubes"] = {
        label       = "Large Tubes",
        model       = "models/cargo/large_tubes.mdl",
        mass        = 19812,
        limit       = 2,
		--allowedTeam = "TEAM_HEAVY_DUTY",
        --requires = { item = "ores", ratio = 3 },
    },
    ["logs_pile_small"] = {
        label       = "Pile Of Logs Small",
        model       = "models/cargo/logs_medium_duty.mdl",
        mass        = 7500,
        limit       = 4,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_LIGHT_DUTY" },
        --requires = { item = "barrel", ratio = 1 },
        --produces = {
            --{ item = "wooden_beams_small", ratio = 2 },
        --},
    },
	["logs_pile"] = {
        label       = "Pile Of Logs",
        model       = "models/cargo/logs_heavy_duty.mdl",
        mass        = 15000,
        limit       = 4,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_HEAVY_DUTY" },
        --requires = { item = "barrel", ratio = 2 },
        --produces = {
            --{ item = "wooden_beams", ratio = 2 },
        --},
    },
	["logs_pile_large"] = {
        label       = "Pile Of Logs Large",
        model       = "models/cargo/logs_heavy_duty_large.mdl",
        mass        = 30000,
        limit       = 2,
		--allowedTeam = "TEAM_HEAVY_DUTY",
        --requires = { item = "barrel", ratio = 4 },
        --produces = {
            --{ item = "wooden_beams_large", ratio = 2 },
        --},
    },
    ["wooden_beams_small"] = {
        label       = "Wooden Beams Small",
        model       = "models/cargo/timber_beams_medium_duty.mdl",
        mass        = 5390,
        limit       = 4,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_LIGHT_DUTY" },
        --requires = { item = "logs_pile_small", ratio = 2 },
    },
	["wooden_beams"] = {
        label       = "Wooden Beams",
        model       = "models/cargo/timber_beams_heavy_duty.mdl",
        mass        = 12320,
        limit       = 4,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_HEAVY_DUTY" },
        --requires = { item = "logs_pile", ratio = 2 },
    },
	["wooden_beams_large"] = {
        label       = "Wooden Beams Large",
        model       = "models/cargo/timber_beams_heavy_duty_large.mdl",
        mass        = 19250,
        limit       = 2,
		--allowedTeam = "TEAM_HEAVY_DUTY",
        --requires = { item = "logs_pile_large", ratio = 2 },
        
    },
	["wooden_beams_single"] = {
        label       = "Wooden Beams Single Stack",
        model       = "models/cargo/timber_beams_light_duty.mdl",
        mass        = 385,
        limit       = 30,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_LIGHT_DUTY" },
        --requires = { item = "logs_pile", ratio = 2 },
    },
	["plywood_small"] = {
        label       = "Plywood Small",
        model       = "models/cargo/plywood_medium_duty.mdl",
        mass        = 5600,
        limit       = 4,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_LIGHT_DUTY" },
        --requires = { item = "logs_pile_small", ratio = 2 },
    },
	["plywood"] = {
        label       = "Plywood",
        model       = "models/cargo/plywood_heavy_duty.mdl",
        mass        = 8400,
        limit       = 4,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_HEAVY_DUTY" },
        --requires = { item = "logs_pile", ratio = 2 },
    },
	["plywood_large"] = {
        label       = "Plywood Large",
        model       = "models/cargo/plywood_heavy_duty_large.mdl",
        mass        = 12600,
        limit       = 2,
		--allowedTeam = "TEAM_HEAVY_DUTY",
        --requires = { item = "logs_pile_large", ratio = 2 },
        
    },
	["plywood_single"] = {
        label       = "Plywood Single Stack",
        model       = "models/cargo/plywood_light_duty.mdl",
        mass        = 1400,
        limit       = 20,
		--allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_LIGHT_DUTY" },
        --requires = { item = "logs_pile_small", ratio = 2 },
    },
	["ammo_box"] = {
        label       = "Ammo box",
        model       = "models/items/ammocrate_smg1.mdl",
        mass        = 150,
        limit       = 10,
		--allowedTeams = { "TEAM_LARGE_PICKUP", "TEAM_SMALL_PICKUP" },
    },
	["fertilizers"] = {
        label       = "Fertilizers",
        model       = "models/cargo/bags_fertilizer.mdl",
        mass        = 250,
        limit       = 10,
		--allowedTeams = { "TEAM_LIGHT_DUTY", "TEAM_LARGE_PICKUP" },
    },
	["vending_machine"] = {
        label       = "Vending Machine",
        model       = "models/props_interiors/vendingmachinesoda01a.mdl",
        mass        = 300,
        limit       = 10,
		--allowedTeams = { "TEAM_LARGE_PICKUP" },
    },
    ["ores"] = {
        label       = "Random Ores",
        model       = "models/props_wasteland/rockgranite03c.mdl",
        mass        = 800,
        limit       = 40,
		--allowedTeams = { "TEAM_LIGHT_DUTY", "TEAM_LARGE_PICKUP" },
        --produces = {
            --{ item = "iron_pipes", ratio = 3 },
        --},
    },
    ["small_food_goods"] = {
        label = "Small Grocery Products",
        limit = 10,
        --allowedTeam = "TEAM_SMALL_PICKUP",
        models = {
            { model = "models/cargo/box01.mdl", mass = 5,  price = 50  },
            { model = "models/cargo/box02.mdl", mass = 10, price = 100 },
            { model = "models/cargo/box03.mdl", mass = 15, price = 150 },
            { model = "models/cargo/box04.mdl", mass = 20, price = 200 },
            { model = "models/cargo/box05.mdl", mass = 25, price = 250 },
        },
    },
    ["big_food_goods"] = {
        label = "Big Grocery Products",
        limit = 10,
        --allowedTeam = "TEAM_LARGE_PICKUP",
        models = {
            { model = "models/cargo/box06.mdl", mass = 30, price = 300 },
            { model = "models/cargo/box07.mdl", mass = 35, price = 350 },
            { model = "models/cargo/box08.mdl", mass = 40, price = 400 },
            { model = "models/cargo/box09.mdl", mass = 45, price = 450 },
            { model = "models/cargo/box10.mdl", mass = 50, price = 500 },
        },
    },
    ["small_car"] = {
        label = "Small Car",
        limit = 3,
        --allowedTeams = { "TEAM_LIGHT_DUTY", "TEAM_MEDIUM_DUTY" },
        models = {
            { model = "models/props_vehicles/car001a_hatchback.mdl", mass = 900,  price = 1000  },
            { model = "models/props_vehicles/car002b_physics.mdl",   mass = 920,  price = 1150 },
            { model = "models/props_vehicles/car003a_physics.mdl",   mass = 1000, price = 1400 },
            { model = "models/props_vehicles/car003b_physics.mdl",   mass = 950,  price = 1350 },
            { model = "models/props_vehicles/car002a_physics.mdl",   mass = 875,  price = 1300 },
        },
        --requires = { item = "pills", ratio = 4 },
    },
    ["big_car"] = {
        label = "Big Car",
        limit = 2,
        --allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_HEAVY_DUTY" },
        models = {
            { model = "models/props_vehicles/truck001a.mdl",       mass = 2500, price = 3200 },
            { model = "models/props_vehicles/truck003a.mdl",       mass = 2800, price = 3400 },
            { model = "models/props_vehicles/truck002a_cab.mdl",   mass = 3200, price = 3750 },
            { model = "models/props_vehicles/van001a_physics.mdl", mass = 2300, price = 2800 },
        },
        --requires = { item = "pills", ratio = 6 },
    },
    ["car_scrap"] = {
        label = "Car Scrap",
        limit = 10,
        --allowedTeams = { "TEAM_SMALL_PICKUP", "TEAM_LARGE_PICKUP" },
        models = {
            { model = "models/props_vehicles/carparts_door01a.mdl",    mass = 50, price = 500 },
            { model = "models/props_c17/trappropeller_engine.mdl",      mass = 60, price = 600 },
            { model = "models/gibs/airboat_broken_engine.mdl",          mass = 55, price = 550 },
            { model = "models/props_vehicles/carparts_axel01a.mdl",    mass = 45, price = 450 },
            { model = "models/props_vehicles/carparts_muffler01a.mdl", mass = 25, price = 400 },
        },
    },
	["boat"] = {
        label = "Boat",
        limit = 5,
        --allowedTeams = { "TEAM_SMALL_PICKUP", "TEAM_LARGE_PICKUP" },
        models = {
            { model = "models/props_canal/boat002b.mdl", mass = 250, price = 1500 },
            { model = "models/props_canal/boat001a.mdl", mass = 250, price = 1500 },
            { model = "models/props_canal/boat001b.mdl", mass = 250, price = 1500 },
        },
    },
	["tires"] = {
        label = "Tires",
        limit = 10,
        --allowedTeams = { "TEAM_SMALL_PICKUP", "TEAM_LARGE_PICKUP" },
        models = {
            { model = "models/props_vehicles/tire001a_tractor.mdl",  mass = 100, price = 350 },
            { model = "models/props_vehicles/tire001b_truck.mdl",     mass = 50,  price = 250 },
            { model = "models/props_vehicles/carparts_tire01a.mdl",   mass = 20,  price = 200 },
            { model = "models/props_vehicles/carparts_tire01a.mdl",   mass = 15,  price = 150 },
        },
    },
	["furniture"] = {
        label = "Furniture",
        limit = 10,
        --allowedTeams = { "TEAM_SMALL_PICKUP", "TEAM_LARGE_PICKUP" },
        models = {
            { model = "models/props_c17/furniturecouch001a.mdl",           mass = 25,  price = 150 },
            { model = "models/props_c17/furniturewashingmachine001a.mdl",  mass = 50,  price = 200 },
            { model = "models/props_c17/furniturefridge001a.mdl",          mass = 100, price = 200 },
            { model = "models/props_c17/furniturestove001a.mdl",           mass = 150, price = 250 },
			{ model = "models/props_wasteland/kitchen_stove001a.mdl",      mass = 150, price = 250 },
        },
    },
	["barrel"] = {
        label = "Barrel",
        limit = 10,
        --allowedTeams = { "TEAM_SMALL_PICKUP", "TEAM_LARGE_PICKUP" },
        models = {
            { model = "models/props_c17/oildrum001.mdl",         mass = 50, price = 150 },
            { model = "models/props_phx/facepunch_barrel.mdl",   mass = 50, price = 150 },
        },
        --produces = {
            --{ item = "logs_pile", ratio = 2 },
            --{ item = "logs_pile_large", ratio = 4 },
            --{ item = "logs_pile_small", ratio = 1 },
        --},
    },
	["file_cabinet"] = {
        label = "File Cabinet",
        limit = 10,
        --allowedTeams = { "TEAM_SMALL_PICKUP", "TEAM_LARGE_PICKUP" },
        models = {
            { model = "models/props_wasteland/controlroom_filecabinet002a.mdl", mass = 150, price = 350 },
            { model = "models/props_wasteland/controlroom_filecabinet001a.mdl", mass = 50,  price = 75  },
			{ model = "models/props_lab/filecabinet02.mdl",                     mass = 50,  price = 75  },
        },
    },
	["log_small"] = {
        label = "Log Small",
        limit = 20,
        --allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_LIGHT_DUTY" },
        models = {
            { model = "models/cargo/logs_medium_duty_2.mdl", mass = 500, price = 200 },
			{ model = "models/cargo/logs_medium_duty_3.mdl", mass = 500, price = 200 },
			{ model = "models/cargo/logs_medium_duty_4.mdl", mass = 500, price = 200 },
			{ model = "models/cargo/logs_medium_duty_5.mdl", mass = 500, price = 200 },
			{ model = "models/cargo/logs_medium_duty_6.mdl", mass = 500, price = 200 },
			{ model = "models/cargo/logs_medium_duty_7.mdl", mass = 500, price = 200 },
            
        --requires = { item = "barrel", ratio = 1 },
        --produces = {
            --{ item = "wooden_beams_small", ratio = 2 },
        --},
        },
    },
	["log"] = {
        label = "Log",
        limit = 20,
        --allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_HEAVY_DUTY" },
        models = {
            { model = "models/cargo/logs_heavy_duty_1.mdl", mass = 1000, price = 433 },
			{ model = "models/cargo/logs_heavy_duty_2.mdl", mass = 1000, price = 433 },
			{ model = "models/cargo/logs_heavy_duty_3.mdl", mass = 1000, price = 433 },
			{ model = "models/cargo/logs_heavy_duty_4.mdl", mass = 1000, price = 433 },
			{ model = "models/cargo/logs_heavy_duty_5.mdl", mass = 1000, price = 433 },
			{ model = "models/cargo/logs_heavy_duty_6.mdl", mass = 1000, price = 433 },
			{ model = "models/cargo/logs_heavy_duty_7.mdl", mass = 1000, price = 433 },
            
        --requires = { item = "barrel", ratio = 1 },
        --produces = {
            --{ item = "wooden_beams_small", ratio = 2 },
        --},
        },
    },
	["log_large"] = {
        label = "Log Large",
        limit = 20,
        --allowedTeams = { "TEAM_MEDIUM_DUTY", "TEAM_HEAVY_DUTY" },
        models = {
            { model = "models/cargo/logs_heavy_duty_large_1.mdl", mass = 2000, price = 933 },
			{ model = "models/cargo/logs_heavy_duty_large_2.mdl", mass = 2000, price = 933 },
			{ model = "models/cargo/logs_heavy_duty_large_3.mdl", mass = 2000, price = 933 },
			{ model = "models/cargo/logs_heavy_duty_large_4.mdl", mass = 2000, price = 933 },
			{ model = "models/cargo/logs_heavy_duty_large_5.mdl", mass = 2000, price = 933 },
			{ model = "models/cargo/logs_heavy_duty_large_6.mdl", mass = 2000, price = 933 },
			{ model = "models/cargo/logs_heavy_duty_large_7.mdl", mass = 2000, price = 933 },
            
        --requires = { item = "barrel", ratio = 1 },
        --produces = {
            --{ item = "wooden_beams_small", ratio = 2 },
        --},
        },
    },
}

DELIVERY_NPCS = {
    ["npc_paperboy"] = {
        label = "PaperBoy",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector( 0, 20, 20 ),
        sells = {
            { item = "news_paper",  label = "News Paper",   price = 1  },
            { item = "pills",  label = "Illegal Pills",   price = 40  },
        },
        buys = {
        },
    },
    ["npc_oldman_diner"] = {
        label = "Oldman Diner Owner",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 20, 0, 20 ),
        sells = {
        },
        buys = {
            { item = "news_paper",  label = "News Paper",   price = 5 },
        },
    },
    ["grocery_worker"] = {
        label = "Grocery Worker",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 0, 50, 50 ),
        sells = {
            { item = "fertilizers",  label = "Fertilizers",   price = 150 },
        },
        buys = {
			{ item = "small_food_goods",   label = "Small Grocery Products",   price = 35 },
            { item = "big_food_goods",    label = "Big Grocery Products",     price = 275 },
        },
    },
    ["warehouse_manager"] = {
        label = "Warehouse Manager",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 0, -50, 50 ),
        sells = {
            { item = "small_food_goods",  label = "Small Grocery Products",   price = 50  },
            { item = "big_food_goods",    label = "Big Grocery Products",     price = 140 },
			{ item = "furniture",         label = "Furniture",                price = 75  },
			{ item = "ammo_box",          label = "Ammo Box",                 price = 100 },
			{ item = "barrel",            label = "Barrel",                   price = 25  },
			{ item = "file_cabinet",      label = "File Cabinet",             price = 50  },
			{ item = "vending_machine",   label = "Vending Machine",          price = 200 },
        },
        buys = {
        },
    },
    ["mechanic"] = {
        label = "Mechanic",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 0, 50, 50 ),
        sells = {
        },
        buys = {
			{ item = "tires",     label = "Tires",     price = 250 },
			{ item = "car_scrap", label = "Car Scrap", price = 500 },
			{ item = "small_car", label = "Small Car", price = 900 },
            { item = "big_car",   label = "Big Car",   price = 350 },
        },
    },
    ["scrapyard"] = {
        label = "Scrapyard Junky",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 250, 0, 100 ),
        sells = {
			{ item = "tires",     label = "Tires",     price = 80   },
			{ item = "car_scrap", label = "Car Scrap", price = 175  },
            { item = "small_car", label = "Small Car", price = 450  },
            { item = "big_car",   label = "Big Car",   price = 1100 },
			{ item = "boat",       label = "Boat",      price = 550 },
        },
        buys = {
            { item = "pills",  label = "Illegal Pills",   price = 100  },
        },
    },
	["lumberjack"] = {
        label = "Lumberjack",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( -50, 650, 100 ),
        sells = {
            { item = "logs_pile_small", label = "Pile Of Logs Small", price = 1200 },
			{ item = "logs_pile",       label = "Pile Of Logs",       price = 2500 },
			{ item = "logs_pile_large", label = "Pile Of Logs Large", price = 5000 },
			{ item = "log_small", 				   label = "Log Small", price = 80 },
			{ item = "log", 					 		label = "Log", price = 166 },
			{ item = "log_large", 				  label = "Log Large", price = 333 },
        },
        buys = {
            { item = "barrel",     label = "Barrel",     price = 150  },
        },
    },
	["sawmill_manager"] = {
        label = "Sawmill Manager",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 300, 650, 0 ),
        sells = {
            { item = "wooden_beams_small", 		  label = "Wooden Beams Small", price = 1000 },
			{ item = "wooden_beams",       		  label = "Wooden Beams",       price = 3500 },
			{ item = "wooden_beams_large", 		  label = "Wooden Beams Large", price = 7000 },
			{ item = "wooden_beams_single", label = "Wooden Beams Single Stack", price = 140 },
			{ item = "plywood_small", 			  	   label = "Plywood Small", price = 1500 },
			{ item = "plywood",       			  	   label = "Plywood",       price = 4000 },
			{ item = "plywood_large", 			  	   label = "Plywood Large", price = 8000 },
			{ item = "plywood_single", 			 label = "Plywood Single Stack", price = 888 },
        },
        buys = {
			{ item = "logs_pile_small",  label = "Pile Of Logs Small", price = 3000 },
			{ item = "logs_pile",        label = "Pile Of Logs",       price = 6500 },
			{ item = "logs_pile_large", label = "Pile Of Logs Large", price = 14000 },
			{ item = "log_small", 				   label = "Log Small", price = 200 },
			{ item = "log", 							 label = "Log", price = 433 },
			{ item = "log_large", 				   label = "Log Large", price = 933 },
        },
    },
	["northern_steel_manager"] = {
        label = "Northern Steel Manager",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 150, 0, 100 ),
        sells = {
            { item = "iron_pipes",   label = "Iron Pipes", price = 4500 },
			{ item = "large_tubes", label = "Large Tubes", price = 6500 },
        },
        buys = {
            { item = "ores", label = "Random Ores", price = 1100 },
        },
    },
	["construction_site_manager"] = {
        label = "Construction Site Manager",
        model = "models/humans/group01/male_04.mdl",
        spawnOffset = Vector( 150, 0, 100 ),
        sells = {
        },
        buys = {
			{ item = "iron_pipes", 						 label = "Iron Pipes", price = 12000 },
			{ item = "large_tubes", 					label = "Large Tubes", price = 18000 },
            { item = "wooden_beams_small", 		  label = "Wooden Beams Small", price = 3000 },
			{ item = "wooden_beams",       		  label = "Wooden Beams",       price = 8500 },
			{ item = "wooden_beams_large", 		 label = "Wooden Beams Large", price = 15000 },
			{ item = "wooden_beams_single", label = "Wooden Beams Single Stack", price = 300 },
			{ item = "plywood_small", 				   label = "Plywood Small", price = 3500 },
			{ item = "plywood",       				   label = "Plywood",       price = 9500 },
			{ item = "plywood_large", 				  label = "Plywood Large", price = 15000 },
			{ item = "plywood_single", 			label = "Plywood Single Stack", price = 1666 },
        },
    },
	["laker_swinger"] = {
        label = "Swinger For The Lakers",
        model = "models/player/eli.mdl",
        spawnOffset = Vector( 0, 50, 50 ),
        sells = {
        },
        buys = {
			{ item = "boat", label = "Boat", price = 500 },
        },
    },
	["guy"] = {
        label = "Guy",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector( 0, 20, 20 ),
        sells = {
        },
        buys = {
			{ item = "furniture", label = "Furniture", price = 75 },
        },
    },
	["officer_cockson"] = {
        label = "Officer Cockson",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector( 0, 20, 20 ),
        sells = {
        },
        buys = {
			{ item = "ammo_box",        label = "Ammo Box",        price = 350 },
			{ item = "vending_machine", label = "Vending Machine", price = 600 },
        },
    },
	["wallace_bank"] = {
        label = "Wallace & Wallace Bank",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector( 0, 20, 20 ),
        sells = {
        },
        buys = {
			{ item = "file_cabinet", label = "File Cabinet", price = 50 },
        },
    },
	["farmer"] = {
        label = "Farmer",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector( 0, 20, 20 ),
        sells = {
        },
        buys = {
			{ item = "fertilizers", label = "Fertilizers", price = 400 },
        },
    },
    ["miner"] = {
        label = "Miner",
        model = "models/humans/group01/male_07.mdl",
        spawnOffset = Vector( 0, 75, 20 ),
        sells = {
            { item = "ores", label = "Random Ores", price = 350 },
        },
        buys = {
        },
    },
}

--DELIVERY_ALLOWED_TEAMS = {
--    "TEAM_SMALL_PICKUP",
--    "TEAM_LARGE_PICKUP",
--    "TEAM_LIGHT_DUTY",
--    "TEAM_MEDIUM_DUTY",
--    "TEAM_HEAVY_DUTY",
--}

function Delivery_IsAllowedJob(ply)
    local team = ply:Team()
    for _, varName in ipairs(DELIVERY_ALLOWED_TEAMS) do
        if _G[varName] ~= nil and team == _G[varName] then
            return true
        end
    end
    return false
end

function Delivery_CanBuyCargo(ply, cargoKey)
    local cargo = DELIVERY_CARGO[cargoKey]
    if not cargo then return false end

    if cargo.allowedTeams then
        local team = ply:Team()
        for _, varName in ipairs(cargo.allowedTeams) do
            local teamVar = _G[varName]
            if teamVar ~= nil and team == teamVar then return true end
        end
        return false
    end

    if cargo.allowedTeam then
        local teamVar = _G[cargo.allowedTeam]
        return teamVar ~= nil and ply:Team() == teamVar
    end

    return true
end

DELIVERY_CONFIG = {
    pickupRadius  = 100,
    cargoLimit    = 5,
    ownershipTime = 600,
}