#!/usr/bin/env bash
set -e

# ================================ #
#       TERMINAL SETUP             #
# ================================ #

REPO_URL="https://raw.githubusercontent.com/3urdparty/terminal/main"
REPO_CLONE_URL="https://github.com/3urdparty/terminal.git"
TMP_DIR="/tmp/terminal-setup"
SSH_DIR="$HOME/.ssh"
CONFIG_DIR="$HOME/.config"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
SSH_KEY="$SSH_DIR/id_ed25519_github"
EMAIL="3urdparty@gmail.com"
OS_TYPE=""

# -------- Colors & Symbols -------- #
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
DIM="\033[2m"
BOLD="\033[1m"
RESET="\033[0m"

TICK="${GREEN}✔${RESET}"
CROSS="${RED}✘${RESET}"
ARROW="${CYAN}❯${RESET}"
DOT="${DIM}·${RESET}"

# -------- Bootstrap Repository -------- #

BOOTSTRAP_DIR="$HOME/.terminal-setup"

# -------- Bootstrap Repository -------- #

bootstrap_repo() {
  # Install Git if missing
  if ! command -v git >/dev/null 2>&1; then
    echo "Installing Git..."

    case "$(uname)" in
      Darwin)
        xcode-select --install 2>/dev/null || true

        until command -v git >/dev/null 2>&1; do
          sleep 5
        done
        ;;
      Linux)
        if command -v apt >/dev/null 2>&1; then
          sudo apt update
          sudo apt install -y git
        else
          echo "Unsupported package manager."
          exit 1
        fi
        ;;
    esac
  fi

  # Clone repository into /tmp
  if [ ! -d "$TMP_DIR/.git" ]; then
    echo "Cloning terminal repository..."
    rm -rf "$TMP_DIR"

    git clone "$REPO_CLONE_URL" "$TMP_DIR"
  else
    echo "Updating terminal repository..."
    git -C "$TMP_DIR" pull --quiet
  fi

  # Initialize submodules
  echo "Initializing submodules..."
  git -C "$TMP_DIR" submodule update --init --recursive
}

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
is_installed() {
  eval "$1" &>/dev/null
}

status_badge() {
  if is_installed "$1"; then
    echo -e "${GREEN}installed${RESET}"
  else
    echo -e "${DIM}not installed${RESET}"
  fi
}

log_step() {
  echo -e "  ${ARROW} $1"
}

log_success() {
  echo -e "  ${TICK} $1"
}

log_info() {
  echo -e "  ${DOT} ${DIM}$1${RESET}"
}

section() {
  echo ""
  echo -e "${BOLD}${CYAN}$1${RESET}"
  echo -e "${DIM}$(printf '%.0s─' {1..40})${RESET}"
}

pause() {
  echo ""
  echo -e "  ${DIM}Press Enter to return to menu...${RESET}"
  read -r
}

# -------- Shallow Clone Helper -------- #
clone_repo() {
  if [ -d "$TMP_DIR" ]; then
    log_info "Repo already cloned, pulling latest..."
    git -C "$TMP_DIR" pull --quiet
  else
    log_step "Cloning repo (shallow)..."
    git clone --depth=1 "$REPO_CLONE_URL" "$TMP_DIR" --quiet
    log_success "Cloned to $TMP_DIR"
  fi
}

cleanup_repo() {
  [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
  log_success "Cleaned up temp files"
}

# -------- Install Functions -------- #

install_homebrew() {
  section "Homebrew"
  if ! command -v brew &>/dev/null; then
    log_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log_success "Homebrew installed"
  else
    log_info "Homebrew already installed"
  fi
}

install_packages() {
  section "System Packages"
  if [ "$OS_TYPE" = "macos" ]; then
    for pkg in kitty neovim zsh git; do
      if brew list "$pkg" &>/dev/null; then
        log_info "$pkg already installed"
      else
        log_step "Installing $pkg..."
        brew install "$pkg"
        log_success "$pkg installed"
      fi
    done
  else
    log_step "Updating apt..."
    sudo apt update -qq
    sudo apt install -y zsh git curl wget xclip &>/dev/null
    log_success "apt packages installed"

    log_step "Installing kitty..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    mkdir -p ~/.local/bin ~/.local/share/applications ~/.config &&
      ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty &&
      ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten &&
      cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/ &&
      cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/ &&
      sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop &&
      sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop &&
      echo 'kitty.desktop' >~/.config/xdg-terminals.list &&
      update-desktop-database ~/.local/share/applications 2>/dev/null || true
    log_success "kitty installed"

    log_step "Installing neovim via PPA..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y &>/dev/null
    sudo apt update -qq
    sudo apt install -y neovim &>/dev/null
    log_success "neovim installed"
  fi
}

install_ohmyzsh() {
  section "Oh My Zsh"
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    log_step "Installing Oh My Zsh..."
    git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
    log_success "Oh My Zsh installed"
  else
    log_info "Oh My Zsh already installed"
  fi
}

install_powerlevel10k() {
  section "Powerlevel10k"
  if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    log_step "Installing Powerlevel10k..."
    git clone --depth=1 --quiet https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k"
    log_success "Powerlevel10k installed"
  else
    log_info "Powerlevel10k already installed"
  fi
}

install_plugins() {
  section "Zsh Plugins"
  mkdir -p "$ZSH_CUSTOM/plugins"

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log_step "Installing zsh-autosuggestions..."
    git clone --quiet https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log_success "zsh-autosuggestions installed"
  else
    log_info "zsh-autosuggestions already installed"
  fi

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    log_step "Installing zsh-syntax-highlighting..."
    git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log_success "zsh-syntax-highlighting installed"
  else
    log_info "zsh-syntax-highlighting already installed"
  fi
}

setup_configs() {
  section "Dotfiles"
  clone_repo

  mkdir -p "$CONFIG_DIR/kitty"
  mkdir -p "$CONFIG_DIR/nvim"

  log_step "Copying kitty config..."
  cp -r "$TMP_DIR/kitty.config/." "$CONFIG_DIR/kitty/"
  log_success "kitty config installed"

  log_step "Copying nvim config..."
  cp -r "$TMP_DIR/nvim.config/." "$CONFIG_DIR/nvim/"
  log_success "nvim config installed"

  log_step "Copying .zshrc..."
  cp "$TMP_DIR/zshrc" "$HOME/.zshrc"
  log_success ".zshrc installed"

  log_step "Copying .p10k.zsh..."
  cp "$TMP_DIR/p10k.zsh" "$HOME/.p10k.zsh"
  log_success ".p10k.zsh installed"

  cleanup_repo
}

setup_ssh() {
  section "SSH"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  local config_file="$SSH_DIR/config"
  touch "$config_file"
  chmod 600 "$config_file"

  if [ ! -f "$SSH_KEY" ]; then
    log_step "Generating SSH key..."
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N "" -q
    eval "$(ssh-agent -s)" &>/dev/null

    if [ "$OS_TYPE" = "macos" ]; then
      ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null
    else
      ssh-add "$SSH_KEY" 2>/dev/null
    fi

    log_success "SSH key generated"
    echo ""
    echo -e "  ${YELLOW}Add this public key to GitHub:${RESET}"
    echo -e "  ${DIM}https://github.com/settings/keys${RESET}"
    echo ""
    echo -e "  ${CYAN}$(cat "$SSH_KEY.pub")${RESET}"
    echo ""
  else
    log_info "SSH key already exists"
  fi

  if ! grep -q "Host github.com" "$config_file"; then
    log_step "Adding GitHub SSH config..."
    {
      echo ""
      echo "Host github.com"
      echo "  HostName github.com"
      echo "  User git"
      echo "  IdentityFile $SSH_KEY"
      echo "  AddKeysToAgent yes"
      [ "$OS_TYPE" = "macos" ] && echo "  UseKeychain yes"
    } >>"$config_file"
    log_success "GitHub SSH config added"
  else
    log_info "GitHub SSH config already exists"
  fi

  if ! grep -q "Host mac" "$config_file"; then
    log_step "Adding mac host alias..."
    {
      echo ""
      echo "Host mac"
      echo "  HostName localhost"
      echo "  User $USER"
      echo "  IdentityFile $SSH_KEY"
    } >>"$config_file"
    log_success "Mac host alias added"
  else
    log_info "Mac host alias already exists"
  fi
}

install_all() {
  [ "$OS_TYPE" = "macos" ] && install_homebrew
  install_packages
  install_ohmyzsh
  install_powerlevel10k
  install_plugins
  setup_configs
  setup_ssh
}

# -------- Menu -------- #

print_header() {
  clear
  echo ""
  echo -e "  ${BOLD}${CYAN}Terminal Setup${RESET}  ${DIM}v1.0.0${RESET}"
  echo -e "  ${DIM}$OS_TYPE${RESET}"
  echo ""
}

print_menu() {
  print_header

  local items=(
    "Homebrew"
    "System Packages"
    "Oh My Zsh"
    "Powerlevel10k"
    "Zsh Plugins"
    "Dotfiles Configs"
    "SSH Setup"
  )

  local checks=(
    "command -v brew"
    "command -v kitty"
    "[ -d $OH_MY_ZSH_DIR ]"
    "[ -d $ZSH_CUSTOM/themes/powerlevel10k ]"
    "[ -d $ZSH_CUSTOM/plugins/zsh-autosuggestions ]"
    "[ -f $HOME/.zshrc ]"
    "[ -f $SSH_KEY ]"
  )

  for i in "${!items[@]}"; do
    local num=$((i + 1))
    local badge
    badge=$(status_badge "${checks[$i]}")
    printf "  ${DIM}%d${RESET}  %-28s %s\n" "$num" "${items[$i]}" "$badge"
  done

  echo ""
  echo -e "  ${DIM}8${RESET}  ${BOLD}Install everything${RESET}"
  echo -e "  ${DIM}0${RESET}  ${DIM}Exit${RESET}"
  echo ""
  echo -e "${DIM}$(printf '%.0s─' {1..44})${RESET}"
  echo -ne "  ${ARROW} "
}

handle_choice() {
  case "$1" in
  1) [ "$OS_TYPE" = "macos" ] && install_homebrew || echo -e "  ${YELLOW}Homebrew is macOS only${RESET}" ;;
  2) install_packages ;;
  3) install_ohmyzsh ;;
  4) install_powerlevel10k ;;
  5) install_plugins ;;
  6) setup_configs ;;
  7) setup_ssh ;;
  8) install_all ;;
  0)
    echo -e "\n  ${DIM}Bye!${RESET}\n"
    exit 0
    ;;
  *) echo -e "\n  ${RED}Invalid option${RESET}" ;;
  esac
}

# -------- Main -------- #
bootstrap_repo
detect_os

while true; do
  print_menu
  read -r choice
  echo ""
  handle_choice "$choice"
  pause
done
