local function CountNearbyOwnedCargo(itemKey, npcPos)
    local count      = 0
    local totalValue = 0
    local lp         = LocalPlayer()
    for _, ent in ipairs(ents.FindByClass("sent_cargo")) do
        if ent:GetCargoKey() == itemKey then
            local owner   = ent:GetNWEntity("CargoOwner")
            local isOwned = not IsValid(owner) or owner == lp
            local nearNPC = npcPos and ent:GetPos():Distance(npcPos) < 300
            local nearPly = ent:GetPos():Distance(lp:GetPos()) < 300
            if isOwned and (nearNPC or nearPly) then
                count      = count + 1
                totalValue = totalValue + ent:GetCargoValue()
            end
        end
    end
    return count, totalValue
end

local function NormalizeRequires(req)
    if not req then return nil end
    if req.item then return { req } end
    return req
end

local function FormatRequirementText(req, separator)
    local reqs = NormalizeRequires(req)
    if not reqs or #reqs == 0 then return nil end

    local parts = {}
    for _, entry in ipairs(reqs) do
        local reqCargo = DELIVERY_CARGO and DELIVERY_CARGO[entry.item]
        parts[#parts + 1] = (entry.ratio or 1) .. "x " .. (reqCargo and reqCargo.label or entry.item)
    end

    return table.concat(parts, separator or ", ")
end

local function BuildCargoInfoText(cargoEntry, priceValue, overrideLiters)
    local priceStr = priceValue > 0 and ("$" .. priceValue) or ""
    if Delivery_IsLiquidCargo and Delivery_IsLiquidCargo(cargoEntry) then
        local liters = overrideLiters or Delivery_GetLiquidLiters(cargoEntry)
        local density = Delivery_GetLiquidDensity(cargoEntry)
        local tons = Delivery_FormatTonsFromKg(liters * density)
        local liquidText = Delivery_FormatLiters(liters) .. " L  •  " .. tons .. " tons"
        return priceStr ~= "" and (priceStr .. "  •  " .. liquidText) or liquidText
    end

    if Delivery_IsGrainCargo and Delivery_IsGrainCargo(cargoEntry) then
        local liters = overrideLiters or Delivery_GetGrainLiters(cargoEntry)
        local density = Delivery_GetGrainDensity(cargoEntry)
        local tons = Delivery_FormatTonsFromKg(liters * density)
        local m3 = math.Round(liters / 1000, 2)
        local grainText = Delivery_FormatLiters(liters) .. " L (" .. m3 .. " m³)  •  " .. tons .. " tons"
        return priceStr ~= "" and (priceStr .. "  •  " .. grainText) or grainText
    end

    local massText = ""
    if cargoEntry then
        if cargoEntry.models then
            local minM, maxM = math.huge, -math.huge
            for _, m in ipairs(cargoEntry.models) do
                if m.mass then
                    minM = math.min(minM, m.mass)
                    maxM = math.max(maxM, m.mass)
                end
            end
            if minM ~= math.huge then
                massText = minM == maxM and (minM .. " kg") or (minM .. "–" .. maxM .. " kg")
            end
        elseif cargoEntry.mass then
            massText = cargoEntry.mass .. " kg"
        end
    end

    return priceStr ~= "" and massText ~= "" and (priceStr .. "  •  " .. massText)
        or (priceStr ~= "" and priceStr or massText)
end

local function OpenDeliveryMenu(npcKey, npcPos)
    local npcData = DELIVERY_NPCS[npcKey]
    if not npcData then return end

    local function OpenSupplyChainInfo()
        local infoFrame = vgui.Create("DFrame")
        infoFrame:SetTitle(npcData.label .. " - Supply Chain Info")
        infoFrame:SetSize(460, 520)
        infoFrame:Center()
        infoFrame:MakePopup()

        local scroll = vgui.Create("DScrollPanel", infoFrame)
        scroll:Dock(FILL)
        scroll:DockMargin(8, 8, 8, 8)

        local intro = vgui.Create("DLabel", scroll)
        intro:SetText("This NPC sells cargo that can be unlocked by completing delivery chains. Each route below shows one way to restock the locked cargo.")
        intro:SetFont("DermaDefault")
        intro:SetTextColor(Color(210, 210, 215))
        intro:SetWrap(true)
        intro:SetAutoStretchVertical(true)
        intro:Dock(TOP)
        intro:DockMargin(0, 0, 0, 8)

        local hasAny = false
        for _, soldItem in ipairs(npcData.sells or {}) do
            local soldCargo = DELIVERY_CARGO[soldItem.item]
            local requires = soldCargo and NormalizeRequires(soldCargo.requires)
            if soldCargo and requires and #requires > 0 then
                hasAny = true

                local header = vgui.Create("DPanel", scroll)
                header:Dock(TOP)
                header:DockMargin(0, 4, 0, 2)
                header:SetTall(24)
                header:SetBackgroundColor(Color(40, 80, 120, 255))

                local hLbl = vgui.Create("DLabel", header)
                hLbl:SetText("  " .. soldCargo.label)
                hLbl:SetFont("DermaDefaultBold")
                hLbl:SetTextColor(Color(220, 240, 255))
                hLbl:Dock(FILL)

                for _, req in ipairs(requires) do
                    local sourceCargo = DELIVERY_CARGO[req.item]

                    local row = vgui.Create("DPanel", scroll)
                    row:Dock(TOP)
                    row:DockMargin(8, 0, 0, 2)
                    row:SetTall(22)
                    row:SetBackgroundColor(Color(45, 45, 50, 255))

                    local lbl = vgui.Create("DLabel", row)
                    lbl:SetText("Deliver " .. (req.ratio or 1) .. "x " .. (sourceCargo and sourceCargo.label or req.item) .. " -> unlock 1x " .. soldCargo.label)
                    lbl:SetFont("DermaDefault")
                    lbl:SetTextColor(Color(180, 230, 180))
                    lbl:Dock(FILL)
                    lbl:DockMargin(6, 0, 0, 0)
                end

                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:DockMargin(8, 0, 0, 4)
                row:SetTall(22)
                row:SetBackgroundColor(Color(52, 46, 40, 255))

                local lbl = vgui.Create("DLabel", row)
                lbl:SetText("Unlock by delivering either: " .. FormatRequirementText(requires, " or "))
                lbl:SetFont("DermaDefault")
                lbl:SetTextColor(Color(235, 205, 130))
                lbl:Dock(FILL)
                lbl:DockMargin(6, 0, 0, 0)
            end
        end

        if not hasAny then
            local lbl = vgui.Create("DLabel", scroll)
            lbl:SetText("This NPC does not sell any cargo with supply-chain requirements.")
            lbl:SetFont("DermaDefault")
            lbl:SetTextColor(Color(160, 160, 160))
            lbl:Dock(TOP)
            lbl:DockMargin(8, 8, 0, 0)
            lbl:SetTall(24)
        end
    end

    local hasSupplyChainInfo = false
    for _, soldItem in ipairs(npcData.sells or {}) do
        local soldCargo = DELIVERY_CARGO[soldItem.item]
        local requires = soldCargo and NormalizeRequires(soldCargo.requires)
        if requires and #requires > 0 then
            hasSupplyChainInfo = true
            break
        end
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle(npcData.label)
    frame:SetSize(450, 550)
    frame:Center()
    frame:MakePopup()

    local topBar = vgui.Create("DPanel", frame)
    topBar:Dock(TOP)
    topBar:SetTall(30)
    topBar:DockMargin(8, 6, 8, 0)
    topBar:SetBackgroundColor(Color(0, 0, 0, 0))

    if hasSupplyChainInfo then
        local infoBtn = vgui.Create("DButton", topBar)
        infoBtn:SetText("Supply Chain Info")
        infoBtn:SetSize(140, 24)
        infoBtn:SetPos(0, 3)
        infoBtn:SetTextColor(Color(200, 230, 255))
        infoBtn.Paint = function(s, w, h)
            draw.RoundedBox(5, 0, 0, w, h, s:IsHovered() and Color(40, 80, 130) or Color(30, 60, 100))
        end
        infoBtn.DoClick = OpenSupplyChainInfo
    end

    local tabs = vgui.Create("DPropertySheet", frame)
    tabs:Dock(FILL)
    tabs:DockMargin(8, 4, 8, 8)

    local function MakeItemRow(parent, itemData, btnLabel, btnColor, onClick, locked, lockReason)
        local row = vgui.Create("DPanel", parent)
        row:SetTall(60)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 6)
        row:SetBackgroundColor(locked and Color(38, 35, 35, 255) or Color(50, 50, 55, 255))

        local cargoEntry = DELIVERY_CARGO and DELIVERY_CARGO[itemData.item]
        local isLiquid = Delivery_IsLiquidCargo and Delivery_IsLiquidCargo(cargoEntry)
        local isGrain  = Delivery_IsGrainCargo and Delivery_IsGrainCargo(cargoEntry)
        local model = cargoEntry and (cargoEntry.model or (cargoEntry.models and cargoEntry.models[1] and cargoEntry.models[1].model))
        local textX = (isLiquid or isGrain) and 12 or 62

        local price = nil -- Pre-declare for slider callback usage
        local slider = nil
        if (isGrain or isLiquid) and btnLabel == "Buy" and not locked then
            local cfg = isGrain and DELIVERY_GRAIN_CONFIG or DELIVERY_TANKER_CONFIG
            local baseLitersFunc = isGrain and Delivery_GetGrainLiters or Delivery_GetLiquidLiters

            row:SetTall(100)
            slider = vgui.Create("DNumSlider", row)
            slider:SetPos(textX, 55)
            slider:SetSize(row:GetWide() - textX - 110, 40)
            slider:SetText("Amount (Liters)")
            slider:SetMin(cfg.minCapacityLiters)
            slider:SetMax(cfg.maxCapacityLiters)
            slider:SetDecimals(0)
            slider:SetValue(baseLitersFunc(cargoEntry))
            slider:SetDark(false)

            slider.OnValueChanged = function(s, val)
                local basePrice = itemData.price
                local baseLiters = baseLitersFunc(cargoEntry)
                local newPrice = math.ceil((val / baseLiters) * basePrice)
                
                -- Update the price label if we can find it
                if IsValid(price) then
                    price:SetText(BuildCargoInfoText(cargoEntry, newPrice, val))
                end
            end

            row.OnSizeChanged = function(s, w, h)
                slider:SetWide(w - textX - 110)
            end
        end

        local icon
        if not isLiquid and not isGrain and model then
            icon = vgui.Create("SpawnIcon", row)
            icon:SetSize(44, 44)
            icon:SetPos(8, 8)
            icon:SetModel(model)
            icon:SetMouseInputEnabled(false)
        elseif not isLiquid and not isGrain then
            icon = vgui.Create("DPanel", row)
            icon:SetSize(44, 44)
            icon:SetPos(8, 8)
            icon:SetBackgroundColor(Color(70, 70, 75, 255))
        end

        local name = vgui.Create("DLabel", row)
        name:SetText(itemData.label)
        name:SetFont("DermaDefaultBold")
        name:SetTextColor(locked and Color(120, 100, 100) or Color(255, 255, 255))
        name:SetPos(textX, 10)
        name:SetSize(220, 20)

        local massText = ""
        if cargoEntry then
            if cargoEntry.models then
                local minM, maxM = math.huge, -math.huge
                for _, m in ipairs(cargoEntry.models) do
                    if m.mass then
                        minM = math.min(minM, m.mass)
                        maxM = math.max(maxM, m.mass)
                    end
                end
                if minM ~= math.huge then
                    massText = minM == maxM and (minM .. " kg") or (minM .. "–" .. maxM .. " kg")
                end
            elseif cargoEntry.mass then
                massText = cargoEntry.mass .. " kg"
            end
        end

        local sellPriceStr = itemData.price > 0 and ("$" .. itemData.price) or ""
        local infoStr  = sellPriceStr ~= "" and massText ~= "" and (sellPriceStr .. "  •  " .. massText)
                      or (sellPriceStr ~= "" and sellPriceStr or massText)

        price = vgui.Create("DLabel", row)
        price:SetText(infoStr)
        price:SetFont("DermaDefaultBold")
        price:SetTextColor(locked and Color(80, 100, 80) or Color(100, 220, 100))
        price:SetPos(textX, 32)
        price:SetSize(250, 20)
        if isLiquid or isGrain then
            price:SetText(BuildCargoInfoText(cargoEntry, itemData.price))
        end

        if locked and lockReason then
            local lockLbl = vgui.Create("DLabel", row)
            lockLbl:SetText("[Locked] " .. lockReason)
            lockLbl:SetFont("DermaDefault")
            lockLbl:SetTextColor(Color(200, 150, 50))
            lockLbl:SetPos(textX, 52)
            lockLbl:SetSize(270, 16)
            row:SetTall(76)
        elseif cargoEntry and cargoEntry.requires then
            local stock = Delivery_GetStockCL and Delivery_GetStockCL(itemData.item) or 0
            local stockLbl = vgui.Create("DLabel", row)
            stockLbl:SetText("Stock: " .. stock)
            stockLbl:SetFont("DermaDefault")
            stockLbl:SetTextColor(stock > 0 and Color(100, 200, 255) or Color(180, 80, 80))
            stockLbl:SetPos(textX, 52)
            stockLbl:SetSize(150, 16)
            row:SetTall(76)
        end

        local btn = vgui.Create("DButton", row)
        btn:SetText(btnLabel)
        btn:SetSize(80, 40)
        btn:SetTextColor(locked and Color(100, 100, 100) or Color(255, 255, 255))
        btn:SetEnabled(not locked)
        btn.Paint = function(s, w, h)
            local col
            if locked then
                col = Color(50, 45, 45)
            else
                col = s:IsHovered() and Color(btnColor.r - 20, btnColor.g - 20, btnColor.b - 20) or btnColor
            end
            draw.RoundedBox(6, 0, 0, w, h, col)
        end
        btn.DoClick = function()
            if slider then
                onClick(math.Round(slider:GetValue()))
            else
                onClick()
            end
        end

        row.PerformLayout = function(s)
            btn:SetPos(s:GetWide() - 96, 10)
        end

        return row
    end

    local function CargoAllowedForMe(cargo)
        if not cargo then return true end
        local team = LocalPlayer():Team()
        if cargo.allowedTeams then
            for _, varName in ipairs(cargo.allowedTeams) do
                local tv = _G[varName]
                if tv ~= nil and team == tv then return true end
            end
            return false
        end
        if cargo.allowedTeam then
            local tv = _G[cargo.allowedTeam]
            return tv ~= nil and team == tv
        end
        return true
    end

    -- BUY TAB
    local buyPanel = vgui.Create("DPanel")
    buyPanel:SetBackgroundColor(Color(35, 35, 38, 255))

    local buyScroll = vgui.Create("DScrollPanel", buyPanel)
    buyScroll:Dock(FILL)
    buyScroll:DockMargin(8, 8, 8, 8)

    local visibleSells = {}
    for _, itemData in ipairs(npcData.sells) do
        local cargo = DELIVERY_CARGO and DELIVERY_CARGO[itemData.item]
        if CargoAllowedForMe(cargo) then
            visibleSells[#visibleSells + 1] = itemData
        end
    end

    if #visibleSells == 0 then
        local lbl = vgui.Create("DLabel", buyScroll)
        lbl:SetText("No cargo available for your current job.")
        lbl:SetTextColor(Color(180, 180, 180))
        lbl:SetFont("DermaDefault")
        lbl:Dock(TOP)
        lbl:DockMargin(10, 10, 0, 0)
        lbl:SetTall(25)
    else
        for _, itemData in ipairs(visibleSells) do
            local localItemData = itemData
            local cargoEntry    = DELIVERY_CARGO and DELIVERY_CARGO[itemData.item]

            -- check supply chain lock
            local locked     = false
            local lockReason = nil
            if cargoEntry and cargoEntry.requires then
                local hasStock = Delivery_HasStockCL and Delivery_HasStockCL(itemData.item)
                if not hasStock then
                    locked = true
                    local reqText = FormatRequirementText(cargoEntry.requires, " or ")
                    lockReason = reqText and ("Requires " .. reqText .. " delivered") or "Requires previous deliveries"
                end
            end

            MakeItemRow(buyScroll, itemData, "Buy", Color(50, 130, 200), function(amt)
                if locked then return end
                net.Start("DeliveryNPC_Buy")
                    net.WriteString(npcKey)
                    net.WriteString(localItemData.item)
                    net.WriteVector(npcPos)
                    if amt then
                        net.WriteUInt(amt, 32)
                    end
                net.SendToServer()
            end, locked, lockReason)
        end
    end

    tabs:AddSheet("  Buy", buyPanel, "icon16/cart_add.png")

    -- SELL TAB
    local sellPanel = vgui.Create("DPanel")
    sellPanel:SetBackgroundColor(Color(35, 35, 38, 255))

    local sellScroll = vgui.Create("DScrollPanel", sellPanel)
    sellScroll:Dock(FILL)
    sellScroll:DockMargin(8, 8, 8, 8)

    local visibleBuys = {}
    for _, itemData in ipairs(npcData.buys) do
        visibleBuys[#visibleBuys + 1] = itemData
    end

    if #visibleBuys == 0 then
        local lbl = vgui.Create("DLabel", sellScroll)
        lbl:SetText("This NPC is not buying anything for your job.")
        lbl:SetTextColor(Color(180, 180, 180))
        lbl:SetFont("DermaDefault")
        lbl:Dock(TOP)
        lbl:DockMargin(10, 10, 0, 0)
        lbl:SetTall(25)
    else
        for _, itemData in ipairs(visibleBuys) do
            local displayLabel = itemData.label
            local displayPrice = itemData.price
            local nearbyCount  = 0
            local currentTotalLiters = nil
            local cargoEntry = DELIVERY_CARGO and DELIVERY_CARGO[itemData.item]
            local isLiquid = Delivery_IsLiquidCargo and Delivery_IsLiquidCargo(cargoEntry)
            local isGrain  = Delivery_IsGrainCargo and Delivery_IsGrainCargo(cargoEntry)

            if isLiquid then
                local tanker = Delivery_GetNearbyOwnedTankerCL and Delivery_GetNearbyOwnedTankerCL(npcPos, itemData.item)
                if IsValid(tanker) then
                    nearbyCount = 1
                    currentTotalLiters = tanker:GetNWInt("DeliveryTankerLiquidLiters", 0)
                    displayLabel = itemData.label .. "  [" .. Delivery_FormatLiters(currentTotalLiters) .. " L loaded]"
                else
                    displayLabel = itemData.label .. "  [no filled tanker nearby]"
                end
            elseif isGrain then
                local grainBeds = Delivery_GetNearbyOwnedGrainBedsCL and Delivery_GetNearbyOwnedGrainBedsCL(npcPos, itemData.item) or {}
                if #grainBeds > 0 then
                    nearbyCount = #grainBeds
                    currentTotalLiters = 0
                    for _, bed in ipairs(grainBeds) do
                        currentTotalLiters = currentTotalLiters + bed:GetNWInt("DeliveryGrainBedLiters", 0)
                    end
                    displayLabel = itemData.label .. "  [" .. Delivery_FormatLiters(currentTotalLiters) .. " L loaded in " .. nearbyCount .. " bed(s)]"
                    
                    local basePrice = itemData.price
                    local baseLiters = Delivery_GetGrainLiters(cargoEntry)
                    if baseLiters > 0 then
                        displayPrice = math.ceil((currentTotalLiters / baseLiters) * basePrice)
                    end
                else
                    displayLabel = itemData.label .. "  [no filled grain bed(s) nearby]"
                end
            elseif itemData.item == "sent_fish" then
                for _, ent in ipairs(ents.GetAll()) do
                    if ent:GetClass() == "sent_fish" then
                        local owner = ent:GetNWEntity("FishOwner")
                        if owner == LocalPlayer() then
                            displayLabel = ent:GetFishLabel()
                            displayPrice = ent:GetFishValue()
                            nearbyCount  = 1
                            break
                        end
                    end
                end
            else
                local totalValue
                nearbyCount, totalValue = CountNearbyOwnedCargo(itemData.item, npcPos)
                if totalValue > 0 then
                    displayPrice = totalValue
                else
                    displayPrice = itemData.price * math.max(nearbyCount, 1)
                end
            end

            local canSell      = nearbyCount > 0
            local localItemData = itemData

            local row = vgui.Create("DPanel", sellScroll)
            row:SetTall(60)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 6)
            row:SetBackgroundColor(canSell and Color(50, 50, 55, 255) or Color(35, 35, 38, 255))

            local model = cargoEntry and (cargoEntry.model or (cargoEntry.models and cargoEntry.models[1] and cargoEntry.models[1].model))
            local textX = (isLiquid or isGrain) and 12 or 62

            local icon
            if not isLiquid and not isGrain and model then
                icon = vgui.Create("SpawnIcon", row)
                icon:SetSize(44, 44)
                icon:SetPos(8, 8)
                icon:SetModel(model)
                icon:SetMouseInputEnabled(false)
            elseif not isLiquid and not isGrain then
                icon = vgui.Create("DPanel", row)
                icon:SetSize(44, 44)
                icon:SetPos(8, 8)
                icon:SetBackgroundColor(Color(70, 70, 75, 255))
            end

            local name = vgui.Create("DLabel", row)
            local countStr = not isLiquid and not isGrain and (nearbyCount > 0 and ("  [" .. nearbyCount .. "x nearby]") or "  [none nearby]") or ""
            name:SetText(displayLabel .. countStr)
            name:SetFont("DermaDefaultBold")
            name:SetTextColor(canSell and Color(255, 255, 255) or Color(120, 120, 120))
            name:SetPos(textX, 10)
            name:SetSize(220, 20)

            local sellMassText = ""
            if cargoEntry then
                if cargoEntry.models then
                    local minM, maxM = math.huge, -math.huge
                    for _, m in ipairs(cargoEntry.models) do
                        if m.mass then
                            minM = math.min(minM, m.mass)
                            maxM = math.max(maxM, m.mass)
                        end
                    end
                    if minM ~= math.huge then
                        sellMassText = minM == maxM and (minM .. " kg") or (minM .. "–" .. maxM .. " kg")
                    end
                elseif cargoEntry.mass then
                    sellMassText = cargoEntry.mass .. " kg"
                end
            end

            local sellPriceStr = displayPrice > 0 and ("$" .. displayPrice) or ""
            local sellInfoStr  = sellPriceStr ~= "" and sellMassText ~= "" and (sellPriceStr .. "  •  " .. sellMassText)
                              or (sellPriceStr ~= "" and sellPriceStr or sellMassText)

            local price = vgui.Create("DLabel", row)
            price:SetText(sellInfoStr)
            price:SetFont("DermaDefaultBold")
            price:SetTextColor(canSell and Color(100, 220, 100) or Color(80, 110, 80))
            price:SetPos(textX, 32)
            price:SetSize(250, 20)
            if isLiquid or isGrain then
                price:SetText(BuildCargoInfoText(cargoEntry, displayPrice, currentTotalLiters))
            end

            local btn = vgui.Create("DButton", row)
            btn:SetText("Sell")
            btn:SetSize(80, 40)
            btn:SetTextColor(canSell and Color(255, 255, 255) or Color(100, 100, 100))
            btn:SetEnabled(canSell)
            btn.Paint = function(s, w, h)
                local col = canSell
                    and (s:IsHovered() and Color(140, 50, 50) or Color(180, 80, 80))
                    or Color(60, 60, 65)
                draw.RoundedBox(6, 0, 0, w, h, col)
            end
            btn.DoClick = function()
                net.Start("DeliveryNPC_Sell")
                    net.WriteString(npcKey)
                    net.WriteString(localItemData.item)
                net.SendToServer()
            end

            row.PerformLayout = function(s)
                btn:SetPos(s:GetWide() - 96, 10)
            end
        end
    end

    tabs:AddSheet("  Sell", sellPanel, "icon16/cart_delete.png")
end

net.Receive("DeliveryNPC_OpenMenu", function()
    local npcKey  = net.ReadString()
    local npcPos  = net.ReadVector()
    OpenDeliveryMenu(npcKey, npcPos)
end)

net.Receive("Delivery_RefreshConfig", function()
    include("delivery/sh_config.lua")
    include("delivery/sh_tanker_config.lua")
    include("delivery/sh_tanker_job_config.lua")
    include("delivery/sh_grain_config.lua")
    include("delivery/sh_grain_job_config.lua")
    print("[Delivery] Client-side configuration refreshed.")
end)
