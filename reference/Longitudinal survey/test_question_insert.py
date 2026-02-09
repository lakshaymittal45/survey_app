import sys
sys.path.insert(0, r'C:\Users\HP\OneDrive\Desktop\Longitudinal survey\survey_application')

from app import app, db
from sqlalchemy import text

# Test the stored procedure
with app.app_context():
    try:
        print("Testing insert_question stored procedure...")
        
        # Test data
        result = db.session.execute(text(
            "CALL insert_question(:section_id, :text, :answer_type)"
        ), {
            "section_id": 1,
            "text": "Test Question",
            "answer_type": "text"
        })
        
        db.session.commit()
        print("✓ Stored procedure executed successfully")
        
        # Get last ID
        result = db.session.execute(text("SELECT LAST_INSERT_ID() as id"))
        row = result.fetchone()
        print(f"✓ Last inserted ID: {row[0]}")
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
