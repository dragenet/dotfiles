# Ghostty config

Minimal — currently just fixes one thing: by default, macOS treats *both*
Option keys as a "compose" key for special characters (e.g. Polish ą/ę/ł),
which breaks Alt-hjkl resizing in tmux/Neovim (`smart-splits.nvim`).

`macos-option-as-alt = left` makes the **left** Option key act as Alt/Meta
for terminal apps, while the **right** Option key keeps producing national
characters as usual.

## Quickstart

```bash
ln -sf ~/Projects/dotfiles/ghostty/config "~/Library/Application Support/com.mitchellh.ghostty/config"
```

Reload Ghostty's config with `Cmd+Shift+,`, or restart Ghostty.
