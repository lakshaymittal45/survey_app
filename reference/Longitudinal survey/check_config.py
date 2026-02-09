# Quick test to check if database is accessible
import sqlite3
import sys

print("Testing database connection...")
print(f"Python: {sys.version}")
print(f"Path: {sys.path}")

# Check if flask app can import
try:
    sys.path.insert(0, r'C:\Users\HP\OneDrive\Desktop\Longitudinal survey\survey_application')
    # Don't import the full app, just check the config
    print("Checking Flask app configuration...")
    with open(r'C:\Users\HP\OneDrive\Desktop\Longitudinal survey\survey_application\app.py', 'r') as f:
        content = f.read()
        if 'insert_question' in content:
            print("✓ Found insert_question references in app.py")
            # Find the lines
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if 'insert_question' in line and 'CALL' in line:
                    print(f"  Line {i+1}: {line.strip()}")
except Exception as e:
    print(f"✗ Error: {e}")
