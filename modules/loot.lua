pfUI:RegisterModule("loot", function ()
  pfUI.loot = CreateFrame("Frame", "pfLootFrame", UIParent)
  pfUI.loot:Hide()
  pfUI.loot:RegisterEvent("LOOT_OPENED")
  pfUI.loot:RegisterEvent("LOOT_CLOSED")
  pfUI.loot:RegisterEvent("LOOT_SLOT_CLEARED")
  pfUI.loot:RegisterEvent("OPEN_MASTER_LOOT_LIST")
  pfUI.loot:RegisterEvent("UPDATE_MASTER_LOOT_LIST")

  pfUI.loot:SetWidth(160+pfUI_config.bars.border*2)
  pfUI.loot.slots = {}
  function pfUI.loot:CreateSlot(id)
    local frame = CreateFrame("LootButton", 'pfLootButton'..id, pfUI.loot)
    frame:SetPoint("LEFT", pfUI_config.bars.border*2, 0)
    frame:SetPoint("RIGHT", -pfUI_config.bars.border*2, 0)
    frame:SetHeight(22)
    frame:SetID(id)
    frame:SetSlot(id)
    frame:SetPoint("TOP", pfUI.loot, 4, (-pfUI_config.bars.border*2+22)-(id*22))

    frame:SetScript("OnClick", function()
      if ( IsControlKeyDown() ) then
        DressUpItemLink(GetLootSlotLink(this:GetID()));
      elseif ( IsShiftKeyDown() ) then
        if ( ChatFrameEditBox:IsVisible() ) then
          ChatFrameEditBox:Insert(GetLootSlotLink(this:GetID()));
        end
      end

      StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")

      pfUI.loot.selectedLootButton = this:GetName()
      pfUI.loot.selectedSlot = this:GetID()
      pfUI.loot.selectedQuality = this.quality
      pfUI.loot.selectedItemName = this.name:GetText()
    end)

    frame:SetScript("OnEnter", function()
      if ( LootSlotIsItem(this:GetID()) ) then
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetLootItem(this:GetID())
        CursorUpdate()
      end
      this.hover:Show()
    end)

    frame:SetScript("OnLeave", function()
      GameTooltip:Hide()
      ResetCursor()
      this.hover:Hide()
    end)

    frame.ficon = CreateFrame("Frame", "pfLootButtonIcon", frame)
    frame.ficon:SetHeight(22)
    frame.ficon:SetWidth(22)
    frame.ficon:ClearAllPoints()
    frame.ficon:SetPoint("RIGHT", frame)
    frame.ficon:SetBackdrop(pfUI.backdrop_col)

    frame.icon = frame.ficon:CreateTexture(nil, "ARTWORK")
    frame.icon:SetTexCoord(.07, .93, .07, .93)
    frame.icon:SetPoint("TOPLEFT", frame.ficon, "TOPLEFT", 2, -2)
    frame.icon:SetPoint("BOTTOMRIGHT", frame.ficon, "BOTTOMRIGHT", -2, 2)

    frame.count = frame.ficon:CreateFontString(nil, "OVERLAY")
    frame.count:ClearAllPoints()
    frame.count:SetJustifyH"RIGHT"
    frame.count:SetPoint("BOTTOMRIGHT", frame.ficon, 2, 2)
    frame.count:SetFont("Interface\\AddOns\\pfUI\\fonts\\arial.ttf", pfUI_config.global.font_size, "OUTLINE")
    frame.count:SetText(1)

    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetJustifyH"LEFT"
    frame.name:ClearAllPoints()
    frame.name:SetPoint("LEFT", frame)
    frame.name:SetPoint("RIGHT", icon, "LEFT")
    frame.name:SetNonSpaceWrap(true)
    frame.name:SetFont("Interface\\AddOns\\pfUI\\fonts\\arial.ttf", pfUI_config.global.font_size, "OUTLINE")

    frame.rarity = frame:CreateTexture(nil, "ARTWORK")
    frame.rarity:SetTexture"Interface\\AddOns\\pfUI\\img\\bar"
    frame.rarity:SetPoint("LEFT", icon, "RIGHT", 0, 0)
    frame.rarity:SetPoint("RIGHT", frame)
    frame.rarity:SetAlpha(.15)
    frame.rarity:SetAllPoints(frame)

    frame.hover = frame:CreateTexture(nil, "ARTWORK")
    frame.hover:SetTexture"Interface\\AddOns\\pfUI\\img\\bar"
    frame.hover:SetPoint("LEFT", icon, "RIGHT", 0, 0)
    frame.hover:SetPoint("RIGHT", frame)
    frame.hover:SetAlpha(.15)
    frame.hover:SetAllPoints(frame)
    frame.hover:Hide()

    pfUI.loot.slots[id] = frame
    return frame
  end

  pfUI.loot:SetScript("OnEvent", function()
    local maxrarity, maxwidth = 0, 0
    if event == "OPEN_MASTER_LOOT_LIST" then
      ToggleDropDownMenu(1, nil, GroupLootDropDown, pfUI.loot.slots[pfUI.loot.selectedSlot], 0, 0)
    end

    if event == "UPDATE_MASTER_LOOT_LIST" then
      UIDropDownMenu_Refresh(GroupLootDropDown)
    end

    if event == "LOOT_OPENED" then
      ShowUIPanel(this)

      if(not this:IsShown()) then
        CloseLoot(not autoLoot)
      end

      local x, y = GetCursorPosition()
      x = x / this:GetEffectiveScale()
      y = y / this:GetEffectiveScale()

      this:ClearAllPoints()
      this:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", x-40, y+20)

      local items = GetNumLootItems()
      if(items > 0) then
        for i=1, items do
          local slot = pfUI.loot.slots[i] or pfUI.loot:CreateSlot(i)
          local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
          local color = ITEM_QUALITY_COLORS[quality]

          if(LootSlotIsCoin(i)) then
            item = string.gsub(item,"\n", ", ")
          end

          if(quantity > 1) then
            slot.count:SetText(quantity)
            slot.count:Show()
          else
            slot.count:Hide()
          end

          if(quality > 1) then
            slot.rarity:SetVertexColor(color.r, color.g, color.b)
            slot.ficon:SetBackdropBorderColor(color.r, color.g, color.b)
            slot.rarity:Show()
          else
            slot.ficon:SetBackdropBorderColor(.5,.5,.5)
            slot.rarity:Hide()
          end

          slot.quality = quality
          slot.name:SetText(item)
          slot.name:SetTextColor(color.r, color.g, color.b)
          slot.icon:SetTexture(texture)

          maxrarity = math.max(maxrarity, quality)
          maxwidth = math.max(maxwidth, slot.name:GetStringWidth())

          slot:Enable()
          slot:Show()
        end
        local color = ITEM_QUALITY_COLORS[maxrarity]
        if maxrarity <= 1 then
          this:SetBackdrop(pfUI.backdrop)
          this:SetBackdropBorderColor(1, 1, 1)
        else
          this:SetBackdrop(pfUI.backdrop_col)
          this:SetBackdropBorderColor(color.r, color.g, color.b, 1)
        end
        this:SetHeight(math.max((items*22)+4*pfUI_config.bars.border), 20)
        this:SetWidth(maxwidth + 22 + 8*pfUI_config.bars.border )
      end
    end

    if event == "LOOT_SLOT_CLEARED" then
      if(not this:IsShown()) then return end
      pfUI.loot.slots[arg1]:Hide()
    end

    if event == "LOOT_CLOSED" then
      StaticPopup_Hide("LOOT_BIND")
      HideUIPanel(this);
      for _, v in pairs(this.slots) do
        v:Hide()
      end
    end
  end)

  LootFrame:UnregisterAllEvents()
  table.insert(UISpecialFrames, "pfLootFrame")

  function GroupLootDropDown_GiveLoot()
    if ( pfUI.loot.selectedQuality >= MASTER_LOOT_THREHOLD ) then
      local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION", ITEM_QUALITY_COLORS[LootFrame.selectedQuality].hex..pfUI.loot.selectedItemName..FONT_COLOR_CODE_CLOSE, this:GetText());
      if ( dialog ) then
        dialog.data = this.value;
      end
    else
      GiveMasterLoot(pfUI.loot.selectedSlot, this.value);
    end
    CloseDropDownMenus();
  end

  StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function(data)
    GiveMasterLoot(pfUI.loot.selectedSlot, data)
  end
end)
