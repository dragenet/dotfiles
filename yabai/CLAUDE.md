# yabai config

macOS-only tiling window manager. Manages window layout automatically so
windows fill the screen without manual resizing.

## Collaboration approach

Same as the rest of this repo: read official docs before discussing config
options, explain *why* before *how*, ask before deciding on commonly
configured options.

## Current state

- Config: [`yabairc`](yabairc), symlinked to `~/.config/yabai/yabairc`.
- Install: `brew install koekeishiya/formulae/yabai`; start/enable with
  `brew services start yabai`.
- Layout: **BSP** (binary space partitioning) — new windows split the focused
  window's space, placed as `second_child` (right/below the current window).
- Padding: 12 px on all sides, 12 px gap between windows.
- Mouse: `alt` as modifier; left-drag moves, right-drag resizes; drop onto
  another window swaps them; `mouse_follows_focus` is on.
- Unmanaged apps (float, never tiled): System Settings, Calculator, Raycast,
  Finder.

## Notes

- SIP (System Integrity Protection) does **not** need to be disabled for basic
  tiling; the scripting addition (needed for focus-follows-mouse across spaces,
  opacity, etc.) requires partial SIP disable. Current config avoids features
  that need it.
- Commonly paired with `skhd` for keyboard shortcuts to manipulate windows/
  spaces. Not wired up yet.
