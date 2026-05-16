ENT.Type        = "anim"
ENT.Base        = "base_gmodentity"
ENT.PrintName   = "Cargo"
ENT.Spawnable   = false
ENT.AdminOnly   = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "CargoKey")
    self:NetworkVar("String", 1, "CargoLabel")
    self:NetworkVar("Int",    0, "CargoValue")
end