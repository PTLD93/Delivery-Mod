include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 50)
    local ang = Angle(0, EyeAngles().y - 90, 90)

    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText("SEWAGE DROPOFF", "ChatFont", 0, 0, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
