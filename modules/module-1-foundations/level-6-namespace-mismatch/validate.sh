#!/bin/bash

echo "🔍 Checking resource namespaces..."

# Check if resources exist in k8smissions namespace
POD_EXISTS=$(kubectl get pod client-app -n k8smissions 2>/dev/null)
SERVICE_EXISTS=$(kubectl get service backend-service -n k8smissions 2>/dev/null)

# Check if they're in wrong namespace
POD_IN_DEFAULT=$(kubectl get pod client-app -n default 2>/dev/null)
SERVICE_IN_DEFAULT=$(kubectl get service backend-service -n default 2>/dev/null)

if [[ -n "$POD_EXISTS" ]] && [[ -n "$SERVICE_EXISTS" ]]; then
    echo "   Pod: ✅ Found in k8smissions namespace"
    echo "   Service: ✅ Found in k8smissions namespace"
    echo "✅ Resources correctly deployed to k8smissions namespace"
    exit 0
else
    echo "❌ Resources not found in k8smissions namespace"
    if [[ -n "$POD_IN_DEFAULT" ]] || [[ -n "$SERVICE_IN_DEFAULT" ]]; then
        echo "💡 Found resources in 'default' namespace - they should be in 'k8smissions'"
    fi
    echo "💡 Check: kubectl get all -n k8smissions"
    echo "💡 Check: kubectl get all -n default"
    exit 1
fi
