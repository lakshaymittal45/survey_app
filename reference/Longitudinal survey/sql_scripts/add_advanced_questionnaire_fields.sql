-- Add advanced questionnaire fields for parent-child questions and trigger conditions
-- This script adds support for hierarchical questions and conditional logic

ALTER TABLE questions ADD COLUMN IF NOT EXISTS parent_id INT NULL;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS trigger_value VARCHAR(255) NULL;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS options TEXT NULL;

-- Add foreign key constraint
ALTER TABLE questions ADD CONSTRAINT fk_parent_question 
FOREIGN KEY (parent_id) REFERENCES questions(question_id) ON DELETE CASCADE;

-- Create index for faster parent lookups
CREATE INDEX idx_questions_parent ON questions(parent_id);

-- Add columns to survey_attempt if not already present (for tracking conditional responses)
ALTER TABLE survey_attempt ADD COLUMN IF NOT EXISTS timestamp_created DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE survey_attempt ADD COLUMN IF NOT EXISTS timestamp_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Optional: Create a view to easily get question hierarchy
CREATE OR REPLACE VIEW vw_question_hierarchy AS
SELECT 
    q.question_id,
    q.section_id,
    q.question_text,
    q.answer_type,
    q.options,
    q.parent_id,
    q.trigger_value,
    CASE 
        WHEN q.parent_id IS NULL THEN 'root'
        ELSE 'child'
    END as question_level,
    parent.question_text as parent_text
FROM questions q
LEFT JOIN questions parent ON q.parent_id = parent.question_id;

-- Optional: Create a procedure to get question tree for a section
DELIMITER $$

CREATE OR REPLACE PROCEDURE get_question_tree(IN p_section_id INT)
BEGIN
    SELECT 
        q.question_id,
        q.question_text,
        q.answer_type,
        q.options,
        q.parent_id,
        q.trigger_value
    FROM questions q
    WHERE q.section_id = p_section_id
    ORDER BY q.parent_id ASC, q.question_id ASC;
END$$

DELIMITER ;
