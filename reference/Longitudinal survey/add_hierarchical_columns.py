import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='1234',
    database='survey_1'
)
cursor = conn.cursor()

print("="*70)
print("CHECKING HIERARCHICAL QUESTION COLUMNS")
print("="*70)

columns_needed = {
    'parent_id': 'INT DEFAULT NULL',
    'trigger_value': 'VARCHAR(255) DEFAULT NULL'
}

for col_name, col_type in columns_needed.items():
    # Check if column exists
    cursor.execute(f"""
        SELECT COUNT(*) as cnt FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'questions' AND COLUMN_NAME = '{col_name}' AND TABLE_SCHEMA = 'survey_1'
    """)
    result = cursor.fetchone()
    
    if result[0] == 0:
        print(f"\nAdding '{col_name}' column...")
        try:
            alter_sql = f"ALTER TABLE questions ADD COLUMN {col_name} {col_type}"
            cursor.execute(alter_sql)
            conn.commit()
            print(f"✓ Column '{col_name}' added")
        except mysql.connector.Error as e:
            print(f"✗ Error adding '{col_name}': {e}")
            conn.rollback()
    else:
        print(f"✓ Column '{col_name}' already exists")

# Verify final schema
print("\n" + "="*70)
print("FINAL QUESTIONS TABLE SCHEMA")
print("="*70)
cursor.execute("DESCRIBE survey_1.questions")
columns = cursor.fetchall()
for col in columns:
    print(f"  {col[0]:25} {col[1]:35}")

cursor.close()
conn.close()
