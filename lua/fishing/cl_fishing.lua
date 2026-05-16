net.Receive("Fishing_OpenRodMenu", function()
    local rod = net.ReadEntity()
    if not IsValid(rod) then return end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Fishing Rod")
    frame:SetSize(280, 200)
    frame:Center()
    frame:MakePopup()

    -- status
    local status = vgui.Create("DLabel", frame)
    status:SetText("Bait on rod: " .. rod:GetBait() .. " / " .. FISHING_CONFIG.maxBait)
    status:SetTextColor(Color(200, 200, 200))
    status:SetFont("DermaDefaultBold")
    status:SetTall(25)
    status:Dock(TOP)
    status:DockMargin(10, 5, 10, 5)

    -- bait cost info
    local costLabel = vgui.Create("DLabel", frame)
    costLabel:SetText("Bait cost: $" .. FISHING_CONFIG.baitPrice .. " each")
    costLabel:SetTextColor(Color(100, 220, 100))
    costLabel:SetTall(20)
    costLabel:Dock(TOP)
    costLabel:DockMargin(10, 0, 10, 8)

    -- bait amount slider
    local slider = vgui.Create("DNumSlider", frame)
    slider:SetText("Bait to add")
    slider:SetMin(1)
    slider:SetMax(FISHING_CONFIG.maxBait - rod:GetBait())
    slider:SetDecimals(0)
    slider:SetValue(1)
    slider:Dock(TOP)
    slider:DockMargin(10, 0, 10, 8)

    if FISHING_CONFIG.maxBait - rod:GetBait() <= 0 then
        local fullLabel = vgui.Create("DLabel", frame)
        fullLabel:SetText("Rod is full of bait!")
        fullLabel:SetTextColor(Color(255, 100, 100))
        fullLabel:SetTall(25)
        fullLabel:Dock(TOP)
        fullLabel:DockMargin(10, 0, 10, 0)
        return
    end

    -- total cost label
    local totalLabel = vgui.Create("DLabel", frame)
    totalLabel:SetText("Total cost: $" .. FISHING_CONFIG.baitPrice)
    totalLabel:SetTextColor(Color(255, 255, 100))
    totalLabel:SetTall(20)
    totalLabel:Dock(TOP)
    totalLabel:DockMargin(10, 0, 10, 5)

    slider.OnValueChanged = function(_, val)
        local amount = math.Round(val)
        totalLabel:SetText("Total cost: $" .. amount * FISHING_CONFIG.baitPrice)
    end

    -- add bait button
    local btn = vgui.Create("DButton", frame)
    btn:SetText("Add Bait")
    btn:SetTall(35)
    btn:Dock(TOP)
    btn:DockMargin(10, 0, 10, 0)
    btn.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and
            Color(30, 110, 180) or Color(50, 130, 200))
    end
    btn:SetTextColor(Color(255, 255, 255))
    btn.DoClick = function()
        local amount = math.Round(slider:GetValue())
        net.Start("Fishing_AddBait")
            net.WriteEntity(rod)
            net.WriteInt(amount, 8)
        net.SendToServer()
        frame:Close()
    end
end)