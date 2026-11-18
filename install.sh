#!/usr/bin/env bash
# read thru this bitch i dare you
# ------argument binds------
MODE=""
NO_BINDS=0

# ------colors------
GREEN=$'\033[32m'
RESET=$'\033[0m'

# ------help menu setup------
usage() {
  cat <<EOF
Usage: ./install.sh [mode] [options]

Modes: 
  --auto,            fully automatic install (only asks for sudo before package install)

  --custom,          interactive install: pick features and how to install packages.

  --check-deps,      check dependencies installed, recomended for manual package install

  --check-integ,     verify files post-install

  ---Note: Both check modes do not edit, create, or touch any files in your system---

Options: 
  --no-binds,        do not touch mango config (Note: this will still edit the config files for border colors)

  --help,            show this help menu. 

EOF
}
# ------package dependencies array------
CORE_PKGS=(quickshell cliphist wl-clipboard brightnessctl ttf-meslo-nerd xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr)
CORE_AUR_PKGS=(mangowm-git python-pywal16-git)
OPTIONAL_PKGS=(grim slurp gnome-keyring)

# ------pacman/aur package detection------
AUR_HELPER=""
missing=()
depcheck() {
  for pkg in "${CORE_PKGS[@]}"; do
    pacman -Qq "$pkg" &>/dev/null
    echo -e "\033[1;32mPackage Found:\033[1;0m $pkg" || missing+="$pkg"
  done
  for pkgs in "${CORE_AUR_PKGS[@]}"; do
    pacman -Qq "$pkgs"
    echo -e "\033[1;32mPackage Found:\033[1;0m $pkgs" || missing+="$pkgs"
  done
  for pkg1 in "${OPTIONAL_PKGS[@]}"; do
    pacman -Qq "$pkg1"
    echo -e "\033[1;32mPackage Found:\033[1;0m $pkg1" || missing+="$pkg1"
  done
  if ((${#missing} > 0)); then
    echo "Missing packages: ${missing[*]}. run 'sudo pacman -S ${missing[*]}' to install."
  else
    echo "All packages from pacman have been found. No installs required."
  fi

}
detect_aur_helper() {
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    echo "AUR helper is $AUR_HELPER"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    echo "AUR helper is $AUR_HELPER"
  else
    AUR_HELPER=""
    echo "No compatible AUR helper found (yay/paru), please use custom install options with manual package install"
  fi
}

# ------custom mode runner------
run_custom() {
  if ! confirm_func "$USER is running the script, is this the correct user?"; then
    echo "Please run the script in the correct user. The installer will quit now."
    exit 1
  fi
  echo "Mode: Custom"
}

# ------dep-check runner------
run_checkdeps() {
  echo "mode: check-deps"
  echo "running checks for Core and Optional Packages"
  depcheck
  detect_aur_helper
  echo -e "\033[1;32m-----dependency check done.\033[1;0m you can now use --auto or --custom to fully install Shell-Yeah-----"
}
# general ass y/n prompter
confirm_func() {
  local answer
  while true; do
    read -r -p "$1 [Y/n]: " answer
    case "${answer}" in
    y | yes | Y | YES | "") return 0 ;;
    n | no) return 1 ;;
    *) echo "please type y or n" ;;
    esac
  done
}

# fuckin which mode did you select
for arg in "$@"; do
  case "$arg" in
  --auto) MODE="auto" ;;
  --custom) MODE="custom" ;;
  --check-deps) MODE="check-deps" ;;
  --check-integ) MODE="check-integ" ;;
  --no-binds) NO_BINDS=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "unknown option: $arg"
    exit 1
    ;;
  esac
done

# we finally get to actual output
echo "Welcome to the Shell-Yeah custom Installer."
echo "This script will guide you through setting up and running Shell-Yeah."
if [[ $EUID -eq 0 ]]; then
  echo "ABORTING INSTALLER. Please use a non-root user."
  exit 1
fi

case "$MODE" in
auto) echo "mode: auto" ;;
custom) run_custom ;;
check-deps) run_checkdeps ;;
check-integ) echo "mode: check-integ" ;;
*)
  usage
  exit 1
  ;;

esac
