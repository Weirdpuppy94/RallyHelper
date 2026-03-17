local RH_CHANNEL_NAME    = "RallyHelper"
local RH_VERIFY_WINDOW   = 30
local RH_VERIFY_REQUIRED = 2
local RH_SEND_THROTTLE   = 20

local ONY_CD = 2 * 60 * 60
local NEF_CD = 2 * 60 * 60
local WB_CD  = 3 * 60 * 60
local WB_WARN_DELAY = 6

local DB
local verify = {}
local lastSend = {}

local floor = math.floor

local DMF_NPCS = {
  ["Sayge"] = true,
  ["Professor Thaddeus Paleo"] = true,
  ["Gelvas Grimegate"] = true,
  ["Stamp Thunderhorn"] = true,
  ["Darkmoon Faire Mystic Mage"] = true,
}

local function SafeZoneText()
  local z = GetZoneText() or ""
  z = string.gsub(z, "|", "/")
  return z
end

local function SanitizeChat(msg)
  if not msg then return "" end
  msg = string.gsub(msg, "|", "||")
  msg = string.gsub(msg, "%%", "%%%%")
  return msg
end

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
  local rem = d - (h * 3600)
  local m = floor(rem / 60)
  return h .. "h " .. m .. "m ago"
end

local function PlayAlert(key)
  if DB and DB.sound and DB.sound.master and DB.sound[key] then
    PlaySound("RaidWarning")
  end
end

local function IsInChannel()
  for i = 1, 10 do
    local name = GetChannelName(i)
    if name == RH_CHANNEL_NAME then return true end
  end
end

local function JoinChannel()
  if not IsInChannel() then
    JoinChannelByName(RH_CHANNEL_NAME)
  end
end

local function GetChannelId()
  local id = GetChannelName(RH_CHANNEL_NAME)
  if type(id) == "number" and id > 0 then return id end
end

local function CanSend(ev)
  local now = time()
  if not lastSend[ev] or (now - lastSend[ev]) >= RH_SEND_THROTTLE then
    lastSend[ev] = now
    return true
  end
end

local function SendEvent(ev, zone)
  if not CanSend(ev) then return end
  local cid = GetChannelId()
  if not cid then return end

  local msg = ev .. "|" .. time() .. "|" .. (UnitName("player") or "?") .. "|" .. (zone or "")
  SendChatMessage(SanitizeChat(msg), "CHANNEL", nil, cid)
end

local function Prune(list)
  local now = time()
  for i = table.getn(list), 1, -1 do
    if now - list[i].ts > RH_VERIFY_WINDOW then
      table.remove(list, i)
    end
  end
end

local function VerifyEvent(ev, ts, sender, zone)
  verify[ev] = verify[ev] or {}
  local list = verify[ev]
  Prune(list)

  for _, v in ipairs(list) do
    if v.sender == sender then return end
  end

  table.insert(list, { ts = ts, sender = sender, zone = zone or "" })

  if table.getn(list) >= RH_VERIFY_REQUIRED then
    local bestTs, bestZone = 0, ""
    for _, v in ipairs(list) do
      if v.ts > bestTs then bestTs = v.ts end
    end
    for _, v in ipairs(list) do
      if v.ts == bestTs and v.zone ~= "" then bestZone = v.zone end
    end
    verify[ev] = nil
    return true, bestTs, bestZone
  end
end

local function AcceptEvent(ev, ts, zone)
  if ev == "ONY_A" then DB.lastOnyA = ts; PlayAlert("ONY") end
  if ev == "ONY_H" then DB.lastOnyH = ts; PlayAlert("ONY") end
  if ev == "NEF_A" then DB.lastNefA = ts; PlayAlert("NEF") end
  if ev == "NEF_H" then DB.lastNefH = ts; PlayAlert("NEF") end
  if ev == "ZG"    then DB.lastZG   = ts; PlayAlert("ZG")  end
  if ev == "DMF"   then DB.lastDMFTime = ts; DB.lastDMFZone = zone; PlayAlert("DMF") end
  if ev == "WB"    then DB.lastWB = ts; DB.lastWBZone = zone; PlayAlert("WB") end
end

local function HandleChannel(msg, channel)
  if channel ~= RH_CHANNEL_NAME then return end

  local ev, ts, sender, zone = string.match(msg, "^([^|]+)|([^|]+)|([^|]+)|?(.*)$")
  ts = tonumber(ts)
  if not ev or not ts or not sender then return end

  local ok, bestTs, bestZone = VerifyEvent(ev, ts, sender, zone)
  if ok then AcceptEvent(ev, bestTs, bestZone) end
end

local function ScheduleWBWarning()
  if not DB.sound.master or not DB.sound.WB then return end
  if not C_Timer or not C_Timer.After then return end
  C_Timer.After(WB_WARN_DELAY, function()
    PlaySound("RaidWarning")
    DEFAULT_CHAT_FRAME:AddMessage("Warchief's Blessing in ~6 seconds!")
  end)
end

local function HandleYell(npc, msg)
  if npc == "Major Mattingly" and string.find(msg, "Dragonslayer") then SendEvent("ONY_A") end
  if npc == "High Overlord Saurfang" and string.find(msg, "Dragonslayer") then SendEvent("ONY_H") end
  if npc == "Field Marshal Afrasiabi" and string.find(msg, "Dragonslayer") then SendEvent("NEF_A") end
  if npc == "Overlord Runthak" and string.find(msg, "Dragonslayer") then SendEvent("NEF_H") end
  if npc == "Molthor" and string.find(msg, "Zandalar") then SendEvent("ZG") end

  if npc == "Thrall" then
    if string.find(msg, "Honor your heroes") or
       string.find(msg, "Be bathed in my power") or
       string.find(msg, "Warchief") then
      SendEvent("WB", "Orgrimmar")
      ScheduleWBWarning()
    end
  end
end

local function TryDMF()
  if UnitExists("target") and DMF_NPCS[UnitName("target")] then
    SendEvent("DMF", SafeZoneText())
  end
end

-- Updated PrintStatus: uses the requested labels and includes zones for DMF
local function PrintStatus()
  local now = time()
  DEFAULT_CHAT_FRAME:AddMessage("Onyxia Stormwind: " .. (DB.lastOnyA and FormatTime(DB.lastOnyA + ONY_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Onyxia Orgrimmar: " .. (DB.lastOnyH and FormatTime(DB.lastOnyH + ONY_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Nefarian Stormwind: " .. (DB.lastNefA and FormatTime(DB.lastNefA + NEF_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Nefarian Orgrimmar: " .. (DB.lastNefH and FormatTime(DB.lastNefH + NEF_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("ZG last drop: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))
  local dmfZone = (DB.lastDMFZone and DB.lastDMFZone ~= "") and DB.lastDMFZone or "unknown"
  DEFAULT_CHAT_FRAME:AddMessage("DMF last seen: " .. (DB.lastDMFTime and (FormatAgo(DB.lastDMFTime) .. " in " .. dmfZone) or ("unknown in " .. dmfZone)))
  DEFAULT_CHAT_FRAME:AddMessage("Rend: " .. (DB.lastWB and FormatTime(DB.lastWB + WB_CD - now) or "ready"))
end

function RallyHelper_InsertToChat(text)
  if not text or text == "" then return end
  if not ChatFrameEditBox:IsShown() then ChatFrame_OpenChat("") end
  if ChatEdit_InsertLink then
    ChatEdit_InsertLink(text)
  else
    ChatFrameEditBox:Insert(text)
  end
end

local function ShareTimersToChat()
  local now = time()
  local zgText = DB.lastZG and FormatAgo(DB.lastZG) or "unknown"
  local dmfZone = (DB.lastDMFZone and DB.lastDMFZone ~= "") and DB.lastDMFZone or "unknown"
  local dmfText = DB.lastDMFTime and (FormatAgo(DB.lastDMFTime) .. " in " .. dmfZone) or ("unknown in " .. dmfZone)

  RallyHelper_InsertToChat(
    "Ony SW: " .. (DB.lastOnyA and FormatTime(DB.lastOnyA + ONY_CD - now) or "ready") .. " | " ..
    "Ony OG: " .. (DB.lastOnyH and FormatTime(DB.lastOnyH + ONY_CD - now) or "ready") .. " | " ..
    "Nef SW: " .. (DB.lastNefA and FormatTime(DB.lastNefA + NEF_CD - now) or "ready") .. " | " ..
    "Nef OG: " .. (DB.lastNefH and FormatTime(DB.lastNefH + NEF_CD - now) or "ready") .. " | " ..
    "ZG last drop: " .. zgText .. " | " ..
    "DMF last seen: " .. dmfText .. " | " ..
    "Rend: " .. (DB.lastWB and FormatTime(DB.lastWB + WB_CD - now) or "ready")
  )
end

SLASH_RALLYHELPER1 = "/rally"
SlashCmdList["RALLYHELPER"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "status" then
    PrintStatus()
    return
  end

  if type(RallyHelper_ToggleUI) == "function" then
    RallyHelper_ToggleUI()
  else
    PrintStatus()
  end
end

local function CreateMinimapButton()
  if RallyHelperMinimapButton then return end

  local b = CreateFrame("Button", "RallyHelperMinimapButton", Minimap)
  b:SetWidth(32)
  b:SetHeight(32)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:SetToplevel(true)
  b:EnableMouse(true)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_Red")
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  b.icon:ClearAllPoints()
  b.icon:SetPoint("CENTER", 0, 0)
  b.icon:SetWidth(18)
  b.icon:SetHeight(18)

  b.border = b:CreateTexture(nil, "OVERLAY")
  b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  b.border:SetPoint("TOPLEFT", 0, 0)
  b.border:SetWidth(54)
  b.border:SetHeight(54)

  DB.minimap = DB.minimap or { angle = 220, hide = false }

  local function UpdatePos()
    local a = DB.minimap.angle or 220
    local rad = a * 0.01745329252
    local r = 80
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * r, math.sin(rad) * r)
  end

  local function CursorUI()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
  end

  b.isDown = false
  b.altDown = false
  b.didDrag = false
  b.downX, b.downY = 0, 0

  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(b, "ANCHOR_LEFT")
    GameTooltip:AddLine("RallyHelper")
    GameTooltip:AddLine("Left Click: Toggle UI")
    GameTooltip:AddLine("Right Click: Status")
    GameTooltip:AddLine("Shift + Left: Share timers")
    GameTooltip:AddLine("Alt + Click: Size window")
    GameTooltip:AddLine("Alt + Drag: Move icon")
    GameTooltip:Show()
  end)

  b:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  b:SetScript("OnMouseDown", function()
    if arg1 ~= "LeftButton" then return end
    b.isDown = true
    b.altDown = IsAltKeyDown() and true or false
    b.didDrag = false
    b.downX, b.downY = CursorUI()
  end)

  b:SetScript("OnUpdate", function()
    if not b.isDown then return end
    if not b.altDown then return end

    local cx, cy = CursorUI()
    local dx = cx - b.downX
    local dy = cy - b.downY
    if (dx*dx + dy*dy) < 16 then return end -- 4px threshold

    b.didDrag = true
    local mx, my = Minimap:GetCenter()
    local ang = math.deg(math.atan2(cy - my, cx - mx))
    if ang < 0 then ang = ang + 360 end
    DB.minimap.angle = ang
    UpdatePos()
  end)

  b:SetScript("OnMouseUp", function()
    if arg1 ~= "LeftButton" then return end
    b.isDown = false
  end)

  b:SetScript("OnClick", function()
    local button = arg1

    if button == "RightButton" then
      PrintStatus()
      return
    end

    if button ~= "LeftButton" then return end

    if IsAltKeyDown() then
      if b.didDrag then
        b.didDrag = false
        return
      end
      if type(RallyHelper_ToggleSizeUI) == "function" then
        RallyHelper_ToggleSizeUI()
      end
      return
    end


    if IsShiftKeyDown() then
      ShareTimersToChat()
      return
    end

    if type(RallyHelper_ToggleUI) == "function" then
      RallyHelper_ToggleUI()
    else
      PrintStatus()
    end
  end)

  UpdatePos()
  if DB.minimap.hide then b:Hide() else b:Show() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_CHANNEL")
f:RegisterEvent("CHAT_MSG_MONSTER_YELL")
f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("QUEST_GREETING")
f:RegisterEvent("MERCHANT_SHOW")

f:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    DB = RallyHelperDB or {}
    RallyHelperDB = DB
    DB.sound = DB.sound or { master = true, ONY = true, NEF = true, ZG = true, DMF = true, WB = true }

    JoinChannel()
    CreateMinimapButton()

    DEFAULT_CHAT_FRAME:AddMessage("RallyHelper Core loaded. (/rally to toggle UI, /rally status for chat)")
  elseif event == "CHAT_MSG_CHANNEL" then
    HandleChannel(arg1, arg9)
  elseif event == "CHAT_MSG_MONSTER_YELL" then
    HandleYell(arg2, arg1)
  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "MERCHANT_SHOW" then
    TryDMF()
  end
end)
