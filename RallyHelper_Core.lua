DEFAULT_CHAT_FRAME:AddMessage("STRING TYPE: "..type(string))
local RH_CHANNEL_NAME    = "RallyHelper"
local RH_VERIFY_WINDOW   = 30
local RH_VERIFY_REQUIRED = 2
local RH_VERIFY_REQUIRED_REQUEST = 5
local RH_SEND_THROTTLE   = 20

local ONY_CD = 2 * 60 * 60
local NEF_CD = 2 * 60 * 60
local WB_CD  = 3 * 60 * 60
local WB_WARN_DELAY = 6

local DB_VERSION = 1

local DB
local verify = {}
local RH_Users = {}
local lastSend = {}

local str = _G.string or string

local strmatch = str.match or function() return nil end
local strfind  = str.find  or function() return nil end
local strlower = str.lower or function(s) return s end
local strsub   = str.sub   or function(s, i, j) return s end
local strlen   = str.len   or function(s) return 0 end
local strgsub  = str.gsub  or function(s) return s end

local floor = math.floor

RHGlobal = RHGlobal or {}
RHGlobal.Unconfirmed = RHGlobal.Unconfirmed or {}
local RH_Unconfirmed = RHGlobal.Unconfirmed

local function SanitizeChat(msg)
  if not msg then return "" end
  msg = strgsub(msg, "%%", "%%%%")
  return msg
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

local function GetChannelId()
  for i = 1, 10 do
    local id, name = GetChannelName(i)
    if name == RH_CHANNEL_NAME then
      return id
    end
  end
  return nil
end


local function Delay(seconds, func)
  local f = CreateFrame("Frame")
  local t = GetTime() + seconds
  f:SetScript("OnUpdate", function()
    if GetTime() >= t then
      f:SetScript("OnUpdate", nil)
      func()
    end
  end)
end

local function JoinChannel()
  if GetChannelId() then return end

  JoinChannelByName(RH_CHANNEL_NAME)

  Delay(1, function()
    if not GetChannelId() then
      JoinChannelByName(RH_CHANNEL_NAME)
    end
  end)
end


local function EnsureChannel()
  if not GetChannelId() then
    JoinChannel()
  end
end

local function CanSend(ev)
  local now = time()
  if not lastSend[ev] or (now - lastSend[ev]) >= RH_SEND_THROTTLE then
    lastSend[ev] = now
    return true
  end
end

local function SanitizeChat(msg)
  if not msg then return "" end
  msg = str.gsub(msg, "%%", "%%%%")
  msg = str.gsub(msg, "|", "||")
  return msg
end

local function SendEvent(ev, zone)
  EnsureChannel()
  if not CanSend(ev) then return end

  local cid = GetChannelId()
  if not cid then return end

  local player = UnitName("player") or "?"
  local sep = "^"
  local msg = ev .. sep .. time() .. sep .. player
  if zone and zone ~= "" then
    msg = msg .. sep .. zone
  end

  if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RH SEND]|r "..msg.." (cid="..tostring(cid)..")")
end

  SendChatMessage(SanitizeChat(msg), "CHANNEL", nil, cid)
end


local function Prune(list)
  local now = time()
  local n = table.getn(list)
  for i = n, 1, -1 do
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
      if v.ts == bestTs and v.zone ~= "" then
        bestZone = v.zone
      end
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

  if DB.toast then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RallyHelper]|r " .. ev .. " confirmed")
  end

  if type(RallyHelper_UpdateUI) == "function" then
    RallyHelper_UpdateUI()
  end
end

local function AddUnconfirmedEvent(ev, ts, sender, zone)
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

local function NormalizeChannelName(name)
    if not name then return "" end
    name = strlower(name)
    name = strgsub(name, "^%d+%.%s*", "")
    name = strgsub(name, "%s+", "")
    return name
end

local function HandleChannel(msg, channel)

    if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RH DEBUG RAW]|r channel="..tostring(channel).." msg="..tostring(msg))
end


    local clean = NormalizeChannelName(channel)
    if clean ~= strlower(RH_CHANNEL_NAME) then
        return
    end

    if type(msg) ~= "string" then return end
    if msg == "" then return end

    if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RH DEBUG]|r HandleChannel fired: "..msg.." / "..channel)
end

    if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff55[RH DEBUG] SplitMessage starting|r")
end


    local function SplitMessage(m)
        local out = {}
        local current = ""

        local len = strlen(m) or 0
        for i = 1, len do
            local c = strsub(m, i, i)
            if c == "^" then
                table.insert(out, current)
                current = ""
            else
                current = current .. c
            end
        end

        table.insert(out, current)
        return out
    end

    local parts = SplitMessage(msg)
    local ev    = parts[1]
    local ts    = tonumber(parts[2])
    local sender= parts[3]
    local zone  = parts[4]

    if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff55[RH DEBUG PARTS]|r ev="..tostring(ev).." ts="..tostring(ts).." sender="..tostring(sender).." zone="..tostring(zone))
end


    if not ev or not ts or not sender then return end
    if zone == "" then zone = nil end

    RH_Users[sender] = time()

    if ev == "REQ" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[RH DEBUG] RespondToRequest() WILL BE CALLED|r")
        if type(RespondToRequest) == "function" then
            RespondToRequest()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[RH DEBUG] RespondToRequest MISSING|r")
        end
        return
    end

    local required = RH_VERIFY_REQUIRED

    if strsub(ev, 1, 6) == "TIMER_" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[RH DEBUG] TIMER RECEIVED: "..ev.."|r")
        ev = strsub(ev, 8)
        required = RH_VERIFY_REQUIRED_REQUEST
    end

    if ev == "ZG" then
	if DB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[RH DEBUG] AcceptEvent(ZG)|r")
        end
		AcceptEvent(ev, ts, zone)
        return
    end

    local ok, bestTs, bestZone = VerifyEvent(ev, ts, sender, zone, required)
    if ok then
        if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[RH DEBUG] VerifyEvent OK → AcceptEvent|r")
end

        AcceptEvent(ev, bestTs, bestZone)
        RH_Unconfirmed[ev] = nil
        return
    end

    if DB.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[RH DEBUG] AddUnconfirmedEvent|r")
end

    AddUnconfirmedEvent(ev, ts, sender, zone)
end

function RespondToRequest()
    local player = UnitName("player") or "?"
    local cid = GetChannelId()
    if not cid then return end

    local function send(ev, ts, zone)
        if not ts then return end
        local msg = ev .. "^" .. ts .. "^" .. player
        if zone then msg = msg .. "^" .. zone end
        SendChatMessage(SanitizeChat(msg), "CHANNEL", nil, cid)
    end

    send("ONY_A", DB.lastOnyA)
    send("ONY_H", DB.lastOnyH)
    send("NEF_A", DB.lastNefA)
    send("NEF_H", DB.lastNefH)
    send("ZG",    DB.lastZG)
    send("DMF",   DB.lastDMFTime, DB.lastDMFZone)
    send("WB",    DB.lastWB,      DB.lastWBZone)
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

local function HandleYell(npc, msg)
  if type(npc) ~= "string" or type(msg) ~= "string" then return end

  local lowerMsg = string.lower(msg)

  local function has(s)
    return string.find(lowerMsg, s, 1, true) ~= nil
  end

  if npc == "Major Mattingly" and (has("onyxia") or has("head")) then
    SendEvent("ONY_A")
    return
  end

  if npc == "Field Marshal Afrasiabi" and (has("nefarian") or has("blackrock")) then
    SendEvent("NEF_A")
    return
  end

  if npc == "High Overlord Saurfang" and (has("onyxia") or has("brood mother")) then
    SendEvent("ONY_H")
    return
  end

  if npc == "High Overlord Saurfang" and (has("nefarian") or has("blackrock")) then
    SendEvent("NEF_H")
    return
  end
  if npc == "Overlord Runthak" then
    if has("onyxia") or has("brood mother") then
      SendEvent("ONY_H")
      return
    end
    if has("nefarian") or has("blackrock") then
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


local DMF_NPCS = {
  ["Sayge"] = true,
  ["Professor Thaddeus Paleo"] = true,
  ["Gelvas Grimegate"] = true,
  ["Stamp Thunderhorn"] = true,
  ["Darkmoon Faire Mystic Mage"] = true,
}

local function SafeZoneText()
  local z = GetZoneText() or ""
  return str.gsub(z, "|", "/")
end

local function TryDMF()
  if UnitExists("npc") then
    local name = UnitName("npc")
    if DMF_NPCS[name] then
      local zone = SafeZoneText()
      AcceptEvent("DMF", time(), zone)
      SendEvent("DMF", zone) 
    end
  end
end



local function RequestTimers()
  SendEvent("REQ")
end

local function FormatTimeSimple(sec)
  if not sec or sec <= 0 then return "ready" end
  local h = math.floor(sec / 3600)
  local m = math.floor((sec - h * 3600) / 60)
  if h > 0 then return h .. "h " .. m .. "m" end
  return m .. "m"
end

function PrintStatus()
  local now = time()
  DEFAULT_CHAT_FRAME:AddMessage("Ony SW: " .. (DB.lastOnyA and FormatTimeSimple(DB.lastOnyA + ONY_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Ony OG: " .. (DB.lastOnyH and FormatTimeSimple(DB.lastOnyH + ONY_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Nef SW: " .. (DB.lastNefA and FormatTimeSimple(DB.lastNefA + NEF_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("Nef OG: " .. (DB.lastNefH and FormatTimeSimple(DB.lastNefH + NEF_CD - now) or "ready"))
  DEFAULT_CHAT_FRAME:AddMessage("ZG last drop: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))
  DEFAULT_CHAT_FRAME:AddMessage("DMF last seen: " .. (DB.lastDMFTime and FormatAgo(DB.lastDMFTime) or "unknown"))
  DEFAULT_CHAT_FRAME:AddMessage("Rend: " .. (DB.lastWB and FormatTimeSimple(DB.lastWB + WB_CD - now) or "ready"))
end

function RallyHelper_InsertToChat(text)
  if not ChatFrameEditBox:IsShown() then
    ChatFrame_OpenChat("")
  end
  ChatFrameEditBox:Insert(text)
end

function ShareTimersToChat()
  local now = time()
  RallyHelper_InsertToChat(
    "Ony SW: " .. (DB.lastOnyA and FormatTimeSimple(DB.lastOnyA + ONY_CD - now) or "ready") .. " | " ..
    "Ony OG: " .. (DB.lastOnyH and FormatTimeSimple(DB.lastOnyH + ONY_CD - now) or "ready") .. " | " ..
    "Nef SW: " .. (DB.lastNefA and FormatTimeSimple(DB.lastNefA + NEF_CD - now) or "ready") .. " | " ..
    "Nef OG: " .. (DB.lastNefH and FormatTimeSimple(DB.lastNefH + NEF_CD - now) or "ready")
  )
end

local function CreateMinimapButton()
  if pfUI and pfUI.api and pfUI.api.CreateMinimapButton then
    pfUI.api.CreateMinimapButton("RallyHelperMinimapButton")
    return
  end

  if RallyHelperMinimapButton then return end

  local b = CreateFrame("Button", "RallyHelperMinimapButton", Minimap)

  b:SetParent(Minimap)
  b:SetFrameStrata("HIGH")
  b:SetFrameLevel(10)
  b:Show()

  b:SetWidth(32)
  b:SetHeight(32)
  b:SetToplevel(true)
  b:EnableMouse(true)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
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
    GameTooltip:AddLine("Middle Mouse: Unconfirmed Buffs")
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
    if arg1 == "MiddleButton" then
      RallyHelper_ToggleUnconfirmed()
      return
    end

    if arg1 == "RightButton" then
      PrintStatus()
      return
    end

    if IsAltKeyDown() then
      if b.didDrag then
        b.didDrag = false
        return
      end
      RallyHelper_ToggleSizeUI()
      return
    end

    if IsShiftKeyDown() then
      ShareTimersToChat()
      return
    end

    RallyHelper_ToggleUI()
  end)

  UpdatePos()
  if DB.minimap.hide then b:Hide() else b:Show() end
end

SLASH_RALLYHELPER1 = "/rally"
SlashCmdList["RALLYHELPER"] = function(msg)
  msg = string.lower(msg or "")

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

  elseif msg == "debug" then
    DB.debug = not DB.debug
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Debug: " .. tostring(DB.debug))
    DEFAULT_CHAT_FRAME:AddMessage("ZG: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))
    DEFAULT_CHAT_FRAME:AddMessage("DMF: " .. (DB.lastDMFTime and FormatAgo(DB.lastDMFTime) or "unknown"))

  elseif msg == "request" then
    RequestTimers()
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Requested timers from channel")

  else
    RallyHelper_ToggleUI()
  end
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

    DB.version = DB.version or 0
    if DB.version < DB_VERSION then
      DB.ui = DB.ui or {}
      DB.minimap = DB.minimap or {}
      DB.locked = false
      DB.toast = true
      DB.version = DB_VERSION
    end

    JoinChannel()
    CreateMinimapButton()
    RequestTimers()

    if type(RH_CreateUI) == "function" then
      RH_CreateUI()
    end
    if RH_UIFrame and RH_UIFrame.Show then
        RH_UIFrame:Show()
    end
    Delay(0.1, function()
        if RH_UIFrame and RH_UIFrame.Show then
            RH_UIFrame:Show()
        end
        if RallyHelperMinimapButton and RallyHelperMinimapButton.Show then
            RallyHelperMinimapButton:Show()
        end
    end)



  elseif event == "CHAT_MSG_CHANNEL" then
    HandleChannel(arg1, arg4)

  elseif event == "CHAT_MSG_MONSTER_YELL" then
    HandleYell(arg2, arg1)

  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "MERCHANT_SHOW" then
    TryDMF()
  end
end)
