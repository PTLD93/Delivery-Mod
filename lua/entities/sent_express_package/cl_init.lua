include("shared.lua")

local LABEL_DIST  = 600
local LABEL_SCALE = 0.11

function ENT:Draw()
    self:DrawModel()

    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    if lp:GetPos():DistToSqr(self:GetPos()) > LABEL_DIST * LABEL_DIST then return end

    if lp:GetEyeTrace().Entity ~= self then return end

    local addr    = self:GetNWString("ExpressAddress", "")
    local expired = self:GetNWBool("ExpressExpired", false)
    local owner   = self:GetNWEntity("ExpressOwner")
    local isMine  = IsValid(owner) and owner == lp

    if addr == "" then return end

    local pos = self:GetPos() + Vector(0, 0, self:BoundingRadius() - 4)
    local ang = lp:EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local col  = expired and Color(200, 80, 80) or (isMine and Color(80, 220, 100) or Color(220, 220, 220))

    cam.Start3D2D(pos, ang, LABEL_SCALE)
        draw.RoundedBox(6, -120, -22, 240, 44, Color(0, 0, 0, 180))
        draw.SimpleText("TO:", "DermaDefault", 0, -12, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleTextOutlined(addr, "DermaDefaultBold", 0, 8, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,200))
    cam.End3D2D()
end
