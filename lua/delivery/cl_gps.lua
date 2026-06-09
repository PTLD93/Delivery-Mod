local WAYPOINT = nil
local TRACKING_START = 0
local TRACKING_DURATION = 10
local TRACKING_TARGET = nil

net.Receive("GPS_SetWaypoint", function()
    local pos = net.ReadVector()
    local name = net.ReadString()
    
    TRACKING_START = CurTime()
    TRACKING_TARGET = { pos = pos, name = name }
    
    LocalPlayer():ChatPrint("[GPS] Tracking " .. name .. "... Please wait 10 seconds.")
end)

hook.Add("HUDPaint", "Delivery_GPS_HUD", function()
    local ply = LocalPlayer()
    
    -- Tracking progress
    if TRACKING_TARGET and CurTime() < TRACKING_START + TRACKING_DURATION then
        local elapsed = CurTime() - TRACKING_START
        local progress = elapsed / TRACKING_DURATION
        
        local w, h = 300, 30
        local x, y = (ScrW() - w) / 2, ScrH() - 150
        
        draw.RoundedBox(4, x, y, w, h, Color(0, 0, 0, 200))
        draw.RoundedBox(4, x + 2, y + 2, (w - 4) * progress, h - 4, Color(0, 255, 0, 200))
        
        draw.SimpleText("GPS Tracking: " .. TRACKING_TARGET.name, "DermaDefaultBold", x + w/2, y + h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        return
    end
    
    -- If tracking finished
    if TRACKING_TARGET and CurTime() >= TRACKING_START + TRACKING_DURATION then
        WAYPOINT = TRACKING_TARGET
        TRACKING_TARGET = nil
        ply:ChatPrint("[GPS] Location found!")
    end
    
    -- Draw waypoint
    if WAYPOINT then
        local pos = WAYPOINT.pos + Vector(0, 0, 80)
        local screen = pos:ToScreen()
        
        if screen.visible then
            local dist = math.floor(ply:GetPos():Distance(WAYPOINT.pos) / 16) -- inches to feet approx
            local text = WAYPOINT.name .. " (" .. dist .. "m)"
            
            draw.SimpleText("▼", "DermaDefaultBold", screen.x, screen.y - 20, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(text, "DermaDefaultBold", screen.x, screen.y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Remove if close
        if ply:GetPos():Distance(WAYPOINT.pos) < 200 then
            WAYPOINT = nil
            ply:ChatPrint("[GPS] Destination reached.")
        end
    end
end)
