#!/usr/bin/env bash

MODE=""
NO_BINDS=0

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

echo $INSTALLER_DIR
confirm_func() {
  local answer
  while true; do
    read -r -p "$1 [Y/n]: " answer
    case "${answer}" in
    y | yes | "") return 0 ;;
    n | no) return 1 ;;
    *) echo "please type y or n" ;;
    esac
  done
}
if confirm_func "$USER is running this script. is this the correct user?"; then
  echo "The Installer will install all files to $HOME and relative directories"
else
  echo "Please run the script from the correct user. The installer will quit now."
  exit 1
fi
