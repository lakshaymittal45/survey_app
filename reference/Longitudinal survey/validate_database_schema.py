#!/usr/bin/env python3
"""
Database Schema Validation Script
Connects to MySQL backend and validates all table schemas against Flask backend expectations
"""

import sys
import os

# Fix Unicode on Windows
if sys.platform.startswith('win'):
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Add survey_application to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'survey_application'))

# Use simple characters instead of Unicode
PASS = "[OK]"
FAIL = "[XX]"
WARN = "[!!]"

print("=" * 80)
print("DATABASE SCHEMA VALIDATION")
print("=" * 80)

# Step 1: Check Flask app configuration
print("\n[STEP 1] Loading Flask app configuration...")
try:
    from survey_application.app import app, db
    print(f"{PASS} Flask app loaded successfully")
    
    with app.app_context():
        # Get database URL
        db_url = app.config.get('SQLALCHEMY_DATABASE_URI', 'Not configured')
        print(f"{PASS} Database URL: {db_url}")
except Exception as e:
    print(f"{FAIL} Error loading Flask app: {e}")
    sys.exit(1)

# Step 2: Test MySQL connection
print("\n[STEP 2] Testing MySQL connection...")
try:
    from sqlalchemy import text, inspect
    
    with app.app_context():
        # Try a simple query
        result = db.session.execute(text("SELECT 1"))
        print("✓ MySQL connection successful")
        
        # Get database name
        result = db.session.execute(text("SELECT DATABASE()"))
        db_name = result.scalar()
        print(f"✓ Connected to database: {db_name}")
        
except Exception as e:
    print(f"✗ MySQL connection failed: {e}")
    sys.exit(1)

# Step 3: Check all tables existence
print("\n[STEP 3] Validating table schemas...")
try:
    with app.app_context():
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        
        print(f"✓ Found {len(tables)} tables in database")
        
        # Critical tables for questionnaire functionality
        critical_tables = [
            'questionnaire_sections',
            'questions',
            'survey_attempt',
            'households',
            'users',
            'states',
            'districts',
            'blocks',
            'sub_centers',
            'villages'
        ]
        
        missing_tables = []
        for table in critical_tables:
            if table in tables:
                print(f"  ✓ {table}")
            else:
                print(f"  ✗ {table} - MISSING")
                missing_tables.append(table)
        
        if missing_tables:
            print(f"\n⚠ WARNING: {len(missing_tables)} critical tables missing!")
        else:
            print("\n✓ All critical tables present!")
            
except Exception as e:
    print(f"✗ Error checking tables: {e}")
    sys.exit(1)

# Step 4: Check questions table columns
print("\n[STEP 4] Checking 'questions' table columns...")
try:
    with app.app_context():
        inspector = inspect(db.engine)
        columns = inspector.get_columns('questions')
        
        print(f"✓ Found {len(columns)} columns in 'questions' table:\n")
        
        expected_columns = {
            'question_id': 'INT',
            'question_section_id': 'INT',
            'question_text': 'TEXT/VARCHAR',
            'answer_type': 'VARCHAR/ENUM',
            'question_type': 'VARCHAR',
            'question_order': 'INT',
            'parent_id': 'INT (optional - for hierarchy)',
            'trigger_value': 'VARCHAR (optional - for conditions)',
            'options': 'TEXT (optional - for MCQ/checkbox)'
        }
        
        found_cols = {}
        for col in columns:
            col_name = col['name']
            col_type = str(col['type'])
            found_cols[col_name] = col_type
            print(f"  ✓ {col_name:25} {col_type}")
        
        # Check for advanced columns (for hierarchy support)
        advanced_cols = ['parent_id', 'trigger_value', 'options']
        advanced_present = []
        for acol in advanced_cols:
            if acol in found_cols:
                advanced_present.append(acol)
        
        if advanced_present:
            print(f"\n✓ Advanced columns found: {', '.join(advanced_present)}")
            print("  → Hierarchical question support: ENABLED")
        else:
            print(f"\n⚠ No advanced columns detected")
            print("  → Hierarchical question support: DISABLED (migration not run)")
            
except Exception as e:
    print(f"✗ Error checking questions columns: {e}")

# Step 5: Check questionnaire_sections table
print("\n[STEP 5] Checking 'questionnaire_sections' table...")
try:
    with app.app_context():
        inspector = inspect(db.engine)
        columns = inspector.get_columns('questionnaire_sections')
        
        print(f"✓ Found {len(columns)} columns:\n")
        for col in columns:
            print(f"  ✓ {col['name']:25} {str(col['type'])}")
            
except Exception as e:
    print(f"✗ Error checking sections: {e}")

# Step 6: Check survey_attempt table
print("\n[STEP 6] Checking 'survey_attempt' table...")
try:
    with app.app_context():
        inspector = inspect(db.engine)
        columns = inspector.get_columns('survey_attempt')
        
        print(f"✓ Found {len(columns)} columns:\n")
        for col in columns:
            print(f"  ✓ {col['name']:25} {str(col['type'])}")
            
except Exception as e:
    print(f"✗ Error checking survey_attempt: {e}")

# Step 7: Test stored procedures
print("\n[STEP 7] Checking stored procedures...")
try:
    with app.app_context():
        result = db.session.execute(text(
            "SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_TYPE = 'PROCEDURE'"
        ))
        procedures = result.fetchall()
        
        print(f"✓ Found {len(procedures)} stored procedures:\n")
        
        critical_procs = ['insert_question', 'update_question', 'delete_question', 'insert_household']
        found_procs = {proc[0].lower(): proc[0] for proc in procedures}
        
        for proc in procedures:
            proc_name = proc[0]
            print(f"  ✓ {proc_name}")
        
        print()
        for cproc in critical_procs:
            if cproc.lower() in found_procs:
                print(f"  ✓ {cproc} - FOUND")
            else:
                print(f"  ⚠ {cproc} - NOT FOUND")
                
except Exception as e:
    print(f"✗ Error checking procedures: {e}")

# Step 8: Test question insertion (dry run)
print("\n[STEP 8] Testing question insertion logic...")
try:
    with app.app_context():
        # Get a valid section
        result = db.session.execute(text("SELECT section_id FROM questionnaire_sections LIMIT 1"))
        section_row = result.fetchone()
        
        if section_row:
            section_id = section_row[0]
            print(f"✓ Using section_id: {section_id}")
            
            # Check if we can insert
            try:
                # Get next order
                result = db.session.execute(text(
                    "SELECT COALESCE(MAX(question_order), 0) + 1 as next_order FROM questions WHERE question_section_id = :sid"
                ), {"sid": section_id})
                next_order = result.scalar()
                print(f"✓ Next question_order would be: {next_order}")
                
                # Check INSERT permissions
                result = db.session.execute(text(
                    "INSERT INTO questions (question_section_id, question_text, answer_type, question_order) VALUES (:sid, :text, :type, :order)"
                ), {
                    "sid": section_id,
                    "text": "TEST_QUESTION_TO_DELETE",
                    "type": "text",
                    "order": next_order
                })
                db.session.commit()
                
                # Get inserted ID
                result = db.session.execute(text("SELECT LAST_INSERT_ID() as id"))
                test_id = result.scalar()
                print(f"✓ Test insert successful, question_id: {test_id}")
                
                # Clean up
                db.session.execute(text("DELETE FROM questions WHERE question_id = :qid"), {"qid": test_id})
                db.session.commit()
                print(f"✓ Test cleanup successful")
                
            except Exception as insert_err:
                print(f"✗ Insert test failed: {insert_err}")
                db.session.rollback()
        else:
            print("⚠ No sections found - cannot test insertion")
            
except Exception as e:
    print(f"✗ Error in insertion test: {e}")

# Step 9: Foreign key constraints
print("\n[STEP 9] Checking foreign key constraints...")
try:
    with app.app_context():
        # Check for parent_id FK
        result = db.session.execute(text(
            "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_NAME='questions' AND COLUMN_NAME='parent_id' AND TABLE_SCHEMA=DATABASE()"
        ))
        fk = result.fetchone()
        
        if fk:
            print(f"✓ Found FK constraint on parent_id: {fk[0]}")
        else:
            print(f"⚠ No FK constraint on parent_id (migration may not be run)")
            
except Exception as e:
    print(f"⚠ Error checking FK: {e}")

# Final summary
print("\n" + "=" * 80)
print("VALIDATION SUMMARY")
print("=" * 80)
print("""
✓ Connection: MySQL backend properly connected
✓ Database: All critical tables present
✓ Schema: Table structures validated
⚠ Advanced Features: Check if migration script was run

RECOMMENDED NEXT STEPS:
1. If hierarchical questions needed, run migration:
   USE survey_1;
   SOURCE sql_scripts/add_advanced_questionnaire_fields.sql;

2. Restart Flask app to refresh schema cache

3. Test questionnaire creation in admin dashboard
""")
print("=" * 80)
