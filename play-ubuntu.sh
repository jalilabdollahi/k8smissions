#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

clear

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required on Ubuntu to install missing packages."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: This launcher is for Ubuntu/Debian systems with apt-get."
  exit 1
fi

APT_UPDATED=0

apt_install() {
  if [ "$APT_UPDATED" -eq 0 ]; then
    echo "Refreshing apt package index..."
    sudo apt-get update
    APT_UPDATED=1
  fi

  sudo apt-get install -y "$@"
}

ensure_cmd() {
  local cmd="$1"
  local package="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Installing missing package: $package"
    apt_install "$package"
  fi
}

# Reset option
if [[ "${1:-}" == "--reset" ]]; then
  if [ ! -f "progress.json" ]; then
    echo "No progress file found; nothing to reset."
    exit 0
  fi

  read -r -p "Reset all progress? This cannot be undone. [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    PLAYER=$(
      python3 -c "import json; d=json.load(open('progress.json')); print(d.get('player_name',''))" \
        2>/dev/null || echo ""
    )
    echo "{\"player_name\":\"$PLAYER\",\"total_xp\":0,\"completed_levels\":[],\"current_module\":\"\",\"current_level\":\"\",\"module_certificates\":[]}" > progress.json
    echo "Progress reset. Starting from Module 1 Level 1."
  else
    echo "Cancelled."
    exit 0
  fi
fi

ensure_cmd jq jq
ensure_cmd python3 python3

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl is not installed."
  exit 1
fi

if ! command -v kind >/dev/null 2>&1; then
  echo "ERROR: kind is not installed."
  exit 1
fi

if ! python3 -m venv --help >/dev/null 2>&1; then
  apt_install python3-venv python3-pip python3-full
fi

if [ ! -x "venv/bin/python" ]; then
  echo "Creating Ubuntu virtual environment..."
  rm -rf venv
  python3 -m venv venv
fi

VENV_PYTHON="$SCRIPT_DIR/venv/bin/python"

if [ -L "venv/bin/python3" ] && readlink "venv/bin/python3" | grep -q "/opt/homebrew/"; then
  echo "Replacing incompatible macOS virtual environment..."
  rm -rf venv
  python3 -m venv venv
fi

if ! "$VENV_PYTHON" -m pip --version >/dev/null 2>&1; then
  echo "Rebuilding virtual environment with pip support..."
  apt_install python3-venv python3-pip python3-full
  rm -rf venv
  python3 -m venv venv
fi

echo "Checking Python dependencies..."
"$VENV_PYTHON" -m pip install -q --upgrade pip
"$VENV_PYTHON" -m pip install -q -r requirements.txt

export PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}"
exec "$VENV_PYTHON" -m engine.engine
