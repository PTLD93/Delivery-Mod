concommand.Add("delivery_place", function() end)
concommand.Add("delivery_remove", function() end)

local function OpenPlacerMenu()
    if not LocalPlayer():IsAdmin() then
        chat.AddText(Color(255, 100, 100), "[Delivery] Admins only.")
        return
    end

    if not DELIVERY_NPCS then
        chat.AddText(Color(255, 100, 100), "[Delivery] Config not loaded!")
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Delivery NPC Placer")
    frame:SetSize(300, 160)
    frame:Center()
    frame:MakePopup()

    local help = vgui.Create("DLabel", frame)
    help:SetText("Look at a surface, pick an NPC type and click Place.")
    help:SetWrap(true)
    help:SetTall(35)
    help:Dock(TOP)
    help:DockMargin(10, 5, 10, 5)
    help:SetTextColor(Color(200, 200, 200))

    local dropdown = vgui.Create("DComboBox", frame)
    dropdown:SetTall(25)
    dropdown:SetValue("Select NPC type...")
    dropdown:Dock(TOP)
    dropdown:DockMargin(10, 0, 10, 8)

    local npcKeys = {}
    for k, _ in pairs(DELIVERY_NPCS) do
        table.insert(npcKeys, k)
    end
    table.sort(npcKeys)

    for _, key in ipairs(npcKeys) do
        local data = DELIVERY_NPCS[key]
        dropdown:AddChoice(data and data.label or key, key)
    end

    local selectedKey = ""
    dropdown.OnSelect = function(_, _, _, npcKey)
        selectedKey = npcKey
    end

    local btnRow = vgui.Create("DPanel", frame)
    btnRow:Dock(TOP)
    btnRow:SetTall(35)
    btnRow:DockMargin(10, 0, 10, 0)
    btnRow:SetBackgroundColor(Color(0, 0, 0, 0))

    local placeBtn = vgui.Create("DButton", btnRow)
    placeBtn:SetText("Place")
    placeBtn:Dock(LEFT)
    placeBtn:SetWide(120)
    placeBtn:DockMargin(0, 0, 5, 0)
    placeBtn.DoClick = function()
        if selectedKey == "" then
            chat.AddText(Color(255, 100, 100), "[Delivery] Select an NPC type first!")
            return
        end
        RunConsoleCommand("delivery_place", selectedKey)
        frame:Close()
    end

    local removeBtn = vgui.Create("DButton", btnRow)
    removeBtn:SetText("Remove Looked-At NPC")
    removeBtn:Dock(FILL)
    removeBtn.DoClick = function()
        RunConsoleCommand("delivery_remove")
        frame:Close()
    end
end

concommand.Add("delivery_placer", function()
    OpenPlacerMenu()
end)