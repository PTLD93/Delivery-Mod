include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 30)

    cam.Start3D2D(pos, Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.1)
        if self:GetHasFish() then
            draw.SimpleText("🐟 " .. self:GetFishLabel() .. " caught!", "DermaDefaultBold", 0, 0, Color(100, 220, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Press E to collect", "DermaDefault", 0, 16, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self:GetFishing() then
            draw.SimpleText("🎣 Fishing... (" .. self:GetBait() .. " bait)", "DermaDefaultBold", 0, 0, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Press E to add bait", "DermaDefault", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end