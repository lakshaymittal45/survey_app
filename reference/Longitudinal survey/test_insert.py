import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='1234',
    database='survey_1'
)
cursor = conn.cursor()

print("="*60)
print("CHECKING TABLE CREATION SCRIPT (questions_table_creation.sql)")
print("="*60)

# Check constraints on questions table
cursor.execute("""
    SHOW CREATE TABLE questions
""")
create_table = cursor.fetchone()
if create_table:
    create_sql = create_table[1]
    if 'CHECK' in create_sql:
        print("\n✓ CHECK constraints found in table definition:")
        # Extract CHECK constraints
        import re
        checks = re.findall(r'CONSTRAINT `([^`]+)` CHECK \(([^)]+)\)', create_sql)
        for check_name, check_expr in checks:
            print(f"  {check_name}: {check_expr}")
    else:
        print("\n⚠ WARNING: No CHECK constraints in table definition!")
else:
    print("\nCould not retrieve table definition")

# Try to insert a test question with correct types
print("\n" + "="*60)
print("TEST: Inserting question with valid types")
print("="*60)

try:
    # Get a section ID
    cursor.execute("SELECT section_id FROM questionnaire_sections LIMIT 1")
    section = cursor.fetchone()
    if section:
        section_id = section[0]
        print(f"Using section_id: {section_id}")
        
        # Try insert with valid types
        cursor.execute("""
            INSERT INTO questions (question_section_id, question_text, question_type, answer_type, question_order)
            VALUES (%s, %s, %s, %s, 999)
        """, (section_id, 'Test Question', 'single_choice', 'numerical'))
        
        conn.commit()
        print("✓ Insert successful with question_type='single_choice', answer_type='numerical'")
        
        # Delete the test record
        cursor.execute("DELETE FROM questions WHERE question_order = 999")
        conn.commit()
        print("✓ Test record deleted")
    else:
        print("No sections found to test with")
        
except mysql.connector.Error as e:
    print(f"✗ Insert failed: {e}")

cursor.close()
conn.close()
