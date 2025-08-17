#!/usr/bin/env bash
set -e

# -------- Variables -------- #
REPO_DIR="$(pwd)"
SSH_DIR="$HOME/.ssh"
CONFIG_DIR="$HOME/.config"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"

# -------- Install Homebrew if missing -------- #
if ! command -v brew &>/dev/null; then
  echo "[*] Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo >>"$HOME/.zprofile"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "[*] Homebrew already installed. Skipping..."
fi

# -------- Install packages -------- #
for pkg in kitty neovim zsh git; do
  if ! brew list --formula | grep -q "^$pkg\$"; then
    echo "[*] Installing $pkg..."
    brew install "$pkg"
  else
    echo "[*] $pkg already installed. Skipping..."
  fi
done

# -------- Kitty config -------- #
if [ -d "$REPO_DIR/kitty" ]; then
  echo "[*] Setting up kitty config..."
  mkdir -p "$CONFIG_DIR/kitty"
  cp -r "$REPO_DIR/kitty/"* "$CONFIG_DIR/kitty/"
else
  echo "[!] Skipping kitty config — repo folder not found."
fi

# -------- Neovim config -------- #
if [ -d "$REPO_DIR/nvim" ]; then
  echo "[*] Setting up nvim config..."
  mkdir -p "$CONFIG_DIR/nvim"
  cp -r "$REPO_DIR/nvim/"* "$CONFIG_DIR/nvim/"
else
  echo "[!] Skipping nvim config — repo folder not found."
fi

# -------- Oh My Zsh -------- #
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
  echo "[*] Installing Oh My Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
else
  echo "[*] Oh My Zsh already installed. Skipping..."
fi

# -------- Zsh config -------- #
if [ -f "$REPO_DIR/zshrc" ]; then
  echo "[*] Setting up zsh config..."
  cp "$REPO_DIR/zshrc" "$HOME/.zshrc"
else
  echo "[!] Skipping zshrc copy — not found in repo."
fi

# -------- Zsh plugins -------- #
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

# -------- SSH config -------- #
echo "[*] Setting up SSH config..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
if [ -f "$REPO_DIR/ssh/macos.config" ]; then
  cp "$REPO_DIR/ssh/macos.config" "$SSH_DIR/config"
  chmod 600 "$SSH_DIR/config"
else
  echo "[!] Skipping SSH config copy — not found in repo."
fi

# -------- SSH key for GitHub -------- #
SSH_KEY="$SSH_DIR/id_ed25519_github"
if [ ! -f "$SSH_KEY" ]; then
  echo "[*] Generating new SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "your_email@example.com" -f "$SSH_KEY" -N ""
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain "$SSH_KEY"

  # Append to ssh config
  {
    echo ""
    echo "Host github.com"
    echo "  AddKeysToAgent yes"
    echo "  UseKeychain yes"
    echo "  IdentityFile $SSH_KEY"
  } >>"$SSH_DIR/config"

  echo "[*] SSH key generated. Copy this to GitHub SSH settings:"
  cat "$SSH_KEY.pub"
else
  echo "[*] SSH key already exists: $SSH_KEY. Skipping..."
fi

echo "[*] Setup complete!"
echo "⚡ Restart terminal or run 'exec zsh' to apply changes."
