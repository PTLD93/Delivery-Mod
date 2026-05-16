AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Sewage Services NPC"
ENT.Author = "Delivery Mod"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:Initialize()
    self:SetModel("models/humans/group03/male_07.mdl")
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)

    self:SetSequence(self:LookupSequence("idle_angry") or 0)
    self:ResetSequenceInfo()

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Wake()
    end

    self:SetNWInt("SewageNPCID", 0)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if SERVER then
        net.Start("Sewage_OpenMenu")
            net.WriteInt(self:EntIndex(), 16)
        net.Send(activator)
    end
end

function ENT:SetNPCID(id)
    self:SetNWInt("SewageNPCID", id)
end
