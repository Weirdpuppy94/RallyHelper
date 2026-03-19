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

---

# **RallyHelper 1.1.0 – Changelog**

### **✨ New Features**
- **Fully redesigned UI**
  - Cleaner layout with improved readability  
  - Color‑coded timers for faster recognition  
  - Updated icons for Onyxia, Nefarian, and Warchief’s Blessing  
- **New Size Configuration Window**
  - Adjust width, height, and scale  
  - Live preview while dragging sliders  
  - Perfect compatibility with pfUI  
- **Improved Minimap Button**
  - **Alt + Drag** to reposition  
  - **Shift + Left‑Click** to share timers in chat  
  - **Right‑Click** for quick status output  
  - **Alt + Left‑Click** opens the size configuration window  

### **🔧 Improvements**
- Complete internal code restructuring (Core + UI)  
- More reliable world buff detection and verification  
- Improved Darkmoon Faire detection  
- Optimized OnUpdate loop (reduced CPU usage)  
- Better pfUI skin integration  
- Cleaner SavedVariables structure  
- More robust channel handling and throttling  

### **🐞 Bug Fixes**
- Fixed Lua syntax issues caused by duplicated `end` blocks  
- Fixed minimap button position not saving correctly  
- Fixed UI flickering on mouseover  
- Fixed incorrect or missing DMF zone display  
- Fixed occasional “unknown” timer values  
- Fixed issues on first load after installation  

### **📦 Other**
- Fully Vanilla‑Lua compatible  
- Verified working on Turtle WoW 1.17+  
- Updated README  
- Codebase prepared for future modules and expansions  


---

## ❓ Why RallyHelper?

Older addons like PizzaWorldBuffs accept **any** message from **any** source, which leads to:
- false timers  
- manipulated timestamps  
- channel spam  
- inconsistent data  

RallyHelper solves this by using:
- verification  
- clean communication  
- modern Lua patterns  
- zero spam  
- robust parsing  

It is designed for **accuracy first**, especially on a server like Turtle WoW where reliability matters.

---


## 🙌 Inspiration

RallyHelper was inspired by the long‑standing PizzaWorldBuffs addon, which served the community for many years.  
This project builds on that idea with a modern, verified and spam‑free approach tailored for Turtle WoW.


## ❤️ Support

RallyHelper is a free community addon.  
If you enjoy it and want to support development, you can do so here:

https://ko-fi.com/weirdpuyppy94
*(optional, no pressure — the addon will always remain free)*

---

## 📜 License

MIT License  
Free to use, modify and share.
```

