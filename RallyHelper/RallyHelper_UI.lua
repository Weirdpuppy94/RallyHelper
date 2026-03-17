-- RallyHelper_UI.lua (FINAL, korrigiert: title hover/drag nil-safe, bg-only fade)
-- Änderungen:
--  - titleFrame vor Verwendung erzeugt
--  - Hover/Drag-Handler verwenden Closures und prüfen auf Existenz
--  - Fade wirkt nur auf bgFrame (Texte/Icons bleiben sichtbar)
--  - bgFrame fängt keine Maus-Events; Rand dezent
--  - Slider/Scale/Size/UpdateTexts unverändert

local ui
local sizeUI
local locked = false

local ONY_ICON = "Interface\\Icons\\INV_Misc_Head_Dragon_Red"
local NEF_ICON = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue"
local WB_ICON  = "Interface\\Icons\\Spell_Nature_BloodLust"

local DEFAULT_W = 420
local DEFAULT_H = 190
local DEFAULT_SCALE = 1.0

local floor = math.floor

-- =========================================================
-- FORMAT
-- =========================================================
local function FormatTime(sec)
  if not sec or sec <= 0 then return "ready" end
  local h = floor(sec / 3600)
  local m = floor((sec - h * 3600) / 60)
  if h > 0 then return h .. "h " .. m .. "m" end
  return m .. "m"
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
  return RallyHelperDB.ui
end

-- =========================================================
-- Helper: safe fade for bgFrame only
-- =========================================================
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

-- =========================================================
-- LAYOUT
-- =========================================================
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

-- =========================================================
-- TEXT UPDATE (Vanilla‑safe) — uses Core field names
-- =========================================================
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

-- =========================================================
-- MAIN UI
-- =========================================================
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

  -- restore saved position if present (use BOTTOMLEFT coords)
  if S.x and S.y then
    ui:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", S.x, S.y)
  else
    ui:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
  end

  -- create a dedicated background frame that holds the backdrop and will be faded
  if not ui.bgFrame then
    ui.bgFrame = CreateFrame("Frame", nil, ui)
    ui.bgFrame:SetAllPoints(ui)
    -- ensure bgFrame is behind the ui content
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

    -- IMPORTANT: do NOT let bgFrame capture mouse events (so dragging works on parent/title)
    ui.bgFrame:EnableMouse(false)
    ui.bgFrame:SetAlpha(0.18)
  else
    ui.bgFrame:ClearAllPoints()
    ui.bgFrame:SetAllPoints(ui)
  end

  -- default scale
  local scale = S.scale or DEFAULT_SCALE
  ui:SetScale(scale)

  if not ui.initialized then
    ui.initialized = true

    -- create titleFrame first (so any later references are safe)
    if not ui.titleFrame or (type(ui.titleFrame) ~= "table") then
      ui.titleFrame = CreateFrame("Frame", nil, ui)
      ui.titleFrame:SetPoint("TOPLEFT", ui, "TOPLEFT", 0, 0)
      ui.titleFrame:SetPoint("TOPRIGHT", ui, "TOPRIGHT", 0, 0)
      ui.titleFrame:SetHeight(24)
      -- ensure titleFrame is above bgFrame
      ui.titleFrame:SetFrameLevel((ui.bgFrame and ui.bgFrame:GetFrameLevel() or 0) + 2)
    end

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

    -- ===== Robust Drag/Mouse handlers (closure-based, nil-safe) =====
    ui:EnableMouse(true)
    ui:SetMovable(true)
    ui:RegisterForDrag("LeftButton")

    local function makeStartMoving(frame)
      return function()
        if not frame then return end
        if locked then return end
        if not frame:IsMovable() then return end
        -- StartMoving is safe to call
        pcall(function() frame:StartMoving() end)
      end
    end

    local function makeStopMoving(frame)
      return function()
        if not frame then return end
        pcall(function() frame:StopMovingOrSizing() end)
        local left = frame:GetLeft() or 0
        local bottom = frame:GetBottom() or 0
        local s = EnsureDB()
        s.x = left
        s.y = bottom
      end
    end

    ui:SetScript("OnDragStart", makeStartMoving(ui))
    ui:SetScript("OnDragStop", makeStopMoving(ui))

    -- ensure titleFrame exists and forwards drag/hover safely
    ui.titleFrame:EnableMouse(true)
    ui.titleFrame:RegisterForDrag("LeftButton")

    ui.titleFrame:SetScript("OnDragStart", function()
      local parent = ui.titleFrame and ui.titleFrame:GetParent()
      if not parent then return end
      if locked then return end
      if not parent:IsMovable() then return end
      pcall(function() parent:StartMoving() end)
    end)

    ui.titleFrame:SetScript("OnDragStop", function()
      local parent = ui.titleFrame and ui.titleFrame:GetParent()
      if not parent then return end
      pcall(function() parent:StopMovingOrSizing() end)
      local left = parent:GetLeft() or 0
      local bottom = parent:GetBottom() or 0
      local s = EnsureDB()
      s.x = left
      s.y = bottom
    end)

    -- safe mouse down/up bookkeeping
    ui:SetScript("OnMouseDown", function()
      if locked then return end
      pcall(function() ui._dragStartX, ui._dragStartY = GetCursorPosition() end)
    end)

    ui:SetScript("OnMouseUp", function()
      pcall(function() ui._dragStartX, ui._dragStartY = nil, nil end)
    end)
    -- ===== end robust drag block =====

    -- Hover fade: only affect bgFrame (not texts/icons)
    -- Use closures referencing bgFrame to avoid nil 'self' issues
    local bg = ui.bgFrame
    if bg then bg:SetAlpha(0.18) end

    ui:SetScript("OnEnter", function()
      local b = ui.bgFrame
      if b then pcall(FadeInBg, b, 0.15, b:GetAlpha() or 0.18, 1.0) end
    end)
    ui:SetScript("OnLeave", function()
      local b = ui.bgFrame
      if b then pcall(FadeOutBg, b, 0.25, b:GetAlpha() or 1.0, 0.18) end
    end)

    -- titleFrame hover uses closure to bgFrame (no reliance on 'self')
    ui.titleFrame:SetScript("OnEnter", function()
      local b = ui.bgFrame
      if b then pcall(FadeInBg, b, 0.15, b:GetAlpha() or 0.18, 1.0) end
    end)
    ui.titleFrame:SetScript("OnLeave", function()
      local b = ui.bgFrame
      if b then pcall(FadeOutBg, b, 0.25, b:GetAlpha() or 1.0, 0.18) end
    end)

    -- ensure FontString has no mouse scripts (FontStrings may not support them)
    if ui.title and type(ui.title.SetScript) == "function" then
      ui.title:SetScript("OnEnter", nil)
      ui.title:SetScript("OnLeave", nil)
    end

    ui._lastUpdate = 0
    ui:SetScript("OnUpdate", function(self)
      local now = GetTime()
      if (now - ui._lastUpdate) < 0.25 then return end
      ui._lastUpdate = now
      UpdateTexts()
    end)
  end

  ApplyLayout()
  UpdateTexts()
end

-- =========================================================
-- SIZE WINDOW (SetPoint safe + robust sliders + scale slider)
-- =========================================================
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

      s:SetScript("OnValueChanged", function(_, v)
        local val = tonumber(v) or s:GetValue() or 0
        setter(floor(val + 0.5))
      end)

      return s
    end

    -- Width slider
    sizeUI.w = MakeSlider("Width", 300, 700, -28, function(v)
      if ui then ui:SetWidth(v) end
      local s = EnsureDB()
      s.w = v
      ApplyLayout()
    end, 10)

    -- Height slider
    sizeUI.h = MakeSlider("Height", 140, 400, -78, function(v)
      if ui then ui:SetHeight(v) end
      local s = EnsureDB()
      s.h = v
      ApplyLayout()
    end, 10)

    -- Scale slider (0.7 - 1.3 step 0.05)
    local function SetScaleValue(v)
      local sdb = EnsureDB()
      sdb.scale = v
      if ui then ui:SetScale(v) end
    end

    sizeUI.scaleLabel = sizeUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeUI.scaleLabel:SetPoint("TOP", 0, -118)
    sizeUI.scaleLabel:SetText("Scale")

    local scaleSlider = CreateFrame("Slider", nil, sizeUI, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOP", 0, -138)
    scaleSlider:SetMinMaxValues(0.7, 1.3)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetScript("OnValueChanged", function(_, v)
      local val = tonumber(v) or scaleSlider:GetValue() or DEFAULT_SCALE
      val = math.floor(val * 100 + 0.5) / 100
      SetScaleValue(val)
    end)

    sizeUI.scale = scaleSlider
  end

  sizeUI:Hide()
end

-- =========================================================
-- TOGGLES
-- =========================================================
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
    local s = EnsureDB()
    if sizeUI.w then sizeUI.w:SetValue(ui and ui:GetWidth() or (s.w or DEFAULT_W)) end
    if sizeUI.h then sizeUI.h:SetValue(ui and ui:GetHeight() or (s.h or DEFAULT_H)) end
    if sizeUI.scale then sizeUI.scale:SetValue(s.scale or DEFAULT_SCALE) end
    sizeUI:Show()
  end
end

_G.RallyHelper_ToggleUI = RallyHelper_ToggleUI
_G.RallyHelper_ToggleSizeUI = RallyHelper_ToggleSizeUI
