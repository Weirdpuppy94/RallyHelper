# RallyHelper

**RallyHelper** shows timers and last‑seen information for Onyxia, Nefarian, Zul'Gurub (ZG) and the Darkmoon Faire (DMF). The UI is movable, resizable and includes a scale slider so icons and text can be enlarged or reduced. The background fades on hover while text and icons remain visible.

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
- **Robust handlers** to avoid common Lua errors on drag/hover

---

## Commands

**In‑game function calls** (can be used from chat with `/run` or from other addons):

- `RallyHelper_ToggleUI()` — Toggle the main RallyHelper window.  
- `RallyHelper_ToggleSizeUI()` — Open the size/scale window (Width, Height, Scale sliders).

**Slash command (recommended)**

RallyHelper provides a convenient slash command:

```
/rally
```

Typing `/rally` will toggle the main UI. If you prefer to call the function directly from chat or macros, use:

```lua
/run RallyHelper_ToggleUI()
```

**Optional: Add or change slash commands**

If your version does not yet register `/rally`, add this snippet to `RallyHelper.lua` (or any file loaded by the addon):

```lua
-- register slash command /rally
SLASH_RALLYHELPER1 = "/rally"
SlashCmdList["RALLYHELPER"] = function(msg)
  -- toggle UI
  if not RallyHelper_ToggleUI then return end
  RallyHelper_ToggleUI()
end
```

Place the snippet near your addon initialization code so it runs when the addon loads.

---

## Installation (GitHub / Turtle WoW)

1. Create a GitHub repository named `RallyHelper`.  
2. Put the addon folder `RallyHelper/` in the repo root containing:
   - `RallyHelper.toc`
   - `RallyHelper.lua`
   - `RallyHelper_UI.lua`
   - `README.md`
   - `LICENSE`
3. Create a **Release** and attach a ZIP that contains the `RallyHelper/` folder (the ZIP must include the addon folder at the root).  
4. In Turtle WoW (or any client that supports GitHub installs), add the Release ZIP URL or the release asset link.

**Local test:** unzip the release into your `Interface/AddOns/` folder and run `/reload` in game.

---

## Usage

- **Open/Close UI:** `/rally` or `/run RallyHelper_ToggleUI()`  
- **Open Size/Scale window:** `/run RallyHelper_ToggleSizeUI()`  
- **Move window:** Left‑click and drag the title area or anywhere in the frame.  
- **Resize:** Use the Width and Height sliders in the Size window.  
- **Scale:** Use the Scale slider in the Size window to change text and icon sizes.  
- **Hover:** Move the mouse over the window to fade the background in; move away to fade out.  
- **Persistence:** Width, Height, Scale and position are saved to `RallyHelperDB.ui`.

---

## Troubleshooting

**1. Addon does not appear / UI invisible**
- Ensure the ZIP you installed contains the `RallyHelper/` folder at the root (not nested inside another folder).
- Confirm `RallyHelper.toc` lists both `RallyHelper.lua` and `RallyHelper_UI.lua`.
- Check the SavedVariables folder is writable by the client.

**2. Lua errors on hover or drag**
- Update to the latest version of the addon (errors were fixed in recent builds).
- Run `/reload` after updating.
- If an error persists, copy the exact error message including file name and line number and open an issue on GitHub.

**3. Slash command `/rally` does nothing**
- Make sure the slash registration snippet (see above) is present and executed on addon load.
- Check for typos in the snippet or conflicts with other addons that may override slash commands.

**4. Position or size not saved**
- Verify `RallyHelperDB` exists in your SavedVariables after running the addon.
- Ensure the client can write to the SavedVariables folder (file system permissions).

**5. Background fades but text/icons disappear**
- This addon intentionally fades only the background. If text/icons disappear, another addon or a modified UI file may be interfering. Try disabling other UI addons to isolate the issue.

---

## Reporting Issues

When opening an issue on GitHub include:
- **Exact error message** (file and line number).  
- **Steps to reproduce** (what you clicked, hovered, or dragged).  
- **Client version** (Turtle WoW build or other) and any other addons enabled.  
- **Screenshot** if helpful.

---

## Developer Notes

- **Exported globals:** `RallyHelper_ToggleUI`, `RallyHelper_ToggleSizeUI`  
- **Saved variables:** `RallyHelperDB.ui` stores `w`, `h`, `x`, `y`, `scale`  
- **Files referenced in `.toc`:** `RallyHelper.lua`, `RallyHelper_UI.lua`  
- **Recommended TOC header** (adjust `Interface` to your target client):

```toc
## Interface: 11404
## Title: RallyHelper
## Notes: Shows Onyxia/Nefarian/DMF/ZG timers; scalable UI with hover fade
## Author: Weirdpuppy
## Version: 1.0.0
RallyHelper.lua
RallyHelper_UI.lua
```

---

## License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.
