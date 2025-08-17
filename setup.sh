#!/usr/bin/env bash
set -e

# -------- Variables -------- #
REPO_DIR="$(pwd)"
SSH_DIR="$HOME/.ssh"
CONFIG_DIR="$HOME/.config"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
SSH_KEY="$SSH_DIR/id_ed25519_github"

# -------- Functions -------- #
install_macos() {
  echo "[*] Setting up for macOS..."

  # Homebrew
  if ! command -v brew &>/dev/null; then
    echo "[*] Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo >>"$HOME/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "[*] Homebrew already installed. Skipping..."
  fi

  # Packages
  for pkg in kitty neovim zsh git; do
    if ! brew list --formula | grep -q "^$pkg\$"; then
      echo "[*] Installing $pkg..."
      brew install "$pkg"
    else
      echo "[*] $pkg already installed. Skipping..."
    fi
  done
}

install_ubuntu() {
  echo "[*] Setting up for Ubuntu..."

  # Update + packages
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y kitty neovim zsh git curl wget
}

common_setup() {
  # Kitty config
  if [ -d "$REPO_DIR/kitty" ]; then
    echo "[*] Setting up kitty config..."
    mkdir -p "$CONFIG_DIR/kitty"
    cp -r "$REPO_DIR/kitty/"* "$CONFIG_DIR/kitty/"
  else
    echo "[!] Skipping kitty config — repo folder not found."
  fi

  # Neovim config
  if [ -d "$REPO_DIR/nvim" ]; then
    echo "[*] Setting up nvim config..."
    mkdir -p "$CONFIG_DIR/nvim"
    cp -r "$REPO_DIR/nvim/"* "$CONFIG_DIR/nvim/"
  else
    echo "[!] Skipping nvim config — repo folder not found."
  fi

  # Oh My Zsh
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "[*] Installing Oh My Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
  else
    echo "[*] Oh My Zsh already installed. Skipping..."
  fi

  # Zsh config
  if [ -f "$REPO_DIR/zshrc" ]; then
    echo "[*] Setting up zsh config..."
    cp "$REPO_DIR/zshrc" "$HOME/.zshrc"
  else
    echo "[!] Skipping zshrc copy — not found in repo."
  fi

  # Zsh plugins
  mkdir -p "$ZSH_CUSTOM/plugins"
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    echo "[*] zsh-autosuggestions already installed. Skipping..."
  fi
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    echo "[*] zsh-syntax-highlighting already installed. Skipping..."
  fi

  # SSH config
  echo "[*] Setting up SSH config..."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  if [ -f "$REPO_DIR/ssh/macos.config" ] && [ "$OS_TYPE" = "macos" ]; then
    cp "$REPO_DIR/ssh/macos.config" "$SSH_DIR/config"
    chmod 600 "$SSH_DIR/config"
  elif [ -f "$REPO_DIR/ssh/ubuntu.config" ] && [ "$OS_TYPE" = "ubuntu" ]; then
    cp "$REPO_DIR/ssh/ubuntu.config" "$SSH_DIR/config"
    chmod 600 "$SSH_DIR/config"
  else
    echo "[!] Skipping SSH config copy — not found for $OS_TYPE."
  fi

  # SSH key
  if [ ! -f "$SSH_KEY" ]; then
    echo "[*] Generating new SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "your_email@example.com" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)"
    if [ "$OS_TYPE" = "macos" ]; then
      ssh-add --apple-use-keychain "$SSH_KEY"
    else
      ssh-add "$SSH_KEY"
    fi

    # Append to ssh config
    {
      echo ""
      echo "Host github.com"
      echo "  AddKeysToAgent yes"
      [ "$OS_TYPE" = "macos" ] && echo "  UseKeychain yes"
      echo "  IdentityFile $SSH_KEY"
    } >>"$SSH_DIR/config"

    echo "[*] SSH key generated. Copy this to GitHub SSH settings:"
    cat "$SSH_KEY.pub"
  else
    echo "[*] SSH key already exists: $SSH_KEY. Skipping..."
  fi
}

# -------- Main -------- #
if [ $# -lt 1 ]; then
  echo "Usage: $0 [macos|ubuntu]"
  exit 1
fi

OS_TYPE="$1"

case "$OS_TYPE" in
macos) install_macos ;;
ubuntu) install_ubuntu ;;
*)
  echo "Unknown option: $OS_TYPE"
  echo "Usage: $0 [macos|ubuntu]"
  exit 1
  ;;
esac

common_setup

echo "[*] Setup complete!"
echo "⚡ Restart terminal or run 'exec zsh' to apply changes."
