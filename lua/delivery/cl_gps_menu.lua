local function OpenGPSMenu(type, addresses)
    local frame = vgui.Create("DFrame")
    frame:SetTitle(type .. " GPS Selection")
    frame:SetSize(300, 400)
    frame:Center()
    frame:MakePopup()

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)

    if #addresses == 0 then
        local lbl = vgui.Create("DLabel", scroll)
        lbl:SetText("No active delivery targets found.")
        lbl:Dock(TOP)
        lbl:SetContentAlignment(5)
        lbl:SetTall(30)
    end

    for _, addr in ipairs(addresses) do
        local btn = vgui.Create("DButton", scroll)
        btn:SetText(addr)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 5)
        btn:SetTall(30)
        btn.DoClick = function()
            net.Start("GPS_SelectAddress")
            net.WriteString(type)
            net.WriteString(addr)
            net.SendToServer()
            frame:Remove()
        end
    end
end

net.Receive("GPS_OpenMenu", function()
    local type = net.ReadString()
    local count = net.ReadInt(8)
    local addresses = {}
    for i = 1, count do
        addresses[i] = net.ReadString()
    end
    OpenGPSMenu(type, addresses)
end)
