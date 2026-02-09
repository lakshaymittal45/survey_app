# Refactoring Plan: Admin Dashboard & User Dashboard Integration

## Current State Analysis

### Admin Dashboard Issues
- Has old questionnaire/question management code in the Questionnaire tab
- This duplicates logic from questionnaire_manager.html
- Uses endpoints: /api/admin/sections, /api/admin/section, /api/admin/question
- Has inline JavaScript for question CRUD operations

### User Dashboard Issues
- After household creation, redirects to /questionnaire
- /questionnaire uses questionnaire.html
- questionnaire.html calls /api/questionnaire-data
- questionnaire.html has hardcoded rendering logic
- Does NOT use survey.html

### questionnaire_manager.html
- Complete, working questionnaire management system
- Has advanced features:
  - Parent-child question relationships
  - Trigger conditions for conditional display
  - Tree visualization
  - Section management
- Uses endpoints: /api/admin/sections, /api/admin/section/{id}/questions, etc.

### survey.html
- Designed for survey taking
- Expects data structure from database
- Has login, household selection, personal details
- Renders questions dynamically
- Has nested/conditional question support
- Uses parent-child relationships

---

## Integration Strategy

### Task 1: Admin Dashboard - Questionnaire Management
**Current**: admin_dashboard.html has a Questionnaire tab with basic add/edit/delete
**Goal**: Replace with full logic from questionnaire_manager.html

**Steps**:
1. Keep admin_dashboard.html structure
2. Remove old questionnaire tab JavaScript (loadSections, loadQuestions, addSection, etc.)
3. Extract questionnaire_manager.html's complete UI and logic
4. Embed into admin_dashboard.html's questionnaire tab
5. Ensure all endpoints match

### Task 2: User Dashboard - Use survey.html
**Current**: user_dashboard.html redirects to /questionnaire → questionnaire.html
**Goal**: Redirect to /survey instead, use survey.html

**Steps**:
1. Change redirect from /questionnaire to /survey route
2. Create /survey route that shows survey.html
3. Ensure survey.html gets household_id from session
4. Update survey.html to load questions from /api/questionnaire-data
5. Remove questionnaire.html from flow

---

## File Status After Refactoring

### Files to KEEP (In Use)
- ✅ app.py - Updated endpoints for survey data
- ✅ admin_dashboard.html - With integrated questionnaire_manager logic
- ✅ user_dashboard.html - With redirect to /survey
- ✅ survey.html - Main survey interface
- ✅ home.html - Landing page
- ✅ user_login.html - User authentication
- ✅ admin_login.html - Admin authentication
- ✅ admin_dashboard.html - Complete admin interface

### Files to DEPRECATE (No Longer Used)
- ❌ questionnaire.html - REPLACED by survey.html + questionnaire_manager.html logic
- ❌ questionnaire_manager.html - Logic merged into admin_dashboard.html
- ⚠️  survey_locations.html - Check if still needed (location management)
- ⚠️  staff_management.html - Check if still needed
- ⚠️  questionnaire_manager.html - Can be archived after merge

---

## Endpoint Mapping

### Admin Endpoints (For questionnaire_manager)
```
GET    /api/admin/sections                    - List all sections
GET    /api/admin/section/{id}/questions     - Get questions in section
POST   /api/admin/section                     - Create section
PUT    /api/admin/section/{id}               - Update section
DELETE /api/admin/section/{id}               - Delete section
POST   /api/admin/question                    - Create question
PUT    /api/admin/question/{id}              - Update question
DELETE /api/admin/question/{id}              - Delete question
```

### User Endpoints (For survey.html)
```
GET    /api/questionnaire-data               - Load all sections with questions
POST   /api/responses                         - Save responses
GET    /api/current-user                      - Get user info
```

### New Route Needed
```
GET    /survey                                - Render survey.html
```

---

## Implementation Details

### admin_dashboard.html Changes
1. Keep tab structure
2. Remove lines with old questionnaire JavaScript (loadSections, loadQuestions, etc.)
3. Add questionnaire_manager.html's:
   - HTML form and tree display
   - JavaScript for question management
   - CSS for tree visualization
4. Update function calls to use correct API endpoints

### user_dashboard.html Changes
1. Change redirect after household creation:
   ```javascript
   // OLD: window.location.href = '/questionnaire';
   // NEW: window.location.href = '/survey';
   ```

### app.py Changes
1. Add new route:
   ```python
   @app.route("/survey")
   @role_required("user")
   def survey():
       if "household_id" not in session:
           return redirect(url_for("user_login"))
       return render_template("survey.html")
   ```
2. Verify all endpoints return correct data structure

### survey.html Changes
1. Update API calls to use Flask endpoints instead of FastAPI
2. Replace login logic to use Flask sessions
3. Update location loading to use Flask endpoints
4. Ensure household_id comes from Flask session

---

## Data Flow After Refactoring

```
ADMIN FLOW:
Admin logs in → admin_dashboard → Questionnaire tab
  ↓
[questionnaire_manager logic - now integrated in admin_dashboard]
  ↓
Add/Edit/Delete questions via /api/admin/section, /api/admin/question
  ↓
Data saved to: questionnaire_sections, questions tables

USER FLOW:
User logs in → user_dashboard
  ↓
Fill household info → Submit
  ↓
POST /api/household (creates household, sets household_id in session)
  ↓
Redirect to /survey
  ↓
survey.html loads with household_id from session
  ↓
GET /api/questionnaire-data (loads all sections with questions)
  ↓
User answers questions
  ↓
POST /api/responses (saves responses to survey_attempt table)
  ↓
Submit and return to user_dashboard
```

---

## Testing Checklist

### Admin Testing
- [ ] Login to admin dashboard
- [ ] Navigate to Questionnaire tab
- [ ] Add new section
- [ ] Add question to section
- [ ] Edit question
- [ ] Delete question
- [ ] Check section ordering

### User Testing
- [ ] Login to user dashboard
- [ ] Create household
- [ ] Redirect to /survey works
- [ ] Questions load from database
- [ ] Can answer questions
- [ ] Can save responses
- [ ] Can navigate between sections
- [ ] Can submit survey

---

## Backward Compatibility Notes

questionnaire.html will be deprecated. If old links or bookmarks reference it:
- Add redirect: /questionnaire → /survey
- Or remove it completely

survey.html currently expects a different API structure (FastAPI with location_tracker DB).
Need to update it to work with Flask + survey_1 database.

