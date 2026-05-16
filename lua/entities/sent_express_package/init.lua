AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local mdl  = self:GetNWString("ExpressModel", "")
    local mass = self:GetNWInt("ExpressMass", 10)

    if mdl == "" then
        local entry = EXPRESS_BOX_MODELS[math.random(#EXPRESS_BOX_MODELS)]
        mdl  = entry.model
        mass = entry.mass
    end

    self:SetModel(mdl)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    timer.Simple(0, function()
        if not IsValid(self) then return end
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(mass)
        end
    end)
end

function ENT:Use(activator)
    if not activator:IsPlayer() then return end
    local addr  = self:GetNWString("ExpressAddress", "Unknown")
    local owner = self:GetNWEntity("ExpressOwner")
    local ownerName = IsValid(owner) and owner:Nick() or "Unknown"
    activator:ChatPrint("[Express] Address: " .. addr .. " | Owner: " .. ownerName)
end

function ENT:CanTool(ply, trace, tool)
    return tool == "weld" or tool == "gmod_wire_grabber"
end

function ENT:CPPICanTool(ply, tool)
    return tool == "weld" or tool == "gmod_wire_grabber"
end

hook.Add("CanTool", "ExpressPackage_CanTool", function(ply, trace, tool)
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "sent_express_package" then
        if tool == "weld" or tool == "gmod_wire_grabber" then
            return true
        end
        return false
    end
end)

function ENT:Think()
    local phys = self:GetPhysicsObject()
    if IsValid(phys) and not phys:IsGravityEnabled() then
        phys:EnableGravity(true)
    end
    self:NextThink(CurTime() + 1)
    return true
end

function ENT:PhysgunPickup(ply)
    return true
end

function ENT:CPPIGetOwner()
    return game.GetWorld()
end

function ENT:CanProperty(ply)
    return false
end
