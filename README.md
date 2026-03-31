#  **RallyHelper** — Modern World Buff Tracker for Turtle WoW

<img width="640" height="640" alt="RallyLogo" src="https://github.com/user-attachments/assets/d3519b5c-a137-4a76-ac6e-d33b8a07fffd" />

**RallyHelper** is a lightweight, modern, and reliable world buff tracker for Turtle WoW.  
It focuses on **accuracy**, **verification**, and **zero spam**, making it a clean alternative to older addons like PizzaWorldBuffs.

Version **1.4.0** introduces a completely redesigned UI, improved synchronization, and a new settings system.

---

## ✨ Key Features

### **✔ Verified world buff detection**
RallyHelper accepts buff events only after verification.  
The default requirement is **2 independent sources**, but **1‑source mode is temporarily enabled** in 1.4.0 to improve responsiveness during low‑population hours.

### **✔ Unconfirmed Buffs**
If only one source reports a buff, RallyHelper shows it as:

```
unconfirmed (12s ago)
```

This helps new users see activity even before full verification.

### **✔ Zero channel spam**
RallyHelper sends **only real events**:
- No heartbeats  
- No periodic updates  
- No version spam  
- No debug noise  

Just clean, minimal communication.

### **✔ Anonymous user count**
`/rally users` shows how many RallyHelper users were active in the last 60 seconds — anonymously.

### **✔ DMF detection**
Automatically detects Darkmoon Faire NPCs and records the last seen zone.

### **✔ New UI (1.4.0)**
- Fully redesigned layout  
- Faction‑colored sections  
- Icons for Ony/Nef/ZG/DMF/WB  
- Auto‑refresh every 0.4s  
- Resizable, scalable, draggable  
- pfUI‑compatible

### **✔ New Settings Window (1.4.0)**
- Faction filter (Horde / Alliance / Both)  
- UI width, height, scale  
- Lock UI  
- Buff sound toggle  
- Clean dialog‑style interface

### **✔ New Unconfirmed Window (1.4.0)**
- Scrollable list  
- Filters for Horde / Alliance / ZG / Warchief  
- Shows timestamp, zone, and source count  
- Helps diagnose incomplete confirmations

### **✔ Improved minimap button**
- Left‑click → toggle UI  
- Alt‑click → settings  
- Shift‑click → share timers  
- Middle‑click → unconfirmed  
- Right‑click → status  
- Alt‑drag → reposition

---

## 📦 Installation

1. Download the latest release ZIP.  
2. Extract into your `Interface/AddOns` folder.  
3. Ensure the folder name is **RallyHelper**.  
4. Restart the game.

---

## 🧭 Quick Commands

All commands start with:

```
/rally
```

### **Core**
- `/rally` — Toggle the main UI  
- `/rally status` — Print current timers  
- `/rally share` — Insert timers into chat edit box  
- `/rally request` — Request timers from other users  
- `/rally users` — Show number of active RallyHelper users  
- `/rally debug` — Toggle debug mode  

### **UI**
- `/rally lock` — Lock/unlock UI movement  
- `/rally reset` — Reset UI position and size  
- `/rally settings` — Open settings window  

### **Sound & notifications**
- `/rallysound on|off` — Enable/disable buff sounds  
- `/rallysound set <EVENT> <path>` — Custom sound file  
- `/rallysound volume <0-100>` — Set volume  
- `/rallytoast chat|ui|none` — Choose confirmation display  

### **Ignore**
- `/rallyignore add|remove|list <name>` — Ignore noisy senders  

---

## 📷 Screenshots

<img width="577" height="223" alt="new-UI" src="https://github.com/user-attachments/assets/ea17a747-a63b-44df-b019-3360719dfa4a" />

![Settings](https://github.com/user-attachments/assets/b092ca3e-c64e-4c23-b5dd-428e304e5181)



---

## 🧾 Changelog & Releases

Full changelog is available in **CHANGELOG.md**.  
See GitHub Releases for version history and downloads.

---

## ⚠️ Known Incompatibility

**LazyPig** modifies global string functions and chat handlers.  
If RallyHelper fails to sync or parse messages, try disabling LazyPig.

---

## ❤️ Support

RallyHelper is a free community addon.  
If you want to support development:

[https://ko-fi.com/weirdpuyppy94](https://ko-fi.com/weirdpuyppy94)

Support is optional and does not affect features or updates.

---

## 📜 License

MIT License — free to use, modify, and share.
