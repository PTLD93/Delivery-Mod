AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator)
    if not activator:IsPlayer() then return end
    
    -- Get active sewage job addresses
    local job = SEWAGE_ACTIVE_JOBS[activator:SteamID()]
    if not job then
        activator:ChatPrint("[GPS] You don't have an active sewage job.")
        return
    end
    
    local addresses = {}
    -- Only show addresses that haven't been collected yet
    for _, addr in ipairs(job.manholes) do
        -- Find the manhole entity for this address to see if it's collected
        local collected = false
        for entIdx, _ in pairs(job.collectedIndices) do
            local ent = ents.GetByIndex(entIdx)
            if IsValid(ent) and ent:GetNWString("ManholeAddress") == addr then
                collected = true
                break
            end
        end
        
        if not collected then
            table.insert(addresses, addr)
        end
    end
    
    if #addresses == 0 then
        if job.collected >= #job.manholes and not job.drained then
            table.insert(addresses, "Sewage Dropoff")
        elseif job.drained and not job.paid then
            table.insert(addresses, "Sewage NPC")
        end
    end
    
    net.Start("GPS_OpenMenu")
    net.WriteString("Sewage")
    net.WriteInt(#addresses, 8)
    for _, addr in ipairs(addresses) do
        net.WriteString(addr)
    end
    net.Send(activator)
end
