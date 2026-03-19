# RallyHelper

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

## 🆕 Changelog

### **v1.0.1 — Stability & Early Adoption Update**

**Fixes**
- Resolved a Lua error caused by malformed addon messages in the RallyHelper channel  
- Hardened message parsing to prevent crashes from invalid or unexpected data  
- Improved Horde/Alliance yell handling for Ony, Nef, ZG, WB  

**New**
- Added *Unconfirmed Buffs*: preliminary timers shown when receiving unverified data  
- Added `/rally users` to display the number of active RallyHelper users (anonymous)  

**Improvements**
- More reliable event handling and zone normalization  
- Cleaner UI updates and better feedback during low‑population usage  
- Increased stability in busy cities and during world buff spam  

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

