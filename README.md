# Delivery Mod

A DarkRP-style delivery/trucking gamemode addon for Garry's Mod. Players buy cargo from NPCs, haul it (by prop, tanker, or grain bed) to other NPCs to sell it, and can rank up their vehicle class as they earn money. Also bundles an Express parcel-delivery job, a Sewage collection job, and a simple Fishing minigame.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Player Guide](#player-guide)
  - [General Cargo Delivery](#general-cargo-delivery)
  - [Tanker Jobs (Liquid Cargo)](#tanker-jobs-liquid-cargo)
  - [Grain Jobs](#grain-jobs)
  - [Sewage Collection Job](#sewage-collection-job)
  - [Express Delivery Job](#express-delivery-job)
  - [Rank System](#rank-system)
  - [Fishing](#fishing)
- [Admin Guide](#admin-guide)
  - [Delivery NPC Commands](#delivery-npc-commands)
  - [Rank NPC Commands](#rank-npc-commands)
  - [Tanker Tool](#tanker-tool)
  - [Grain Bed Tool](#grain-bed-tool)
  - [Express Job Commands](#express-job-commands)
  - [Sewage Job Commands](#sewage-job-commands)
- [Configuration](#configuration)
- [File Structure](#file-structure)

## Features

- **General cargo system** — buy cargo from NPCs, either use a gravity gun or wire grabber, drive to another NPC and sell.
- **Liquid tanker jobs** — mark any prop as a tanker, fill it with diesel/gasoline or any other form of liquid from a refinery NPC, and drain it at a gas station or somewhere else.
- **Grain hauling jobs** — same idea as tankers, but for wheat/corn/soybeans between a farm and a silo.
- **Sewage collection job** — collect waste from manholes around the map, haul it in a sewage tanker, and drain it at a dropoff for a payout.
- **Express parcel job** — this one is a bit different compared to the rest, youll have to approach the NPC, press E on them to get a job, and theres a bunch of catagories for each vehicle type, and once you start the job,it will give you a certain ammount of packages to deliver them to, and you have to do it before the timer runs out, or else your paycheck will be reduced depending on the number of packages youve delivered.
- **Rank system** — this npc is basically how you unlock other types of cargoes for each catagory, youll see ALLOWTEAMS strings in the config files on some of the cargoes, it is currently commented out, you can re enable them by uncommenting them.
- **Fishing minigame** — buy a rod and bait, cast into water, and catch fish of varying rarity/value.
- **Admin placement tools** — every NPC, manhole and dropoff is placed in-world via console commands and saved to a per-map SQL database, so layouts persist across restarts.

## Installation

1. Drop the addon folder into your server's (or single-player) `garrysmod/addons/` directory.
2. Restart the server (or relaunch the game). No additional dependencies are required, but an admin mod that supports `ply:IsAdmin()` (e.g. ULX) is recommended since most setup commands are admin-gated.
4. As an admin, place your NPCs/manholes for your map using the commands in the [Admin Guide](#admin-guide) below.

## Player Guide

### General Cargo Delivery

1. Find an NPC that **sells** cargo (open the buy menu by using — <kbd>E</kbd> — on them) and purchase an item. It spawns near the NPC.
2. Use a vehicle or gravity gun to load the cargo up and drive it to an NPC that **buys** that item, incase you cant pick up a cargo with gravity gun, you must use wire grabber instead.
3. Sell it to the NPC through the same menu for a payout.
4. Some cargoes will be restricted depending on the rank, you can either enable or disable them, but what this does is that it restricts cargoes for certain jobs, those being Light duty, Medium Duty and Heavy Duty,the rank NPC helps you unlock them by paying for each of the ranks.

### Tanker Jobs (Liquid Cargo)

1. Spawn a prop to use as your tank, then select the **Delivery Tanker Tool** from the spawn menu (under the *Blue Light RP* tab) and left-click the prop to mark it as a tanker. Adjust capacity (in liters) with the tool's slider before marking it.
2. Right-click the same prop with the tool to unmark it if you need to reassign it.
3. Drive to a refinery NPC and use the tanker filling interaction to pump diesel/gasoline or any other liquid of sort into your tank.
4. Drive to a gas station NPC or somewhere else and drain the tanker for payment. Fill/drain both happen over time based on a transfer rate, not instantly.

### Grain Jobs

Works exactly like the tanker job above, but with the **Grain Bed Tool** instead: mark a flatbed/prop, fill it with wheat, corn, or soybeans at a grain farm, and empty it at a silo/factory for payment.

### Sewage Collection Job

1. Mark a tanker prop with the **Sewage Tanker Tool**.
2. Drive around to the manholes scattered across the map and collect waste from each one within range.
3. Once full (or when you've done enough manholes), drive to the sewage dropoff and drain your tanker for the payout.

### Express Delivery Job

1. Talk to an Express dispatcher NPC to get assigned a batch of packages (the number and vehicle-size requirement scale with your vehicle: Mini Van, Panel Van Small/Large, or Box Van).
2. Pick up the packages and deliver each one to its matching address listed on the packages before the timer runs out, if you get lost, there is a provided GPS under Entities and in the catagory **Delivery Mod**.
3. Completing the run pays out based on how many packages you delivered before the time runs out, delivering everything gets you the full payout.

### Rank System

Visit the Rank Vendor NPC to purchase a rank: **Light Duty**, **Medium Duty**, or **Heavy Duty**. Higher ranks cost more but unlock access to bigger vehicles/teams and the cargo types restricted to them.

### Fishing

Buy a fishing rod and bait from the fishing NPC, cast near water, and wait for a bite. Catching a fish rewards you with money based on its rarity (Carp being common, Golden Fish being a rare high-value catch).

## Admin Guide

All setup commands below are restricted to admins (`ply:IsAdmin()`). Run them in the developer console (`` ` ``) while looking at a surface/entity unless noted otherwise.

### Delivery NPC Commands

| Command | Description |
|---|---|
| `delivery_place <npc_key>` | Spawns and saves a delivery NPC of the given key at the surface you're looking at (e.g. `delivery_place npc_paperboy`). |
| `delivery_placer` | Opens up a menu to easily select one of the npcs which will spawn in the spot youre looking at currently. |
| `delivery_remove` | Removes the delivery NPC you're looking at (and deletes it from the database). |
| `delivery_list` | Prints every valid `npc_key` and its display label to your chat, for use with `delivery_place`. |

> NPC keys and their buy/sell offers are defined in `lua/delivery/sh_config.lua` (`DELIVERY_NPCS`), with more added by `sh_tanker_job_config.lua` and `sh_grain_job_config.lua`.

### Rank NPC Commands

| Command | Description |
|---|---|
| `delivery_place_rank` | Places a Rank Vendor NPC at the surface you're looking at. |
| `delivery_remove_rank` | Removes the Rank Vendor NPC you're looking at. |
| `delivery_resetranks <name\|steamid\|all>` | Resets rank purchases for a specific player (by name or SteamID) or for everyone (`all`). Also resets their ULX donator level if ULX is installed. |

### Tanker Tool

Select **Delivery Tanker Tool** in the spawn menu (Blue Light RP tab). Set the capacity slider, left-click a prop to mark it as a tanker, right-click to unmark it. No console command needed for regular players — this is a Q-menu tool.

### Grain Bed Tool

Same workflow as the Tanker Tool above, but via the **Grain Bed Tool** in the spawn menu, for grain cargo.

### Express Job Commands

| Command | Description |
|---|---|
| `express_place_npc` | Places an Express dispatcher NPC at the surface you're looking at. |
| `express_remove_npc` | Removes the Express NPC you're looking at. |
| `express_place_dropoff <address>` | Places a delivery dropoff point tagged with an address. Run with no argument to print the list of valid addresses (from `EXPRESS_ADDRESSES` in `sh_express_config.lua`). |
| `express_remove_dropoff` | Removes the dropoff you're looking at. |
| `express_export` | Prints a Lua table of all currently placed Express NPCs/dropoffs for the current map to console, for saving into map-data config. |
| `express_reset` | Resets Express map data. |

### Sewage Job Commands

| Command | Description |
|---|---|
| `sewage_place_npc` | Places a sewage collection NPC at the surface you're looking at. |
| `sewage_remove_npc` | Removes the sewage NPC you're looking at. |
| `sewage_place_manhole <address\|index>` | Places a manhole tagged with an address. Run with no argument to print the suggested address list (from `SEWAGE_MANHOLE_ADDRESSES`); you can pass either the text or its list index number. |
| `sewage_remove_manhole` | Removes the manhole you're looking at. |
| `sewage_place_dropoff` | Places a sewage dropoff point at the surface you're looking at. |
| `sewage_remove_dropoff` | Removes the dropoff you're looking at. |
| `sewage_export` | Prints a Lua table of all placed sewage NPCs/manholes/dropoffs for the current map to console. |
| `sewage_reset` | Resets sewage map data. |

## Configuration

All gameplay tuning lives in shared config files under `lua/delivery/` and `lua/fishing/`:

| File | Controls |
|---|---|
| `sh_config.lua` | Core cargo list (`DELIVERY_CARGO`), NPC buy/sell offers (`DELIVERY_NPCS`), pickup radius, cargo limit, ownership timeout. |
| `sh_tanker_config.lua` / `sh_tanker_job_config.lua` | Tanker capacity range, transfer rate, liquid cargo (diesel/gasoline) or other types of liquid and their NPCs. |
| `sh_grain_config.lua` / `sh_grain_job_config.lua` | Grain bed capacity range, transfer rate, grain cargo (wheat/corn/soybeans) and their NPCs. |
| `sh_sewage_config.lua` | Manhole count/payout, tanker capacity, fill/empty rates, list of manhole addresses. |
| `sh_express_config.lua` | Package count ranges, time limits, payout caps, vehicle-size variants, delivery addresses, box models. |
| `sh_rank_config.lua` | Rank vendor NPC model, and the price/label of each rank tier. |
| `../fishing/sh_config.lua` | Bite timing, rod/bait price, fish list with rarity and value. |

Cargo entries in `DELIVERY_CARGO` support optional fields:
- `allowedTeam` / `allowedTeams` — restricts who can buy the item to specific vehicle teams.
- `requires` — makes the item unavailable to buy until a prerequisite cargo has been delivered a certain number of times.
- `produces` — delivering this cargo unlocks a set amount of another cargo type for purchase.

## File Structure

```
lua/
├── autorun/
│   ├── client/        # Client-side bootstrap (delivery + fishing)
│   └── server/        # Server-side bootstrap (delivery + fishing + sewage entities)
├── delivery/           # Core delivery, tanker, grain, express, sewage, rank logic
├── entities/           # SENTs: NPCs, cargo props, dropoffs, GPS markers, manholes, fish, rod
├── fishing/             # Fishing minigame logic
└── weapons/gmod_tool/stools/   # Q-menu tools: Delivery Tanker, Grain Bed, Sewage Tanker
```

---
