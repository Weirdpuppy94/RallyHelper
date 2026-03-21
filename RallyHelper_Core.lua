local function RH_ForceJoinChannel()
  local channels = { GetChannelList() }
  local isIn = false

  for _, ch in next, channels do
    if string.lower(ch) == "rhglobal" then
      isIn = true
      break
    end
  end

  if not isIn then
    JoinChannelByName("RHGlobal")
  end
end

local RH_DEBUG_CHANNEL = "RallyDebug"
local function RH_Debug(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RH DEBUG]|r " .. msg)
end
local RH_ChannelJoinDelay = CreateFrame("Frame")
RH_ChannelJoinDelay:Hide()

RH_ChannelJoinDelay:SetScript("OnShow", function()
  this.startTime = GetTime()
end)

RH_ChannelJoinDelay:SetScript("OnHide", function()
  RH_ForceJoinChannel()
end)

RH_ChannelJoinDelay:SetScript("OnUpdate", function()
  local delay = 15
  if GetTime() >= this.startTime + delay then
    RH_ChannelJoinDelay:Hide()
  end
end)


local RH_CHANNEL        = "RHGlobal"
local RH_VERIFY_WINDOW  = 30
local RH_VERIFY_REQUIRED = 2
local RH_VERIFY_REQUIRED_REQUEST = 5
local RH_SEND_THROTTLE  = 20

local ONY_CD = 2 * 60 * 60
local NEF_CD = 2 * 60 * 60
local WB_CD  = 3 * 60 * 60

local DB_VERSION = 1

local DB
local verify = {}
local RH_Users = {}
local lastSend = {}
local RH_Unconfirmed = {}

local strmatch = string.match or function() return nil end
local strfind  = string.find  or function() return nil end
local strlower = string.lower or function(s) return s end
local strsub   = string.sub   or function(s, i, j) return s end
local floor    = math.floor

local function RH_After(delay, func)
  local f = CreateFrame("Frame")
  local start = GetTime()
  f:SetScript("OnUpdate", function()
    if GetTime() - start >= delay then
      f:SetScript("OnUpdate", nil)
      func()
    end
  end)
end

local DMF_NPCS = {
  ["Sayge"] = true,
  ["Professor Thaddeus Paleo"] = true,
  ["Gelvas Grimegate"] = true,
  ["Stamp Thunderhorn"] = true,
  ["Darkmoon Faire Mystic Mage"] = true,
}

local function SafeZoneText()
  local z = GetZoneText() or ""
  return string.gsub(z, "|", "/")
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
  local m = floor((d - h * 3600) / 60)
  return h .. "h " .. m .. "m ago"
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

  local channels = { GetChannelList() }
  local id = nil

  local count = table.getn(channels)
  local i = 1
  while i <= count do
    local index = channels[i]
    local name  = channels[i+1]
    if name and string.lower(name) == string.lower(RH_CHANNEL) then
      id = index
      break
    end
    i = i + 2
  end

  if not id then return end

  local msg = ev .. "|" .. time() .. "|" .. (UnitName("player") or "?") .. "|" .. (zone or "")
  SendChatMessage(SanitizeChat(msg), "CHANNEL", nil, id)
end



local function Prune(list)
  local now = time()
  for i = table.getn(list), 1, -1 do
    if now - list[i].ts > RH_VERIFY_WINDOW then
      table.remove(list, i)
    end
  end
end

local function VerifyEvent(ev, ts, sender, zone, required)
  required = required or RH_VERIFY_REQUIRED

  verify[ev] = verify[ev] or {}
  local list = verify[ev]
  Prune(list)

  for _, v in ipairs(list) do
    if v.sender == sender then return end
  end

  table.insert(list, { ts = ts, sender = sender, zone = zone or "" })

  if table.getn(list) >= required then
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
  if ev == "ONY_A" then DB.lastOnyA = ts end
  if ev == "ONY_H" then DB.lastOnyH = ts end
  if ev == "NEF_A" then DB.lastNefA = ts end
  if ev == "NEF_H" then DB.lastNefH = ts end
  if ev == "ZG"    then DB.lastZG   = ts end
  if ev == "DMF"   then DB.lastDMFTime = ts; DB.lastDMFZone = zone end
  if ev == "WB"    then DB.lastWB = ts; DB.lastWBZone = zone end

  RH_Unconfirmed[ev] = nil
  RH_Debug("confirmed " .. ev)
  if DB.toast then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RallyHelper]|r " .. ev .. " confirmed")
  end

  if type(RallyHelper_UpdateUI) == "function" then
    RallyHelper_UpdateUI()
  end
end

local function AddUnconfirmedEvent(ev, ts, sender, zone)
  RH_Debug("unconfirmed " .. ev .. " from " .. sender)
  RH_Unconfirmed[ev] = {
    ts = ts,
    sender = sender,
    zone = zone,
    time = time(),
  }
  if type(RallyHelper_UpdateUI) == "function" then
    RallyHelper_UpdateUI()
  end
end

local function RespondToRequest()
  if DB.lastOnyA then SendEvent("TIMER_ONY_A") end
  if DB.lastOnyH then SendEvent("TIMER_ONY_H") end
  if DB.lastNefA then SendEvent("TIMER_NEF_A") end
  if DB.lastNefH then SendEvent("TIMER_NEF_H") end
  if DB.lastZG then SendEvent("TIMER_ZG") end
  if DB.lastDMFTime then SendEvent("TIMER_DMF", DB.lastDMFZone or "") end
  if DB.lastWB then SendEvent("TIMER_WB", DB.lastWBZone or "") end
end

local function SplitMessage(msg)
  local a, b, c, d = "", "", "", ""
  local p1 = string.find(msg, "|")
  if not p1 then return msg end

  a = string.sub(msg, 1, p1 - 1)
  local rest = string.sub(msg, p1 + 1)

  local p2 = string.find(rest, "|")
  if not p2 then return a end

  b = string.sub(rest, 1, p2 - 1)
  rest = string.sub(rest, p2 + 1)

  local p3 = string.find(rest, "|")
  if not p3 then
    c = rest
    return a, b, c
  end

  c = string.sub(rest, 1, p3 - 1)
  d = string.sub(rest, p3 + 1)

  return a, b, c, d
end

local function HandleRallyMessage(msg)
  local ev, ts, sender, zone = SplitMessage(msg)
  ts = tonumber(ts)
  if not ev or not ts or not sender then return end
  if zone == "" then zone = nil end

  RH_Users[sender] = time()

  if ev == "REQ" then
    RespondToRequest()
    return
  end

  local required = RH_VERIFY_REQUIRED

  if strsub(ev, 1, 6) == "TIMER_" then
    ev = strsub(ev, 8)
    required = RH_VERIFY_REQUIRED_REQUEST
  end

  if ev == "ZG" then
    AcceptEvent(ev, ts, zone)
    return
  end

  local ok, bestTs, bestZone = VerifyEvent(ev, ts, sender, zone, required)
  if ok then
    AcceptEvent(ev, bestTs, bestZone)
    return
  end

  AddUnconfirmedEvent(ev, ts, sender, zone)
end

local function HandleChannel(msg, channel)
  local normalized = string.lower(channel or "")
  if not string.find(normalized, "rhglobal") then return end
  if type(msg) ~= "string" then return end
  if msg == "" then return end
  if not strfind(msg, "|") then return end

  HandleRallyMessage(msg)
end


local function HandleYell(npc, msg)
  if type(npc) ~= "string" or type(msg) ~= "string" then return end

  local lowerMsg = strlower(msg)

  local function has(s)
    return strfind(lowerMsg, s, 1, true) ~= nil
  end

  if npc == "Major Mattingly" and (has("onyxia") or has("slain") or has("head")) then
    SendEvent("ONY_A")
    return
  end

  if npc == "Field Marshal Afrasiabi" and (has("blackrock") or has("nefarian") or has("slain")) then
    SendEvent("NEF_A")
    return
  end

  if npc == "High Overlord Saurfang" and (has("onyxia") or has("slain")) then
    SendEvent("ONY_H")
    return
  end

  if npc == "Overlord Runthak" then
    if has("onyxia") or has("brood mother") then
      SendEvent("ONY_H")
      return
    end
    if has("blackrock") or has("nefarian") then
      SendEvent("NEF_H")
      return
    end
    return
  end

  if npc == "Molthor" and (has("hakkar") or has("slayer of hakkar")) then
    AcceptEvent("ZG", time())
    SendEvent("ZG")
    return
  end

  if npc == "Thrall" and (has("warchief") or has("rend")) then
    SendEvent("WB", "Orgrimmar")
    return
  end
end

local function TryDMF()
  if UnitExists("target") and DMF_NPCS[UnitName("target")] then
    SendEvent("DMF", SafeZoneText())
  end
end


local function CountUsers()
  local now = time()
  local count = 0
  for name, ts in pairs(RH_Users) do
    if now - ts < 60 then
      count = count + 1
    else
      RH_Users[name] = nil
    end
  end
  return count
end

function PrintStatus()
  local now = time()
  DEFAULT_CHAT_FRAME:AddMessage("Ony SW: " .. (DB.lastOnyA and FormatTime(DB.lastOnyA + ONY_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Ony OG: " .. (DB.lastOnyH and FormatTime(DB.lastOnyH + ONY_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Nef SW: " .. (DB.lastNefA and FormatTime(DB.lastNefA + NEF_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Nef OG: " .. (DB.lastNefH and FormatTime(DB.lastNefH + NEF_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("ZG last drop: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))
  DEFAULT_CHAT_FRAME:AddMessage("DMF last seen: " .. (DB.lastDMFTime and FormatAgo(DB.lastDMFTime) or "unknown"))
  DEFAULT_CHAT_FRAME:AddMessage("Rend: " .. (DB.lastWB and FormatTime(DB.lastWB + WB_CD - now) or "ready"))
end

function RallyHelper_InsertToChat(text)
  if not ChatFrameEditBox:IsShown() then ChatFrame_OpenChat("") end
  ChatFrameEditBox:Insert(text)
end

function ShareTimersToChat()
  local now = time()
  RallyHelper_InsertToChat(
    "Ony SW: " .. (DB.lastOnyA and FormatTime(DB.lastOnyA + ONY_CD - now) or "ready") .. " | " ..
    "Ony OG: " .. (DB.lastOnyH and FormatTime(DB.lastOnyH + ONY_CD - now) or "ready") .. " | " ..
    "Nef SW: " .. (DB.lastNefA and FormatTime(DB.lastNefA + NEF_CD - now) or "ready") .. " | " ..
    "Nef OG: " .. (DB.lastNefH and FormatTime(DB.lastNefH + NEF_CD - now) or "ready")
  )
end

SLASH_RALLYHELPER1 = "/rally"
SlashCmdList["RALLYHELPER"] = function(msg)
  msg = strlower(msg or "")

  if msg == "status" then
    PrintStatus()
  elseif msg == "share" then
    ShareTimersToChat()
  elseif msg == "reset" then
    DB.ui = nil
    ReloadUI()
  elseif msg == "lock" then
    DB.locked = not DB.locked
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] UI lock: " .. tostring(DB.locked))
  elseif msg == "users" then
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Users online: " .. CountUsers())
  elseif msg == "request" then
    SendEvent("REQ")
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Requested timers from RHGlobal")
  else
    if type(RallyHelper_ToggleUI) == "function" then
      RallyHelper_ToggleUI()
    end
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
    b.altDown = IsAltKeyDown()
    b.didDrag = false
    b.downX, b.downY = CursorUI()
  end)

  b:SetScript("OnUpdate", function()
    if not b.isDown or not b.altDown then return end
    local cx, cy = CursorUI()
    local dx, dy = cx - b.downX, cy - b.downY
    if (dx*dx + dy*dy) < 16 then return end
    b.didDrag = true
    local mx, my = Minimap:GetCenter()
    local ang = math.deg(math.atan2(cy - my, cx - mx))
    if ang < 0 then ang = ang + 360 end
    DB.minimap.angle = ang
    UpdatePos()
  end)

  b:SetScript("OnMouseUp", function()
    b.isDown = false
  end)

  b:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      PrintStatus()
      return
    end
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
    end
  end)

  UpdatePos()
  if DB.minimap.hide then
    b:Hide()
  else
    b:Show()
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_CHANNEL")
f:RegisterEvent("CHAT_MSG_MONSTER_YELL")
f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("QUEST_GREETING")
f:RegisterEvent("MERCHANT_SHOW")

local function RH_TrySendREQ()
  local channels = { GetChannelList() }
  local id = nil

  local count = table.getn(channels)
  local i = 1
  while i <= count do
    local index = channels[i]
    local name  = channels[i+1]
    if name and string.lower(name) == string.lower(RH_CHANNEL) then
      id = index
      break
    end
    i = i + 2
  end

  if id then
    SendEvent("REQ")
  else
    RH_After(1, RH_TrySendREQ)
  end
end

f:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    DB = RallyHelperDB or {}
    RallyHelperDB = DB
	RH_ChannelJoinDelay:Show()

    DB.version = DB.version or 0
    if DB.version < DB_VERSION then

      DB.ui = DB.ui or {}
      DB.minimap = DB.minimap or {}
      DB.locked = false
      DB.toast = true
      DB.version = DB_VERSION
    end

    RH_After(1, RH_TrySendREQ)
    CreateMinimapButton()
    CreateUI()

elseif event == "CHAT_MSG_CHANNEL" then
    local ch = string.lower(arg4 or "")
    ch = string.gsub(ch, "[%s%p%d]", "")
    if not string.find(ch, "rhglobal") then return end
    HandleChannel(arg1, ch)



  elseif event == "CHAT_MSG_MONSTER_YELL" then
    HandleYell(arg2, arg1)

  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "MERCHANT_SHOW" then
    TryDMF()
  end
end)

