# yabai config

macOS tiling window manager — automatically arranges windows in a BSP
(binary space partitioning) layout so they fill the screen without manual
resizing.

## Prerequisites

```bash
brew install koekeishiya/formulae/yabai
```

No SIP changes required for this config — all features used here work with
SIP fully enabled.

## Quickstart

```bash
mkdir -p ~/.config/yabai
ln -s ~/Projects/dotfiles/yabai/yabairc ~/.config/yabai/yabairc

brew services start yabai
```

Yabai reads `~/.config/yabai/yabairc` on startup. Re-run with
`yabai --restart-service` after editing the config.

## What's configured

| Setting | Value |
|---------|-------|
| Layout | BSP (binary space partitioning) |
| New window placement | `second_child` — splits the focused window |
| Padding | 12 px all sides, 12 px gap between windows |
| Mouse modifier | `alt` (left Option key) |
| Left-drag | Move window |
| Right-drag | Resize window |
| Drop onto window | Swap the two windows |
| Mouse follows focus | On |

### Unmanaged apps (float, never tiled)

System Settings, Calculator, Raycast, Finder.

## Notes

- Keyboard shortcuts to move/swap/focus windows require `skhd` (not set up
  yet). Without it, use mouse or the app's own window management.
- The scripting addition (`yabai --load-sa`) enables extra features
  (cross-space focus, opacity, etc.) but requires partial SIP disable —
  not needed for this config.
