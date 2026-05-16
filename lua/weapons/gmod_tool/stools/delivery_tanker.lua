TOOL.Category = "Blue Light RP"
TOOL.Name = "#Delivery Tanker"
TOOL.Command = nil
TOOL.ConfigName = ""

local minCapacity = DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.minCapacityLiters or 5000
local maxCapacity = DELIVERY_TANKER_CONFIG and DELIVERY_TANKER_CONFIG.maxCapacityLiters or 30000

TOOL.ClientConVar["capacity"] = tostring(minCapacity)

if CLIENT then
    language.Add("tool.delivery_tanker.name", "Delivery Tanker Tool")
    language.Add("tool.delivery_tanker.desc", "Mark a Prop as a tanker for liquid based delivery jobs.")
    language.Add("tool.delivery_tanker.0", "Left click to mark a tanker. Right click to unmark it.")
end

local function GetChosenCapacity(self)
    return Delivery_ClampTankerCapacity(self:GetClientNumber("capacity"))
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ent = trace.Entity
    local ok, msg = Delivery_MarkTankerProp(self:GetOwner(), ent, GetChosenCapacity(self))
    self:GetOwner():ChatPrint("[Delivery] " .. msg)
    return ok
end

function TOOL:RightClick(trace)
    if CLIENT then return true end

    local ent = trace.Entity
    local ok, msg = Delivery_UnmarkTankerProp(self:GetOwner(), ent)
    self:GetOwner():ChatPrint("[Delivery] " .. msg)
    return ok
end

function TOOL.BuildCPanel(panel)
    if not panel then return end
    panel:Help("Mark one Prop or Primitive Shape as your tanker. Right click to remove the tanker mark.")
    local slider = panel:NumSlider("Tanker Capacity (L)", "delivery_tanker_capacity", minCapacity, maxCapacity, 0)
    if slider and slider.SetDecimals then
        slider:SetDecimals(0)
    end
end
