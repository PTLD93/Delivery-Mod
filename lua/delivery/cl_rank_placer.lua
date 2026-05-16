concommand.Add("delivery_place_rank", function() end)
concommand.Add("delivery_remove_rank", function() end)

local function OpenRankPlacerMenu()
    if not LocalPlayer():IsAdmin() then
        chat.AddText(Color(255, 100, 100), "[Delivery] Admins only.")
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Rank Vendor Placer")
    frame:SetSize(300, 120)
    frame:Center()
    frame:MakePopup()

    local help = vgui.Create("DLabel", frame)
    help:SetText("Look at a surface, then click Place.")
    help:SetWrap(true)
    help:SetTall(30)
    help:Dock(TOP)
    help:DockMargin(10, 5, 10, 5)
    help:SetTextColor(Color(200, 200, 200))

    local btnRow = vgui.Create("DPanel", frame)
    btnRow:Dock(TOP)
    btnRow:SetTall(35)
    btnRow:DockMargin(10, 0, 10, 0)
    btnRow:SetBackgroundColor(Color(0, 0, 0, 0))

    local placeBtn = vgui.Create("DButton", btnRow)
    placeBtn:SetText("Place Rank Vendor")
    placeBtn:Dock(LEFT)
    placeBtn:SetWide(150)
    placeBtn:DockMargin(0, 0, 5, 0)
    placeBtn.DoClick = function()
        RunConsoleCommand("delivery_place_rank")
        frame:Close()
    end

    local removeBtn = vgui.Create("DButton", btnRow)
    removeBtn:SetText("Remove Looked-At")
    removeBtn:Dock(FILL)
    removeBtn.DoClick = function()
        RunConsoleCommand("delivery_remove_rank")
        frame:Close()
    end
end

concommand.Add("delivery_placer_rank", function()
    OpenRankPlacerMenu()
end)
