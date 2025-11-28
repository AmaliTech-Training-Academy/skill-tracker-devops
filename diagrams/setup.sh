#!/bin/bash
# Setup script for diagram generation

set -e

echo "=========================================="
echo "Skill Tracker - Diagram Setup"
echo "=========================================="
echo ""

# Check Python
echo "🔍 Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ $PYTHON_VERSION found"
else
    echo "❌ Python 3 not found"
    echo "Please install Python 3.7+ from https://www.python.org/"
    exit 1
fi

# Check Graphviz
echo ""
echo "🔍 Checking Graphviz..."
if command -v dot &> /dev/null; then
    GRAPHVIZ_VERSION=$(dot -V 2>&1)
    echo "✅ $GRAPHVIZ_VERSION found"
else
    echo "❌ Graphviz not found"
    echo ""
    echo "Install Graphviz:"
    echo "  macOS:    brew install graphviz"
    echo "  Ubuntu:   sudo apt-get install graphviz"
    echo "  Windows:  choco install graphviz"
    echo ""
    echo "Or download from: https://graphviz.org/download/"
    exit 1
fi

# Install Python packages
echo ""
echo "📦 Installing Python packages..."
if pip3 install -r requirements.txt; then
    echo "✅ Python packages installed"
else
    echo "❌ Failed to install Python packages"
    exit 1
fi

# Verify installation
echo ""
echo "🔍 Verifying installation..."
if python3 -c "import diagrams" 2>/dev/null; then
    echo "✅ diagrams package verified"
else
    echo "❌ diagrams package not found"
    exit 1
fi

# Success
echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "Generate diagrams with:"
echo "  python3 generate_all_diagrams.py"
echo ""
echo "Or generate individual diagrams:"
echo "  python3 generate_architecture.py"
echo "  python3 generate_network.py"
echo "  python3 generate_cicd.py"
echo "  python3 generate_monitoring.py"
echo "  python3 generate_data_flow.py"
echo ""
