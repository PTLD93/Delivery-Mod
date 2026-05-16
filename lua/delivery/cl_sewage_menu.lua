local SEWAGE_MENU_FRAME

local SEWAGE_JOB_ACTIVE    = false
local SEWAGE_JOB_MANHOLES  = {}
local SEWAGE_JOB_COLLECTED = 0
local SEWAGE_JOB_DRAINED   = false

local function OpenSewageMenu(npcIdx)
    if IsValid(SEWAGE_MENU_FRAME) then SEWAGE_MENU_FRAME:Remove() end

    local hasJob   = SEWAGE_JOB_ACTIVE
    local drained  = SEWAGE_JOB_DRAINED
    local collected = SEWAGE_JOB_COLLECTED
    local total    = #SEWAGE_JOB_MANHOLES

    local frame = vgui.Create("DFrame")
    SEWAGE_MENU_FRAME = frame
    frame:SetTitle("Sewage Services")
    frame:SetSize(380, hasJob and 300 or 220)
    frame:Center()
    frame:MakePopup()

    local inner = vgui.Create("DPanel", frame)
    inner:Dock(FILL)
    inner:DockMargin(12, 8, 12, 12)
    inner:SetBackgroundColor(Color(35, 35, 38, 255))

    if not hasJob then
        local desc = vgui.Create("DLabel", inner)
        desc:SetText(
            "Collect sewage from " .. SEWAGE_CONFIG.manholesPerJob .. " manholes across the map.\n" ..
            "Drive your sewage tanker to each manhole, then empty it at the dropoff.\n\n" ..
            "Full payout: $" .. SEWAGE_CONFIG.fullPayout .. " | No time limit."
        )
        desc:SetTextColor(Color(200, 200, 200))
        desc:SetFont("DermaDefault")
        desc:Dock(TOP)
        desc:DockMargin(0, 6, 0, 16)
        desc:SetTall(72)
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)

        local btn = vgui.Create("DButton", inner)
        btn:SetText("Start Sewage Job")
        btn:SetTall(44)
        btn:Dock(TOP)
        btn:SetTextColor(Color(255, 255, 255))
        btn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and Color(60, 130, 60) or Color(80, 160, 80))
        end
        btn.DoClick = function()
            net.Start("Sewage_RequestStart")
                net.WriteInt(npcIdx, 16)
            net.SendToServer()
            frame:Remove()
        end
    elseif drained then
        local progress = vgui.Create("DLabel", inner)
        progress:SetText("Manholes collected: " .. collected .. " / " .. total)
        progress:SetTextColor(Color(100, 220, 100))
        progress:SetFont("DermaDefaultBold")
        progress:Dock(TOP)
        progress:DockMargin(0, 6, 0, 6)
        progress:SetTall(22)

        local hint = vgui.Create("DLabel", inner)
        hint:SetText("Tanker emptied at the dropoff. Collect your payment below.")
        hint:SetTextColor(Color(200, 200, 200))
        hint:SetFont("DermaDefault")
        hint:Dock(TOP)
        hint:DockMargin(0, 0, 0, 14)
        hint:SetTall(30)
        hint:SetWrap(true)

        local payBtn = vgui.Create("DButton", inner)
        payBtn:SetText("Collect Payment")
        payBtn:SetTall(44)
        payBtn:Dock(TOP)
        payBtn:SetTextColor(Color(255, 255, 255))
        payBtn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and Color(40, 140, 200) or Color(50, 160, 220))
        end
        payBtn.DoClick = function()
            net.Start("Sewage_RequestPayment")
            net.SendToServer()
            frame:Remove()
        end
    else
        local progress = vgui.Create("DLabel", inner)
        progress:SetText("Manholes collected: " .. collected .. " / " .. total)
        progress:SetTextColor(Color(100, 220, 100))
        progress:SetFont("DermaDefaultBold")
        progress:Dock(TOP)
        progress:DockMargin(0, 6, 0, 6)
        progress:SetTall(22)

        local hint = vgui.Create("DLabel", inner)
        hint:SetText("Collect sewage from all manholes, then empty your\nsewage tanker at the dropoff before returning here.")
        hint:SetTextColor(Color(200, 200, 200))
        hint:SetFont("DermaDefault")
        hint:Dock(TOP)
        hint:DockMargin(0, 0, 0, 14)
        hint:SetTall(38)
        hint:SetWrap(true)

        local cancelBtn = vgui.Create("DButton", inner)
        cancelBtn:SetText("Cancel Job")
        cancelBtn:SetTall(36)
        cancelBtn:Dock(TOP)
        cancelBtn:SetTextColor(Color(255, 255, 255))
        cancelBtn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and Color(160, 40, 40) or Color(180, 60, 60))
        end
        cancelBtn.DoClick = function()
            net.Start("Sewage_CancelJob")
            net.SendToServer()
            SEWAGE_JOB_ACTIVE    = false
            SEWAGE_JOB_MANHOLES  = {}
            SEWAGE_JOB_COLLECTED = 0
            SEWAGE_JOB_DRAINED   = false
            frame:Remove()
        end
    end
end

net.Receive("Sewage_OpenMenu", function()
    local npcIdx = net.ReadInt(16)
    OpenSewageMenu(npcIdx)
end)

net.Receive("Sewage_SyncJob", function()
    local hasJob = net.ReadBool()

    if hasJob then
        local count = net.ReadInt(8)
        SEWAGE_JOB_MANHOLES = {}
        for i = 1, count do
            SEWAGE_JOB_MANHOLES[i] = net.ReadString()
        end
        SEWAGE_JOB_COLLECTED = net.ReadInt(8)

        local collectedCount = net.ReadInt(16)
        SEWAGE_JOB_COLLECTED_INDICES = {}
        for i = 1, collectedCount do
            SEWAGE_JOB_COLLECTED_INDICES[net.ReadInt(16)] = true
        end

        SEWAGE_JOB_DRAINED   = net.ReadBool()
        local paid           = net.ReadBool()
        SEWAGE_JOB_ACTIVE    = not paid
    else
        SEWAGE_JOB_ACTIVE    = false
        SEWAGE_JOB_MANHOLES  = {}
        SEWAGE_JOB_COLLECTED = 0
        SEWAGE_JOB_COLLECTED_INDICES = {}
        SEWAGE_JOB_DRAINED   = false
    end
end)

net.Receive("Sewage_ClearJob", function()
    SEWAGE_JOB_ACTIVE    = false
    SEWAGE_JOB_MANHOLES  = {}
    SEWAGE_JOB_COLLECTED = 0
    SEWAGE_JOB_DRAINED   = false
    if IsValid(SEWAGE_MENU_FRAME) then SEWAGE_MENU_FRAME:Remove() end
end)

function Sewage_IsJobActive()    return SEWAGE_JOB_ACTIVE end
function Sewage_GetJobManholes() return SEWAGE_JOB_MANHOLES end
function Sewage_GetJobCollected() return SEWAGE_JOB_COLLECTED end
function Sewage_IsJobDrained()   return SEWAGE_JOB_DRAINED end
