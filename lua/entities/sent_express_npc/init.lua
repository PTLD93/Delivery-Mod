AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/humans/group01/male_09.mdl")
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)
    self:SetSequence(self:LookupSequence("idle_angry") or 0)
    self:ResetSequenceInfo()

    timer.Simple(0, function()
        if IsValid(self) then
            self:CPPISetOwner(game.GetWorld())
        end
    end)
end

function ENT:CPPIGetOwner()
    return game.GetWorld()
end

function ENT:CanTool(ply)
    return ply:IsAdmin()
end

function ENT:CanProperty(ply)
    return false
end

hook.Add("CanTool", "ExpressNPC_CanTool", function(ply, trace, tool)
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "sent_express_npc" then
        return ply:IsAdmin()
    end
end)

function ENT:Use(activator)
    if not activator:IsPlayer() then return end
    if activator:GetPos():Distance(self:GetPos()) > EXPRESS_CONFIG.pickupRadius then return end

    net.Start("Express_OpenMenu")
        net.WriteInt(self:EntIndex(), 16)
    net.Send(activator)
end

function ENT:OnRemove()
end
