# Questionnaire System - Fixed & Enhanced

## What Was Fixed

### 1. **questionnaire.html** - Enhanced with:
   - ✅ Proper section-wise question loading from `/api/questionnaire-data`
   - ✅ Better error handling when questions are missing
   - ✅ XSS protection with `escapeHtml()` function
   - ✅ Support for all answer types: text, numerical, mcq, multiple
   - ✅ Offline mode support (saves to localStorage when offline)
   - ✅ Auto-sync capability when connection is restored
   - ✅ Detailed logging for debugging
   - ✅ Better error messages showing what section/question failed

### 2. **app.py - `/api/responses` endpoint** (lines 328-393):
   - ✅ Now properly stores responses in `survey_attempt.response_data` JSON field
   - ✅ Uses `JSON_MERGE_PATCH` to accumulate section responses
   - ✅ Creates new survey_attempt record if doesn't exist
   - ✅ Updates existing record with new section responses
   - ✅ Tracks section_id with each save
   - ✅ Includes timestamps for audit trail
   - ✅ Proper error handling and rollback on failure

### 3. **Database Mapping**:
   - Uses existing `survey_attempt` table (confirmed in schema)
   - Stores all responses in `response_data` JSON field
   - Tracks `status` (Draft/Completed) and timestamps

---

## How It Works Now

### User Flow:
```
1. User creates household in dashboard
   ↓
2. Redirects to /questionnaire
   ↓
3. questionnaire.html loads
   - Calls GET /api/questionnaire-data
   - Gets all sections with nested questions
   ↓
4. User answers questions section-by-section
   ↓
5. On "Save & Next" or "Save & Exit"
   - Collects all responses from current section
   - POST to /api/responses with:
     {
       section_id: X,
       responses: { question_id: answer, ... },
       timestamp: ISO_TIMESTAMP
     }
   ↓
6. Backend (app.py /api/responses):
   - Verifies user & household
   - Merges new responses with existing survey_attempt.response_data
   - Updates status = 'Draft'
   - Commits to database
   ↓
7. Frontend continues to next section or exits
```

### Offline Mode:
```
If offline:
- Responses saved to localStorage as: offlineResponses
- User sees: "✓ Saved offline (will sync when online)"
- When online status returns: Auto-sync available
```

---

## API Endpoint: POST /api/responses

**Request**:
```json
{
  "section_id": 1,
  "responses": {
    "1": "John Doe",
    "2": "Male",
    "3": "28"
  },
  "timestamp": "2026-01-22T10:30:00.000Z"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "message": "Section 1 responses saved successfully",
  "saved_count": 3
}
```

**Response (Error)**:
```json
{
  "success": false,
  "error": "Household not found"
}
```

---

## Database Storage

**Table**: `survey_attempt`
**Column**: `response_data` (JSON)

**Format**:
```json
{
  "section_id": 1,
  "responses": {
    "1": "John Doe",
    "2": "Male",
    "3": "28"
  },
  "timestamp": "2026-01-22T10:30:00.000Z",
  "section_number": 1
}
```

Multiple sections are merged using JSON_MERGE_PATCH, accumulating all responses.

---

## Key Features

✅ **Section-wise Nested Questions**: Questions are loaded grouped by section
✅ **Offline Support**: Responses save locally when offline
✅ **Auto-sync**: Syncs when connection restored
✅ **Type Safety**: Proper escaping and validation
✅ **Audit Trail**: Timestamps tracked for each save
✅ **Error Recovery**: Detailed error messages for debugging
✅ **Progress Tracking**: Progress bar shows section completion
✅ **Session Protection**: Verifies household belongs to user

---

## Testing

### Test 1: Basic Save
1. Login → Create Household → Start Questionnaire
2. Answer a question
3. Click "Save & Next"
4. Check browser console: Should see "✓ Saved successfully!"
5. Check DB: survey_attempt.response_data should have responses

### Test 2: Offline Mode
1. Open DevTools (F12)
2. Network tab → Offline checkbox
3. Answer questions
4. Click "Save & Exit"
5. Should see: "✓ Saved offline (will sync when online)"
6. Check localStorage: offlineResponses should have data
7. Turn offline off, refresh page
8. Should see sync notification

### Test 3: Section Navigation
1. Answer Section 1 questions
2. Click "Save & Next"
3. Section 1 saved, Section 2 loads
4. Answer Section 2 questions
5. Click "Previous" → Goes back to Section 1
6. Previously saved answers should still be there
7. Click "Save & Next" again → Go to Section 2

### Test 4: Missing Questions
1. If no questions in admin, admin should see error
2. Questionnaire should show: "No questions configured"
3. Buttons should be disabled
4. User cannot submit

---

## Files Modified

1. **templates/questionnaire.html** - Enhanced JS with offline support
2. **app.py** - Updated `/api/responses` endpoint + added `from datetime import datetime`

## Ready to Use ✅

The system is now complete and ready for testing!
