#!/bin/bash
# ============================================================
# Telco Customer Churn App - Local Startup Script
# Run this from the project root directory:  bash start_app.sh
# ============================================================

set -e

# Navigate to the project root (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📂 Working directory: $SCRIPT_DIR"

# Point to the local MLflow model artifacts
export MODEL_DIR="$SCRIPT_DIR/src/serving/model/3b1a41221fc44548aed629fa42b762e0/artifacts/model"

# Ensure feature_columns.txt is accessible alongside the model
# (inference.py looks for it at MODEL_DIR/feature_columns.txt)
FEATURE_FILE="$MODEL_DIR/feature_columns.txt"
ARTIFACTS_DIR="$SCRIPT_DIR/src/serving/model/3b1a41221fc44548aed629fa42b762e0/artifacts"

if [ ! -f "$FEATURE_FILE" ]; then
    echo "📋 Copying feature_columns.txt into model directory..."
    cp "$ARTIFACTS_DIR/feature_columns.txt" "$MODEL_DIR/"
fi

# Set PYTHONPATH so src/ submodules are importable
export PYTHONPATH="$SCRIPT_DIR/src"

echo ""
echo "✅ MODEL_DIR  : $MODEL_DIR"
echo "✅ PYTHONPATH : $PYTHONPATH"
echo ""

# Install libomp via Homebrew (required by XGBoost on macOS)
if ! brew list libomp &>/dev/null; then
    echo "📦 Installing libomp (required by XGBoost on macOS)..."
    brew install libomp
fi

# Install Python dependencies if needed
if ! python3 -c "import fastapi, gradio, mlflow, xgboost" 2>/dev/null; then
    echo "📦 Installing Python dependencies (this may take a minute)..."
    pip3 install fastapi uvicorn gradio mlflow scikit-learn xgboost pandas numpy "httpx[socks]" --quiet
fi

echo "🚀 Starting Telco Churn Prediction App on http://localhost:8000"
echo "   → Gradio UI  : http://localhost:8000/ui"
echo "   → API docs   : http://localhost:8000/docs"
echo "   → Health     : http://localhost:8000/"
echo ""
echo "   Press Ctrl+C to stop the server."
echo ""

# Launch the FastAPI + Gradio app
python3 -m uvicorn src.app.main:app --host 0.0.0.0 --port 8000
