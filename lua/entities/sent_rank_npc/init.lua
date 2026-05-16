AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(RANK_NPC_CONFIG and RANK_NPC_CONFIG.model or "models/humans/group03/male_07.mdl")
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

function ENT:Use(activator)
    if not activator:IsPlayer() then return end

    local radius = RANK_NPC_CONFIG and RANK_NPC_CONFIG.pickupRadius or 150
    if activator:GetPos():Distance(self:GetPos()) > radius then return end

    net.Start("RankNPC_OpenMenu")
    net.Send(activator)
end

function ENT:OnRemove()
    if RANK_NPC_REFRESHING then return end
    print("[Delivery] A Rank Vendor was removed, triggering refresh...")
    timer.Simple(0.1, function()
        RankNPC_RefreshAll()
    end)
end

function ENT:CanTool(ply)
    return ply:IsAdmin()
end

function ENT:CanProperty(ply)
    return ply:IsSuperAdmin()
end
