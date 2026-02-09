-- Update all section titles to remove the "XX. " prefix
-- This assumes the current titles exactly match the prefixed versions.
-- After running these, the titles will be clean, and CALL reorder_sections() 
-- will automatically resort them alphabetically by the new titles.

UPDATE questionnaire_sections 
SET section_title = 'General Questions' 
WHERE section_title = '01. General Questions';

UPDATE questionnaire_sections 
SET section_title = 'Respondent Details' 
WHERE section_title = '02. Respondent Details';

UPDATE questionnaire_sections 
SET section_title = 'Water Supply and Storage' 
WHERE section_title = '03. Water Supply and Storage';

UPDATE questionnaire_sections 
SET section_title = 'Pest Control - Mosquito Repellents' 
WHERE section_title = '04. Pest Control - Mosquito Repellents';

UPDATE questionnaire_sections 
SET section_title = 'Pesticide or DDT' 
WHERE section_title = '05. Pesticide or DDT';

UPDATE questionnaire_sections 
SET section_title = 'Details of Family Members' 
WHERE section_title = '06. Details of Family Members';

-- Reorder sections alphabetically by the new clean titles
CALL reorder_sections();