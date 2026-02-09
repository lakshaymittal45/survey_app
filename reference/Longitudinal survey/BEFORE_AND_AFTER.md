# Before vs After - Questionnaire Integration

## Admin Dashboard Questionnaire Tab

### BEFORE (Basic CRUD)
```
┌─────────────────────────────────────────┐
│ Questionnaire Management                 │
│                                          │
│ Sections                                 │
│ ┌──────────────────────────────────────┐ │
│ │ Title: [__________________]          │ │
│ │ [Add Section]                        │ │
│ └──────────────────────────────────────┘ │
│ Section List (table)                     │
│                                          │
│ Questions                                │
│ ┌──────────────────────────────────────┐ │
│ │ Section: [Select section ▼]          │ │
│ │ Type: [text ▼]                       │ │
│ │ Text: [__________________]           │ │
│ │ [Add Question]                       │ │
│ └──────────────────────────────────────┘ │
│ Question List (table, flat)              │
└─────────────────────────────────────────┘

Limitations:
- No parent-child relationships
- No conditional logic
- No hierarchy visualization
- No trigger conditions
```

### AFTER (Advanced Hierarchical)
```
┌─────────────────────────────────────────────────────────────┐
│ Questionnaire Management (Advanced)                          │
│                                                               │
│ ┌──────────────────────────────┬──────────────────────────┐  │
│ │ Question Configuration       │ Live Structure           │  │
│ │                              │                          │  │
│ │ Target Section *             │ Household Demographics   │  │
│ │ [Select section ▼]           │ ├─ Do you own vehicle?   │  │
│ │                              │ │  (if=Yes)              │  │
│ │ Logical Parent               │ │  ├─ Vehicle type?      │  │
│ │ [None (Root) ▼]              │ │  └─ Maintenance cost?  │  │
│ │                              │ └─ Employment status?    │  │
│ │ Show if parent selection is: │                          │  │
│ │ (shown only if parent set)    │ [Refresh]               │  │
│ │                              │                          │  │
│ │ Question Text *              │                          │  │
│ │ [____________________]        │                          │  │
│ │ (Min 100px height)           │                          │  │
│ │                              │                          │  │
│ │ Type: [mcq ▼]  Options: [...] │                        │  │
│ │                              │                          │  │
│ │ [Save & Add Question]         │                          │  │
│ └──────────────────────────────┴──────────────────────────┘  │
│                                                               │
│ Manage Sections                                              │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Section Title: [_________________]                       │ │
│ │ [Add Section]                                            │ │
│ │                                                          │ │
│ │ Section List with Edit/Delete for each                  │ │
│ └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

New Features:
✅ Parent-child question relationships
✅ Trigger conditions (if parent = X, show this)
✅ Hierarchical tree visualization
✅ Real-time hierarchy updates
✅ Smart trigger UI (dropdown vs text)
✅ Cascading delete
✅ Multi-level nesting support
```

## Database Schema

### BEFORE
```sql
CREATE TABLE questions (
  question_id INT PRIMARY KEY AUTO_INCREMENT,
  question_section_id INT,
  question_text TEXT,
  answer_type VARCHAR(50),
  FOREIGN KEY (question_section_id) REFERENCES questionnaire_sections(section_id)
);
```

### AFTER
```sql
CREATE TABLE questions (
  question_id INT PRIMARY KEY AUTO_INCREMENT,
  question_section_id INT,
  question_text TEXT,
  answer_type VARCHAR(50),
  parent_id INT NULL,                    -- NEW
  trigger_value VARCHAR(255) NULL,       -- NEW
  options TEXT NULL,                     -- NEW
  FOREIGN KEY (question_section_id) REFERENCES questionnaire_sections(section_id),
  FOREIGN KEY (parent_id) REFERENCES questions(question_id) ON DELETE CASCADE  -- NEW
);

-- NEW INDEX for fast parent lookups
CREATE INDEX idx_questions_parent ON questions(parent_id);
```

### New Views & Procedures
```sql
-- View for easy hierarchy queries
CREATE VIEW vw_question_hierarchy AS
SELECT q.*, parent.question_text as parent_text
FROM questions q
LEFT JOIN questions parent ON q.parent_id = parent.question_id;

-- Procedure to get section's question tree
PROCEDURE get_question_tree(IN section_id INT)
```

## Flask Backend

### BEFORE - Create Question Endpoint
```python
@app.route("/api/admin/question", methods=["POST"])
def admin_create_question():
    data = json_body()
    db.session.execute(text("CALL insert_question(:section_id, :text, :answer_type)"), {
        "section_id": data["section_id"],
        "text": data["question_text"],
        "answer_type": data["answer_type"],
    })
    db.session.commit()
    return jsonify({"success": True})
```

**Accepted Payload:**
```json
{
  "section_id": 1,
  "question_text": "Question?",
  "answer_type": "text"
}
```

### AFTER - Enhanced Create Question Endpoint
```python
@app.route("/api/admin/question", methods=["POST"])
def admin_create_question():
    data = json_body()
    # Insert via stored procedure
    db.session.execute(text("CALL insert_question(...)"), {...})
    db.session.commit()
    
    # Get inserted ID
    question_id = db.session.execute(text("SELECT LAST_INSERT_ID()")).scalar()
    
    # Update with parent/trigger/options if provided
    if parent_id or trigger_value or options:
        db.session.execute(text(
            "UPDATE questions SET parent_id=?, trigger_value=?, options=? WHERE question_id=?"
        ), {...})
        db.session.commit()
    
    return jsonify({"success": True})
```

**Accepted Payload:**
```json
{
  "section_id": 1,
  "question_text": "Question?",
  "answer_type": "mcq",
  "options": "Yes,No",              -- NEW
  "parent_id": 5,                   -- NEW
  "trigger_value": "Yes"            -- NEW
}
```

## Frontend JavaScript

### BEFORE - Basic Form
```javascript
async function addQuestion() {
  const sectionId = document.getElementById('questionSection').value;
  const text = document.getElementById('questionText').value;
  const answerType = document.getElementById('questionAnswerType').value;
  
  const response = await fetch('/api/admin/question', {
    method: 'POST',
    body: JSON.stringify({
      section_id: sectionId,
      question_text: text,
      answer_type: answerType
    })
  });
  
  // Simple table display
}

async function loadQuestions() {
  // Fetch all questions, display flat table
}
```

### AFTER - Advanced Hierarchical
```javascript
// NEW: Load section questions into tree structure
async function loadQuestionTree() {
  const sectionId = document.getElementById('qm_section_id').value;
  const questions = await fetch(`/api/admin/section/${sectionId}/questions`).json();
  
  // Populate parent dropdown
  const parentSelect = document.getElementById('qm_parent_id');
  questions.forEach(q => {
    parentSelect.innerHTML += `<option value="${q.question_id}">${q.question_text}</option>`;
  });
  
  // Render hierarchical tree
  renderQuestionTree(questions);
}

// NEW: Smart trigger UI based on parent options
function updateTriggerUI() {
  const parentId = document.getElementById('qm_parent_id').value;
  const parentOptions = qmQuestionMap[parentId];
  
  if (parentOptions) {
    // Parent has predefined options, show dropdown
    wrapper.innerHTML = '<select>' + options.map(o => `<option>${o}</option>`).join('') + '</select>';
  } else {
    // No predefined options, show text input
    wrapper.innerHTML = '<input type="text" placeholder="Enter trigger value">';
  }
}

// NEW: Render tree with hierarchy
function renderQuestionTree(questions) {
  const byParent = {};
  questions.forEach(q => {
    const parentId = q.parent_id || 0;
    if (!byParent[parentId]) byParent[parentId] = [];
    byParent[parentId].push(q);
  });
  
  // Recursive rendering with indentation
  function renderNode(q, depth) {
    const children = byParent[q.question_id] || [];
    let html = `<li style="margin-left: ${depth * 20}px;">
      <div>${q.question_text}</div>
      ${q.trigger_value ? `<span>if=${q.trigger_value}</span>` : ''}
      <ul>`;
    
    children.forEach(child => {
      html += renderNode(child, depth + 1);
    });
    
    html += '</ul></li>';
    return html;
  }
  
  // Display tree
}

// NEW: Form with parent/trigger support
form.onsubmit = async (e) => {
  const payload = {
    section_id: ...,
    question_text: ...,
    answer_type: ...,
    options: ...,
    parent_id: ...,        // NEW
    trigger_value: ...     // NEW
  };
  
  const response = await fetch('/api/admin/question', {
    method: 'POST',
    body: JSON.stringify(payload)
  });
};
```

## User Experience Comparison

### Adding Simple Root Question
**Before:** Click "Add Question" → Select section → Type text → Save
**After:** Select section → Type question → Save (2 fewer steps)

### Adding Conditional Question
**Before:** Not possible
**After:** 
1. Select section
2. Select parent question
3. See parent options appear
4. Select trigger value
5. Type child question
6. Save → See in tree immediately

### Visualizing Question Structure
**Before:** Flat table - hard to see relationships
```
Do you own a vehicle?
Vehicle type?
Maintenance cost?
Employment status?
```

**After:** Hierarchical tree - relationships clear
```
├─ Do you own vehicle?
│  ├─ Vehicle type? (if=Yes)
│  └─ Maintenance cost? (if=Yes)
└─ Employment status?
```

## Data Examples

### Simple Questions (No Hierarchy)
```json
{
  "question_id": 1,
  "question_text": "What is your name?",
  "answer_type": "text",
  "parent_id": null,
  "trigger_value": null,
  "options": null
}
```

### Hierarchical Questions
```json
{
  "question_id": 2,
  "question_text": "Do you own a vehicle?",
  "answer_type": "mcq",
  "parent_id": null,
  "trigger_value": null,
  "options": "Yes,No,Don't know"
},
{
  "question_id": 3,
  "question_text": "What type of vehicle?",
  "answer_type": "mcq",
  "parent_id": 2,
  "trigger_value": "Yes",
  "options": "Car,Motorcycle,Truck,Other"
},
{
  "question_id": 4,
  "question_text": "Annual maintenance cost?",
  "answer_type": "number",
  "parent_id": 2,
  "trigger_value": "Yes",
  "options": null
}
```

## Summary of Changes

| Aspect | Before | After |
|--------|--------|-------|
| Question Depth | 1 level | Unlimited |
| Conditional Logic | None | Yes (trigger_value) |
| Visualization | Flat table | Hierarchical tree |
| Options Support | No | Yes |
| Parent Relationships | No | Yes (foreign key) |
| UI Complexity | Simple form | Advanced builder |
| Form Fields | 3 | 6+ |
| API Payload | 3 fields | 6+ fields |
| Tree Rendering | N/A | Real-time |
| Cascade Deletes | No | Yes |

---

**Status:** Upgrade complete! Ready for database migration and testing. ✅
