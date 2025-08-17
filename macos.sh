#!/usr/bin/env bash
set -e

# -------- Variables -------- #
REPO_DIR="$(pwd)"
SSH_DIR="$HOME/.ssh"
CONFIG_DIR="$HOME/.config"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# -------- Install Homebrew if missing -------- #
if ! command -v brew &>/dev/null; then
  echo "[*] Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo >> /Users/3urdparty/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/3urdparty/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"


# -------- Install packages -------- #
echo "[*] Installing kitty, neovim, and zsh..."
brew install kitty neovim zsh git

# -------- Kitty config -------- #
echo "[*] Setting up kitty config..."
mkdir -p "$CONFIG_DIR/kitty"
cp -r "$REPO_DIR/kitty/"* "$CONFIG_DIR/kitty/"

# -------- Neovim config -------- #
echo "[*] Setting up nvim config..."
mkdir -p "$CONFIG_DIR/nvim"
cp -r "$REPO_DIR/nvim/"* "$CONFIG_DIR/nvim/"

# -------- Zsh config -------- #
echo "[*] Setting up zsh..."
cp "$REPO_DIR/.zshrc" "$HOME/.zshrc"

# Clone plugins
mkdir -p "$ZSH_CUSTOM/plugins"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# -------- SSH config -------- #
echo "[*] Setting up SSH config..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
cp "$REPO_DIR/ssh/config" "$SSH_DIR/config"
chmod 600 "$SSH_DIR/config"

# -------- SSH key for GitHub -------- #
SSH_KEY="$SSH_DIR/id_ed25519_github"
if [ ! -f "$SSH_KEY" ]; then
  echo "[*] Generating new SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "your_email@example.com" -f "$SSH_KEY" -N ""
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain "$SSH_KEY"

  # Append to ssh config
  echo -e "\nHost github.com\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile $SSH_KEY" >>"$SSH_DIR/config"

  echo "[*] SSH key generated. Copy this to GitHub SSH settings:"
  cat "$SSH_KEY.pub"
else
  echo "[*] SSH key already exists: $SSH_KEY"
fi

echo "[*] Setup complete!"
echo "⚡ Restart terminal or run 'exec zsh' to apply changes."
