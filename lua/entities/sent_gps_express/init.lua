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
    
    -- Get active express job addresses
    local job = EXPRESS_ACTIVE_JOBS[activator:SteamID()]
    if not job then
        activator:ChatPrint("[GPS] You don't have an active express job.")
        return
    end
    
    local addresses = {}
    local seen = {}
    for _, pkgIdx in ipairs(job.packages) do
        local pkg = ents.GetByIndex(pkgIdx)
        if IsValid(pkg) then
            local addr = pkg:GetNWString("ExpressAddress", "")
            if addr ~= "" and not seen[addr] then
                table.insert(addresses, addr)
                seen[addr] = true
            end
        end
    end
    
    if #addresses == 0 and job.delivered >= job.total then
        table.insert(addresses, "Express NPC")
    end
    
    net.Start("GPS_OpenMenu")
    net.WriteString("Express")
    net.WriteInt(#addresses, 8)
    for _, addr in ipairs(addresses) do
        net.WriteString(addr)
    end
    net.Send(activator)
end
