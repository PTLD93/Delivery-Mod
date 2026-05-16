local function FormatTime(secs)
    secs = math.max(0, math.floor(secs))
    return string.format("%02d:%02d", math.floor(secs / 60), secs % 60)
end

hook.Add("HUDPaint", "Express_HUD", function()
    if not EXPRESS_JOB_ACTIVE then return end

    local timeLeft = 0
    local completed = EXPRESS_JOB_COMPLETED or false
    if not EXPRESS_JOB_EXPIRED and not completed then
        local limit = EXPRESS_JOB_TIMELIMIT or EXPRESS_CONFIG.timeLimitLarge
        timeLeft = limit - (CurTime() - (EXPRESS_JOB_START or CurTime()))
        timeLeft = math.max(0, timeLeft)
    end

    local delivered = EXPRESS_JOB_DELIVERED or 0
    local total     = EXPRESS_JOB_TOTAL     or 0
    local expired   = EXPRESS_JOB_EXPIRED   or false

    local sw, sh = ScrW(), ScrH()
    local w, h   = 240, 66
    local x      = sw - w - 20
    local y      = sh - h - 80

    draw.RoundedBox(8, x, y, w, h, Color(20, 20, 22, 210))
    draw.RoundedBox(8, x, y, w, 3,  Color(255, 200, 50, 230))

    draw.SimpleText("EXPRESS DELIVERY", "DermaDefaultBold", x + w / 2, y + 10, Color(255, 210, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local progressText = "Packages: " .. delivered .. " / " .. total
    draw.SimpleText(progressText, "DermaDefault", x + w / 2, y + 30, Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local timeColor, timeText
    if completed then
        timeColor = Color(100, 220, 100)
        timeText  = "COMPLETE!"
    elseif expired then
        timeColor = Color(255, 80, 80)
        timeText  = "TIME UP"
    else
        timeColor = timeLeft < 120 and Color(255, 80, 80) or Color(200, 200, 200)
        timeText  = FormatTime(timeLeft)
    end
    draw.SimpleText(timeText, "DermaDefaultBold", x + w / 2, y + 48, timeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
