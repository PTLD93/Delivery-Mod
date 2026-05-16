include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 50)
    local ang = Angle(0, EyeAngles().y - 90, 90)

    local address = self:GetNWString("ManholeAddress", "")

    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText("SEWAGE MANHOLE", "ChatFont", 0, 0, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if address and address ~= "" then
            draw.SimpleText(address, "ChatFont", 0, 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("NO ADDRESS", "ChatFont", 0, 15, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
