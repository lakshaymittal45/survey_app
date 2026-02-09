import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='1234',
    database='survey_1'
)
cursor = conn.cursor()

print("="*70)
print("ADDING 'options' COLUMN TO questions TABLE")
print("="*70)

try:
    # Add the options column if it doesn't exist
    alter_sql = """
        ALTER TABLE questions
        ADD COLUMN options JSON DEFAULT NULL AFTER answer_type
    """
    
    print("\nExecuting ALTER TABLE...")
    cursor.execute(alter_sql)
    conn.commit()
    print("✓ Column 'options' added successfully")
    
    # Verify it was added
    cursor.execute("DESCRIBE survey_1.questions")
    columns = cursor.fetchall()
    print("\nUpdated table schema:")
    for col in columns:
        print(f"  {col[0]:25} {col[1]:30}")
        
except mysql.connector.Error as e:
    if "Duplicate column" in str(e):
        print("✓ Column 'options' already exists")
    else:
        print(f"✗ Error: {e}")
        conn.rollback()
finally:
    cursor.close()
    conn.close()

print("\n" + "="*70)
