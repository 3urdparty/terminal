#!/usr/bin/env bash
set -e

# -------- variables -------- #
repo_dir="$(pwd)"
ssh_dir="$home/.ssh"
config_dir="$home/.config"
oh_my_zsh_dir="$home/.oh-my-zsh"
zsh_custom="${zsh_custom:-$oh_my_zsh_dir/custom}"
ssh_key="$ssh_dir/id_ed25519_github"

# -------- functions -------- #
install_macos() {
  echo "[*] setting up for macos..."

  # homebrew
  if ! command -v brew &>/dev/null; then
    echo "[*] homebrew not found, installing..."
    /bin/bash -c "$(curl -fssl https://raw.githubusercontent.com/homebrew/install/head/install.sh)"
    echo >>"$home/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$home/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "[*] homebrew already installed. skipping..."
  fi

  # packages
  for pkg in kitty neovim zsh git; do
    if ! brew list --formula | grep -q "^$pkg\$"; then
      echo "[*] installing $pkg..."
      brew install "$pkg"
    else
      echo "[*] $pkg already installed. skipping..."
    fi
  done
}

install_ubuntu() {
  echo "[*] setting up for ubuntu..."

  # update + packages
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y kitty zsh git curl wget
  sudo snap install --classic nvim
}

common_setup() {
  # kitty config
  if [ -d "$repo_dir/kitty" ]; then
    echo "[*] setting up kitty config..."
    mkdir -p "$config_dir/kitty"
    cp -r "$repo_dir/kitty/"* "$config_dir/kitty/"
  else
    echo "[!] skipping kitty config — repo folder not found."
  fi

  # neovim config
  if [ -d "$repo_dir/nvim" ]; then
    echo "[*] setting up nvim config..."
    mkdir -p "$config_dir/nvim"
    cp -r "$repo_dir/nvim/"* "$config_dir/nvim/"
  else
    echo "[!] skipping nvim config — repo folder not found."
  fi

  # oh my zsh
  if [ ! -d "$oh_my_zsh_dir" ]; then
    echo "[*] installing oh my zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$oh_my_zsh_dir"
  else
    echo "[*] oh my zsh already installed. skipping..."
  fi

  # zsh config
  if [ -f "$repo_dir/zshrc" ]; then
    echo "[*] setting up zsh config..."
    cp "$repo_dir/zshrc" "$home/.zshrc"
  else
    echo "[!] skipping zshrc copy — not found in repo."
  fi

  # zsh plugins
  mkdir -p "$zsh_custom/plugins"

  # install zsh-autosuggestions if not already installed
  if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
  else
    echo "[*] zsh-autosuggestions already installed. skipping..."
  fi

  # install zsh-syntax-highlighting if not already installed
  if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
  else
    echo "[*] zsh-syntax-highlighting already installed. skipping..."
  fi

# copy your custom p10k.zsh from your repo to your home directory
  if [ -f "$repo_dir/p10k.zsh" ]; then
    echo "[*] setting up p10k config from repo..."
    cp "$repo_dir/p10k.zsh" "$home/.p10k.zsh"
  else
    echo "[!] skipping p10k.zsh copy — not found in repo."
  fi

  # clone powerlevel10k theme (the actual engine) if not already installed
  if [ ! -d "${zsh_custom:-$home/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "[*] cloning powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${zsh_custom:-$home/.oh-my-zsh/custom}/themes/powerlevel10k"
  else
    echo "[*] powerlevel10k theme already installed. skipping..."
  fi

  # ssh config
  echo "[*] setting up ssh config..."
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  if [ -f "$repo_dir/ssh/macos.config" ] && [ "$os_type" = "macos" ]; then
    cp "$repo_dir/ssh/macos.config" "$ssh_dir/config"
    chmod 600 "$ssh_dir/config"
  elif [ -f "$repo_dir/ssh/ubuntu.config" ] && [ "$os_type" = "ubuntu" ]; then
    cp "$repo_dir/ssh/ubuntu.config" "$ssh_dir/config"
    chmod 600 "$ssh_dir/config"
  else
    echo "[!] skipping ssh config copy — not found for $os_type."
  fi

  email="3urdparty@gmail.com"
  # ssh key
  if [ ! -f "$ssh_key" ]; then
    echo "[*] generating new ssh key for github..."
    ssh-keygen -t ed25519 -c "$email" -f "$ssh_key" -n ""
    eval "$(ssh-agent -s)"
    if [ "$os_type" = "macos" ]; then
      ssh-add --apple-use-keychain "$ssh_key"
    else
      ssh-add "$ssh_key"
    fi

    # append to ssh config
    {
      echo ""
      echo "host github.com"
      echo "  addkeystoagent yes"
      [ "$os_type" = "macos" ] && echo "  usekeychain yes"
      echo "  identityfile $ssh_key"
    } >>"$ssh_dir/config"

    echo "[*] ssh key generated. copy this to github ssh settings:"
    cat "$ssh_key.pub"
  else
    echo "[*] ssh key already exists: $ssh_key. skipping..."
  fi
}

# -------- main -------- #
if [ $# -lt 1 ]; then
  echo "usage: $0 [macos|ubuntu]"
  exit 1
fi

os_type="$1"

case "$os_type" in
macos) install_macos ;;
ubuntu) install_ubuntu ;;
*)
  echo "unknown option: $os_type"
  echo "usage: $0 [macos|ubuntu]"
  exit 1
  ;;
esac

common_setup

echo "[*] setup complete!"
echo "⚡ restart terminal or run 'exec zsh' to apply changes."
