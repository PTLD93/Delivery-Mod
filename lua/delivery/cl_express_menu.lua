local activeNPCIdx = nil

local function OpenExpressMenu(npcIdx, hasJob, jobTotal, jobDelivered)
    if IsValid(EXPRESS_MENU_FRAME) then EXPRESS_MENU_FRAME:Remove() end

    local frame = vgui.Create("DFrame")
    EXPRESS_MENU_FRAME = frame
    frame:SetTitle("Express Delivery")
    frame:SetSize(400, hasJob and 280 or 480)
    frame:Center()
    frame:MakePopup()

    local inner = vgui.Create("DPanel", frame)
    inner:Dock(FILL)
    inner:DockMargin(12, 8, 12, 12)
    inner:SetBackgroundColor(Color(35, 35, 38, 255))

    if not hasJob then
        local scroll = vgui.Create("DScrollPanel", inner)
        scroll:Dock(FILL)

        local desc = vgui.Create("DLabel", scroll)
        desc:SetText("Select a delivery vehicle type to start. Each has different package limits and pay ranges based on the amount of packages assigned.")
        desc:SetTextColor(Color(200, 200, 200))
        desc:SetFont("DermaDefault")
        desc:Dock(TOP)
        desc:DockMargin(0, 6, 0, 16)
        desc:SetTall(40)
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)

        for i, v in ipairs(EXPRESS_VARIANTS) do
            local btn = vgui.Create("DButton", scroll)
            btn:SetTall(60)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 8)
            btn:SetText("")
            btn.Paint = function(s, w, h)
                local col = s:IsHovered() and Color(60, 60, 65) or Color(45, 45, 48)
                draw.RoundedBox(8, 0, 0, w, h, col)
                
                draw.SimpleText(v.name, "DermaDefaultBold", 12, 10, Color(255, 255, 255))
                draw.SimpleText("Salary: $" .. (v.minSalary / 1000) .. "k – $" .. (v.maxSalary / 1000) .. "k", "DermaDefault", 12, 26, Color(100, 220, 100))
                draw.SimpleText("Packages: " .. v.minPackages .. " – " .. v.maxPackages .. " (" .. (v.sizeDesc or "Mixed") .. ")", "DermaDefault", 12, 42, Color(180, 180, 180))
                draw.SimpleText("Time: " .. math.floor(v.minTime / 60) .. " – " .. math.floor(v.maxTime / 60) .. " mins", "DermaDefault", w - 12, h / 2, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function()
                net.Start("Express_StartJob")
                    net.WriteInt(npcIdx, 16)
                    net.WriteInt(i, 4) -- Send variant index
                net.SendToServer()
                frame:Remove()
            end
        end
    else
        local progress = vgui.Create("DLabel", inner)
        progress:SetText("Packages Delivered: " .. jobDelivered .. " / " .. jobTotal)
        progress:SetTextColor(Color(100, 220, 100))
        progress:SetFont("DermaDefaultBold")
        progress:Dock(TOP)
        progress:DockMargin(0, 6, 0, 6)
        progress:SetTall(22)

        local hint = vgui.Create("DLabel", inner)
        hint:SetText("Bring all packages to the listed addresses,\nthen return here to collect your payment.")
        hint:SetTextColor(Color(200, 200, 200))
        hint:SetFont("DermaDefault")
        hint:Dock(TOP)
        hint:DockMargin(0, 0, 0, 14)
        hint:SetTall(38)
        hint:SetWrap(true)
        hint:SetAutoStretchVertical(true)

        local turnBtn = vgui.Create("DButton", inner)
        turnBtn:SetText("Collect Payment")
        turnBtn:SetTall(40)
        turnBtn:Dock(TOP)
        turnBtn:DockMargin(0, 0, 0, 8)
        turnBtn:SetTextColor(Color(255, 255, 255))
        turnBtn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and Color(40, 140, 200) or Color(50, 160, 220))
        end
        turnBtn.DoClick = function()
            net.Start("Express_TurnIn")
            net.SendToServer()
            frame:Remove()
        end

        local cancelBtn = vgui.Create("DButton", inner)
        cancelBtn:SetText("Cancel Job")
        cancelBtn:SetTall(36)
        cancelBtn:Dock(TOP)
        cancelBtn:SetTextColor(Color(255, 255, 255))
        cancelBtn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and Color(160, 40, 40) or Color(180, 60, 60))
        end
        cancelBtn.DoClick = function()
            net.Start("Express_CancelJob")
            net.SendToServer()
            EXPRESS_JOB_ACTIVE    = false
            EXPRESS_JOB_EXPIRED   = false
            EXPRESS_JOB_TOTAL     = 0
            EXPRESS_JOB_DELIVERED = 0
            EXPRESS_JOB_START     = nil
            frame:Remove()
        end
    end
end

net.Receive("Express_OpenMenu", function()
    local npcIdx = net.ReadInt(16)
    activeNPCIdx = npcIdx

    local hasJob      = EXPRESS_JOB_ACTIVE or false
    local jobTotal    = EXPRESS_JOB_TOTAL or 0
    local jobDelivered = EXPRESS_JOB_DELIVERED or 0

    OpenExpressMenu(npcIdx, hasJob, jobTotal, jobDelivered)
end)

net.Receive("Express_JobStarted", function()
    EXPRESS_JOB_ACTIVE     = true
    EXPRESS_JOB_TOTAL      = net.ReadInt(8)
    EXPRESS_JOB_START      = net.ReadFloat()
    EXPRESS_JOB_TIMELIMIT  = net.ReadInt(16)
    EXPRESS_JOB_DELIVERED  = 0
    EXPRESS_JOB_EXPIRED    = false
    EXPRESS_JOB_COMPLETED  = false

    local mins = math.floor(EXPRESS_JOB_TIMELIMIT / 60)
    LocalPlayer():ChatPrint("[Express] Job started! Deliver " .. EXPRESS_JOB_TOTAL .. " packages within " .. mins .. " minutes.")
end)

net.Receive("Express_PackageDelivered", function()
    EXPRESS_JOB_DELIVERED = net.ReadInt(8)
    EXPRESS_JOB_TOTAL     = net.ReadInt(8)
    if EXPRESS_JOB_DELIVERED >= EXPRESS_JOB_TOTAL then
        EXPRESS_JOB_COMPLETED = true
    end
end)

net.Receive("Express_JobComplete", function()
    local delivered = net.ReadInt(8)
    local total     = net.ReadInt(8)
    local payout    = net.ReadInt(32)

    EXPRESS_JOB_ACTIVE  = false
    EXPRESS_JOB_EXPIRED = false

    chat.AddText(
        Color(255, 215, 0), "[Express] ",
        Color(255, 255, 255), "Job complete! Delivered ",
        Color(100, 220, 100), tostring(delivered) .. "/" .. tostring(total),
        Color(255, 255, 255), " packages. Payout: ",
        Color(100, 220, 100), "$" .. tostring(payout)
    )
end)

net.Receive("Express_JobExpired", function()
    EXPRESS_JOB_EXPIRED = true
    LocalPlayer():ChatPrint("[Express] Time's up! Return to the express NPC to collect payment for packages delivered.")
end)

net.Receive("Express_SyncJob", function()
    EXPRESS_JOB_TOTAL      = net.ReadInt(8)
    EXPRESS_JOB_DELIVERED  = net.ReadInt(8)
    EXPRESS_JOB_START      = net.ReadFloat()
    EXPRESS_JOB_EXPIRED    = net.ReadBool()
    EXPRESS_JOB_TIMELIMIT  = net.ReadInt(16)
    EXPRESS_JOB_ACTIVE     = true
end)
