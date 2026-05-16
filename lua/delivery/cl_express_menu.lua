local activeNPCIdx = nil

local function OpenExpressMenu(npcIdx, hasJob, jobTotal, jobDelivered)
    if IsValid(EXPRESS_MENU_FRAME) then EXPRESS_MENU_FRAME:Remove() end

    local frame = vgui.Create("DFrame")
    EXPRESS_MENU_FRAME = frame
    frame:SetTitle("Express Delivery")
    frame:SetSize(380, hasJob and 280 or 240)
    frame:Center()
    frame:MakePopup()

    local inner = vgui.Create("DPanel", frame)
    inner:Dock(FILL)
    inner:DockMargin(12, 8, 12, 12)
    inner:SetBackgroundColor(Color(35, 35, 38, 255))

    if not hasJob then
        local desc = vgui.Create("DLabel", inner)
        local minPayout = EXPRESS_CONFIG.maxPayout / 2
        desc:SetText("Pick up a batch of 6–20 packages and deliver them\nto the correct addresses across the map.\n\n6–10 packages: up to $" .. minPayout .. " | 11–20 packages: up to $" .. EXPRESS_CONFIG.maxPayout .. "\nTime limit: 35 minutes")
        desc:SetTextColor(Color(200, 200, 200))
        desc:SetFont("DermaDefault")
        desc:Dock(TOP)
        desc:DockMargin(0, 6, 0, 16)
        desc:SetTall(72)
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)

        local btn = vgui.Create("DButton", inner)
        btn:SetText("Start Delivery")
        btn:SetTall(44)
        btn:Dock(TOP)
        btn:SetTextColor(Color(255, 255, 255))
        btn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and Color(40, 160, 60) or Color(50, 200, 80))
        end
        btn.DoClick = function()
            net.Start("Express_StartJob")
                net.WriteInt(npcIdx, 16)
            net.SendToServer()
            frame:Remove()
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
