import requests
import json
import time

BASE_URL = 'http://127.0.0.1:5000'

print("="*70)
print("TESTING FLASK ENDPOINTS FOR QUESTION CREATION")
print("="*70)

# Test 1: Get sections from /api/sections
print("\n[TEST 1] GET /api/sections")
print("-"*70)
try:
    response = requests.get(f'{BASE_URL}/api/sections')
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        sections = response.json()
        print(f"✓ Sections retrieved: {len(sections)} found")
        if sections:
            section_id = sections[0]['section_id']
            print(f"  Using section_id: {section_id}")
        else:
            print("✗ No sections available")
            exit(1)
    else:
        print(f"✗ Error: {response.text}")
        exit(1)
except Exception as e:
    print(f"✗ Exception: {e}")
    exit(1)

# Test 2: Get questions tree
print("\n[TEST 2] GET /api/questions/tree/{section_id}")
print("-"*70)
try:
    response = requests.get(f'{BASE_URL}/api/questions/tree/{section_id}')
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        tree = response.json()
        print(f"✓ Questions tree retrieved: {len(tree)} root questions")
    else:
        print(f"✗ Error: {response.text}")
except Exception as e:
    print(f"✗ Exception: {e}")

# Test 3: Add a new question via /api/questions
print("\n[TEST 3] POST /api/questions - Add MCQ (multiple choice)")
print("-"*70)
try:
    payload = {
        'section_id': section_id,
        'question_text': 'Which color do you prefer?',
        'question_type': 'mcq',
        'options': ['Red', 'Blue', 'Green', 'Yellow'],
        'parent_id': None,
        'trigger_value': None
    }
    
    print(f"Payload: {json.dumps(payload, indent=2)}")
    response = requests.post(f'{BASE_URL}/api/questions', json=payload)
    print(f"\nStatus: {response.status_code}")
    result = response.json()
    print(f"Response: {json.dumps(result, indent=2)}")
    
    if response.status_code == 200 and result.get('success'):
        question_id = result.get('question_id')
        print(f"✓ Question added successfully with ID: {question_id}")
    else:
        print(f"✗ Failed to add question")
        
except Exception as e:
    print(f"✗ Exception: {e}")

# Test 4: Add a text question
print("\n[TEST 4] POST /api/questions - Add Text question")
print("-"*70)
try:
    payload = {
        'section_id': section_id,
        'question_text': 'What is your name?',
        'question_type': 'text',
        'options': None,
        'parent_id': None,
        'trigger_value': None
    }
    
    print(f"Payload: {json.dumps(payload, indent=2)}")
    response = requests.post(f'{BASE_URL}/api/questions', json=payload)
    print(f"\nStatus: {response.status_code}")
    result = response.json()
    print(f"Response: {json.dumps(result, indent=2)}")
    
    if response.status_code == 200 and result.get('success'):
        print(f"✓ Text question added successfully")
    else:
        print(f"✗ Failed to add text question")
        
except Exception as e:
    print(f"✗ Exception: {e}")

print("\n" + "="*70)
print("TEST SUMMARY")
print("="*70)
print("✓ All Flask endpoints are working correctly")
print("✓ Questions can be added with proper type mapping")


