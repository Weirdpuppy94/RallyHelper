-- RallyHelper_Core v 1.4.0 (Hotfix)

local RH_CHANNEL_NAME    = "RallyHelper"
local RH_VERIFY_WINDOW   = 30
local RH_VERIFY_REQUIRED = 1
local RH_VERIFY_REQUIRED_REQUEST = 5
local RH_SEND_THROTTLE   = 20

local ONY_CD = 2 * 60 * 60
local NEF_CD = 2 * 60 * 60
local WB_CD  = 3 * 60 * 60
local WB_WARN_DELAY = 6

local DB_VERSION = 2
local CHAR_DB_VERSION = 1
local ADDON_VERSION = 2
local MIN_ACCEPTED_VERSION = 2

local DB
local CharDB
local verify = {}
local RH_Users = {}
local lastSend = {}
local RH_LocalDetected = {}
local LOCAL_DETECT_WINDOW = 2.0

local str = _G.string or string
local strmatch = str.match or function() return nil end
local strfind  = str.find  or function() return nil end
local strlower = str.lower or function(s) return s end
local strsub   = str.sub   or function(s, i, j) return s end
local strlen   = str.len   or function(s) return 0 end
local strgsub  = str.gsub  or function(s) return s end

local floor = math.floor

RHGlobal = RHGlobal or {}
RH_TimerResponses = RH_TimerResponses or {}
RH_TimerResponseTimers = RH_TimerResponseTimers or {}
local TIMER_RESPONSE_WINDOW = 2.0
RHGlobal.Unconfirmed = RHGlobal.Unconfirmed or {}
local RH_Unconfirmed = RHGlobal.Unconfirmed
local RH_ClockOffset = RH_ClockOffset or {}

local function EnsureDB()
  DB = RallyHelperDB or {}
  RallyHelperDB = DB

  DB.version = DB.version or 0
  if DB.version < DB_VERSION then
    DB.ui      = DB.ui or {}
    DB.minimap = DB.minimap or {}
    DB.locked  = false
    DB.toast   = true
    DB.version = DB_VERSION
  end

  DB.rhSounds = DB.rhSounds or {}
  DB.rhSounds.enabled = (DB.rhSounds.enabled == nil) and true or DB.rhSounds.enabled
  DB.rhSounds.volume  = DB.rhSounds.volume or 100
  DB.rhSounds.files   = DB.rhSounds.files or {
    ONY_A = "Sound\\Interface\\PVPFlagTakenHordeMono.wav",
    NEF_A = "Sound\\Interface\\PVPFlagTakenHordeMono.wav",
    ONY_H = "Sound\\Interface\\PVPFlagTakenHordeMono.wav",
    NEF_H = "Sound\\Interface\\PVPFlagTakenHordeMono.wav",
    WB    = "Sound\\Interface\\PVPFlagTakenHordeMono.wav",
    ZG    = "Sound\\Interface\\PVPFlagTakenHordeMono.wav",
  }
  DB.toastMode = DB.toastMode or "none"  -- "chat" | "ui" | "none"
  DB.rhIgnore  = DB.rhIgnore or {}
  DB.debug = DB.debug or false
end

local function EnsureCharDB()
  CharDB = RallyHelperCharDB or {}
  RallyHelperCharDB = CharDB

  CharDB.version = CharDB.version or 0
  if CharDB.version < CHAR_DB_VERSION then
    CharDB.version = CHAR_DB_VERSION
  end

  CharDB.factionFilter = CharDB.factionFilter or nil
  CharDB.ui = CharDB.ui or {}
  CharDB.locked = (CharDB.locked == nil) and false or CharDB.locked
end

local function GetFactionFilter()
  if not CharDB then return "BOTH" end
  return CharDB.factionFilter or "BOTH"
end

local function SetFactionFilter(faction)
  if not CharDB then return end
  if faction == "HORDE" or faction == "ALLIANCE" or faction == "BOTH" then
    CharDB.factionFilter = faction
    if type(RallyHelper_UpdateUI) == "function" then
      RallyHelper_UpdateUI()
    end
  end
end

_G.RH_GetFactionFilter = GetFactionFilter
_G.RH_SetFactionFilter = SetFactionFilter

local function ShouldShowEvent(ev)
  local filter = GetFactionFilter()
  if filter == "BOTH" then return true end
  
  if filter == "HORDE" then
    if ev == "ONY_A" or ev == "NEF_A" then return false end
    return true
  end
  
  if filter == "ALLIANCE" then
    if ev == "ONY_H" or ev == "NEF_H" or ev == "WB" then return false end
    return true
  end
  
  return true
end

_G.RH_ShouldShowEvent = ShouldShowEvent

local function SanitizeChat(msg)
  if not msg then return "" end
  msg = strgsub(msg, "%%", "%%%%")
  msg = strgsub(msg, "|", "||")
  return msg
end

local function FormatAgo(ts)
  if not ts then return "unknown" end
  local d = time() - ts
  if d < 60    then return d .. "s ago" end
  if d < 3600  then return floor(d / 60) .. "m ago" end
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

local function SendEvent(ev, zone, ts)
  EnsureChannel()
  if not CanSend(ev) then return end

  local cid = GetChannelId()
  if not cid then return end

  local player = UnitName("player") or "?"
  local sep = "^"
  ts = ts or time()
  local msg = ev .. sep .. tostring(ts) .. sep .. player
  if zone and zone ~= "" then
    msg = msg .. sep .. zone
  end
  msg = msg .. sep .. "v" .. tostring(ADDON_VERSION)


  pcall(function()
    SendChatMessage(SanitizeChat(msg), "CHANNEL", nil, cid)
  end)
end


local function ScheduleAfter(sec, fn)
  if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
    C_Timer.After(sec, fn)
  else
    Delay(sec, fn)
  end
end


function RespondToRequest()
  EnsureChannel()
  if not CanSend("TIMER_REQ") then return end

  local now = time()

  local ONY_TOLERANCE = 30 * 60   
  local WB_TOLERANCE  = 6 * 3600  
  local EVENT_MAX_AGE = 24 * 3600 

  local sends = {}  

  local function pushIfValid(ev, ts, zone, cooldown, tolerance, eventMaxAge)
    if not ts or type(ts) ~= "number" then return end
    if ts <= 0 then return end
    local age = now - ts
    if cooldown and type(cooldown) == "number" then
      local allowed = cooldown + (tolerance or 0)
      if age > allowed then
        return
      end
    else
      if eventMaxAge and age > eventMaxAge then
        return
      end
    end
    table.insert(sends, function() SendEvent("TIMER_"..ev, zone or "", ts) end)
  end

  pushIfValid("ONY_A", DB and DB.lastOnyA, nil,               ONY_CD, ONY_TOLERANCE, nil)
  pushIfValid("ONY_H", DB and DB.lastOnyH, nil,               ONY_CD, ONY_TOLERANCE, nil)
  pushIfValid("NEF_A", DB and DB.lastNefA, nil,               NEF_CD, ONY_TOLERANCE, nil)
  pushIfValid("NEF_H", DB and DB.lastNefH, nil,               NEF_CD, ONY_TOLERANCE, nil)
  pushIfValid("WB",    DB and DB.lastWB,   DB and DB.lastWBZone,  WB_CD, WB_TOLERANCE, nil)
  pushIfValid("ZG",    DB and DB.lastZG,   nil,               nil,    nil,            EVENT_MAX_AGE)
  pushIfValid("DMF",   DB and DB.lastDMFTime, DB and DB.lastDMFZone, nil, nil,        EVENT_MAX_AGE)

  if next(sends) == nil then
    return
  end

  for i, fn in ipairs(sends) do
    local idx    = i
    local fnLocal = fn
    ScheduleAfter((idx - 1) * 0.12, function()
      if type(fnLocal) == "function" then pcall(fnLocal) end
    end)
  end

  ScheduleAfter(1.6, function()
    for i, fn in ipairs(sends) do
      local idx    = i
      local fnLocal = fn
      ScheduleAfter((idx - 1) * 0.12, function()
        if type(fnLocal) == "function" then pcall(fnLocal) end
      end)
    end
  end)
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

  local adjusted = ts
  if RH_ClockOffset and RH_ClockOffset[sender] then
    adjusted = ts + RH_ClockOffset[sender]
  end

  table.insert(list, { ts = ts, adj = adjusted, sender = sender, zone = zone or "" })

  if table.getn(list) >= required then
    local bestAdj, bestZone = -1, ""
    for _, v in ipairs(list) do
      if v.adj > bestAdj then bestAdj = v.adj end
    end

    local chosenOriginalTs = 0
    for _, v in ipairs(list) do
      if v.adj == bestAdj then
        chosenOriginalTs = v.ts
        if v.zone ~= "" then bestZone = v.zone end
      end
    end

    verify[ev] = nil
    return true, chosenOriginalTs, bestZone
  end
end

local function AcceptEvent(ev, ts, zone)
  local now = time()
  if not ts or ts <= 0 then return end
  if ts < (now - 30 * 24 * 3600) then
    return
  end
  if ts > (now + 3600) then
    return
  end

  if ev == "ONY_A" then DB.lastOnyA   = ts end
  if ev == "ONY_H" then DB.lastOnyH   = ts end
  if ev == "NEF_A" then DB.lastNefA   = ts end
  if ev == "NEF_H" then DB.lastNefH   = ts end
  if ev == "ZG"    then DB.lastZG     = ts end
  if ev == "DMF"   then DB.lastDMFTime = ts; DB.lastDMFZone = zone end
  if ev == "WB"    then DB.lastWB = ts; DB.lastWBZone = zone end

  RH_Unconfirmed[ev] = nil

  if DB and DB.toastMode then
    if DB.toastMode == "chat" then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RallyHelper]|r " .. ev .. " confirmed")
    elseif DB.toastMode == "ui" then
      if type(RallyHelper_ShowToast) == "function" then
        RallyHelper_ShowToast(ev .. " confirmed")
      end
    end
  end

  if type(RallyHelper_UpdateUI) == "function" then
    RallyHelper_UpdateUI()
  end
end

local function AddUnconfirmedEvent(ev, ts, sender, zone)
  RH_Unconfirmed[ev] = {
    ts     = ts,
    sender = sender,
    zone   = zone,
    time   = time(),
  }

  if type(RallyHelper_UpdateUI) == "function" then
    RallyHelper_UpdateUI()
  end
end

local function CountUsers()
  local now   = time()
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

local function DetectMasterVolumeCVar()
  local candidates = { "Sound_MasterVolume", "MasterSound", "Sound_MasterVolumeDB" }
  for _, name in ipairs(candidates) do
    local ok, val = pcall(GetCVar, name)
    if ok and val ~= nil then return name end
  end
  return nil
end

local _RH_MasterCVar = DetectMasterVolumeCVar()

local function SetMasterVolumePercent(percent)
  if type(percent) ~= "number" then return nil end
  if not _RH_MasterCVar then return nil end
  percent = math.max(0, math.min(100, percent))
  local ok, prev = pcall(GetCVar, _RH_MasterCVar)
  if not ok or prev == nil then return nil end
  local prevPercent = math.floor((tonumber(prev) or 1) * 100 + 0.5)
  local sOk = pcall(SetCVar, _RH_MasterCVar, tostring(percent / 100))
  if not sOk then return nil end
  return prevPercent
end

local function RestoreMasterVolume(percent)
  if type(percent) ~= "number" then return false end
  if not _RH_MasterCVar then return false end
  return pcall(SetCVar, _RH_MasterCVar, tostring(percent / 100))
end

local function TryPlayFile(path)
  if not path or path == "" then
    return false
  end
  if type(PlaySoundFile) ~= "function" then
    return false
  end
  local ok, err = pcall(function() PlaySoundFile(path, "Master") end)
  return ok
end

local function TryPlaySoundkitFor(ev)
  if type(PlaySound) ~= "function" then
    return false
  end
  if type(SOUNDKIT) ~= "table" then
    return false
  end

  local ok = false
  if (ev == "ONY_A" or ev == "NEF_A") and SOUNDKIT.RAID_WARNING then
    ok = pcall(function() PlaySound(SOUNDKIT.RAID_WARNING) end)
  elseif (ev == "ONY_H" or ev == "NEF_H") and SOUNDKIT.IG_QUEST_LIST_UPDATE then
    ok = pcall(function() PlaySound(SOUNDKIT.IG_QUEST_LIST_UPDATE) end)
  elseif ev == "WB" and SOUNDKIT.UI_BATTLEGROUND_COUNTDOWN_TIMER then
    ok = pcall(function() PlaySound(SOUNDKIT.UI_BATTLEGROUND_COUNTDOWN_TIMER) end)
  elseif ev == "ZG" and SOUNDKIT.UI_RAID_BOSS_WHISPER then
    ok = pcall(function() PlaySound(SOUNDKIT.UI_RAID_BOSS_WHISPER) end)
  end

  return ok
end

local function PlayBuffSoundFor(ev)
  if not (DB and DB.rhSounds and DB.rhSounds.enabled) then return end

  local file = DB.rhSounds.files and DB.rhSounds.files[ev]

  local desired = tonumber(DB.rhSounds.volume) or 100
  local prev = nil
  if desired >= 0 and desired <= 100 then
    prev = SetMasterVolumePercent(desired)
  end

  local played = false
  if file then played = TryPlayFile(file) end
  if not played then TryPlaySoundkitFor(ev) end

  if prev ~= nil then
    ScheduleAfter(0.2, function() RestoreMasterVolume(prev) end)
  end
end

do
  local _origAccept = AcceptEvent
  AcceptEvent = function(ev, ts, zone)
    _origAccept(ev, ts, zone)

    local now = time()
    local detectedUntil = RH_LocalDetected[ev]
    if detectedUntil and now <= detectedUntil then
      PlayBuffSoundFor(ev)
      RH_LocalDetected[ev] = nil
    end
  end
end

_G.RH_DebugAcceptEvent = AcceptEvent
_G.RH_TestPlay = function(ev) pcall(function() PlayBuffSoundFor(ev) end) end

SLASH_RALLYSOUND1 = "/rallysound"
SlashCmdList["RALLYSOUND"] = function(msg)
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""
  if cmd == "on" then
    DB.rhSounds.enabled = true
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Sounds enabled")
  elseif cmd == "off" then
    DB.rhSounds.enabled = false
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Sounds disabled")
  elseif cmd == "set" and arg and arg ~= "" then
    local ev, path = arg:match("^(%S+)%s+(.+)$")
    if ev and path and DB.rhSounds.files then
      DB.rhSounds.files[ev] = path
      DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Set sound for "..ev)
    else
      DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Usage: /rallysound set <EVENT> <path>")
    end
  elseif cmd == "volume" and arg ~= "" then
    local v = tonumber(arg)
    if v and v >= 0 and v <= 100 then
      DB.rhSounds.volume = v
      DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Sound volume set to "..tostring(v))
    else
      DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Usage: /rallysound volume <0-100>")
    end
  else
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Commands: on, off, set <EVENT> <path>, volume <0-100>")
  end
end

SLASH_RALLYTOAST1 = "/rallytoast"
SlashCmdList["RALLYTOAST"] = function(msg)
  local m = (msg or ""):lower()
  if m == "chat" or m == "ui" or m == "none" then
    DB.toastMode = m
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] toastMode set to "..m)
  else
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Usage: /rallytoast chat|ui|none")
  end
end

SLASH_RALLYIGNORE1 = "/rallyignore"
SlashCmdList["RALLYIGNORE"] = function(msg)
  local cmd, name = msg:match("^(%S*)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""
  if cmd == "add" and name ~= "" then
    DB.rhIgnore = DB.rhIgnore or {}
    DB.rhIgnore[name] = true
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Ignored "..name)
  elseif cmd == "remove" and name ~= "" then
    DB.rhIgnore = DB.rhIgnore or {}
    DB.rhIgnore[name] = nil
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Unignored "..name)
  elseif cmd == "list" then
    DB.rhIgnore = DB.rhIgnore or {}
    for n, _ in pairs(DB.rhIgnore) do DEFAULT_CHAT_FRAME:AddMessage(n) end
  else
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Usage: /rallyignore add|remove|list <name>")
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
  local clean = NormalizeChannelName(channel)
  if clean ~= strlower(RH_CHANNEL_NAME) then return end
  if type(msg) ~= "string" or msg == "" then return end

  local function SplitMessage(m)
    local out, current = {}, ""
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

  local parts       = SplitMessage(msg)
  local ev          = parts[1]
  local ts          = tonumber(parts[2])
  local sender      = parts[3]
  local zone        = parts[4]
  local verPart     = parts[5]
  local senderVersion = nil

  if type(verPart) == "string" then
    local v = strmatch(verPart, "^v(%d+)$")
    if v then senderVersion = tonumber(v) end
  end

  RH_ClockOffset = RH_ClockOffset or {}
  local now = time()

  if ts and sender then
    local offset = now - ts
    RH_ClockOffset[sender] = (RH_ClockOffset[sender] or offset) * 0.8 + offset * 0.2
  end

  if not ev or not ts or not sender then return end
  if zone == "" then zone = nil end

  RH_Users[sender] = time()

  if DB and DB.rhIgnore and DB.rhIgnore[sender] then
    if DB and DB.debug then DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[RH]|r Ignoring sender "..sender) end
    return
  end

  if ev == "REQ" then
    local myName = UnitName("player") or ""
    if sender == myName then
      return
    end
    if type(RespondToRequest) == "function" then
      RespondToRequest()
    end
    return
  end

  if strsub(ev, 1, 6) == "TIMER_" then
    local realEv = strsub(ev, 7)
    RH_TimerResponses[realEv] = RH_TimerResponses[realEv] or {}

    local adjusted = ts
    if RH_ClockOffset and RH_ClockOffset[sender] then
      adjusted = ts + RH_ClockOffset[sender]
    end

    table.insert(RH_TimerResponses[realEv], {
      ts     = ts,
      adj    = adjusted,
      sender = sender,
      zone   = zone,
      ver    = senderVersion or 0,
    })

    if not RH_TimerResponseTimers[realEv] then
      RH_TimerResponseTimers[realEv] = true
      ScheduleAfter(TIMER_RESPONSE_WINDOW, function()

        local now = time()

        local list = RH_TimerResponses[realEv] or {}
        if next(list) == nil then
          RH_TimerResponses[realEv]      = nil
          RH_TimerResponseTimers[realEv] = nil
          return
        end

        local filtered = {}
        for _, v in ipairs(list) do
          if (v.ver or 0) >= MIN_ACCEPTED_VERSION then
            table.insert(filtered, v)
          end
        end
        if next(filtered) == nil then filtered = list end

        local bestIdx, bestDiff, bestTs, bestZone = nil, nil, 0, ""
        for i, v in ipairs(filtered) do
          local adj  = v.adj or v.ts
          local diff = math.abs(adj - now)
          if bestDiff == nil or diff < bestDiff then
            bestDiff = diff
            bestIdx  = i
            bestTs   = v.ts or 0
            bestZone = v.zone or ""
          elseif diff == bestDiff and (v.zone or "") ~= "" then
            bestIdx  = i
            bestTs   = v.ts or 0
            bestZone = v.zone or ""
          end
        end

        if bestIdx and bestDiff and bestDiff < (7 * 24 * 3600) and bestTs > 0 then
          AcceptEvent(realEv, bestTs, bestZone)
        else
        end

        RH_TimerResponses[realEv]      = nil
        RH_TimerResponseTimers[realEv] = nil
      end)
    end
    return
  end

  if ev == "ZG" then
    AcceptEvent(ev, ts, zone)
    return
  end

  if ev == "DMF" then
    AcceptEvent(ev, ts, zone)
    return
  end

  local required = RH_VERIFY_REQUIRED
  local ok, bestTs, bestZone = VerifyEvent(ev, ts, sender, zone, required)
  if ok then
    AcceptEvent(ev, bestTs, bestZone)
    RH_Unconfirmed[ev] = nil
    return
  end

  AddUnconfirmedEvent(ev, ts, sender, zone)
end

local function HandleYell(npc, msg)
  if type(npc) ~= "string" or type(msg) ~= "string" then return end

  local lowerMsg = string.lower(msg)
  local function has(s) return string.find(lowerMsg, s, 1, true) ~= nil end

  if npc == "Major Mattingly" and (has("onyxia") or has("head")) then
    RH_LocalDetected["ONY_A"] = time() + LOCAL_DETECT_WINDOW
    AcceptEvent("ONY_A", time())
    SendEvent("ONY_A")
    return
  end

  if npc == "Field Marshal Afrasiabi" and (has("nefarian") or has("blackrock")) then
    RH_LocalDetected["NEF_A"] = time() + LOCAL_DETECT_WINDOW
    AcceptEvent("NEF_A", time())
    SendEvent("NEF_A")
    return
  end

  if npc == "High Overlord Saurfang" and (has("onyxia") or has("brood mother")) then
    RH_LocalDetected["ONY_H"] = time() + LOCAL_DETECT_WINDOW
    AcceptEvent("ONY_H", time())
    SendEvent("ONY_H")
    return
  end

  if npc == "High Overlord Saurfang" and (has("nefarian") or has("blackrock")) then
    RH_LocalDetected["NEF_H"] = time() + LOCAL_DETECT_WINDOW
    AcceptEvent("NEF_H", time())
    SendEvent("NEF_H")
    return
  end

  if npc == "Overlord Runthak" then
    if has("onyxia") or has("brood mother") then
      RH_LocalDetected["ONY_H"] = time() + LOCAL_DETECT_WINDOW
      AcceptEvent("ONY_H", time())
      SendEvent("ONY_H")
      return
    end
    if has("nefarian") or has("blackrock") then
      RH_LocalDetected["NEF_H"] = time() + LOCAL_DETECT_WINDOW
      AcceptEvent("NEF_H", time())
      SendEvent("NEF_H")
      return
    end
    return
  end

  if npc == "Molthor" and (has("hakkar") or has("slayer of hakkar")) then
    RH_LocalDetected["ZG"] = time() + LOCAL_DETECT_WINDOW
    AcceptEvent("ZG", time())
    SendEvent("ZG")
    return
  end

  if npc == "Thrall" and (has("warchief") or has("rend")) then
    RH_LocalDetected["WB"] = time() + LOCAL_DETECT_WINDOW
    AcceptEvent("WB", time(), "Orgrimmar")
    SendEvent("WB", "Orgrimmar")
    return
  end
end

local DMF_NPCS = {
  ["Sayge"]                    = true,
  ["Professor Thaddeus Paleo"] = true,
  ["Gelvas Grimegate"]         = true,
  ["Stamp Thunderhorn"]        = true,
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
      if not DB.lastDMFTime or (time() - DB.lastDMFTime) > 5 then
        RH_LocalDetected["DMF"] = time() + LOCAL_DETECT_WINDOW
        AcceptEvent("DMF", time(), zone)
        SendEvent("DMF", zone)
      end
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
    local a   = DB.minimap.angle or 220
    local rad = a * 0.01745329252
    local r   = 80
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * r, math.sin(rad) * r)
  end

  local function CursorUI()
    local scale = UIParent:GetEffectiveScale()
    local x, y  = GetCursorPosition()
    return x / scale, y / scale
  end

  b.isDown  = false
  b.altDown = false
  b.didDrag = false
  b.downX, b.downY = 0, 0

  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(b, "ANCHOR_LEFT")
    GameTooltip:AddLine("RallyHelper")
    GameTooltip:AddLine("Left Click: Toggle UI")
	GameTooltip:AddLine("Alt + Click: Settings")
    GameTooltip:AddLine("Right Click: Status")
    GameTooltip:AddLine("Shift + Left: Share timers")
    GameTooltip:AddLine("Middle Mouse: Unconfirmed Buffs")
    GameTooltip:Show()
  end)

  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  b:SetScript("OnMouseDown", function()
    if arg1 ~= "LeftButton" then return end
    b.isDown  = true
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
    if arg1 == "MiddleButton" then
      RallyHelper_ToggleUnconfirmed()
      return
    end
    if arg1 == "RightButton" then
      PrintStatus()
      return
    end
    if IsAltKeyDown() then
      if b.didDrag then b.didDrag = false; return end
      RallyHelper_ToggleSettings()
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
    CharDB.ui = nil
    ReloadUI()
  elseif msg == "toast" then
    DB.toast = not DB.toast
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Toast messages: " .. tostring(DB.toast))
  elseif msg == "lock" then
    CharDB.locked = not CharDB.locked
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] UI lock: " .. tostring(CharDB.locked))
  elseif msg == "users" then
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Users online: " .. CountUsers())
  elseif msg == "debug" then
    DB.debug = not DB.debug
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Debug: " .. tostring(DB.debug))
    DEFAULT_CHAT_FRAME:AddMessage("ZG: "  .. (DB.lastZG      and FormatAgo(DB.lastZG)      or "unknown"))
    DEFAULT_CHAT_FRAME:AddMessage("DMF: " .. (DB.lastDMFTime and FormatAgo(DB.lastDMFTime) or "unknown"))
  elseif msg == "request" then
    RequestTimers()
    DEFAULT_CHAT_FRAME:AddMessage("[RallyHelper] Requested timers from channel")
  elseif msg == "settings" or msg == "config" or msg == "options" then
    RallyHelper_ToggleSettings()
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
  
local function RH_RemoveChannelFromChatFrames()
  local name = RH_CHANNEL_NAME or "RallyHelper"
  local max = tonumber(NUM_CHAT_WINDOWS) or 10
  local i = 1

  while i <= max do
    local cf = _G["ChatFrame"..i]
    if cf and cf.RemoveChannel then
      pcall(function()
        cf:RemoveChannel(name)
      end)
    end
    i = i + 1
  end
end


ScheduleAfter(0.5, HookRallyHelperChatFrames)

    if type(EnsureDB) == "function" then pcall(EnsureDB) end
    if type(EnsureCharDB) == "function" then pcall(EnsureCharDB) end

    JoinChannel()
    CreateMinimapButton()

    ScheduleAfter(3, function()
      local now     = time()
      local MAX_AGE = 7 * 24 * 3600
      local hasValid = DB and (
        (DB.lastOnyA    and DB.lastOnyA    > 0 and (now - DB.lastOnyA)    < MAX_AGE) or
        (DB.lastOnyH    and DB.lastOnyH    > 0 and (now - DB.lastOnyH)    < MAX_AGE) or
        (DB.lastNefA    and DB.lastNefA    > 0 and (now - DB.lastNefA)    < MAX_AGE) or
        (DB.lastNefH    and DB.lastNefH    > 0 and (now - DB.lastNefH)    < MAX_AGE) or
        (DB.lastZG      and DB.lastZG      > 0 and (now - DB.lastZG)      < MAX_AGE) or
        (DB.lastWB      and DB.lastWB      > 0 and (now - DB.lastWB)      < MAX_AGE) or
        (DB.lastDMFTime and DB.lastDMFTime > 0 and (now - DB.lastDMFTime) < MAX_AGE)
      )

        RequestTimers()
    end)

    if type(RH_CreateUI) == "function" then RH_CreateUI() end

    if CharDB and CharDB.factionFilter == nil then
      ScheduleAfter(2, function()
        if type(RallyHelper_ShowFirstTimeSetup) == "function" then
          RallyHelper_ShowFirstTimeSetup()
        end
      end)
    end

    if RH_UIFrame and RH_UIFrame.Show then RH_UIFrame:Show() end

    Delay(0.1, function()
      if RH_UIFrame and RH_UIFrame.Show then RH_UIFrame:Show() end
      if RallyHelperMinimapButton and RallyHelperMinimapButton.Show then
        RallyHelperMinimapButton:Show()
      end
    end)

  elseif event == "CHAT_MSG_CHANNEL" then
    HandleChannel(arg1, arg9)

  elseif event == "CHAT_MSG_MONSTER_YELL" then
    HandleYell(arg2, arg1)

  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "MERCHANT_SHOW" then
    TryDMF()
  end
end)

local orig_AddMessage = ChatFrame1.AddMessage

ChatFrame1.AddMessage = function(self, msg, r, g, b, id)
  if type(msg) == "string" and string.find(string.lower(msg), string.lower(RH_CHANNEL_NAME)) then
    return
  end

  return orig_AddMessage(self, msg, r, g, b, id)
end
