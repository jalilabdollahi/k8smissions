#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "K8sMissions Installation (Ubuntu)"
echo "================================="
echo

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required on Ubuntu to install missing packages."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: This installer is for Ubuntu/Debian systems with apt-get."
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

echo "Checking system dependencies..."
ensure_cmd curl curl
ensure_cmd jq jq
ensure_cmd python3 python3
ensure_cmd kind kind

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl is not installed."
  echo "Install it first, for example:"
  echo "  sudo snap install kubectl --classic"
  echo "or follow:"
  echo "  https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
  exit 1
fi

if ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)'; then
  echo "ERROR: Python 3.9+ is required."
  python3 --version || true
  exit 1
fi

echo "Python version: $(python3 --version 2>&1)"

if ! python3 -m venv --help >/dev/null 2>&1; then
  echo "Installing Python venv support..."
  apt_install python3-venv
fi

echo "System dependencies are ready."
echo

if [ -d "venv" ] && [ ! -x "venv/bin/python" ]; then
  echo "Removing incompatible virtual environment copied from another machine..."
  rm -rf venv
fi

if [ -L "venv/bin/python3" ] && readlink "venv/bin/python3" | grep -q "/opt/homebrew/"; then
  echo "Removing macOS virtual environment so Ubuntu can rebuild it..."
  rm -rf venv
fi

if [ ! -d "venv" ]; then
  echo "Creating Python virtual environment..."
  python3 -m venv venv
fi

echo "Installing Python dependencies..."
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python"

if [ ! -x "$VENV_PYTHON" ]; then
  echo "Installing Python venv support..."
  apt_install python3-venv python3-pip python3-full
  rm -rf venv
  python3 -m venv venv
fi

if ! "$VENV_PYTHON" -m pip --version >/dev/null 2>&1; then
  echo "Rebuilding virtual environment with pip support..."
  apt_install python3-venv python3-pip python3-full
  rm -rf venv
  python3 -m venv venv
fi

"$VENV_PYTHON" -m pip install -q --upgrade pip
"$VENV_PYTHON" -m pip install -q -r requirements.txt
echo "Python packages installed."
echo

CLUSTER_NAME="k8smissions"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists."
else
  echo "Creating Kubernetes cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "${CLUSTER_NAME}"
fi

kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

echo "Setting up namespace '${CLUSTER_NAME}'..."
kubectl create namespace "${CLUSTER_NAME}" --dry-run=client -o yaml | kubectl apply -f -

echo "Applying RBAC safety guards..."
if [ -f "rbac/k8smissions-rbac.yaml" ]; then
  kubectl apply -f rbac/k8smissions-rbac.yaml
  echo "RBAC configured."
else
  echo "WARNING: rbac/k8smissions-rbac.yaml not found; skipping."
fi

echo
echo "K8sMissions is ready."
echo "Run: ./play.sh"
