<img width="640" height="640" alt="RallyLogo" src="https://github.com/user-attachments/assets/d3519b5c-a137-4a76-ac6e-d33b8a07fffd" />


RallyHelper is a lightweight, modern and reliable world buff tracker for Turtle WoW.  
It focuses on **accuracy**, **verification**, and **zero spam**, making it a clean alternative to older addons like PizzaWorldBuffs.

---


## ✨ Features

### ✔ Verified World Buff Detection
RallyHelper only accepts world buff events when they are confirmed by multiple RallyHelper users.  
This prevents:
- fake timers  
- manipulated timestamps  
- false positives  
- addon spam  

### ✔ Unconfirmed Buffs (NEW in v1.0.1)
When only one source reports a buff, RallyHelper now shows a **preliminary timer** marked as:

```
unconfirmed (12s ago)
```

This helps new users understand that the addon is working even before enough RallyHelper users are online.

### ✔ Zero Channel Spam
RallyHelper sends **only real events**, never:
- heartbeats  
- version checks  
- periodic updates  
- map sync  
- debug spam  

This keeps the RallyHelper channel clean and efficient.

### ✔ Anonymous User Count (NEW)
Use:

```
/rally users
```

to see how many RallyHelper users are currently active.  
This is fully anonymous and requires no extra messages.

### ✔ DMF Detection
Automatically detects Darkmoon Faire NPCs and records the last seen location.

### ✔ Clean UI with pfUI Support
Resizable, movable, minimalistic UI with optional pfUI skinning.

---

## 📦 Installation

1. Download the latest release ZIP  
2. Extract it into your `Interface/AddOns` folder  
3. Ensure the folder name is **RallyHelper**  
4. Restart the game

---

## 🧭 Commands

```
/rally
```
Toggle the UI.

```
/rally status
```
Print timers in chat.

```
/rally share
```
Share timers to chat.

```
/rally users
```
Show number of active RallyHelper users (anonymous).

```
/rally lock
```
Lock or unlock the UI.

```
/rally reset
```
Reset UI position and settings.

---

# 🧾 **RallyHelper – Changelog**

## **v1.3.6 – Stability & Vanilla Compatibility Update**  
**Release:** 2026‑03‑22

### 🔧 **Fixes**
- Fixed a critical issue where `SetVerticalScroll(offset)` caused UI errors when opening the Unconfirmed window.  
  Root cause: Slider events fired before the ScrollFrame was fully initialized.
- Fixed a syntax error (`end expected near <eof>`) caused by a missing `end` in `CreateUnconfirmedUI()`.
- Fixed `RallyHelper_ToggleUI` being `nil` due to the file not loading past the syntax error.
- Fixed Vanilla/Turtle incompatibility in `CreateSizeUI()` (`SetPoint("CENTER")` → now uses full 5‑argument form).
- Fixed potential crash when the Unconfirmed list was empty (`i == 0`) by clamping slider values.
- Fixed negative scroll offsets in Vanilla by enforcing safe clamping in the slider handler.
- Fixed race condition where the ScrollFrame could be accessed before its ScrollChild existed.

### 🛡️ **Stability Improvements**
- Added fully defensive slider logic:
  - ignores nil offsets  
  - clamps negative values  
  - checks ScrollFrame + ScrollChild before scrolling  
  - prevents all known Vanilla scroll crashes
- MouseWheel handler now safely checks for slider existence.
- Unconfirmed UI now loads reliably even with zero events.
- Removed duplicate local variables and cleaned up function structure.

### 🧹 **Code Cleanup**
- Removed duplicate `local sizeUI` declaration.
- Removed stray or duplicated `end` blocks.
- Improved indentation and readability.
- Ensured ScrollFrame initialization order is fully Vanilla‑safe.

---

## **v1.3.0 – Unconfirmed UI Rework**

### ✨ **New**
- Added a complete Unconfirmed Events UI:
  - ScrollFrame with slider  
  - Filter checkboxes (Alliance, Horde, ZG, WB)  
  - Dynamic event list  
  - Clean pfUI‑compatible layout
- Added safer handling for unconfirmed world buff events.

### 🔧 **Fixes**
- Events now sort correctly by timestamp.
- Enforced a maximum of 20 entries to prevent overflow.
- Improved layout consistency and text alignment.

---

## **v1.2.0 – Sync & RHGlobal Stabilization**

### ✨ **New**
- Introduced `RHGlobal.Unconfirmed` as a persistent global storage.
- Added support for solo players without LFT channel.
- Added dedicated `RallyDebug` channel for clean debugging.

### 🔧 **Fixes**
- Resolved sync issues caused by TurtleWoW system channels.
- Improved event parsing and validation.
- Ensured events are received even when not in LFT.

### 🧹 **Cleanup**
- Removed outdated sync logic.
- Unified event handling and storage.

---

## ⚠️ Known Incompatibility: LazyPig

Some users have reported that **LazyPig** interferes with RallyHelper’s functionality.

### Observed symptoms:
- Timers not being shared  
- Confirm events not being processed  
- REQ/TIMER sync not working reliably  

### Possible cause:
LazyPig modifies or hooks into:

- global `string.*` functions  
- chat event handlers  
- channel parsing logic  

These modifications can disrupt RallyHelper’s event parsing and verification logic.

### Recommendation:
If RallyHelper does not synchronize timers correctly, try **disabling LazyPig**.  
This issue may be caused either by LazyPig itself or by the combination of LazyPig’s hooks with RallyHelper’s new defensive code.

---

## ❤️ Final Notes
RallyHelper remains intentionally lightweight, transparent, and community‑friendly.  
All new features are designed to be safe, predictable, and resistant to manipulation — without relying on server time tricks or hidden logic.


---


## 🙌 Inspiration

RallyHelper was inspired by the long‑standing PizzaWorldBuffs addon, which served the community for many years.  
This project builds on that idea with a modern, verified and spam‑free approach tailored for Turtle WoW.


## ❤️ Support

RallyHelper is a free community addon.  
If you enjoy it and want to support development, you can do so here:

https://ko-fi.com/weirdpuyppy94

Any support is greatly appreciated.
I’m currently going through a financially challenging period, and contributions help me continue maintaining and improving this project.

Support is completely optional and has no impact on features or updates.

---

## 📜 License

MIT License  
Free to use, modify and share.
```

