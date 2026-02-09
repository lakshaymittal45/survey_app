import sys
import os

# --- THE FIX: Add the parent directory to Python's path ---
# This allows us to import 'app' from one level up
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import app, db
from sqlalchemy import text
from werkzeug.security import generate_password_hash

def create_accounts():
    with app.app_context():
        print("--- Starting Account Creation ---")

        # 1. Admin Account
        admin_user = "admin"
        admin_pass = "admin123"
        admin_hash = generate_password_hash(admin_pass)
        
        try:
            db.session.execute(
                text("INSERT INTO admins (username, password, password_hash) VALUES (:u, :p, :ph)"),
                {"u": admin_user, "p": admin_pass, "ph": admin_hash}
            )
            db.session.commit()
            print("✅ SUCCESS: Admin account created.")
        except Exception as e:
            db.session.rollback()
            print(f"⚠️  SKIPPED: Admin account might already exist.")

        # 2. Field User Account
        field_user = "user"
        field_pass = "user123"
        field_hash = generate_password_hash(field_pass)

        try:
            db.session.execute(
                text("INSERT INTO users (username, password_hash) VALUES (:u, :ph)"),
                {"u": field_user, "ph": field_hash}
            )
            db.session.commit()
            print("✅ SUCCESS: User account created.")
        except Exception as e:
            db.session.rollback()
            print(f"⚠️  SKIPPED: User account might already exist.")

if __name__ == "__main__":
    create_accounts()