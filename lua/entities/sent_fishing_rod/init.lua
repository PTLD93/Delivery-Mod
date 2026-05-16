AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/harpoon002a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetBait(0)
    self:SetFishing(false)
    self:SetHasFish(false)
    self:SetFishLabel("")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    timer.Simple(0.2, function()
        if not IsValid(self) then return end
        self:SpawnHook()
    end)
end

function ENT:SpawnHook()
    local hook = ents.Create("prop_physics")
    if not IsValid(hook) then return end

    hook:SetModel("models/props_interiors/pot02a.mdl")
    hook:SetPos(self:GetPos() + Vector(0, 0, -20))
    hook:Spawn()
    hook:Activate()

    local hookPhys = hook:GetPhysicsObject()
    if IsValid(hookPhys) then
        hookPhys:SetMass(5)
        hookPhys:Wake()
    end

    local rope = constraint.Rope(
        self,
        hook,
        0,
        0,
        Vector(40,0,0),
        Vector(0,0,0),
        160,
        0,
        0,
        2,
        "cable/rope",
        false
    )

    self.HookEnt = hook
    self.RopeEnt = rope
end

function ENT:IsHookInWater()
    if not IsValid(self.HookEnt) then return false end
    return self.HookEnt:WaterLevel() > 0
end

function ENT:StartFishing(activator)
    self:SetFishing(true)
    local biteTime = math.random(FISHING_CONFIG.biteTimeMin, FISHING_CONFIG.biteTimeMax)

    timer.Create("FishingBite_" .. self:EntIndex(), biteTime, 1, function()
        if not IsValid(self) then return end
        if not self:GetFishing() then return end

        if not self:IsHookInWater() then
            self:SetFishing(false)
            return
        end

        local f = FISHING_GetRandomFish()
        self:SetFishing(false)
        self:SetHasFish(true)
        self:SetFishLabel(f.label)
        self:SetBait(self:GetBait() - 1)

        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():Distance(self:GetPos()) < 500 then
                ply:ChatPrint("[Fishing] A " .. f.label .. " was caught on a nearby rod!")
            end
        end
    end)
end

function ENT:Think()
    if self:GetFishing() then
        if not self:IsHookInWater() then
            self:SetFishing(false)
            timer.Remove("FishingBite_" .. self:EntIndex())

            for _, ply in ipairs(player.GetAll()) do
                if ply:GetPos():Distance(self:GetPos()) < 200 then
                    ply:ChatPrint("[Fishing] The hook left the water, fishing cancelled!")
                end
            end
        end
    elseif not self:GetHasFish() and self:GetBait() > 0 and self:IsHookInWater() then
        -- hook back in water with bait, restart fishing
        self:StartFishing(nil)

        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():Distance(self:GetPos()) < 200 then
                ply:ChatPrint("[Fishing] The hook is back in water, fishing resumed!")
            end
        end
    end

    self:NextThink(CurTime() + 0.5)
    return true
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if self.LastUse and CurTime() - self.LastUse < 1 then return end
    self.LastUse = CurTime()

    if self:GetHasFish() then
        local fishLabel = self:GetFishLabel()
        local fishData  = nil

        for _, f in ipairs(FISHING_FISH) do
            if f.label == fishLabel then
                fishData = f
                break
            end
        end

        if not fishData then return end

        local fish = ents.Create("sent_fish")
        if not IsValid(fish) then return end

        fish:SetPos(activator:GetPos() + activator:GetForward() * 40 + Vector(0, 0, 10))
        fish:Spawn()
        fish:Activate()

        fish:SetFishLabel(fishData.label)
        fish:SetFishValue(fishData.value)
        fish:SetOwnerPlayer(activator)
        fish:SetNWEntity("FishOwner", activator)

        self:SetHasFish(false)
        self:SetFishLabel("")

        activator:ChatPrint("[Fishing] Collected a " .. fishData.label .. " worth $" .. fishData.value .. "!")

        if self:GetBait() > 0 then
            self:StartFishing(activator)
        else
            activator:ChatPrint("[Fishing] Rod is out of bait!")
        end

        return
    end

    if not self:IsHookInWater() then
        activator:ChatPrint("[Fishing] The hook must be in water to fish!")
        return
    end

    net.Start("Fishing_OpenRodMenu")
        net.WriteEntity(self)
    net.Send(activator)
end

function ENT:OnRemove()
    timer.Remove("FishingBite_" .. self:EntIndex())
    if IsValid(self.RopeEnt) then
        self.RopeEnt:Remove()
    end
    if IsValid(self.HookEnt) then
        self.HookEnt:Remove()
    end
end

function ENT:CanTool(ply, trace, tool)
    return true
end

function ENT:PhysgunPickup(ply)
    return true
end