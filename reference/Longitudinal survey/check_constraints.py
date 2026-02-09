#!/usr/bin/env python3
"""
Check the CHECK constraints on questions table
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'survey_application'))

from survey_application.app import app, db
from sqlalchemy import text

print("Checking questions table constraints...\n")

with app.app_context():
    # Get table creation info
    result = db.session.execute(text("SHOW CREATE TABLE questions"))
    row = result.fetchone()
    if row:
        table_def = row[1]
        print("TABLE DEFINITION:")
        print(table_def)
        print("\n" + "=" * 80)
    
    # Get constraints info
    result = db.session.execute(text("""
        SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE TABLE_NAME = 'questions' AND TABLE_SCHEMA = DATABASE()
    """))
    constraints = result.fetchall()
    
    print("\nCONSTRAINTS:")
    for constraint in constraints:
        print(f"  {constraint[0]:30} ({constraint[1]})")
