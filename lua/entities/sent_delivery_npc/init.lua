AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local gender  = math.random() > 0.5 and "male" or "female"
    local modelID = math.random(1, gender == "male" and 9 or 6)
    if gender == "female" and modelID > 4 then modelID = modelID + 1 end

    self:SetModel(string.format("models/Humans/group01/%s_0%s.mdl", gender, modelID))
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

function ENT:OnRemove()
    if DELIVERY_REFRESHING then return end
    print("[Delivery] A delivery NPC was removed, triggering refresh...")
    timer.Simple(0.1, function()
        Delivery_RefreshNPCs()
    end)
end

function ENT:CanTool(ply)
    return ply:IsAdmin()
end

hook.Add("CanTool", "DeliveryNPC_CanTool", function(ply, trace, tool)
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "sent_delivery_npc" then
        return ply:IsAdmin()
    end
end)

function ENT:CanProperty(ply)
    if not ply:IsSuperAdmin() then return false end
end

function ENT:Use(activator)
    if not activator:IsPlayer() then return end

    local npcKey = self:GetDeliveryNPCKey()
    if npcKey == "" then return end

    local npcData = DELIVERY_NPCS[npcKey]
    if not npcData then return end

    if activator:GetPos():Distance(self:GetPos()) > DELIVERY_CONFIG.pickupRadius then return end

    net.Start("DeliveryNPC_OpenMenu")
        net.WriteString(npcKey)
        net.WriteVector(self:GetPos())
    net.Send(activator)
end