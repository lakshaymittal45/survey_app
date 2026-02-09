# API Connectivity Report - Survey Application
**Generated:** January 22, 2026

---

## Summary
This document analyzes the connectivity between HTML templates and Flask API endpoints in `app.py`.

### Overall Status: ⚠️ **CRITICAL ISSUES FOUND**

---

## 1. QUESTIONNAIRE_MANAGER.HTML 

### API Base URL
```javascript
const API_BASE = "http://127.0.0.1:8000/api";
```

### API Calls Made:
| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/api/sections` | GET | ✅ EXISTS | Works correctly |
| `/api/questions/tree/{section_id}` | GET | ✅ EXISTS | Works correctly |
| `/api/questions` | POST | ❌ **MISSING** | Expected by form, NOT in app.py |

### Issues:
1. **Missing POST endpoint:** The form tries to POST to `/api/questions` to create a question
   - **Current endpoint in app.py:** `/api/admin/question` (POST)
   - **Line in app.py:** ~769
   - **Fix Required:** Change form submission to use `/api/admin/question` or add a new `/api/questions` route

### Code Location:
- **File:** `questionnaire_manager.html`
- **Line:** 232 (form submission)
```javascript
const response = await fetch(`${API_BASE}/questions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
});
```

---

## 2. SURVEY.HTML

### API Base URL
```javascript
const API = "http://127.0.0.1:8000";
const API_BASE = `${API}/api`;
```

### API Calls Made:
| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/login` | POST | ❌ **MISSING** | Not in app.py |
| `/locations/{level}/{parent_id}` | GET | ❌ **MISSING** | Not in app.py |
| `/initialize-survey` | POST | ❌ **MISSING** | Not in app.py |
| `/api/sections` | GET | ✅ EXISTS | Works correctly |
| `/api/questions/tree/{section_id}` | GET | ✅ EXISTS | Works correctly |
| `/api/responses` | POST | ✅ EXISTS | Works correctly |
| `/api/complete-survey` | POST | ⚠️ **TYPO** | Called as `/api/api/complete-survey` (double /api) |
| `/api/update-person` | POST | ⚠️ **TYPO** | Called as `/api/api/update-person` (double /api) |

### Critical Issues:

#### Issue 1: Missing `/login` endpoint
- **Called from:** survey.html line 259
- **Expected behavior:** Staff authentication
- **App.py has:** No `/login` endpoint at this path
- **Suggestion:** Create `/login` endpoint or use existing `/admin-login`

#### Issue 2: Missing `/locations/` endpoints
- **Called from:** survey.html lines 288, 333
- **Expected behavior:** Get geographic hierarchy (states, districts, blocks, etc.)
- **App.py has:** No `/locations/` routes
- **Status:** These routes completely missing
- **Required endpoints:**
  - `GET /locations/states`
  - `GET /locations/{level}/{parent_id}`
  - `POST /locations/bulk/{level}/{parent_id}`

#### Issue 3: Missing `/initialize-survey` endpoint
- **Called from:** survey.html line 333
- **Expected behavior:** Initialize survey for a person
- **App.py has:** No such endpoint (but has `/initialize-survey` at line 1253 in old code)
- **Current app.py:** Actually HAS this but might be removed in refactoring

#### Issue 4: Double `/api/` prefix
- **Lines:** 582, 616 in survey.html
- **Problem:** Calls `${API}/api/complete-survey` when `API` is already the base URL
- **Result:** Endpoint becomes `/api/api/complete-survey` (BROKEN)
- **Fix:** Change to `${API_BASE}/complete-survey`

### Code Locations - Issues:
```javascript
// Line 259 - Missing endpoint
const res = await fetch(`${API}/login`, {

// Line 288 - Missing endpoint  
const res = await fetch(`${API}/locations/${type}/${parentId}`);

// Line 333 - Missing endpoint
const res = await fetch(`${API}/initialize-survey`, {

// Line 582 - BROKEN (double /api)
await fetch(`${API}/api/complete-survey?attempt_id=${attemptId}`, { method: 'POST' });

// Line 616 - BROKEN (double /api)
const res = await fetch(`${API}/api/update-person`, {
```

---

## 3. STAFF_MANAGEMENT.HTML

### API Base URL
```javascript
const API = "http://127.0.0.1:8000/api";
```

### API Calls Made:
| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/api/staff?search=` | GET | ❌ **MISSING** | Not in app.py |
| `/api/staff` | POST | ❌ **MISSING** | Not in app.py |
| `/api/staff/toggle/{id}` | PATCH | ❌ **MISSING** | Not in app.py |

### Issues:
1. **Complete endpoint family missing:** No `/api/staff` endpoints exist in app.py
   - Expected for staff registration, listing, and status management
   - **Alternative in app.py:** Uses `/api/admin/users` and `/api/admin/admins` instead
   
### Code Locations:
- **File:** `staff_management.html`
- **Lines:** 58, 93, 103
```javascript
// Line 58 - Missing
const res = await fetch(`${API}/staff?search=${search}`);

// Line 93 - Missing
const res = await fetch(`${API}/staff`, {
    method: 'POST',

// Line 103 - Missing
const res = await fetch(`${API}/staff/toggle/${id}`, { method: 'PATCH' });
```

---

## 4. OTHER HTML FILES STATUS

### user_dashboard.html
- Status: ✅ **WORKING**
- Uses: `/api/districts/`, `/api/blocks/`, `/api/sub-centers/`, `/api/villages/by-subcenter/`
- All endpoints exist in app.py
- Note: Uses relative paths starting with `/api` (not hardcoded host)

### admin_dashboard.html
- Status: ✅ **WORKING** 
- Uses: `/api/admin/*` endpoints
- All endpoints exist in app.py
- Comprehensive coverage of state/district/block/village/user/admin management
- Uses `apiFetch()` wrapper function for API calls

### survey_locations.html
- Status: ❌ **MISSING ENDPOINTS**
- Calls: `/locations/states`, `/locations/{level}`, `/locations/bulk/{level}/{pid}`
- None of these exist in current app.py
- Would need complete implementation

### home.html
- Status: ✅ **SIMPLE** - Just displays static content, no API calls

### questionnaire.html
- Status: ✅ **NOT FOUND** - Template doesn't exist in provided files
- Expected to be referenced by `/questionnaire` route which exists in app.py

---

## Summary Table

| File | Status | Issues Count | Severity |
|------|--------|--------------|----------|
| questionnaire_manager.html | ⚠️ Partial | 1 | Medium |
| survey.html | ❌ Broken | 5 | **CRITICAL** |
| staff_management.html | ❌ Missing | 3 | **CRITICAL** |
| survey_locations.html | ❌ Missing | 3 | **CRITICAL** |
| user_dashboard.html | ✅ Working | 0 | - |
| admin_dashboard.html | ✅ Working | 0 | - |
| home.html | ✅ Working | 0 | - |

---

## Required Actions

### Priority 1 (CRITICAL) - Fix Broken Endpoints
1. **Fix survey.html double /api prefix** (Lines 582, 616)
   - Change `${API}/api/...` to `${API_BASE}/...`

2. **Implement missing location endpoints** in app.py
   ```python
   @app.route("/locations/<level>/<int:parent_id>")
   @app.route("/locations/states")
   @app.route("/locations/bulk/<level>/<int:parent_id>", methods=["POST"])
   ```

3. **Implement login endpoint** in app.py
   ```python
   @app.route("/login", methods=["POST"])
   ```

4. **Implement initialize-survey endpoint** in app.py
   ```python
   @app.route("/initialize-survey", methods=["POST"])
   ```

### Priority 2 (MEDIUM) - API Route Mismatch
1. **questionnaire_manager.html:** Change POST to `/api/admin/question` instead of `/api/questions`
   - Or create alias `/api/questions` that calls `/api/admin/question`

### Priority 3 (HIGH) - Staff Management
1. **Decide:** Use existing `/api/admin/users` and `/api/admin/admins` or create `/api/staff` endpoints
2. **Update:** staff_management.html to use correct endpoints

---

## App.py Status Check

### Current Flask Routes:
✅ Pages Routes:
- `/` (home)
- `/user-login`
- `/admin-login`
- `/user-dashboard`
- `/admin-dashboard`
- `/questionnaire`
- `/survey`

✅ User API Routes:
- `/api/current-user`
- `/api/states`
- `/api/districts/<int:state_id>`
- `/api/blocks/<int:district_id>`
- `/api/sub-centers/<int:block_id>`
- `/api/villages/by-subcenter/<int:sub_center_id>`
- `/api/household` (POST)
- `/api/questionnaire-data`
- `/api/responses` (POST)

✅ Admin API Routes (Sections):
- `/api/admin/sections` (GET)
- `/api/admin/section` (POST, PUT, DELETE)

✅ Admin API Routes (Questions):
- `/api/admin/question` (POST, PUT, DELETE)

✅ Admin API Routes (Geographic):
- `/api/admin/all-states`
- `/api/admin/all-districts`
- `/api/admin/all-blocks`
- `/api/admin/all-villages`
- `/api/admin/all-sub-centers`

✅ Admin API Routes (Users):
- `/api/admin/users` (GET)
- `/api/admin/user` (POST, DELETE)

✅ Admin API Routes (Admins):
- `/api/admin/admins` (GET)
- `/api/admin/admin` (POST, DELETE)

❌ Missing Routes (called by HTML):
- `/login` (POST)
- `/locations/*` (GET, POST)
- `/initialize-survey` (POST)
- `/staff` (GET, POST, PATCH)

---

## Recommendations

### Immediate Action:
1. Fix survey.html API path typos (double /api)
2. Implement missing `/login`, `/locations/`, `/initialize-survey` endpoints
3. Either use existing user/admin endpoints for staff management or create `/staff` routes

### Long-term:
1. Unify API endpoint naming conventions
2. Create API documentation/mapping
3. Implement API version control
4. Add endpoint validation tests
5. Use centralized API configuration instead of hardcoded URLs

---

**Report End**
