TOOL.Category = "Blue Light RP"
TOOL.Name = "#Grain Bed Tool"
TOOL.Command = nil
TOOL.ConfigName = ""

local minCapacity = DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.minCapacityLiters or 5000
local maxCapacity = DELIVERY_GRAIN_CONFIG and DELIVERY_GRAIN_CONFIG.maxCapacityLiters or 100000

TOOL.ClientConVar["capacity"] = tostring(minCapacity)
TOOL.ClientConVar["nerfed"] = "0"

if CLIENT then
    language.Add("tool.delivery_grain.name", "Grain Bed Tool")
    language.Add("tool.delivery_grain.desc", "Mark a Prop as a grain bed for grain based delivery jobs.")
    language.Add("tool.delivery_grain.0", "Left click to mark a grain bed. Right click to unmark it.")
end

local function GetChosenCapacity(self)
    return Delivery_ClampGrainBedCapacity(self:GetClientNumber("capacity"))
end

local function GetChosenNerfed(self)
    return self:GetClientNumber("nerfed", 0) == 1
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ent = trace.Entity
    local ok, msg = Delivery_MarkGrainBedProp(self:GetOwner(), ent, GetChosenCapacity(self), GetChosenNerfed(self))
    self:GetOwner():ChatPrint("[Delivery] " .. msg)
    return ok
end

function TOOL:RightClick(trace)
    if CLIENT then return true end

    local ent = trace.Entity
    local ok, msg = Delivery_UnmarkGrainBedProp(self:GetOwner(), ent)
    self:GetOwner():ChatPrint("[Delivery] " .. msg)
    return ok
end

function TOOL.BuildCPanel(panel)
    if not panel then return end
    panel:Help("Mark one Prop or Primitive Shape as your grain bed. Right click to remove the grain bed mark.")
    local slider = panel:NumSlider("Grain Bed Capacity (L)", "delivery_grain_capacity", minCapacity, maxCapacity, 0)
    if slider and slider.SetDecimals then
        slider:SetDecimals(0)
    end
    panel:CheckBox("Nerfed (weight won't change when filled, sell price -50%)", "delivery_grain_nerfed")
end
