AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/wood_crate001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCargoKey("")
    self:SetCargoLabel("")
    self:SetCargoValue(0)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator)
    if not activator:IsPlayer() then return end

    local prev = self:GetNWEntity("CargoOwner")
    if IsValid(prev) and prev == activator then
        activator:ChatPrint("[Delivery] You already own this " .. self:GetCargoLabel() .. ".")
        return
    end

    local prevName = IsValid(prev) and prev:Nick() or nil
    self:SetNWEntity("CargoOwner", activator)
    activator:ChatPrint("[Delivery] You claimed the " .. self:GetCargoLabel() .. ".")
    if prevName then
        prev:ChatPrint("[Delivery] Your " .. self:GetCargoLabel() .. " was claimed by " .. activator:Nick() .. "!")
    end
end

function ENT:SetupCargo(cargoKey)
    local data = DELIVERY_CARGO[cargoKey]
    if not data then return end

    local chosenModel, chosenMass, chosenPrice
    if data.models and #data.models > 0 then
        local pick  = data.models[math.random(#data.models)]
        chosenModel = pick.model
        chosenMass  = pick.mass
        chosenPrice = pick.price or 0
    else
        chosenModel = data.model
        chosenMass  = data.mass or 50
        chosenPrice = 0
    end

    self:SetModel(chosenModel)
    self:SetCargoKey(cargoKey)
    self:SetCargoLabel(data.label)
    self:SetCargoValue(chosenPrice)

    -- reinitialize physics with the new model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    timer.Simple(0, function()
        if not IsValid(self) then return end
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(chosenMass)
        end
    end)
end

function ENT:Think()
    local phys = self:GetPhysicsObject()
    if IsValid(phys) and not phys:IsGravityEnabled() then
        phys:EnableGravity(true)
    end
    self:NextThink(CurTime() + 1)
    return true
end

function ENT:CanTool(ply, trace, tool)
    return tool == "weld" or tool == "gmod_wire_grabber"
end

function ENT:PhysgunPickup(ply)
    return false
end

function ENT:CPPIGetOwner()
    return game.GetWorld()
end

function ENT:CPPICanTool(ply, tool)
    return tool == "weld" or tool == "gmod_wire_grabber"
end

function ENT:CanProperty(ply)
    return false
end

hook.Add("CanTool", "Cargo_AllowWeldAndWireGrab", function(ply, trace, tool)
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "sent_cargo" then
        if tool == "weld" or tool == "gmod_wire_grabber" then
            return true
        end
        return false
    end
end)