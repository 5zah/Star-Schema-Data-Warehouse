"""
Root entry point for the Manufacturing Data Warehouse, Scaling, and Reconciliation Framework.
"""
import sys
import os

# Set UTF-8 encoding for standard output on Windows
if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

# Ensure workspace root is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.cli import main

if __name__ == "__main__":
    main()
