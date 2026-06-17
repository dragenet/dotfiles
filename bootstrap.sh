#!/usr/bin/env bash
#
# Bootstrap script for dragenet/dotfiles.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dragenet/dotfiles/master/bootstrap.sh | bash
#   ./bootstrap.sh                 # from a cloned checkout
#
# Installs core tooling (git, tmux, neovim 0.11+, ripgrep, fd, TPM), clones
# this repo if it isn't already checked out, and symlinks the configs into
# place. Safe to re-run.
#
# Override the checkout location with DOTFILES_DIR (default ~/.dotfiles).

set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/dragenet/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$1" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

detect_platform() {
  case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac

  if [ "$PLATFORM" = "linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then PKG_MGR="apt"
    elif command -v dnf >/dev/null 2>&1; then PKG_MGR="dnf"
    elif command -v pacman >/dev/null 2>&1; then PKG_MGR="pacman"
    else die "No supported package manager found (apt, dnf, pacman)"
    fi
  fi
}

load_brew_env() {
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
                   /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

install_macos_packages() {
  load_brew_env || true
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_env || die "Homebrew install finished but brew was not found"
  fi

  log "Installing core packages via Homebrew"
  brew install git tmux ripgrep fd neovim

  if ! xcode-select -p >/dev/null 2>&1; then
    log "Requesting Xcode Command Line Tools (a GUI prompt may appear)"
    xcode-select --install || true
  fi
}

install_linux_packages() {
  log "Installing core packages via $PKG_MGR"
  case "$PKG_MGR" in
    apt)
      $SUDO apt-get update
      $SUDO apt-get install -y git tmux ripgrep fd-find build-essential curl
      if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      fi
      ;;
    dnf)
      $SUDO dnf install -y git tmux ripgrep fd-find curl
      $SUDO dnf groupinstall -y "Development Tools" || true
      ;;
    pacman)
      $SUDO pacman -Sy --needed --noconfirm git tmux ripgrep fd base-devel curl
      ;;
  esac
}

nvim_version_ok() {
  command -v nvim >/dev/null 2>&1 || return 1
  local ver major minor
  ver="$(nvim --version | head -n1 | sed -E 's/^NVIM v//')"
  major="${ver%%.*}"
  minor="${ver#*.}"; minor="${minor%%.*}"
  [ "$major" -gt 0 ] || [ "$minor" -ge 11 ]
}

install_neovim_via_brew_linux() {
  load_brew_env || true
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew (for Linux)"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_env || die "Homebrew install finished but brew was not found"
  fi
  brew install neovim
}

install_neovim_via_tarball() {
  local arch asset url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64) asset="nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
    *) die "Unsupported architecture for Neovim tarball: $arch" ;;
  esac

  url="https://github.com/neovim/neovim/releases/latest/download/$asset"
  tmp="$(mktemp -d)"
  log "Downloading Neovim from $url"
  curl -fsSL "$url" -o "$tmp/nvim.tar.gz"

  mkdir -p "$HOME/.local/opt"
  rm -rf "$HOME/.local/opt/nvim"
  tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt"
  mv "$HOME/.local/opt/${asset%.tar.gz}" "$HOME/.local/opt/nvim"
  rm -rf "$tmp"

  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  warn "Installed Neovim to ~/.local/opt/nvim. Make sure ~/.local/bin is on your \$PATH."
}

install_neovim_linux() {
  if nvim_version_ok; then
    log "Neovim already satisfies >= 0.11 ($(nvim --version | head -n1))"
    return
  fi

  log "Neovim 0.11+ is required but not found (or too old)."
  local choice="2"
  if [ -r /dev/tty ]; then
    {
      echo "How should Neovim be installed?"
      echo "  1) Homebrew on Linux (installs Homebrew if missing, then 'brew install neovim')"
      echo "  2) Official prebuilt tarball from neovim releases (default)"
      read -r -p "Choose [1/2]: " choice
    } </dev/tty >/dev/tty || choice="2"
  else
    warn "No tty available; defaulting to the official Neovim tarball"
  fi
  choice="${choice:-2}"

  case "$choice" in
    1) install_neovim_via_brew_linux ;;
    *) install_neovim_via_tarball ;;
  esac
}

resolve_dotfiles_dir() {
  local source="${BASH_SOURCE[0]:-}"
  if [ -n "$source" ] && [ -f "$source" ]; then
    local script_dir
    script_dir="$(cd "$(dirname "$source")" && pwd)"
    if [ -f "$script_dir/nvim/init.lua" ]; then
      DOTFILES_DIR="$script_dir"
      log "Running from existing checkout: $DOTFILES_DIR"
      return
    fi
  fi

  if [ -f "$DOTFILES_DIR/nvim/init.lua" ]; then
    log "Found existing dotfiles checkout at $DOTFILES_DIR"
    return
  fi

  log "Cloning dotfiles to $DOTFILES_DIR"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$REPO_URL" "$DOTFILES_DIR"
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm_dir" ]; then
    log "TPM already installed"
  else
    log "Installing TPM (tmux plugin manager)"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

link() {
  local target="$1" link_path="$2"
  if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ]; then
    log "Already linked: $link_path"
    return
  fi
  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    local backup="$link_path.bak.$(date +%s)"
    warn "Backing up existing $link_path -> $backup"
    mv "$link_path" "$backup"
  fi
  mkdir -p "$(dirname "$link_path")"
  ln -sf "$target" "$link_path"
  log "Linked $link_path -> $target"
}

ask_yes_no() {
  local prompt="$1" default="$2" reply
  if [ ! -r /dev/tty ]; then
    [ "$default" = "y" ]
  else
    read -r -p "$prompt " reply </dev/tty >/dev/tty || reply=""
    reply="${reply:-$default}"
    case "$reply" in
      y|Y) return 0 ;;
      *) return 1 ;;
    esac
  fi
}

install_node() {
  case "$PLATFORM" in
    macos) brew install node ;;
    linux)
      case "$PKG_MGR" in
        apt) $SUDO apt-get install -y nodejs npm ;;
        dnf) $SUDO dnf install -y nodejs npm ;;
        pacman) $SUDO pacman -S --needed --noconfirm nodejs npm ;;
      esac
      ;;
  esac
}

install_go() {
  case "$PLATFORM" in
    macos) brew install go ;;
    linux)
      case "$PKG_MGR" in
        apt) $SUDO apt-get install -y golang-go ;;
        dnf) $SUDO dnf install -y golang ;;
        pacman) $SUDO pacman -S --needed --noconfirm go ;;
      esac
      ;;
  esac
}

install_python() {
  case "$PLATFORM" in
    macos) brew install python3 ;;
    linux)
      case "$PKG_MGR" in
        apt) $SUDO apt-get install -y python3 python3-pip python3-venv ;;
        dnf) $SUDO dnf install -y python3 python3-pip ;;
        pacman) $SUDO pacman -S --needed --noconfirm python python-pip ;;
      esac
      ;;
  esac
}

PY_TOOL_RUNNER=""

# Picks a tool to install ansible into its own isolated environment (so it
# doesn't fight with the system/Homebrew Python). Prefers whichever of
# pipx/uv is already installed; if neither is present, asks the user.
ensure_python_tool_runner() {
  [ -n "$PY_TOOL_RUNNER" ] && return

  if command -v pipx >/dev/null 2>&1; then
    PY_TOOL_RUNNER="pipx"; return
  fi
  if command -v uv >/dev/null 2>&1; then
    PY_TOOL_RUNNER="uv"; return
  fi

  local choice="1"
  if [ -r /dev/tty ]; then
    {
      echo "Neither pipx nor uv found (needed to install ansible in an isolated environment)."
      echo "  1) pipx (default)"
      echo "  2) uv"
      read -r -p "Choose [1/2]: " choice
    } </dev/tty >/dev/tty || choice="1"
  fi
  choice="${choice:-1}"

  case "$choice" in
    2)
      log "Installing uv"
      curl -LsSf https://astral.sh/uv/install.sh | sh
      export PATH="$HOME/.local/bin:$PATH"
      PY_TOOL_RUNNER="uv"
      ;;
    *)
      log "Installing pipx"
      case "$PLATFORM" in
        macos) brew install pipx ;;
        linux)
          case "$PKG_MGR" in
            apt) $SUDO apt-get install -y pipx ;;
            dnf) $SUDO dnf install -y pipx ;;
            pacman) $SUDO pacman -S --needed --noconfirm python-pipx ;;
          esac
          ;;
      esac
      pipx ensurepath
      PY_TOOL_RUNNER="pipx"
      ;;
  esac
}

install_ansible() {
  ensure_python_tool_runner
  case "$PY_TOOL_RUNNER" in
    pipx) pipx install --include-deps ansible ;;
    uv) uv tool install --with-executables-from ansible-core ansible ;;
  esac
}

install_rust() {
  if command -v rustup >/dev/null 2>&1; then
    log "rustup already installed"
    return
  fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

install_yabai() {
  log "Installing yabai (tiling window manager)"
  brew install koekeishiya/formulae/yabai
  brew services start yabai
  link "$DOTFILES_DIR/yabai/yabairc" "$HOME/.config/yabai/yabairc"
}

install_optional_toolchains() {
  if [ ! -r /dev/tty ]; then
    log "No tty available; skipping optional language toolchain prompts (see nvim/README.md)"
    return
  fi

  log "Optional language toolchains (used by mason LSPs/formatters in nvim)"
  if ask_yes_no "Install Node.js? [y/N]" "n"; then install_node; fi
  if ask_yes_no "Install Go? [y/N]" "n"; then install_go; fi
  if ask_yes_no "Install Python 3? [y/N]" "n"; then install_python; fi
  if ask_yes_no "Install Rust (via rustup)? [y/N]" "n"; then install_rust; fi
  if ask_yes_no "Install Ansible (via pipx/uv)? [y/N]" "n"; then install_ansible; fi
}

create_symlinks() {
  link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
  link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

  if [ "$PLATFORM" = "macos" ] && { [ -d "/Applications/Ghostty.app" ] || [ -d "$HOME/Applications/Ghostty.app" ]; }; then
    link "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  else
    log "Ghostty.app not found, skipping Ghostty config symlink"
  fi
}

print_summary() {
  cat <<EOF

Done!

Next steps:
  - Start tmux, then press 'Ctrl-b I' to install tmux plugins via TPM.
  - Launch nvim - lazy.nvim and mason will bootstrap plugins/LSPs on first run.
  - See nvim/README.md for a Nerd Font and the formatter/linter CLIs
    installed via :MasonInstall.
EOF
}

main() {
  detect_platform

  if [ "$PLATFORM" = "macos" ]; then
    install_macos_packages
  else
    install_linux_packages
    install_neovim_linux
  fi

  resolve_dotfiles_dir
  install_tpm
  create_symlinks
  install_optional_toolchains

  if [ "$PLATFORM" = "macos" ]; then
    if ask_yes_no "Install yabai (tiling window manager, macOS only)? [y/N]" "n"; then
      install_yabai
    fi
  fi

  print_summary
}

main "$@"
