# Questionnaire Integration - Setup Checklist

## ✅ Completed Tasks

### Frontend Integration
- [x] Updated admin_dashboard.html questionnaire tab with advanced UI
- [x] Implemented parent-child question selector
- [x] Added trigger condition UI with smart input (dropdown vs text)
- [x] Created tree visualization for question hierarchy
- [x] Implemented real-time tree refresh on question add
- [x] Added delete functionality with cascade support

### Backend Updates
- [x] Updated POST /api/admin/question to handle parent_id, trigger_value, options
- [x] Added logic to store parent-child relationships
- [x] Maintained backwards compatibility with old questions

### Documentation
- [x] Created QUESTIONNAIRE_ADVANCED_GUIDE.md with full setup instructions
- [x] Documented API changes and new fields
- [x] Created SQL migration script

### Syntax Verification
- [x] Verified app.py compiles without errors

## 🔧 TODO - Database Migration

Run this in MySQL Workbench or terminal to apply changes:

```sql
USE survey_1;
SOURCE sql_scripts/add_advanced_questionnaire_fields.sql;
```

**Or run individually:**

```sql
-- Add columns to questions table
ALTER TABLE questions ADD COLUMN IF NOT EXISTS parent_id INT NULL;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS trigger_value VARCHAR(255) NULL;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS options TEXT NULL;

-- Add foreign key
ALTER TABLE questions ADD CONSTRAINT fk_parent_question 
FOREIGN KEY (parent_id) REFERENCES questions(question_id) ON DELETE CASCADE;

-- Create index for faster lookups
CREATE INDEX idx_questions_parent ON questions(parent_id);
```

## 🧪 TODO - Testing

### Unit Test Checklist
- [ ] Add root question (parent_id = null)
- [ ] Add child question with parent_id and trigger_value
- [ ] Verify tree shows parent above child with indent
- [ ] Verify trigger badge shows "if=VALUE" in tree
- [ ] Delete root question - verify child deleted
- [ ] Delete child question - verify parent remains
- [ ] Add MCQ parent - verify dropdown shows in trigger UI
- [ ] Add text parent - verify text input shows in trigger UI
- [ ] Reload page - verify tree persists

### Integration Test Checklist
- [ ] Admin login works
- [ ] Questionnaire tab loads
- [ ] Section dropdown populated
- [ ] Parent dropdown updates on section change
- [ ] Trigger UI appears/disappears on parent selection
- [ ] Form submission saves to database
- [ ] Tree visualization matches database state
- [ ] Edit section still works
- [ ] Delete section cascades to questions

### End-to-End Test (Future)
- [ ] User dashboard: hierarchical questions display
- [ ] Survey form: respects trigger conditions
- [ ] Response save: tracks conditional answers
- [ ] Admin view: can see all responses including conditional

## 📋 Current State Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Admin Dashboard UI | ✅ Complete | Advanced form with tree view |
| App.py Endpoints | ✅ Complete | Handles parent/trigger/options |
| Database Schema | ⏳ Pending | SQL script created, needs execution |
| Syntax Checks | ✅ Verified | Python code compiles OK |
| Documentation | ✅ Complete | Full guide created |

## 🚀 Next Phase: Survey Form Integration

When database migration is complete, update questionnaire.html to:
1. Load questions hierarchically
2. Show/hide based on trigger_value matching
3. Handle multi-level nesting
4. Save conditional answers

## 📁 Files Changed

1. **templates/admin_dashboard.html** - Questionnaire tab (lines 266-348, 1420-1647, 507-517)
2. **app.py** - Question creation endpoint (lines 948-1000)
3. **sql_scripts/add_advanced_questionnaire_fields.sql** - NEW database migration
4. **QUESTIONNAIRE_ADVANCED_GUIDE.md** - NEW full documentation

## ⚠️ Important Notes

- Admin must run SQL migration before testing
- Existing questions work unchanged (backwards compatible)
- Tree view only shows after section selected
- Parent dropdown auto-populates when section changes
- Trigger UI intelligently chooses input type based on parent options

## 📞 Support

If issues occur:
1. Check browser console for JavaScript errors
2. Check Flask logs for backend errors
3. Verify database columns added with: `DESCRIBE questions;`
4. Ensure parent_id references valid question_id

---

**Status:** Ready for database migration and testing ✅
