include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 15)

    cam.Start3D2D(pos, Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.1)
        draw.SimpleText(self:GetFishLabel(), "DermaDefaultBold", 0, 0, Color(100, 220, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("$" .. self:GetFishValue(), "DermaDefault", 0, 16, Color(100, 220, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end