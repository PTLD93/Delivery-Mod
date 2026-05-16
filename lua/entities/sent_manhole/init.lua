AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/tubes/circle2x2.mdl")
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Wake()
    end

    self:SetNWInt("ManholeID", 0)
    self:SetNWString("ManholeAddress", "")
end

function ENT:SetManholeAddress(address)
    self:SetNWString("ManholeAddress", address or "")
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if SERVER then
        Sewage_PlayerUseManhole(activator, self)
    end
end

function ENT:SetManholeID(id)
    self:SetNWInt("ManholeID", id)
end
