#!/usr/bin/env python
"""Direct test of the Flask question endpoint bypassing HTTP"""

import sys
sys.path.insert(0, r'c:\Users\HP\OneDrive\Desktop\Longitudinal survey\survey_application')

# Import Flask app
from app import app, db
from sqlalchemy import text

# Create app context
with app.app_context():
    print("="*70)
    print("DIRECT FLASK ENDPOINT TEST")
    print("="*70)
    
    # Test 1: Get a section
    print("\n[TEST 1] Get sections")
    try:
        result = db.session.execute(text("SELECT * FROM questionnaire_sections LIMIT 1")).mappings().fetchone()
        if result:
            section_id = result['section_id']
            print(f"✓ Found section {section_id}: {result['section_title']}")
        else:
            print("✗ No sections found")
            section_id = None
    except Exception as e:
        print(f"✗ Error: {e}")
        section_id = None
    
    if section_id:
        # Test 2: Test the admin_create_question function directly
        print(f"\n[TEST 2] Test admin_create_question endpoint logic")
        print("-"*70)
        
        # Simulate the request data
        data = {
            'section_id': section_id,
            'question_text': 'Direct test question',
            'answer_type': 'mcq',
            'options': 'Option A, Option B',
            'parent_id': None,
            'trigger_value': None
        }
        
        print(f"Input data: {data}")
        
        try:
            # Map answer_type to valid question_type values
            answer_type_mapping = {
                'text': 'open_ended',
                'number': 'open_ended',
                'mcq': 'single_choice',
                'checkbox': 'multiple_choice',
                'single_choice': 'single_choice',
                'multiple_choice': 'multiple_choice',
                'open_ended': 'open_ended'
            }
            
            answer_type = data.get('answer_type')
            question_type = answer_type_mapping.get(answer_type, 'open_ended')
            
            # Normalize answer_type to database values
            if answer_type in ['number', 'mcq', 'checkbox']:
                answer_type = 'numerical'
            elif answer_type in ['open_ended']:
                answer_type = 'text'
            elif answer_type not in ['text', 'numerical']:
                answer_type = 'text'
            
            print(f"Mapped question_type: {question_type}")
            print(f"Mapped answer_type: {answer_type}")
            
            # Get next order
            result = db.session.execute(text(
                "SELECT COALESCE(MAX(question_order), 0) + 1 as next_order FROM questions WHERE question_section_id = :sid"
            ), {"sid": section_id})
            next_order = result.scalar() or 1
            print(f"Next order: {next_order}")
            
            # Build INSERT
            columns = ["question_section_id", "question_text", "answer_type", "question_type", "question_order"]
            values = [":section_id", ":text", ":answer_type", ":question_type", ":order"]
            params = {
                "section_id": section_id,
                "text": data.get('question_text'),
                "answer_type": answer_type,
                "question_type": question_type,
                "order": next_order
            }
            
            # Add options if present
            options = data.get('options')
            if options:
                if isinstance(options, str):
                    options = [o.strip() for o in options.split(',')]
                columns.append("options")
                values.append(":options")
                import json
                params["options"] = json.dumps(options)
            
            insert_query = f"INSERT INTO questions ({', '.join(columns)}) VALUES ({', '.join(values)})"
            print(f"\nINSERT Query: {insert_query}")
            print(f"Parameters: {params}")
            
            # Execute
            db.session.execute(text(insert_query), params)
            db.session.commit()
            
            result = db.session.execute(text("SELECT LAST_INSERT_ID() as id"))
            question_id = result.scalar()
            
            print(f"\n✓ SUCCESS! Question inserted with ID: {question_id}")
            
            # Verify it was inserted
            verify = db.session.execute(text(
                "SELECT * FROM questions WHERE question_id = :qid"
            ), {"qid": question_id}).mappings().fetchone()
            print(f"Verification: {dict(verify)}")
            
        except Exception as e:
            print(f"✗ Error during insertion: {e}")
            import traceback
            traceback.print_exc()
            db.session.rollback()

print("\n" + "="*70)
print("TEST COMPLETE")
print("="*70)
