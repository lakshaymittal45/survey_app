from sqlalchemy import create_engine, text

# Connection
engine = create_engine("mysql+pymysql://root:1234@127.0.0.1:3306/survey_1")

with engine.connect() as conn:
    try:
        # Drop old constraint and add new composite constraint
        conn.execute(text("""
            ALTER TABLE questions 
            DROP INDEX uk_question_order,
            ADD UNIQUE KEY uk_question_order (question_section_id, question_order)
        """))
        conn.commit()
        print("✅ Successfully updated uk_question_order constraint!")
        print("   - Changed from UNIQUE(question_order)")
        print("   - To UNIQUE(question_section_id, question_order)")
        print("\nQuestions can now have order 1, 2, 3 etc. in EACH section independently.")
    except Exception as e:
        print(f"❌ Error: {e}")
        conn.rollback()
