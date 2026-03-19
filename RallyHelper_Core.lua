local RH_CHANNEL_NAME    = "RallyHelper"
local RH_VERIFY_WINDOW   = 30
local RH_VERIFY_REQUIRED = 2
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

local function IsInChannel()
  for i = 1, 10 do
    if GetChannelName(i) == RH_CHANNEL_NAME then return true end
  end
end

local function JoinChannel()
  if not IsInChannel() then JoinChannelByName(RH_CHANNEL_NAME) end
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
  if ev == "ONY_A" then DB.lastOnyA = ts end
  if ev == "ONY_H" then DB.lastOnyH = ts end
  if ev == "NEF_A" then DB.lastNefA = ts end
  if ev == "NEF_H" then DB.lastNefH = ts end
  if ev == "ZG"    then DB.lastZG   = ts end
  if ev == "DMF"   then DB.lastDMFTime = ts; DB.lastDMFZone = zone end
  if ev == "WB"    then DB.lastWB = ts; DB.lastWBZone = zone end

  if DB.toast then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RallyHelper]|r " .. ev .. " confirmed")
  end
end

local RH_Unconfirmed = {}

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

local function HandleChannel(msg, channel)
  if channel ~= RH_CHANNEL_NAME then return end
  if type(msg) ~= "string" then return end
  if not msg or msg == "" then return end

  local ev, ts, sender, zone = string.match(msg, "^([^|]+)|([^|]+)|([^|]+)|?(.*)$")
  if not ev or not ts or not sender then return end

  ts = tonumber(ts)
  if not ts then return end
  if zone == "" then zone = nil end

  RH_Users[sender] = time()

  if ev == "ZG" then
    AcceptEvent(ev, ts, zone)
    return
  end

  local ok, bestTs, bestZone = VerifyEvent(ev, ts, sender, zone)
  if ok then
    AcceptEvent(ev, bestTs, bestZone)
    RH_Unconfirmed[ev] = nil
    return
  end

  AddUnconfirmedEvent(ev, ts, sender, zone)
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
  if not npc or not msg then return end

  local lowerMsg = string.lower(msg)

  if npc == "Major Mattingly" and (lowerMsg:find("onyxia") or lowerMsg:find("slain") or lowerMsg:find("head")) then
    SendEvent("ONY_A")
    return
  end

  if npc == "Field Marshal Afrasiabi" and (lowerMsg:find("blackrock") or lowerMsg:find("nefarian") or lowerMsg:find("slain")) then
    SendEvent("NEF_A")
    return
  end

  if npc == "High Overlord Saurfang" and (lowerMsg:find("onyxia") or lowerMsg:find("slain")) then
    SendEvent("ONY_H")
    return
  end

  if npc == "Overlord Runthak" and (lowerMsg:find("blackrock") or lowerMsg:find("nefarian") or lowerMsg:find("slain")) then
    SendEvent("NEF_H")
    return
  end

  if npc == "Molthor" and (lowerMsg:find("hakkar") or lowerMsg:find("slayer of hakkar")) then
    AcceptEvent("ZG", time())
    SendEvent("ZG")
    return
  end

  if npc == "Thrall" and (lowerMsg:find("warchief") or lowerMsg:find("rend")) then
    SendEvent("WB", "Orgrimmar")
    return
  end
end



local function TryDMF()
  if UnitExists("target") and DMF_NPCS[UnitName("target")] then
    SendEvent("DMF", SafeZoneText())
  end
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
    DEFAULT_CHAT_FRAME:AddMessage("ZG: " .. (DB.lastZG and FormatAgo(DB.lastZG) or "unknown"))
    DEFAULT_CHAT_FRAME:AddMessage("DMF: " .. (DB.lastDMFTime and FormatAgo(DB.lastDMFTime) or "unknown"))
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

  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

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

  b:SetScript("OnMouseUp", function() b.isDown = false end)

  b:SetScript("OnClick", function()
    if arg1 == "RightButton" then PrintStatus(); return end
    if IsAltKeyDown() then
      if b.didDrag then b.didDrag = false; return end
      if type(RallyHelper_ToggleSizeUI) == "function" then RallyHelper_ToggleSizeUI() end
      return
    end
    if IsShiftKeyDown() then ShareTimersToChat(); return end
    if type(RallyHelper_ToggleUI) == "function" then RallyHelper_ToggleUI() end
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
  elseif event == "CHAT_MSG_CHANNEL" then
    HandleChannel(arg1, arg9)
  elseif event == "CHAT_MSG_MONSTER_YELL" then
    HandleYell(arg2, arg1)
  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "MERCHANT_SHOW" then
    TryDMF()
  end
end)
