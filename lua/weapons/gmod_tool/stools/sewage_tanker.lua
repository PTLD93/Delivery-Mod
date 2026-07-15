TOOL.Category = "Blue Light RP"
TOOL.Name = "#Sewage Tanker"
TOOL.Command = nil
TOOL.ConfigName = ""

local minCapacity = SEWAGE_CONFIG and SEWAGE_CONFIG.tankerCapacity or 10000
local maxCapacity = SEWAGE_CONFIG and (SEWAGE_CONFIG.tankerCapacity * 3) or 30000

TOOL.ClientConVar["capacity"] = tostring(minCapacity)
TOOL.ClientConVar["nerfed"] = "0"

if CLIENT then
    language.Add("tool.sewage_tanker.name", "Sewage Tanker Tool")
    language.Add("tool.sewage_tanker.desc", "Mark a Prop as a sewage tanker for sewage collection jobs.")
    language.Add("tool.sewage_tanker.0", "Left click to mark a sewage tanker. Right click to unmark it.")
end

local function GetChosenCapacity(self)
    return math.Clamp(tonumber(self:GetClientNumber("capacity")) or minCapacity, minCapacity, maxCapacity)
end

local function GetChosenNerfed(self)
    return self:GetClientNumber("nerfed", 0) == 1
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ent = trace.Entity
    local ok, msg = Delivery_MarkSewageTanker(self:GetOwner(), ent, GetChosenCapacity(self), GetChosenNerfed(self))
    self:GetOwner():ChatPrint("[Sewage] " .. msg)
    return ok
end

function TOOL:RightClick(trace)
    if CLIENT then return true end

    local ent = trace.Entity
    local ok, msg = Delivery_UnmarkSewageTanker(self:GetOwner(), ent)
    self:GetOwner():ChatPrint("[Sewage] " .. msg)
    return ok
end

function TOOL.BuildCPanel(panel)
    if not panel then return end
    panel:Help("Mark one Prop or Primitive Shape as your sewage tanker. Right click to remove the sewage tanker mark.")
    local slider = panel:NumSlider("Tanker Capacity (L)", "sewage_tanker_capacity", minCapacity, maxCapacity, 0)
    if slider and slider.SetDecimals then
        slider:SetDecimals(0)
    end
    panel:CheckBox("Nerfed (weight won't change when filled, payout -50%)", "sewage_tanker_nerfed")
end
