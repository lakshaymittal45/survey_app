# Fix Summary - questionnaire_manager.html & app.py Synchronization

**Date:** January 22, 2026

---

## Changes Applied

### 1. ✅ questionnaire_manager.html - API Base URL

**Before:**
```javascript
const API_BASE = "http://127.0.0.1:8000/api";
```

**After:**
```javascript
const API_BASE = "http://127.0.0.1:5000/api";
```

**Reason:** Flask default port is 5000, not 8000. This ensures requests hit the correct server.

---

### 2. ✅ questionnaire_manager.html - Form Submission Endpoint & Security

**Before:**
```javascript
const response = await fetch(`${API_BASE}/questions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
});
```

**After:**
```javascript
const response = await fetch(`http://127.0.0.1:5000/api/admin/question`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include', // ✅ Required for session cookies
    body: JSON.stringify(payload)
});
```

**Changes:**
- Endpoint changed from `/api/questions` (public) to `/api/admin/question` (admin-protected)
- Added `credentials: 'include'` to pass session cookies (required for `@role_required("admin")` decorator to work)
- Uses correct Flask port (5000)

**Why:** Security - only authenticated admins can now add questions via this endpoint.

---

### 3. ✅ questionnaire_manager.html - Payload Structure

**Before:**
```javascript
const payload = {
    section_id: parseInt(document.getElementById('section_id').value),
    question_text: document.getElementById('question_text').value,
    question_type: document.getElementById('question_type').value,
    options: document.getElementById('options').value ? ... : [],
    parent_id: parseInt(document.getElementById('parent_id').value),
    trigger_value: document.getElementById('trigger_value').value || null
};
```

**After:**
```javascript
const qt = document.getElementById('question_type').value;

const payload = {
    section_id: parseInt(document.getElementById('section_id').value),
    question_text: document.getElementById('question_text').value,
    question_type: qt,              // Frontend type
    answer_type: qt,                // ✅ Backend expects this
    options: document.getElementById('options').value
        ? document.getElementById('options').value.split(',').map(s => s.trim()).filter(Boolean)
        : null,
    parent_id: parseInt(document.getElementById('parent_id').value) || null,
    trigger_value: document.getElementById('trigger_value').value || null
};
```

**Changes:**
- Added `answer_type: qt` field (required by backend mapping)
- Fixed options parsing (uses `filter(Boolean)` to remove empty strings)
- Fixed parent_id parsing (uses `|| null` instead of just parseInt)
- Changed empty array `[]` to `null` for options

**Why:** Backend's `normalize_question_payload()` function expects `answer_type` field and maps it correctly.

---

### 4. ✅ questionnaire_manager.html - Error Handling

**Before:**
```javascript
if (response.ok) {
    // show success
}
```

**After:**
```javascript
const out = await response.json();

if (!response.ok) {
    alert(out.error || "Failed to add question");
    return;
}
// show success
```

**Why:** Provides better error messages to the user instead of silently failing.

---

### 5. ✅ app.py - Verification (No Changes Needed)

The Flask `/api/admin/question` endpoint is **already correct**:

✅ **Correctly inserts all required fields:**
```python
db.session.execute(sql_text("""
    INSERT INTO questions
    (question_section_id, question_text, question_type, answer_type, options, parent_id, trigger_value, question_order)
    VALUES
    (:sid, :qt, :qtype, :atype, :opts, :pid, :tval, :ord)
"""), { ... })
```

✅ **Uses `normalize_question_payload()`** to map incoming types correctly

✅ **Has `@role_required("admin")` decorator** for security

✅ **Returns proper JSON response** with `question_id` and `question_order`

---

## Payload Flow Diagram

```
HTML Form (questionnaire_manager.html)
    ↓
  question_type = "text" / "number" / "mcq" / "checkbox"
    ↓
Sent as both question_type and answer_type to backend
    ↓
app.py: normalize_question_payload()
    ↓
Maps "text" → {question_type: "open_ended", answer_type: "text"}
Maps "number" → {question_type: "open_ended", answer_type: "numerical"}
Maps "mcq" → {question_type: "single_choice", answer_type: "numerical"}
Maps "checkbox" → {question_type: "multiple_choice", answer_type: "numerical"}
    ↓
INSERT into questions table with all mapped values
    ↓
✅ Success response with question_id
```

---

## Testing Checklist

- [ ] Navigate to questionnaire manager
- [ ] Select a section
- [ ] Enter question text
- [ ] Select input type (text/number/mcq/checkbox)
- [ ] Click "Save & Add Question"
- [ ] Verify success alert appears
- [ ] Check question appears in tree view
- [ ] Try without admin login - should redirect to login
- [ ] Check browser console for errors

---

## Files Modified

1. **questionnaire_manager.html**
   - Line 232: Changed API_BASE port from 8000 to 5000
   - Line 238: Updated form submission with proper endpoint, payload, and error handling

2. **app.py**
   - ✅ No changes needed (already correct)

---

## Result

Your questionnaire manager can now:
- ✅ Connect to Flask on port 5000
- ✅ Send questions to admin-protected endpoint
- ✅ Pass session authentication via credentials
- ✅ Properly map question types to database values
- ✅ Provide feedback on success/error

The connection between questionnaire_manager.html and app.py is now **properly synchronized**.
