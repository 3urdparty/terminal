#!/usr/bin/env bash
set -e

# -------- Variables -------- #
REPO_DIR="$(pwd)"
SSH_DIR="$HOME/.ssh"
CONFIG_DIR="$HOME/.config"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# -------- Helper Functions -------- #
install_packages() {
  echo "[*] Installing kitty, neovim, and zsh..."
  if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y kitty neovim zsh git curl
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y kitty neovim zsh git curl
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm kitty neovim zsh git curl
  else
    echo "Package manager not supported. Please install dependencies manually."
    exit 1
  fi
}

setup_kitty() {
  echo "[*] Setting up kitty config..."
  mkdir -p "$CONFIG_DIR/kitty"
  cp -r "$REPO_DIR/kitty/"* "$CONFIG_DIR/kitty/"
}

setup_nvim() {
  echo "[*] Setting up nvim config..."
  mkdir -p "$CONFIG_DIR/nvim"
  cp -r "$REPO_DIR/nvim/"* "$CONFIG_DIR/nvim/"
}

setup_terminal_profile(){
# Create a new profile (returns its UUID)
PROFILE_ID="default"
PROFILE_NAME="default"

# Add the new profile to the list
gsettings set org.gnome.Terminal.ProfilesList list \
  "$(gsettings get org.gnome.Terminal.ProfilesList list | sed "s/]$/, '$PROFILE_ID']/")"

# Set its visible name
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" visible-name "$PROFILE_NAME"

# Enable custom font and set it
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" use-system-font false
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" font 'JetBrainsMono Nerd Font 12'

# (Optional) set as default
gsettings set org.gnome.Terminal.ProfilesList default "$PROFILE_ID"

}

setup_meslo_fonts(){
	sudo mkdir -p /usr/local/share/fonts/truetype/custom
	sudo cp -r "$REPO_DIR/fonts/." /usr/local/share/fonts/truetype/custom/
	fc-cache -fv
}

setup_zsh() {
  echo "[*] Setting up zsh..."
  cp "$REPO_DIR/zshrc" "$HOME/.zshrc"
  cp "$REPO_DIR/p10k.zsh" "$HOME/.p10k.zsh"
  cp -r "$REPO_DIR/oh-my-zsh/." "$HOME/.oh-my-zsh/"
  compaudit | xargs chmod g-w,o-w
  setup_terminal_profile
  setup_meslo_fonts

  # Clone plugins
  mkdir -p "$ZSH_CUSTOM/plugins"
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
}

setup_ssh() {
  echo "[*] Setting up SSH config..."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  cp "$REPO_DIR/ssh/ubuntu.config" "$SSH_DIR/config"
  chmod 600 "$SSH_DIR/config"
}

setup_ssh_key() {
  local SSH_KEY="$SSH_DIR/id_ed25519_github"
  if [ ! -f "$SSH_KEY" ]; then
    echo "[*] Generating new SSH key for GitHub..."
    read -rp "Enter your GitHub email: " email
    ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"

    echo -e "\nHost github.com\n  AddKeysToAgent yes\n  IdentityFile $SSH_KEY" >>"$SSH_DIR/config"

    echo "[*] SSH key generated. Copy this to GitHub SSH settings:"
    cat "$SSH_KEY.pub"
  else
    echo "[*] SSH key already exists: $SSH_KEY"
  fi
}

run_all() {
  install_packages
  setup_kitty
  setup_nvim
  setup_zsh
  setup_ssh
  setup_ssh_key
}

# -------- Menu -------- #
echo "======================================="
echo "      ⚙️  Dev Environment Setup"
echo "======================================="
echo "Select what you want to install/configure:"
echo "  1) Install required packages"
echo "  2) Setup Kitty config"
echo "  3) Setup Neovim config"
echo "  4) Setup Zsh config"
echo "  5) Setup SSH config"
echo "  6) Generate SSH key for GitHub"
echo "  7) Run ALL"
echo "  0) Exit"
echo "---------------------------------------"

read -rp "Enter your choice: " choice

case $choice in
  1) install_packages ;;
  2) setup_kitty ;;
  3) setup_nvim ;;
  4) setup_zsh ;;
  5) setup_ssh ;;
  6) setup_ssh_key ;;
  7) run_all ;;
  0) echo "Exiting..." && exit 0 ;;
  *) echo "Invalid choice." && exit 1 ;;
esac

echo
echo "[*] Done!"
echo "⚡ Restart terminal or run 'exec zsh' to apply changes."
