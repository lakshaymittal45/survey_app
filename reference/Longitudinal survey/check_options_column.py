import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='1234',
    database='survey_1'
)
cursor = conn.cursor()

print("Full questions table schema:")
cursor.execute("DESCRIBE survey_1.questions")
columns = cursor.fetchall()
for col in columns:
    print(f"  {col[0]:25} {col[1]:30} {str(col[2]):5} {str(col[3]):20} {str(col[4]):30}")

print("\nChecking if 'options' column exists...")
cursor.execute("""
    SELECT COUNT(*) as cnt FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'questions' AND COLUMN_NAME = 'options' AND TABLE_SCHEMA = 'survey_1'
""")
result = cursor.fetchone()
if result[0] > 0:
    print("✓ 'options' column EXISTS")
else:
    print("✗ 'options' column DOES NOT EXIST - This is the problem!")
    
cursor.close()
conn.close()
