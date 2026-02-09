import mysql.connector

try:
    conn = mysql.connector.connect(
        host='127.0.0.1',
        user='root',
        password='1234'
    )
    cursor = conn.cursor()
    cursor.execute("SHOW DATABASES")
    databases = cursor.fetchall()
    print("Available databases:")
    for db in databases:
        print(f"  - {db[0]}")
    
    # Check if survey_1 and survey_db exist
    survey_dbs = [db[0] for db in databases if 'survey' in db[0].lower()]
    print(f"\nSurvey databases found: {survey_dbs}")
    
    # Check tables in survey_1 if it exists
    if 'survey_1' in survey_dbs:
        print("\nTables in survey_1:")
        cursor.execute("USE survey_1")
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        for table in tables:
            print(f"  - {table[0]}")
    
    cursor.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
