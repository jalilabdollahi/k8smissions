#!/bin/bash
set -e

echo "🚀 K8sMissions Installation"
echo "==========================="
echo ""

# ─── Check prerequisites ───────────────────────────────────────────────────────
command -v kind    >/dev/null || { echo "❌ kind not found.    Install: brew install kind";    exit 1; }
command -v kubectl >/dev/null || { echo "❌ kubectl not found. Install: brew install kubectl"; exit 1; }
command -v python3 >/dev/null || { echo "❌ python3 not found"; exit 1; }

# Verify Python >= 3.9
PYTHON_VERSION=$(python3 -c "
import sys
v = sys.version_info
print(f'{v.major}.{v.minor}')
exit(0 if (v.major, v.minor) >= (3, 9) else 1)
") || {
  echo "❌ Python 3.9+ required (found $PYTHON_VERSION)"
  echo "   macOS:  brew install python@3.11"
  echo "   Linux:  sudo apt install python3.11"
  exit 1
}
echo "✅ Python $PYTHON_VERSION"

# Check jq
if ! command -v jq &>/dev/null; then
  echo "📦 Installing jq..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install jq
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update && sudo apt-get install -y jq
  else
    echo "❌ Please install jq manually: https://stedolan.github.io/jq/download/"; exit 1
  fi
fi
echo "✅ jq available"
echo ""

# ─── Python virtual environment ────────────────────────────────────────────────
if [ ! -d "venv" ]; then
  echo "🐍 Creating Python virtual environment..."
  python3 -m venv venv
fi

echo "📦 Installing Python dependencies..."
if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
  source venv/Scripts/activate
else
  echo "❌ venv activation script not found"; exit 1
fi

pip install -q -r requirements.txt
echo "✅ Python packages installed"
echo ""

# ─── Kubernetes cluster ────────────────────────────────────────────────────────
CLUSTER_NAME="k8smissions"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "✅ Cluster '${CLUSTER_NAME}' already exists"
else
  echo "🔧 Creating Kubernetes cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "${CLUSTER_NAME}"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"

# ─── Namespace ─────────────────────────────────────────────────────────────────
echo "🏗️  Setting up namespace '${CLUSTER_NAME}'..."
kubectl create namespace "${CLUSTER_NAME}" --dry-run=client -o yaml | kubectl apply -f -

# ─── RBAC safety guards ────────────────────────────────────────────────────────
echo "🛡️  Applying RBAC safety guards..."
if [ -f "rbac/k8smissions-rbac.yaml" ]; then
  kubectl apply -f rbac/k8smissions-rbac.yaml
  echo "✅ RBAC configured"
else
  echo "⚠️  rbac/k8smissions-rbac.yaml not found — skipping (implement before production use)"
fi

echo ""
echo "════════════════════════════════════"
echo "✅  K8sMissions is ready!"
echo "   Run:  ./play.sh"
echo "════════════════════════════════════"
echo ""
