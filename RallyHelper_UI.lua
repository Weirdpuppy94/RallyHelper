local ui
local sizeUI

local ONY_ICON = "Interface\\Icons\\INV_Misc_Head_Dragon_Red"
local NEF_ICON = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue"
local WB_ICON  = "Interface\\Icons\\Spell_Nature_BloodLust"

local DEFAULT_W = 420
local DEFAULT_H = 190
local DEFAULT_SCALE = 1.0

local floor = math.floor

local function IsLocked()
  return RallyHelperDB and RallyHelperDB.locked
end

local function FormatTime(sec)
  if not sec or sec <= 0 then return "ready", 0 end
  local h = floor(sec / 3600)
  local m = floor((sec - h * 3600) / 60)
  if h > 0 then return h .. "h " .. m .. "m", sec end
  return m .. "m", sec
end

local function Colorize(text, sec)
  if not sec or sec <= 0 then
    return "|cff33ff33" .. text .. "|r"
  elseif sec < 1800 then
    return "|cffffff33" .. text .. "|r"
  else
    return "|cffff3333" .. text .. "|r"
  end
end

local function FormatAgo(ts)
  if not ts then return "unknown" end
  local d = time() - ts
  if d < 60 then return d .. "s ago" end
  if d < 3600 then return floor(d / 60) .. "m ago" end
  local h = floor(d / 3600)
  local m = floor((d - h * 3600) / 60)
  return h .. "h " .. m .. "m ago"
end
local function EnsureDB()
  RallyHelperDB = RallyHelperDB or {}
  RallyHelperDB.ui = RallyHelperDB.ui or {}

  local S = RallyHelperDB.ui

  if S.w == nil then S.w = DEFAULT_W end
  if S.h == nil then S.h = DEFAULT_H end
  if S.scale == nil then S.scale = DEFAULT_SCALE end

  return S
end

local function ApplyPfUISkin(frame)
  if not frame or not pfUI or not pfUI.api then return end

  if pfUI.api.SkinFrame then
    pcall(pfUI.api.SkinFrame, frame)
  end

  if frame.bgFrame and pfUI.api.SkinBackdrop then
    pcall(pfUI.api.SkinBackdrop, frame.bgFrame)
  end
end

local function FadeInBg(bg, timeToFade, startAlpha, endAlpha)
  if not bg then return end
  if type(UIFrameFadeIn) == "function" then
    UIFrameFadeIn(bg, timeToFade or 0.15, startAlpha or bg:GetAlpha() or 0.18, endAlpha or 1.0)
  else
    bg:SetAlpha(endAlpha or 1.0)
  end
end

local function FadeOutBg(bg, timeToFade, startAlpha, endAlpha)
  if not bg then return end
  if type(UIFrameFadeOut) == "function" then
    UIFrameFadeOut(bg, timeToFade or 0.25, startAlpha or bg:GetAlpha() or 1.0, endAlpha or 0.18)
  else
    bg:SetAlpha(endAlpha or 0.18)
  end
end

local function ApplyLayout()
  if not ui or not ui.initialized then return end

  local W = ui:GetWidth()
  local PAD = 16
  local GAP = 20

  local CONTENT_W = W - PAD * 2
  local COL_W = (CONTENT_W - GAP) / 2

  local COL1_X = PAD
  local COL2_X = PAD + COL_W + GAP

  ui.onyIcon:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X + COL_W/2 - 40, -30)
  ui.onyTitle:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X, -30)
  ui.onyTitle:SetWidth(COL_W)

  ui.nefIcon:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X + COL_W/2 - 40, -30)
  ui.nefTitle:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X, -30)
  ui.nefTitle:SetWidth(COL_W)

  ui.onySW:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X, -54); ui.onySW:SetWidth(COL_W)
  ui.onyOG:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X, -70); ui.onyOG:SetWidth(COL_W)

  ui.nefSW:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X, -54); ui.nefSW:SetWidth(COL_W)
  ui.nefOG:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X, -70); ui.nefOG:SetWidth(COL_W)

  ui.zg:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD, -98);   ui.zg:SetWidth(CONTENT_W)
  ui.dmf:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD, -114); ui.dmf:SetWidth(CONTENT_W)

  ui.wbIcon:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD + CONTENT_W/2 - 120, -138)
  ui.wb:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD, -138); ui.wb:SetWidth(CONTENT_W)
end

local function UpdateTexts()
  if not ui or not ui.initialized then return end

  local DB = RallyHelperDB
  local t = time()

  if not DB then
    ui.onySW:SetText("Stormwind: unknown")
    ui.onyOG:SetText("Orgrimmar: unknown")
    ui.nefSW:SetText("Stormwind: unknown")
    ui.nefOG:SetText("Orgrimmar: unknown")
    ui.zg:SetText("ZG last drop: unknown")
    ui.dmf:SetText("DMF last seen: unknown")
    ui.wb:SetText("Warchief's Blessing: unknown")
    return
  end

  ui.onySW:SetText("Stormwind: " .. (DB.lastOnyA and FormatTime(DB.lastOnyA + 7200 - t) or "ready"))
  ui.onyOG:SetText("Orgrimmar: " .. (DB.lastOnyH and FormatTime(DB.lastOnyH + 7200 - t) or "ready"))
  ui.nefSW:SetText("Stormwind: " .. (DB.lastNefA and FormatTime(DB.lastNefA + 7200 - t) or "ready"))
  ui.nefOG:SetText("Orgrimmar: " .. (DB.lastNefH and FormatTime(DB.lastNefH + 7200 - t) or "ready"))

  ui.zg:SetText("ZG last drop: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))

  local dmfZone = (DB.lastDMFZone and DB.lastDMFZone ~= "") and DB.lastDMFZone or "unknown"
  local dmfText = DB.lastDMFTime and (FormatAgo(DB.lastDMFTime) .. " in " .. dmfZone) or ("unknown in " .. dmfZone)
  ui.dmf:SetText("DMF last seen: " .. dmfText)

  ui.wb:SetText("Warchief's Blessing: " .. (DB.lastWB and FormatTime(DB.lastWB + 10800 - t) or "ready"))
end

local function CreateUI()
  local S = EnsureDB()

  ui = _G["RallyHelperFrame"]
  if not ui then
    ui = CreateFrame("Frame", "RallyHelperFrame", UIParent)
  end

  ui:SetToplevel(true)
  ui:SetClampedToScreen(true)
  ui:SetFrameStrata("DIALOG")
  ui:SetFrameLevel(500)

  ui:SetWidth(S.w or DEFAULT_W)
  ui:SetHeight(S.h or DEFAULT_H)
  ui:ClearAllPoints()

  if S.x and S.y then
    ui:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", S.x, S.y)
  else
    ui:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
  end

  if not ui.bgFrame then
    ui.bgFrame = CreateFrame("Frame", nil, ui)
    ui.bgFrame:SetAllPoints(ui)
    local bgLevel = (ui:GetFrameLevel() or 0) - 2
    if bgLevel < 0 then bgLevel = 0 end
    ui.bgFrame:SetFrameLevel(bgLevel)

    ui.bgFrame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = nil,
      tile = true, tileSize = 16, edgeSize = 0,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ui.bgFrame:SetBackdropColor(0, 0, 0, 0.75)
    ui.bgFrame:SetBackdropBorderColor(0, 0, 0, 0)
    ui.bgFrame:EnableMouse(false)
    ui.bgFrame:SetAlpha(0.18)
  else
    ui.bgFrame:ClearAllPoints()
    ui.bgFrame:SetAllPoints(ui)
  end

  ApplyPfUISkin(ui)

  ui:SetScale(S.scale or DEFAULT_SCALE)

  if not ui.initialized then
    ui.initialized = true

    ui.titleFrame = ui.titleFrame or CreateFrame("Frame", nil, ui)
    ui.titleFrame:SetPoint("TOPLEFT", ui, "TOPLEFT", 0, 0)
    ui.titleFrame:SetPoint("TOPRIGHT", ui, "TOPRIGHT", 0, 0)
    ui.titleFrame:SetHeight(24)
    ui.titleFrame:SetFrameLevel((ui.bgFrame and ui.bgFrame:GetFrameLevel() or 0) + 2)

    ui.title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.title:SetPoint("TOP", 0, -6)
    ui.title:SetText("RallyHelper")

    local function CenterText(r, g, b)
      local f = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      f:SetJustifyH("CENTER")
      if r then f:SetTextColor(r, g, b) end
      return f
    end

    ui.onyIcon = ui:CreateTexture(nil, "ARTWORK")
    ui.onyIcon:SetTexture(ONY_ICON)
    ui.onyIcon:SetWidth(16); ui.onyIcon:SetHeight(16)

    ui.nefIcon = ui:CreateTexture(nil, "ARTWORK")
    ui.nefIcon:SetTexture(NEF_ICON)
    ui.nefIcon:SetWidth(16); ui.nefIcon:SetHeight(16)

    ui.wbIcon = ui:CreateTexture(nil, "ARTWORK")
    ui.wbIcon:SetTexture(WB_ICON)
    ui.wbIcon:SetWidth(14); ui.wbIcon:SetHeight(14)

    ui.onyTitle = CenterText()
    ui.nefTitle = CenterText()
    ui.onyTitle:SetText("Onyxia")
    ui.nefTitle:SetText("Nefarian")

    ui.onySW = CenterText(0.3, 0.6, 1)
    ui.onyOG = CenterText(1, 0.3, 0.3)
    ui.nefSW = CenterText(0.3, 0.6, 1)
    ui.nefOG = CenterText(1, 0.3, 0.3)
    ui.zg  = CenterText(0.2, 1, 0.2)
    ui.dmf = CenterText(0.7, 0.4, 1)
    ui.wb  = CenterText(1, 0.6, 0.1)

    ui:EnableMouse(true)
    ui:SetMovable(true)
    ui:RegisterForDrag("LeftButton")

    ui:SetScript("OnDragStart", function()
      if IsLocked() then return end
      pcall(function() ui:StartMoving() end)
    end)

    ui:SetScript("OnDragStop", function()
      pcall(function() ui:StopMovingOrSizing() end)
      local s = EnsureDB()
      s.x = ui:GetLeft() or 0
      s.y = ui:GetBottom() or 0
    end)

    ui.titleFrame:EnableMouse(true)
    ui.titleFrame:RegisterForDrag("LeftButton")

    ui.titleFrame:SetScript("OnDragStart", function()
      if IsLocked() then return end
      pcall(function() ui:StartMoving() end)
    end)

    ui.titleFrame:SetScript("OnDragStop", function()
      pcall(function() ui:StopMovingOrSizing() end)
      local s = EnsureDB()
      s.x = ui:GetLeft() or 0
      s.y = ui:GetBottom() or 0
    end)

    ui:SetScript("OnEnter", function()
      local b = ui.bgFrame
      if b then pcall(FadeInBg, b, 0.15, b:GetAlpha() or 0.18, 1.0) end
    end)
    ui:SetScript("OnLeave", function()
      local b = ui.bgFrame
      if b then pcall(FadeOutBg, b, 0.25, b:GetAlpha() or 1.0, 0.18) end
    end)

    ui.titleFrame:SetScript("OnEnter", function()
      local b = ui.bgFrame
      if b then pcall(FadeInBg, b, 0.15, b:GetAlpha() or 0.18, 1.0) end
    end)
    ui.titleFrame:SetScript("OnLeave", function()
      local b = ui.bgFrame
      if b then pcall(FadeOutBg, b, 0.25, b:GetAlpha() or 1.0, 0.18) end
    end)

    ui._lastUpdate = 0
    ui:SetScript("OnUpdate", function()
      local now = GetTime()
      if (now - ui._lastUpdate) < 0.25 then return end
      ui._lastUpdate = now
      UpdateTexts()
    end)
  end

  ApplyLayout()
  UpdateTexts()
end

local function CreateSizeUI()
  sizeUI = _G["RallyHelperSizeFrame"]
  if not sizeUI then
    sizeUI = CreateFrame("Frame", "RallyHelperSizeFrame", UIParent)
  end

  sizeUI:SetWidth(300)
  sizeUI:SetHeight(160)
  sizeUI:ClearAllPoints()
  sizeUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  sizeUI:SetFrameStrata("DIALOG")
  sizeUI:SetFrameLevel(600)

  sizeUI:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  sizeUI:SetBackdropColor(0, 0, 0, 0.9)

  ApplyPfUISkin(sizeUI)

  if not sizeUI.initialized then
    sizeUI.initialized = true

    sizeUI.title = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeUI.title:SetPoint("TOP", 0, -8)
    sizeUI.title:SetText("RallyHelper Size")

    local function MakeSlider(label, min, max, y, setter, step)
      local t = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      t:SetPoint("TOP", 0, y)
      t:SetText(label)

      local s = CreateFrame("Slider", nil, sizeUI, "OptionsSliderTemplate")
      s:SetPoint("TOP", 0, y - 20)
      s:SetMinMaxValues(min, max)
      s:SetValueStep(step or 1)

      s:SetScript("OnValueChanged", function()
  if IsLocked() then return end
  local v = tonumber(arg1) or tonumber(s:GetValue()) or 0
  setter(v)
end)


      return s
    end

    sizeUI.w = MakeSlider("Width", 300, 700, -28, function(v)
      local val = floor((tonumber(v) or 0) + 0.5)
      if ui then ui:SetWidth(val) end
      local sdb = EnsureDB()
      sdb.w = val
      ApplyLayout()
    end, 10)

    sizeUI.h = MakeSlider("Height", 140, 400, -78, function(v)
      local val = floor((tonumber(v) or 0) + 0.5)
      if ui then ui:SetHeight(val) end
      local sdb = EnsureDB()
      sdb.h = val
      ApplyLayout()
    end, 10)


    sizeUI.scaleLabel = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeUI.scaleLabel:SetPoint("TOP", 0, -118)
    sizeUI.scaleLabel:SetText("Scale")

    local scaleSlider = CreateFrame("Slider", nil, sizeUI, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOP", 0, -138)
    scaleSlider:SetMinMaxValues(0.7, 1.3)
    scaleSlider:SetValueStep(0.05)

    scaleSlider:SetScript("OnValueChanged", function()
      local v = tonumber(arg1) or tonumber(scaleSlider:GetValue()) or DEFAULT_SCALE
      v = floor(v * 100 + 0.5) / 100
      local sdb = EnsureDB()
      sdb.scale = v
      if ui then ui:SetScale(v) end
    end)

    sizeUI.scale = scaleSlider
  end

  sizeUI:Hide()
end

RallyHelper_ToggleUI = function()
  if not ui then CreateUI() end
  if ui:IsShown() then ui:Hide() else ui:Show() end
end

RallyHelper_ToggleSizeUI = function()
  if not ui then CreateUI() end
  if not sizeUI then CreateSizeUI() end

  if sizeUI:IsShown() then
    sizeUI:Hide()
  else
    local sdb = EnsureDB()
    if sizeUI.w then sizeUI.w:SetValue(ui and ui:GetWidth() or (sdb.w or DEFAULT_W)) end
    if sizeUI.h then sizeUI.h:SetValue(ui and ui:GetHeight() or (sdb.h or DEFAULT_H)) end
    if sizeUI.scale then sizeUI.scale:SetValue(sdb.scale or DEFAULT_SCALE) end
    sizeUI:Show()
  end
end

_G.RallyHelper_ToggleUI = RallyHelper_ToggleUI
_G.RallyHelper_ToggleSizeUI = RallyHelper_ToggleSizeUI
