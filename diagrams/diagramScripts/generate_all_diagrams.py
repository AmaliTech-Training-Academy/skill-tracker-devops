#!/usr/bin/env python3
"""
Generate all Skill Tracker architecture diagrams
Requires: pip install diagrams
"""

import subprocess
import sys
import os

# List of diagram scripts
DIAGRAM_SCRIPTS = [
    "generate_architecture.py",
    "generate_network.py",
    "generate_cicd.py",
    "generate_monitoring.py",
    "generate_data_flow.py",
]

def check_dependencies():
    """Check if required packages are installed"""
    try:
        import diagrams
        print("✅ diagrams package is installed")
        return True
    except ImportError:
        print("❌ diagrams package not found")
        print("\nInstall it with:")
        print("  pip install diagrams")
        print("\nOr:")
        print("  pip install -r requirements.txt")
        return False

def generate_diagram(script_name):
    """Generate a single diagram"""
    print(f"\n🎨 Generating {script_name}...")
    try:
        result = subprocess.run(
            [sys.executable, script_name],
            capture_output=True,
            text=True,
            check=True
        )
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error generating {script_name}")
        print(e.stderr)
        return False

def main():
    """Main function to generate all diagrams"""
    print("=" * 60)
    print("Skill Tracker - Diagram Generator")
    print("=" * 60)

    # Check dependencies
    if not check_dependencies():
        sys.exit(1)

    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # Generate all diagrams
    success_count = 0
    for script in DIAGRAM_SCRIPTS:
        if generate_diagram(script):
            success_count += 1

    # Summary
    print("\n" + "=" * 60)
    print(f"✅ Successfully generated {success_count}/{len(DIAGRAM_SCRIPTS)} diagrams")
    print("=" * 60)

    if success_count == len(DIAGRAM_SCRIPTS):
        print("\n📁 Generated files:")
        print("  - architecture_overview.png")
        print("  - network_architecture.png")
        print("  - cicd_pipeline.png")
        print("  - monitoring_stack.png")
        print("  - data_flow.png")
        print("\n💡 View these diagrams in your image viewer or include them in documentation")
    else:
        print(f"\n⚠️  {len(DIAGRAM_SCRIPTS) - success_count} diagram(s) failed to generate")
        sys.exit(1)

if __name__ == "__main__":
    main()
