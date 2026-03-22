RHGlobal = RHGlobal or {}
RHGlobal.Unconfirmed = RHGlobal.Unconfirmed or {}

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
  RallyHelperDB.ui = RallyHelperDB.ui or { w = DEFAULT_W, h = DEFAULT_H, scale = DEFAULT_SCALE }
  return RallyHelperDB.ui
end

local function ApplyPfUISkin(frame)
  if not frame or not pfUI or not pfUI.api then return end
  if pfUI.api.SkinFrame then pcall(pfUI.api.SkinFrame, frame) end
end

local function ApplyLayout()
  if not ui or not ui.initialized then return end

  local W = ui:GetWidth()
  local PAD, GAP = 16, 20
  local COL_W = (W - PAD * 2 - GAP) / 2
  local COL1_X, COL2_X = PAD, PAD + COL_W + GAP

  ui.onyIcon:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X + COL_W/2 - 40, -30)
  ui.onyTitle:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X, -30)
  ui.onyTitle:SetWidth(COL_W)

  ui.nefIcon:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X + COL_W/2 - 40, -30)
  ui.nefTitle:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X, -30)
  ui.nefTitle:SetWidth(COL_W)

  ui.onySW:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X, -54)
  ui.onySW:SetWidth(COL_W)

  ui.onyOG:SetPoint("TOPLEFT", ui, "TOPLEFT", COL1_X, -70)
  ui.onyOG:SetWidth(COL_W)

  ui.nefSW:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X, -54)
  ui.nefSW:SetWidth(COL_W)

  ui.nefOG:SetPoint("TOPLEFT", ui, "TOPLEFT", COL2_X, -70)
  ui.nefOG:SetWidth(COL_W)

  ui.zg:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD, -98)
  ui.zg:SetWidth(W - PAD*2)

  ui.dmf:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD, -114)
  ui.dmf:SetWidth(W - PAD*2)

  ui.wb:SetPoint("TOPLEFT", ui, "TOPLEFT", PAD, -138)
  ui.wb:SetWidth(W - PAD*2)
end

function UpdateTexts()
  if not ui or not ui.initialized or not RallyHelperDB then return end
  local DB = RallyHelperDB
  local t = time()

  local function FormatUnconfirmed(ev, label)
    local u = RHGlobal.Unconfirmed[ev]
    if not u then return nil end
    return "|cFFAAAAAA" .. label .. ": unconfirmed (" .. FormatAgo(u.ts) .. ")|r"
  end

  ui.onySW:SetText(
    FormatUnconfirmed("ONY_A", "Stormwind")
    or ("Stormwind: " .. Colorize(FormatTime(DB.lastOnyA and DB.lastOnyA + 7200 - t)))
  )

  ui.onyOG:SetText(
    FormatUnconfirmed("ONY_H", "Orgrimmar")
    or ("Orgrimmar: " .. Colorize(FormatTime(DB.lastOnyH and DB.lastOnyH + 7200 - t)))
  )

  ui.nefSW:SetText(
    FormatUnconfirmed("NEF_A", "Stormwind")
    or ("Stormwind: " .. Colorize(FormatTime(DB.lastNefA and DB.lastNefA + 7200 - t)))
  )

  ui.nefOG:SetText(
    FormatUnconfirmed("NEF_H", "Orgrimmar")
    or ("Orgrimmar: " .. Colorize(FormatTime(DB.lastNefH and DB.lastNefH + 7200 - t)))
  )

  ui.zg:SetText("ZG last drop: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))

  ui.dmf:SetText(
    "DMF last seen: "
    .. (DB.lastDMFTime and (FormatAgo(DB.lastDMFTime) .. " in " .. (DB.lastDMFZone or "unknown")) or "unknown")
  )

  ui.wb:SetText(
    FormatUnconfirmed("WB", "Warchief's Blessing")
    or ("Warchief's Blessing: " .. Colorize(FormatTime(DB.lastWB and DB.lastWB + 10800 - t)))
  )
end

function CreateUI()
  local S = EnsureDB()

  ui = ui or CreateFrame("Frame", "RallyHelperFrame", UIParent)
  ui:SetWidth(S.w)
  ui:SetHeight(S.h)
  ui:SetClampedToScreen(true)
  ui:SetMovable(true)
  ui:SetScale(S.scale or 1.0)

  if S.x and S.y then
    ui:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", S.x, S.y)
  else
    ui:SetPoint("CENTER")
  end

  ui.bgFrame = ui.bgFrame or CreateFrame("Frame", nil, ui)
  ui.bgFrame:SetAllPoints()
  ui.bgFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    insets = { left=4, right=4, top=4, bottom=4 }
  })
  ui.bgFrame:SetBackdropColor(0,0,0,0.75)
  ui.bgFrame:SetAlpha(0.18)

  if not ui.initialized then
    ui.initialized = true

    local function CreateFS(r, g, b)
      local f = ui:CreateFontString(nil, "OVERLAY")
      f:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
      if r then f:SetTextColor(r, g, b) end
      f:SetJustifyH("CENTER")
      return f
    end

    ui.onyIcon = ui:CreateTexture(nil, "ARTWORK")
    ui.onyIcon:SetTexture(ONY_ICON)
    ui.onyIcon:SetWidth(16)
    ui.onyIcon:SetHeight(16)

    ui.nefIcon = ui:CreateTexture(nil, "ARTWORK")
    ui.nefIcon:SetTexture(NEF_ICON)
    ui.nefIcon:SetWidth(16)
    ui.nefIcon:SetHeight(16)

    ui.onyTitle = CreateFS()
    ui.onyTitle:SetText("Onyxia")

    ui.nefTitle = CreateFS()
    ui.nefTitle:SetText("Nefarian")

    ui.onySW = CreateFS(0.3, 0.6, 1)
    ui.onyOG = CreateFS(1, 0.3, 0.3)
    ui.nefSW = CreateFS(0.3, 0.6, 1)
    ui.nefOG = CreateFS(1, 0.3, 0.3)

    ui.zg  = CreateFS(0.2, 1, 0.2)
    ui.dmf = CreateFS(0.7, 0.4, 1)
    ui.wb  = CreateFS(1, 0.6, 0.1)

    ui:EnableMouse(true)
    ui:RegisterForDrag("LeftButton")

    ui:SetScript("OnDragStart", function()
      if not IsLocked() then ui:StartMoving() end
    end)

    ui:SetScript("OnDragStop", function()
      ui:StopMovingOrSizing()
      S.x, S.y = ui:GetLeft(), ui:GetBottom()
    end)

    ui:SetScript("OnEnter", function()
      ui.bgFrame:SetAlpha(1.0)
    end)

    ui:SetScript("OnLeave", function()
      ui.bgFrame:SetAlpha(0.18)
    end)

    ui:SetScript("OnUpdate", function()
      if (GetTime() - (ui._last or 0)) > 0.5 then
        ui._last = GetTime()
        UpdateTexts()
      end
    end)
  end

  ApplyLayout()
  UpdateTexts()
  ApplyPfUISkin(ui)
end

function CreateSizeUI()
  local function CreateFS(parent, size, r, g, b)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    if r then f:SetTextColor(r, g, b) end
    f:SetJustifyH("LEFT")
    return f
  end

  if sizeUI then return end

  sizeUI = CreateFrame("Frame", "RallyHelperSizeFrame", UIParent)
  sizeUI:SetWidth(340)
  sizeUI:SetHeight(240)
  sizeUI:ClearAllPoints()
  sizeUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  sizeUI:SetFrameStrata("DIALOG")

  sizeUI:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true, tileSize=32, edgeSize=32,
    insets={left=11,right=12,top=12,bottom=11}
  })

  sizeUI:EnableMouse(true)
  sizeUI:SetMovable(true)
  sizeUI:RegisterForDrag("LeftButton")
  sizeUI:SetScript("OnDragStart", function() sizeUI:StartMoving() end)
  sizeUI:SetScript("OnDragStop", function() sizeUI:StopMovingOrSizing() end)

  local title = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -15)
  title:SetText("RallyHelper UI Settings")

  local widthText = CreateFS(sizeUI, 14)
  widthText:SetPoint("TOPLEFT", 20, -50)
  widthText:SetText("Width")

  local widthSlider = CreateFrame("Slider", nil, sizeUI, "OptionsSliderTemplate")
  widthSlider:SetPoint("TOPLEFT", 20, -70)
  widthSlider:SetWidth(300)
  widthSlider:SetMinMaxValues(300, 700)
  widthSlider:SetValueStep(10)

  widthSlider:SetScript("OnValueChanged", function()
    local v = floor(widthSlider:GetValue() + 0.5)
    local S = EnsureDB()
    S.w = v
    if ui then ui:SetWidth(v) ApplyLayout() end
  end)

  local heightText = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  heightText:SetPoint("TOPLEFT", 20, -110)
  heightText:SetText("Height")

  local heightSlider = CreateFrame("Slider", nil, sizeUI, "OptionsSliderTemplate")
  heightSlider:SetPoint("TOPLEFT", 20, -130)
  heightSlider:SetWidth(300)
  heightSlider:SetMinMaxValues(140, 400)
  heightSlider:SetValueStep(10)

  heightSlider:SetScript("OnValueChanged", function()
    local v = floor(heightSlider:GetValue() + 0.5)
    local S = EnsureDB()
    S.h = v
    if ui then ui:SetHeight(v) ApplyLayout() end
  end)

  local scaleText = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  scaleText:SetPoint("TOPLEFT", 20, -160)
  scaleText:SetText("Scale")

  local scaleSlider = CreateFrame("Slider", nil, sizeUI, "OptionsSliderTemplate")
  scaleSlider:SetPoint("TOPLEFT", 20, -180)
  scaleSlider:SetWidth(300)
  scaleSlider:SetMinMaxValues(0.7, 1.3)
  scaleSlider:SetValueStep(0.05)

  scaleSlider:SetScript("OnValueChanged", function()
    local v = floor(scaleSlider:GetValue() * 100 + 0.5) / 100
    local S = EnsureDB()
    S.scale = v
    if ui then ui:SetScale(v) end
  end)

  local close = CreateFrame("Button", nil, sizeUI, "UIPanelButtonTemplate")
  close:SetWidth(80)
  close:SetHeight(24)
  close:SetPoint("BOTTOM", 0, 15)
  close:SetText("Close")
  close:SetScript("OnClick", function() sizeUI:Hide() end)

  local S = EnsureDB()
  widthSlider:SetValue(S.w or DEFAULT_W)
  heightSlider:SetValue(S.h or DEFAULT_H)
  scaleSlider:SetValue(S.scale or DEFAULT_SCALE)
end

_G.RallyHelper_ToggleUI = function()
  if not ui then CreateUI() end
  if ui:IsShown() then ui:Hide() else ui:Show() end
end

_G.RallyHelper_ToggleSizeUI = function()
  if not sizeUI then CreateSizeUI() end
  if sizeUI:IsShown() then sizeUI:Hide() else sizeUI:Show() end
end

_G.RallyHelper_UpdateUI = UpdateTexts
_G.RH_CreateUI = CreateUI
