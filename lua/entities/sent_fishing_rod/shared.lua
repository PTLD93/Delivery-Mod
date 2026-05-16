ENT.Type        = "anim"
ENT.Base        = "base_gmodentity"
ENT.PrintName   = "Fishing Rod"
ENT.Spawnable   = false
ENT.AdminOnly   = false

function ENT:SetupDataTables()
    self:NetworkVar("Int",    0, "Bait")
    self:NetworkVar("Bool",   0, "Fishing")
    self:NetworkVar("Bool",   1, "HasFish")
    self:NetworkVar("String", 0, "FishLabel")
    self:NetworkVar("Entity", 0, "OwnerPlayer")
end