# Advanced Questionnaire Manager - Integration Guide

## Overview
The admin_dashboard.html questionnaire tab has been upgraded from basic CRUD to an advanced questionnaire builder with:
- **Parent-Child Question Relationships** - Create hierarchical question structures
- **Trigger Conditions** - Show/hide questions based on parent answers
- **Live Tree Visualization** - See the question hierarchy in real-time
- **Options Management** - Support for MCQ and checkbox answer types

## Recent Changes

### 1. Frontend Updates - admin_dashboard.html

**New Questionnaire Tab Structure:**
```
┌─────────────────────────────────────────────┐
│  Questionnaire Management (Advanced)         │
├──────────────────────┬──────────────────────┤
│                      │                      │
│  Question Config     │  Live Structure      │
│  • Section select    │  • Tree visualization│
│  • Parent select     │  • Hierarchy display │
│  • Question text     │  • Trigger badges    │
│  • Type & options    │  • Delete buttons    │
│  • Submit button     │  • Refresh button    │
│                      │                      │
└──────────────────────┴──────────────────────┘
│                      │
│  Manage Sections     │
│  • Add sections      │
│  • Edit/delete       │
└──────────────────────┘
```

**Key JavaScript Functions:**
1. `loadQuestionnaireSections()` - Load all sections into dropdown
2. `loadQuestionTree()` - Load questions for selected section
3. `renderQuestionTree(questions)` - Render hierarchical tree view
4. `updateTriggerUI()` - Show trigger options when parent selected
5. `initQuestionnairForm()` - Initialize form submission handler
6. `deleteQmQuestion(questionId)` - Delete question with cascading

**New Form Fields:**
- Target Section (required)
- Logical Parent (optional - if set, shows trigger options)
- Question Text (required)
- Question Type (text, number, mcq, checkbox)
- Options (comma-separated, for MCQ/checkbox)
- Trigger Value (shown when parent selected)

### 2. Backend Updates - app.py

**Updated Endpoint: POST /api/admin/question**

The create question endpoint now accepts and stores:
```python
{
    "section_id": 1,           # Required
    "question_text": "...",    # Required
    "answer_type": "mcq",      # Required
    "options": "Yes,No",       # Optional
    "parent_id": 5,            # Optional - parent question ID
    "trigger_value": "Yes"     # Optional - when to show this question
}
```

**Logic:**
1. Insert question via stored procedure (basic fields)
2. Retrieve inserted question ID
3. Update with parent_id, trigger_value, options

### 3. Database Changes - SQL Migration

**File:** `sql_scripts/add_advanced_questionnaire_fields.sql`

**New Columns on `questions` Table:**
```sql
ALTER TABLE questions ADD COLUMN parent_id INT NULL;
ALTER TABLE questions ADD COLUMN trigger_value VARCHAR(255) NULL;
ALTER TABLE questions ADD COLUMN options TEXT NULL;

-- Foreign key ensures parent must exist
ALTER TABLE questions ADD CONSTRAINT fk_parent_question 
FOREIGN KEY (parent_id) REFERENCES questions(question_id) ON DELETE CASCADE;
```

**New Index:**
```sql
CREATE INDEX idx_questions_parent ON questions(parent_id);
```

**Optional Features (from migration script):**
- View `vw_question_hierarchy` - Easy parent-child queries
- Procedure `get_question_tree` - Fetch section hierarchy

## Setup Instructions

### Step 1: Apply Database Migration
```sql
-- Connect to survey_1 database
USE survey_1;

-- Run the migration script
SOURCE sql_scripts/add_advanced_questionnaire_fields.sql;

-- Verify columns were added
DESCRIBE questions;
```

### Step 2: Verify Flask App
```powershell
cd "C:\Users\HP\OneDrive\Desktop\Longitudinal survey\survey_application"
python -m py_compile app.py
# Should output: ✓ app.py Syntax OK
```

### Step 3: Test the New Interface
1. Start Flask app: `python app.py`
2. Login as admin
3. Go to Admin Dashboard
4. Click "Questionnaire" tab
5. Select a section → see questions tree
6. Add new question with parent relationship
7. Verify tree updates in real-time

## Usage Examples

### Example 1: Simple Parent-Child
```
Section: Household Demographics
├─ Q1: "Do you own a vehicle?" (Type: mcq, Options: "Yes,No")
   ├─ Q1a: "What type?" (Parent: Q1, Trigger: "Yes", Type: mcq)
   └─ Q1b: "Monthly maintenance cost?" (Parent: Q1, Trigger: "Yes", Type: number)
```

### Example 2: Multi-Level Hierarchy
```
Section: Income
├─ Q1: "Employment Status?" (mcq: "Employed,Unemployed,Self-employed")
   ├─ Q1a: "Employer Name?" (Parent: Q1, Trigger: "Employed")
   ├─ Q1b: "Business Type?" (Parent: Q1, Trigger: "Self-employed")
   │   ├─ Q1b-i: "Annual Revenue?" (Parent: Q1b, Trigger: "Self-employed")
```

## API Reference

### GET /api/admin/sections
Returns all questionnaire sections.
```json
[
  {"section_id": 1, "section_title": "Demographics", "section_order": 1},
  {"section_id": 2, "section_title": "Income", "section_order": 2}
]
```

### GET /api/admin/section/{section_id}/questions
Returns all questions for a section (including parent/trigger info).
```json
[
  {
    "question_id": 1,
    "question_text": "Own vehicle?",
    "answer_type": "mcq",
    "options": "Yes,No",
    "parent_id": null,
    "trigger_value": null
  },
  {
    "question_id": 2,
    "question_text": "Vehicle type?",
    "answer_type": "mcq",
    "options": "Car,Bike,Other",
    "parent_id": 1,
    "trigger_value": "Yes"
  }
]
```

### POST /api/admin/question
Create new question (supports parent-child).
```json
Request:
{
  "section_id": 1,
  "question_text": "Question text",
  "answer_type": "mcq",
  "options": "Option1,Option2",
  "parent_id": 5,
  "trigger_value": "Option1"
}

Response:
{"success": true}
```

## Frontend Behavior

### 1. Section Selection
- User selects section from dropdown
- Triggers `loadQuestionTree()`
- Fetches all questions in that section
- Populates parent dropdown with existing questions
- Renders tree visualization

### 2. Parent Selection
- When parent is selected, `updateTriggerUI()` called
- If parent has predefined options (mcq/checkbox):
  - Shows dropdown with options
  - User selects trigger value
- Else:
  - Shows text input for custom trigger value

### 3. Form Submission
- Validates section and question text
- If parent selected, includes parent_id and trigger_value
- POSTs to /api/admin/question
- Clears form and refreshes tree

### 4. Tree Visualization
- Root questions (parent_id=null) at depth 0
- Child questions indented below parents
- Trigger badges show: `if=Yes`, `if=Option2`, etc.
- Delete buttons available for each question
- Hierarchical indentation shows structure

## Important Notes

### Data Integrity
- When parent question deleted, child questions are also deleted (CASCADE)
- Trigger values should match actual options if parent has predefined options
- Empty parent_id indicates root question

### Backwards Compatibility
- Existing questions without parent_id/trigger_value still work
- Migration script uses IF NOT EXISTS to avoid errors if columns exist
- Old CRUD operations still supported

### Display Logic (in survey form - future implementation)
When user fills questionnaire, the system should:
1. Show root questions first
2. When user answers a question with children:
   - Check if child's trigger_value matches answer
   - If match, show child question
   - If no match, hide child question
3. Repeat for nested hierarchies

## Troubleshooting

### Issue: "Select a section to view hierarchy"
- **Solution:** Reload page and select section again

### Issue: Trigger UI not showing
- **Solution:** Ensure parent_id value is valid (exists in questions table)

### Issue: Tree shows but parent dropdown empty
- **Solution:** The selected section may have no questions yet. Add a root question first.

### Issue: Database error when adding question
- **Possible causes:**
  - parent_id doesn't exist
  - section_id is invalid
  - Database columns not added (run migration script)

## Next Steps

1. **Update survey form** (questionnaire.html) to respect parent-child relationships:
   - Load questions hierarchically
   - Show/hide based on trigger_value matching

2. **Add trigger value validation** in frontend:
   - Validate trigger_value matches parent options

3. **Create question templates:**
   - Pre-built hierarchies (Yes/No filters, multi-level income, etc.)

4. **Export/Import functionality:**
   - Save question structures as JSON
   - Reuse across different surveys

## Files Modified

1. **templates/admin_dashboard.html**
   - Questionnaire tab HTML (lines 266-348)
   - JavaScript functions (lines 1420-1647)
   - Initialization code (lines 507-517)

2. **app.py**
   - POST /api/admin/question endpoint (lines 948-1000)
   - Now handles parent_id, trigger_value, options

3. **sql_scripts/add_advanced_questionnaire_fields.sql** (NEW)
   - Migration script for database columns
   - Views and procedures for hierarchy queries

## Contact
For issues or questions about the questionnaire integration, refer to the documentation or check Flask logs for error details.
