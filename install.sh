#!/usr/bin/env bash
# read thru this bitch i dare you
# ------argument binds------
MODE=""
NO_BINDS=0
installer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
missing_aur=()
depcheck() {
  echo "----------------------------"
  echo "Checking dependency installs"
  echo "----------------------------"
  for pkg in "${CORE_PKGS[@]}"; do
    pacman -Qq "$pkg" || missing+=("$pkg")
  done
  for pkgs in "${CORE_AUR_PKGS[@]}"; do
    pacman -Qq "$pkgs" || missing_aur+=("$pkgs")
  done
  for pkg1 in "${OPTIONAL_PKGS[@]}"; do
    pacman -Qq "$pkg1" || missing+=("$pkg1")
  done
  if ((${#missing[@]} > 0 || ${#missing_aur[@]} > 0)); then
    cat <<EOF
Missing Packages found:
------pacman------
$(printf '  - %s\n' "${missing[@]}")
------  AUR  ------
$(printf '  - %s\n' "${missing_aur[@]}")
If running --check-deps or --custom with manual install, please install these packages. Otherwise, the script will handle the install for you
EOF
  else
    echo "All packages from pacman have been found. No installs required."
  fi

}
#-----------Finds AUR helper, prefers paru over yay-------------
detect_aur_helper() {
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    echo "---------------------------"
    echo -e "AUR helper is \033[1;32m$AUR_HELPER\033[1;0m"
    echo "---------------------------"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    echo "---------------------------"
    echo -e "AUR helper is \033[1;32m$AUR_HELPER\033[1;0m"
    echo "---------------------------"
  else
    AUR_HELPER=""
    echo "No compatible AUR helper found (yay/paru), please use custom install options with manual package install"
  fi
}

#--------installer using pacman and detected AUR HElper--------
failed_pkgs=()

download() {
  echo "---------------------------------------------"
  echo "Now running package Install for ${missing[*]} ${missing_aur[*]}"
  echo "---------------------------------------------"
  echo "please enter your sudo password (This is needed to install the packages):"
  if ! sudo -v; then
    echo "Password auth failed. the script will exit now."
    exit 1
  fi
  if ((${#missing[@]} <= 0)); then
    echo "No missing pacman repo packages, Moving to AUR packages."
  else
    for pkgs in "${missing[@]}"; do
      sudo pacman -S --noconfirm $pkgs
      if [[ -z $(pacman -Qq "$pkgs") ]]; then
        echo "Package install failed. Moving to next package." && failed_pkgs+=("$pkgs")
      else
        echo -e "\033[1;32mPackage installed:\033[1;0m $pkgs"
      fi
    done
  fi
  if ((${#missing_aur[@]} <= 0)); then
    echo "No missing AUR packages. If the script didnt find your AUR helper, please use --custom flag with manual install, otherwise, ignore this message"
  else
    if [[ -n $AUR_HELPER ]]; then
      for pkg1 in "${missing_aur[@]}"; do
        "$AUR_HELPER" -S --noconfirm "$pkg1"
        if [[ -z $(pacman -Qq "$pkg1") ]]; then
          echo "Package install failed. Moving to next package." && failed_pkgs+=("$pkg1")
        else
          echo -e "\033[1;32mPackage installed:\033[1;0m $pkg1"
        fi
      done
    fi
  fi
  if ((${#failed_pkgs[@]} > 0)); then
    echo "These Packages failed to install, please run --custom with manual install and install these beforehand."
    echo "----------------------------------"
    echo "${failed_pkgs[@]}"
    echo "----------------------------------"
  fi
}

#--------quickshell config writing stuff------------
target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

qs_conf_backup_or_create() {
  echo "------------------------------------------------------"
  echo "Now checking quickshell config files and directories. "
  echo "------------------------------------------------------"
  if [[ -d "$target_dir" && -n "$(ls -A "$target_dir")" ]]; then
    echo "$target_dir exists and has files in it. Moving to a backup; ${target_dir}.bak"
    cp -r "$target_dir" "${target_dir}.bak"
    echo "backup created, moving Shell-Yeah files to $target_dir"
    cp -r "$installer_dir/quickshell" "$target_dir"
  elif [[ -d "$target_dir" && ! -n "$(ls -A "$target_dir")" ]]; then
    echo "$target_dir exists, but is empty, removing quickshell dir"
    rm -rf "$target_dir"
    echo "Moving Shell-Yeah files into ${target_dir}"
    cp -r "$installer_dir/quickshell" "$target_dir"
  else
    echo "$target_dir does not exist. Creating..."
    cp -r "$installer_dir/quickshell" "$target_dir"
  fi
  if [[ -d "$target_dir" && -n "$(ls -A "$target_dir")" ]]; then
    echo "Shell-Yeah files copied, run --check-integ after full install completes to verify files."
  fi
}

# ------ mango config detection-------------
mango_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mango"
mango_conf_file="${XDG_CONFIG_HOME:-$HOME/.config}/mango/config.conf"
mango_toml_file="${XDG_CONFIG_HOME:-$HOME/.config}/mango/config.toml"
mango_style=""
detect_mango_conf() {
  echo "---------------------------"
  if [[ -d "$mango_dir" ]]; then
    echo "Mango directory is $mango_dir"
    echo "--------------------------------------------"
    if [[ -f "$mango_conf_file" ]]; then
      mango_style=".conf"
      echo "Mango config file type: $mango_style"
      echo "----------------------------------"
    elif [[ -f "$mango_toml_file" ]]; then
      mango_style=".toml"
      echo "Mango config file type: $mango_style"
      echo "-----------------------------------"
    fi
  else
    echo "Local mango directory not found, the installer will not create one unless in --auto mode"
  fi
}

mango_write_file() {
  echo "WRITE FILE FUNC"
}

# ----- auto flag runner using the above functions-----------
run_auto() {
  echo "Mode: Auto"
  echo "The Installer will check dependencies, ask for password, and install shell + packages."
  detect_aur_helper
  depcheck
  if ((${#missing[@]} > 0 || ${#missing_aur[@]} > 0)); then
    download
  fi
  qs_conf_backup_or_create
  detect_mango_conf
  mango_write_file

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
  detect_aur_helper
  depcheck
  echo -e "\033[1;32m-----dependency check done.\033[1;0m you can now use --auto or --custom to fully install Shell-Yeah-----"
}
# general ass y/n prompter
confirm_func() {
  local answer
  while true; do
    read -r -p "$1 [Y/n]: " answer
    case "${answer}" in
    y | yes | Y | YES | "") return 0 ;;
    n | no | N | NO) return 1 ;;
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
auto) run_auto ;;
custom) run_custom ;;
check-deps) run_checkdeps ;;
check-integ) echo "mode: check-integ" ;;
*)
  usage
  exit 1
  ;;

esac
