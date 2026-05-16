ENT.Base      = "base_anim"
ENT.Type      = "anim"
ENT.PrintName = "Delivery NPC"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "DeliveryNPCKey")
    self:NetworkVar("String", 1, "DeliveryNPCLabel")
    self:NetworkVar("Int",    0, "DeliveryNPCID")
end