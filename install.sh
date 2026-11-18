#!/usr/bin/env bash

MODE=""
NO_BINDS=0

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

run_custom() {
  if ! confirm_func "$USER is running the script, is this the correct user?"; then
    echo "Please run the script in the correct user. The installer will quit now."
    exit 1
  fi
  echo: "Mode: Custom"
}
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

echo "Welcome to the Shell-Yeah custom Installer."
echo "This script will guide you through setting up and running Shell-Yeah."
if [[ $EUID -eq 0 ]]; then
  echo "ABORTING INSTALLER. Please use a non-root user."
  exit 1
fi

INSTALLER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

case "$MODE" in
auto) echo "mode: auto" ;;
custom) run_custom ;;
check-deps) echo "mode: check-dependencies" ;;
check-integ) echo "mode: check-integ" ;;
*)
  usage
  exit 1
  ;;

esac
