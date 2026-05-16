ENT.Type        = "anim"
ENT.Base        = "base_gmodentity"
ENT.PrintName   = "Fish"
ENT.Spawnable   = false
ENT.AdminOnly   = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "FishLabel")
    self:NetworkVar("Int",    0, "FishValue")
end