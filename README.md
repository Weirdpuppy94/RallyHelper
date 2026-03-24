<img width="640" height="640" alt="RallyLogo" src="https://github.com/user-attachments/assets/d3519b5c-a137-4a76-ac6e-d33b8a07fffd" />

**RallyHelper** is a lightweight, modern and reliable world buff tracker for Turtle WoW.  
It focuses on **accuracy**, **verification**, and **zero spam**, making it a clean alternative to older addons like PizzaWorldBuffs.

---

## ✨ Key features

- **Verified world buff detection**  
  Only accepts world buff events after verification by multiple RallyHelper users to prevent fake timers, manipulated timestamps and false positives.

- **Unconfirmed Buffs**  
  Shows preliminary timers when a single source reports a buff, marked as `unconfirmed (12s ago)` so new users can see the addon working before full verification.

- **Zero channel spam**  
  Sends only real events — no heartbeats, version checks, periodic updates or debug spam.

- **Anonymous user count**  
  `/rally users` shows how many RallyHelper users were active in the last 60 seconds (anonymous).

- **DMF detection**  
  Automatically detects Darkmoon Faire NPCs and records the last seen location.

- **Minimal, resizable UI**  
  Clean UI with optional pfUI skin compatibility.

---

## 📦 Installation

1. Download the latest release ZIP.  
2. Extract into your `Interface/AddOns` folder.  
3. Ensure the folder name is **RallyHelper**.  
4. Restart the game.

---

## 🧭 Quick commands

All commands start with:

/rally


**Core**
- `/rally` — Toggle the main UI.  
- `/rally status` — Print current timers to chat.  
- `/rally share` — Insert your timers into the chat edit box for manual posting.  
- `/rally request` — Request timers from other RallyHelper users.  
- `/rally users` — Show number of active RallyHelper users (anonymous).

**UI**
- `/rally lock` — Toggle UI lock (lock/unlock movement).  
- `/rally reset` — Reset UI position and size.  
- `/rally debug` — Toggle debug output (for troubleshooting).

**Sound & notifications**
- `/rallysound on|off` — Enable/disable buff sounds.  
- `/rallysound set <EVENT> <path>` — Set a custom sound file for an event.  
- `/rallysound volume <0-100>` — Set playback volume percent.  
- `/rallytoast chat|ui|none` — Choose how confirmations are shown (chat, UI toast, or none).

**Ignore**
- `/rallyignore add|remove|list <name>` — Temporarily ignore noisy or buggy senders.

---

## 📷 Screenshot


![Screenshot RallyHelper](https://github.com/user-attachments/assets/3b09776f-a457-496e-91e1-aee7f5766dcb)


> Tip: store images in `assets/` and reference them with relative paths so they render correctly on GitHub.

---

## 🧾 Changelog & Releases

Full changelog is maintained in `CHANGELOG.md`. See the latest release notes on the GitHub Releases page.

---

## ⚠️ Known incompatibility

**LazyPig** has been reported to interfere with RallyHelper (modifies global string functions and chat handlers). If sync fails, try disabling LazyPig.

---

## ❤️ Support

RallyHelper is a free community addon. If you want to support development:

https://ko-fi.com/weirdpuyppy94

Support is optional and does not affect features or updates.

---

## 📜 License

MIT License — free to use, modify and share.
