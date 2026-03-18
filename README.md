# RallyHelper

**RallyHelper** shows timers and last‑seen information for Onyxia, Nefarian, Zul'Gurub (ZG) and the Darkmoon Faire (DMF).  
The UI is movable, resizable and includes a scale slider so icons and text can be enlarged or reduced.  
The background fades on hover while text and icons remain visible.

RallyHelper is designed for **Turtle WoW (Vanilla 1.12.1)** and focuses on **robust, verifiable world buff tracking** without relying on manipulated server time.

---

## Features

- **Onyxia / Nefarian timers** for Alliance and Horde spawns  
- **ZG last drop** timestamp  
- **DMF last seen** timestamp including zone  
- **Warchief’s Blessing** cooldown display  
- **Resizable window** with Width / Height sliders  
- **Scale slider** to change text and icon sizes  
- **Hover fade** that affects only the background (text and icons stay visible)  
- **Movable window** with position persistence across sessions  
- **UI lock mode** to prevent accidental movement or resizing  
- **Multi‑source verification** for received world buff events  
- **Channel throttling** to avoid spam and duplicate timestamps  
- **Robust handlers** to avoid common Lua errors on drag/hover  

---

## Commands

### Slash command

```
/rally
```

- `/rally` — Toggle the main UI  
- `/rally lock` — Lock or unlock the UI (prevents moving and resizing)  
- `/rally reset` — Reset UI position and size  

### In‑game function calls

- `RallyHelper_ToggleUI()` — Toggle the main RallyHelper window  
- `RallyHelper_ToggleSizeUI()` — Open the size/scale window  

---

## Why RallyHelper exists

Before RallyHelper, **PizzaWorldBuffs** was used for world buff tracking.

### What PizzaWorldBuffs did well
- Introduced a simple and effective way to share world buff timestamps  
- Lightweight communication model  
- Easy to understand and extend  
- Solved a real problem when no alternatives existed  

### Why it became unreliable on Turtle WoW
On Turtle WoW the server time can be manipulated or desynchronized, which caused:
- incorrect timestamps  
- negative or drifting cooldowns  
- missing buff triggers  
- inconsistent results between players  

PizzaWorldBuffs was never designed for manipulated server time or modern Turtle WoW quirks, so these issues were outside its original scope.

### Why RallyHelper was created
RallyHelper is a **modernized, stable successor** that:
- does **not rely on server time**  
- uses **multi‑source verification** before accepting events  
- is resilient against channel spam  
- works reliably with desynced timestamps  
- integrates cleanly with pfUI and modern Turtle setups  

**PizzaWorldBuffs inspired this addon. RallyHelper exists because the original idea was good — it just needed a more robust foundation.**

---

## Compatibility

### ✔ Confirmed working with
- pfUI (Turtle version)  
- VanillaFixes  
- NameplateFixes  
- Questie / pfQuest  
- LunaUnitFrames  
- AtlasLoot  
- Aux / Auctionator  
- Gatherer / GatherLite  
- KTM / ThreatMeter  
- Standard Blizzard UI  

### ❌ Incompatible addons (must be disabled)

**GetHead**  
Hooks and modifies `CHAT_MSG_MONSTER_YELL`, which prevents RallyHelper from reliably detecting world buff triggers.

**PizzaWorldBuffs**  
Uses the same communication channel and sends unverified events, which interferes with RallyHelper’s verification system and can cause incorrect or missing timestamps.

If either addon is enabled, RallyHelper cannot function reliably.

---

## Installation (GitHub / Turtle WoW)

1. Create a GitHub repository named `RallyHelper`.  
2. Put the addon folder `RallyHelper/` in the repo root containing:
   - `RallyHelper.toc`
   - `RallyHelper.lua`
   - `RallyHelper_UI.lua`
   - `README.md`
   - `LICENSE`
3. Create a **Release** and attach a ZIP that contains the `RallyHelper/` folder at the root.  
4. Install the ZIP via GitHub or extract it into `Interface/AddOns/`.

---

## Usage

- **Open/Close UI:** `/rally`  
- **Open Size/Scale window:** `/run RallyHelper_ToggleSizeUI()`  
- **Move window:** Drag the title bar or frame (unless locked)  
- **Resize / Scale:** Use sliders in the Size window  
- **Lock UI:** `/rally lock`  
- **Persistence:** Position, size and scale are saved in `RallyHelperDB.ui`

---

## Troubleshooting

**UI can still be moved or resized while locked**  
- Ensure you are using the latest version.  
- Run `/reload` after locking the UI.

**World buffs not detected**
- Disable **GetHead** and **PizzaWorldBuffs**.  
- Ensure you are in the RallyHelper communication channel.

**Incorrect timers**
- RallyHelper requires at least two independent confirmations before accepting an event.  
- Single or spoofed messages are intentionally ignored.

---

## Developer Notes

- **Saved variables:** `RallyHelperDB`, `RallyHelperDB.ui`  
- **Exported globals:** `RallyHelper_ToggleUI`, `RallyHelper_ToggleSizeUI`  
- **Target client:** Turtle WoW (Vanilla 1.12.1)  

---

## License

This project is licensed under the **MIT License**.

---

## Support the Project

RallyHelper is a free and open‑source addon developed in my spare time.

If you find it useful and would like to support its continued development, you can buy me a coffee:

☕ https://ko-fi.com/YOUR_KOFI_NAME

Any support is greatly appreciated.
I’m currently going through a financially challenging period, and contributions help me continue maintaining and improving this project.

Support is completely optional and has no impact on features or updates.
