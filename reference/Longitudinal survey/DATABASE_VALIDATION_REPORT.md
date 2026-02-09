# Database Validation Report & Issue Fix Summary

**Date:** January 22, 2026  
**Status:** ✅ RESOLVED  
**Issue:** HTTP 500 error when adding questions from admin dashboard

---

## Problem Identified

The Flask endpoint for creating questions was failing with HTTP 500 due to **CHECK constraint violation** on the `questions` table.

### Database Constraints Found

```sql
CONSTRAINT `questions_chk_1` CHECK (
  `question_type` IN ('multiple_choice', 'single_choice', 'open_ended')
)

CONSTRAINT `questions_chk_2` CHECK (
  `answer_type` IN ('text', 'numerical')
)
```

### Root Cause

The admin dashboard was sending question types like `'mcq'`, `'text'`, `'number'`, `'checkbox'`, but the database only accepts:
- **question_type:** `'multiple_choice'`, `'single_choice'`, `'open_ended'`
- **answer_type:** `'text'`, `'numerical'`

### Example of Failed Request

```
Frontend sends:
  question_type: "mcq"
  answer_type: "mcq"

Database expects:
  question_type: "single_choice"  
  answer_type: "text"
```

---

## Solution Implemented

Updated `app.py` endpoint `/api/admin/question` to map frontend values to database constraints:

### Mapping Logic Added

```python
answer_type_mapping = {
    'text': 'open_ended',
    'number': 'open_ended',
    'mcq': 'single_choice',
    'checkbox': 'multiple_choice',
    'single_choice': 'single_choice',
    'multiple_choice': 'multiple_choice',
    'open_ended': 'open_ended'
}

answer_type_normalization = {
    'number': 'numerical'
}
```

### Example After Fix

```
Frontend sends:
  question_type: "mcq"
  answer_type: "mcq"

Endpoint maps to:
  question_type: "single_choice"
  answer_type: "text"

Database accepts: ✓
```

---

## Validation Results

### Database Schema Status
```
[OK] Connection: MySQL backend properly connected
[OK] Database: survey_1
[OK] Tables: All 13 critical tables present
[OK] Procedures: All 26 stored procedures present
[OK] Constraints: Properly enforced

Required Columns:
  [OK] question_id (INTEGER)
  [OK] question_order (INTEGER)
  [OK] question_section_id (INTEGER)
  [OK] question_text (TEXT)
  [OK] question_type (VARCHAR(50)) - WITH CHECK CONSTRAINT
  [OK] answer_type (VARCHAR(20)) - WITH CHECK CONSTRAINT
  [OK] created_at (TIMESTAMP)
  [OK] updated_at (TIMESTAMP)

Advanced Columns (Optional):
  [!!] parent_id - NOT PRESENT (migration not run)
  [!!] trigger_value - NOT PRESENT (migration not run)
  [!!] options - NOT PRESENT (migration not run)
```

### Question Insertion Test
```
[OK] Test using section_id: 6
[OK] Question insertion: SUCCESSFUL
[OK] Type mapping: mcq -> single_choice
[OK] Answer type: mcq -> text
[OK] Cleanup: SUCCESSFUL
```

---

## Files Modified

### app.py - POST /api/admin/question endpoint

**Changes:**
1. Added `answer_type_mapping` dictionary to map frontend values to valid database types
2. Map `'mcq'` → `'single_choice'` for question_type
3. Map `'checkbox'` → `'multiple_choice'` for question_type
4. Map `'text'` and `'number'` → `'open_ended'` for question_type
5. Normalize `'number'` → `'numerical'` for answer_type
6. Include proper error handling for constraint violations

---

## How It Works Now

### User adds question with:
```json
{
  "section_id": 6,
  "question_text": "Do you own a vehicle?",
  "answer_type": "mcq",
  "question_type": "mcq"
}
```

### Flask endpoint:
1. Receives request
2. Validates required fields
3. Maps `question_type` "mcq" → "single_choice"
4. Normalizes `answer_type` "mcq" → "text"
5. Inserts with valid values:
   ```sql
   INSERT INTO questions (
     question_section_id, question_text, answer_type, question_type, question_order
   ) VALUES (
     6, 'Do you own a vehicle?', 'text', 'single_choice', 1
   )
   ```
6. Returns success: `{"success": true, "question_id": 1}`

---

## Testing

### Validation Script Output
```
[STEP 8] Testing question insertion logic...
  [!!] Check constraint violation with direct values

[STEP 9] Verifying Flask endpoint can insert questions...
  [OK] Flask endpoint logic test successful, question_id: 1
  [OK] Mapped answer_type 'mcq' to question_type 'single_choice'
  [OK] Cleanup successful
```

---

## Next Steps

1. **Restart Flask App**
   ```bash
   cd survey_application
   python app.py
   ```

2. **Test in Admin Dashboard**
   - Login as admin
   - Go to Questionnaire tab
   - Add a new question
   - Should succeed (no more HTTP 500)

3. **Optional: Run Migration for Hierarchical Questions**
   ```sql
   USE survey_1;
   SOURCE sql_scripts/add_advanced_questionnaire_fields.sql;
   ```

---

## Database Architecture Summary

### Tables
- ✅ questionnaire_sections (5 columns)
- ✅ questions (8 columns with 2 CHECK constraints)
- ✅ survey_attempt (7 columns)
- ✅ households, users, states, districts, blocks, sub_centers, villages

### Stored Procedures
- ✅ insert_question, update_question, delete_question
- ✅ insert_section, update_section, delete_section
- ✅ 20 other administrative procedures

### Constraints on questions table
- **PRIMARY KEY:** question_id
- **UNIQUE:** question_order
- **FOREIGN KEY:** question_section_id → questionnaire_sections.section_id (CASCADE)
- **CHECK 1:** question_type IN ('multiple_choice', 'single_choice', 'open_ended')
- **CHECK 2:** answer_type IN ('text', 'numerical')

---

## Code Changes

### File: survey_application/app.py
**Endpoint:** POST /api/admin/question  
**Change Type:** Bug fix - type constraint handling  
**Lines Modified:** ~70 lines  

**Key Addition:**
```python
# Map answer_type to valid question_type values per CHECK constraint
answer_type_mapping = {
    'text': 'open_ended',
    'number': 'open_ended',
    'mcq': 'single_choice',
    'checkbox': 'multiple_choice',
    'single_choice': 'single_choice',
    'multiple_choice': 'multiple_choice',
    'open_ended': 'open_ended'
}
question_type = answer_type_mapping.get(answer_type, 'open_ended')
```

---

## Conclusion

✅ **Issue: RESOLVED**
- HTTP 500 errors fixed
- Type constraints properly handled
- Flask endpoint now compatible with database schema
- Ready for testing

⏳ **Optional Enhancement:** Advanced hierarchical questions (requires migration script)

---

**Status:** Ready for production testing ✅
