AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate1x1.mdl")
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Wake()
    end

    self:SetNWInt("SewageDropoffID", 0)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if SERVER then
        Sewage_PlayerUseSewageDropoff(activator, self)
    end
end

function ENT:SetDropoffID(id)
    self:SetNWInt("SewageDropoffID", id)
end
