AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/CS_militia/fishriver01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetFishLabel("")
    self:SetFishValue(0)

    timer.Simple(0, function()
        if not IsValid(self) then return end
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(2)
        end
    end)
end

function ENT:SetOwnerPlayer(ply)
    self.OwnerPlayer = ply
    self:SetNWEntity("FishOwner", ply)
end

function ENT:GetOwnerPlayer()
    return self.OwnerPlayer
end

function ENT:CanTool(ply, trace, tool)
    return true
end

function ENT:PhysgunPickup(ply)
    return true
end