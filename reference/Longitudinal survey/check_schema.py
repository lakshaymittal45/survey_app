import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='1234',
    database='survey_1'
)
cursor = conn.cursor()

# Check critical table structures
tables_to_check = ['questions', 'questionnaire_sections', 'users', 'admins']

for table in tables_to_check:
    print(f"\n{'='*60}")
    print(f"Table: {table}")
    print(f"{'='*60}")
    cursor.execute(f"DESCRIBE {table}")
    columns = cursor.fetchall()
    for col in columns:
        print(f"  {col[0]:20} {col[1]:30} {col[2]:5} {col[3]:5}")

# Check if questions table has the right columns
print(f"\n{'='*60}")
print("CHECKING: questions table for answer_type column")
print(f"{'='*60}")
cursor.execute("DESCRIBE survey_1.questions")
cols = cursor.fetchall()
col_names = [col[0] for col in cols]
if 'answer_type' in col_names:
    print("✓ answer_type column EXISTS")
else:
    print("✗ answer_type column MISSING - needs to be added")
    
if 'question_type' in col_names:
    print("✓ question_type column EXISTS")
else:
    print("✗ question_type column MISSING")

cursor.close()
conn.close()
