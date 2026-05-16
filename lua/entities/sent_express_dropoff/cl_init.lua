include("shared.lua")

local LABEL_DIST  = 800
local LABEL_SCALE = 0.13

local SPRITE_MAT   = Material("sprites/light_glow02_add")
local SPRITE_COLOR = Color(50, 255, 80, 255)
local SPRITE_SIZE  = 80
local SPRITE_DIST  = 3000

local function HasMatchingPackage(addr)
    local lp = LocalPlayer()
    for _, pkg in ipairs(ents.FindByClass("sent_express_package")) do
        if not IsValid(pkg) then continue end
        local owner = pkg:GetNWEntity("ExpressOwner")
        if not IsValid(owner) or owner ~= lp then continue end
        if pkg:GetNWString("ExpressAddress", "") == addr then return true end
    end
    return false
end

hook.Add("PostDrawTranslucentRenderables", "ExpressDropoff_Sprites", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if not EXPRESS_JOB_ACTIVE then return end

    local eyePos = lp:EyePos()
    local pulse  = 0.85 + math.sin(CurTime() * 3) * 0.15

    for _, ent in ipairs(ents.FindByClass("sent_express_dropoff")) do
        if not IsValid(ent) then continue end

        local addr = ent:GetNWString("DropoffAddress", "")
        if addr == "" then continue end
        if not HasMatchingPackage(addr) then continue end

        local spritePos = ent:GetPos() + Vector(0, 0, 40)
        if eyePos:DistToSqr(spritePos) > SPRITE_DIST * SPRITE_DIST then continue end

        local tr = util.TraceLine({
            start  = eyePos,
            endpos = spritePos,
            filter = lp,
        })
        if tr.Hit and tr.HitPos:DistToSqr(spritePos) > 64 * 64 then continue end

        local size = SPRITE_SIZE * pulse
        render.SetMaterial(SPRITE_MAT)
        render.DrawSprite(spritePos, size, size, SPRITE_COLOR)
    end
end)

function ENT:Draw()
    self:DrawModel()

    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if lp:GetPos():DistToSqr(self:GetPos()) > LABEL_DIST * LABEL_DIST then return end

    if lp:GetEyeTrace().Entity ~= self then return end

    local addr    = self:GetNWString("DropoffAddress", "")
    if addr == "" then return end

    local hasMatch = HasMatchingPackage(addr)
    local col      = hasMatch and Color(80, 230, 100) or Color(200, 200, 200)
    local bgCol    = hasMatch and Color(0, 60, 0, 200) or Color(0, 0, 0, 180)

    local pos = self:GetPos() + Vector(0, 0, 30)
    local ang = lp:EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, ang, LABEL_SCALE)
        draw.RoundedBox(6, -130, -28, 260, 56, bgCol)
        draw.SimpleText("DROP OFF:", "DermaDefault", 0, -14, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleTextOutlined(addr, "DermaDefaultBold", 0, 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,220))
    cam.End3D2D()
end
