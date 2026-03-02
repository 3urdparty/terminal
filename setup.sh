#!/usr/bin/env bash
set -e

# ============================= #
#        DOTFILES INSTALLER     #
# ============================= #

# -------- Colors -------- #
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# -------- Variables -------- #
REPO_DIR="$(pwd)"
SSH_DIR="$HOME/.ssh"
CONFIG_DIR="$HOME/.config"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
SSH_KEY="$SSH_DIR/id_ed25519_github"
EMAIL="3urdparty@gmail.com"

OS_TYPE=""

# -------- OS Detection -------- #
detect_os() {
  case "$(uname)" in
  Darwin) OS_TYPE="macos" ;;
  Linux)
    if grep -qi ubuntu /etc/os-release 2>/dev/null; then
      OS_TYPE="ubuntu"
    else
      echo -e "${RED}Unsupported Linux distro.${RESET}"
      exit 1
    fi
    ;;
  *)
    echo -e "${RED}Unsupported OS.${RESET}"
    exit 1
    ;;
  esac
}

# -------- Helpers -------- #
print_header() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════╗"
  echo "║        ⚡ Dotfiles Installer         ║"
  echo "╚══════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "Detected OS: ${YELLOW}$OS_TYPE${RESET}"
  echo ""
}

status() {
  if eval "$1" &>/dev/null; then
    echo -e "${GREEN}Installed ✅${RESET}"
  else
    echo -e "${RED}Not Installed ❌${RESET}"
  fi
}

pause() {
  echo ""
  read -rp "Press Enter to continue..."
}

# -------- Install Functions -------- #

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "Homebrew already installed."
  fi
}

install_packages_macos() {
  for pkg in kitty neovim zsh git; do
    brew list "$pkg" &>/dev/null || brew install "$pkg"
  done
}

install_packages_ubuntu() {
  sudo apt update
  sudo apt install -y kitty zsh git curl wget
  sudo snap install --classic nvim || true
}

install_ohmyzsh() {
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
  fi
}

install_powerlevel10k() {
  if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k"
  fi
}

install_plugins() {
  mkdir -p "$ZSH_CUSTOM/plugins"

  [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] &&
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

  [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] &&
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
}

setup_configs() {
  mkdir -p "$CONFIG_DIR"

  [ -d "$REPO_DIR/kitty" ] && cp -r "$REPO_DIR/kitty" "$CONFIG_DIR/"
  [ -d "$REPO_DIR/nvim" ] && cp -r "$REPO_DIR/nvim" "$CONFIG_DIR/"
  [ -f "$REPO_DIR/zshrc" ] && cp "$REPO_DIR/zshrc" "$HOME/.zshrc"
}

setup_ssh() {
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
    echo ""
    echo "Add this key to GitHub:"
    cat "$SSH_KEY.pub"
  fi
}

# -------- Menu -------- #

show_menu() {
  print_header

  echo -e "${BOLD}Select what to install:${RESET}"
  echo ""

  echo "1) Homebrew (macOS only)     - $(status "command -v brew")"
  echo "2) System Packages           - $(status "command -v kitty")"
  echo "3) Oh My Zsh                 - $(status "[ -d $OH_MY_ZSH_DIR ]")"
  echo "4) Powerlevel10k Theme       - $(status "[ -d $ZSH_CUSTOM/themes/powerlevel10k ]")"
  echo "5) Zsh Plugins               - $(status "[ -d $ZSH_CUSTOM/plugins/zsh-autosuggestions ]")"
  echo "6) Dotfiles Configs          - $(status "[ -f $HOME/.zshrc ]")"
  echo "7) SSH Setup                 - $(status "[ -f $SSH_KEY ]")"
  echo ""
  echo "8) Install EVERYTHING"
  echo "0) Exit"
  echo ""
}

handle_choice() {
  case "$1" in
  1) [ "$OS_TYPE" = "macos" ] && install_homebrew ;;
  2)
    if [ "$OS_TYPE" = "macos" ]; then
      install_packages_macos
    else
      install_packages_ubuntu
    fi
    ;;
  3) install_ohmyzsh ;;
  4) install_powerlevel10k ;;
  5) install_plugins ;;
  6) setup_configs ;;
  7) setup_ssh ;;
  8)
    [ "$OS_TYPE" = "macos" ] && install_homebrew
    [ "$OS_TYPE" = "macos" ] && install_packages_macos
    [ "$OS_TYPE" = "ubuntu" ] && install_packages_ubuntu
    install_ohmyzsh
    install_powerlevel10k
    install_plugins
    setup_configs
    setup_ssh
    ;;
  0) exit 0 ;;
  *) echo "Invalid option." ;;
  esac
}

# -------- Main Loop -------- #

detect_os

while true; do
  show_menu
  read -rp "Enter choice: " choice
  handle_choice "$choice"
  pause
done
