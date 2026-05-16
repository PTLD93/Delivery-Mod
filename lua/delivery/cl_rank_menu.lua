local ownedLevels = {}
local lockIcon = Material("icon16/lock.png")

net.Receive("RankNPC_SyncOwned", function()
    local bits = net.ReadUInt(8)
    ownedLevels = {}
    for i = 1, 3 do
        if bit.band(bits, bit.lshift(1, i - 1)) ~= 0 then
            ownedLevels[i] = true
        end
    end
end)

net.Receive("RankNPC_OpenMenu", function()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Rank Vendor")
    frame:SetSize(380, 240)
    frame:Center()
    frame:MakePopup()

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 8, 8, 8)

    for level = 1, 3 do
        local data   = RANK_LEVELS[level]
        local owned  = ownedLevels[level]
        local locked = level > 1 and not ownedLevels[level - 1] and not owned

        local row = vgui.Create("DPanel", scroll)
        row:SetTall(58)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetBackgroundColor(owned and Color(35, 60, 35, 255) or locked and Color(38, 38, 42, 255) or Color(45, 45, 50, 255))

        if locked then
            row.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(38, 38, 42, 255))
                surface.SetDrawColor(255, 255, 255, 25)
                surface.DrawRect(0, 0, w, h)
            end
        end

        local tierLabel = vgui.Create("DLabel", row)
        tierLabel:SetText(data.label)
        tierLabel:SetFont("DermaDefaultBold")
        tierLabel:SetTextColor(locked and Color(130, 130, 130) or Color(255, 255, 255))
        tierLabel:SetPos(locked and 30 or 12, 8)
        tierLabel:SetSize(200, 20)

        if locked then
            local lockImg = vgui.Create("DImage", row)
            lockImg:SetPos(12, 10)
            lockImg:SetSize(14, 14)
            lockImg:SetMaterial(lockIcon)
            lockImg:SetImageColor(Color(160, 160, 160, 200))
        end

        if not owned then
            local priceLabel = vgui.Create("DLabel", row)
            priceLabel:SetText("$" .. data.price)
            priceLabel:SetFont("DermaDefault")
            priceLabel:SetTextColor(Color(220, 180, 60))
            priceLabel:SetPos(12, 30)
            priceLabel:SetSize(200, 18)
        else
            local ownedLabel = vgui.Create("DLabel", row)
            ownedLabel:SetText("Access Granted")
            ownedLabel:SetFont("DermaDefault")
            ownedLabel:SetTextColor(Color(80, 210, 80))
            ownedLabel:SetPos(12, 30)
            ownedLabel:SetSize(200, 18)
        end

        local btn = vgui.Create("DButton", row)
        btn:SetSize(100, 38)
        btn:SetTextColor(Color(255, 255, 255))

        if owned then
            btn:SetText("Apply")
            btn.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(30, 100, 30) or Color(45, 130, 45))
            end
            btn.DoClick = function()
                net.Start("RankNPC_Apply")
                    net.WriteUInt(level, 4)
                net.SendToServer()
                frame:Close()
            end
        else
            btn:SetText("Purchase")
            btn.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and Color(30, 80, 160) or Color(50, 110, 200))
            end
            btn.DoClick = function()
                net.Start("RankNPC_Buy")
                    net.WriteUInt(level, 4)
                net.SendToServer()
                frame:Close()
            end
        end

        row.PerformLayout = function(s)
            btn:SetPos(s:GetWide() - 112, 10)
        end
    end
end)
