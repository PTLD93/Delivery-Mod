include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos   = self:GetPos() + Vector(0, 0, 85)
    local ang   = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, ang, 0.18)
        draw.SimpleTextOutlined("Express Delivery", "DermaLarge", 0, 0, Color(255, 210, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,220))
    cam.End3D2D()
end
