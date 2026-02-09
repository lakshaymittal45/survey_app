import os
from sqlalchemy import text
from app import app, db

SQL_FILE = os.path.join(os.path.dirname(__file__), "survey_schema_full.sql")

def run_sql_script():
    with app.app_context():
        with open(SQL_FILE, "r", encoding="utf-8") as f:
            sql = f.read()

        for statement in sql.split(";"):
            stmt = statement.strip()
            if stmt:
                db.session.execute(text(stmt))

        db.session.commit()
        print("✅ Database schema created successfully")

if __name__ == "__main__":
    run_sql_script()
