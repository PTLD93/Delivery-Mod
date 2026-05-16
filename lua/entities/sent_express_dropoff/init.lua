AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate1x1.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)

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

hook.Add("CanTool", "ExpressDropoff_CanTool", function(ply, trace, tool)
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "sent_express_dropoff" then
        return ply:IsAdmin()
    end
end)

function ENT:Use(activator)
    if not activator:IsPlayer() then return end

    local job = EXPRESS_ACTIVE_JOBS and EXPRESS_ACTIVE_JOBS[activator:SteamID()]
    if not job then
        activator:ChatPrint("[Express] You don't have an active delivery job.")
        return
    end

    if job.expired then
        activator:ChatPrint("[Express] Your time is up! Return packages to the express NPC.")
        return
    end

    local myAddress = self:GetNWString("DropoffAddress", "")
    if myAddress == "" then return end

    local delivered = 0
    for _, pkg in ipairs(ents.FindByClass("sent_express_package")) do
        if not IsValid(pkg) then continue end

        local owner = pkg:GetNWEntity("ExpressOwner")
        if not IsValid(owner) or owner ~= activator then continue end

        local pkgAddr = pkg:GetNWString("ExpressAddress", "")
        if pkgAddr ~= myAddress then continue end

        local dist = pkg:GetPos():Distance(self:GetPos())
        if dist > EXPRESS_CONFIG.deliverRadius then continue end

        if Express_DeliverPackage(activator, pkg) then
            delivered = delivered + 1
        end
    end

    if delivered > 0 then
        activator:ChatPrint("[Express] Delivered " .. delivered .. " package(s) to " .. myAddress .. "!")
    else
        activator:ChatPrint("[Express] No matching packages for " .. myAddress .. " nearby.")
    end
end
