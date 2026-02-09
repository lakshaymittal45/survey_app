-- QUESTIONS TABLE (with section foreign key and cascading delete)
-- Fixed: Safe temp table handling + Error 1093 workaround in insert_question
CREATE TABLE questions (
    question_id INT AUTO_INCREMENT NOT NULL,
    question_order INT NOT NULL, -- For reordering/display logic (sequential, gap-free)
    question_section_id INT DEFAULT NULL, -- Foreign key to questionnaire_sections.section_id
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL,
    answer_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (question_id),
    UNIQUE KEY uk_question_order (question_order),
    INDEX idx_question_order (question_order),
    INDEX idx_question_section_id (question_section_id),
    CONSTRAINT fk_question_section
        FOREIGN KEY (question_section_id)
        REFERENCES questionnaire_sections(section_id)
        ON DELETE CASCADE  -- Deletes all questions when section is deleted
        ON UPDATE CASCADE,
    CHECK (question_type IN ('multiple_choice', 'single_choice', 'open_ended')),
    CHECK (answer_type IN ('text', 'numerical'))
) ENGINE=InnoDB;

DELIMITER //

-- REORDER QUESTIONS (safe temp table + proper section grouping)
DROP PROCEDURE IF EXISTS reorder_questions//

CREATE PROCEDURE reorder_questions()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS temp_question;
    
    CREATE TEMPORARY TABLE temp_question (old_id INT, new_order INT);
    
    INSERT INTO temp_question
    SELECT q.question_id,
           ROW_NUMBER() OVER (
               ORDER BY
                   CASE WHEN q.question_section_id IS NULL THEN -1 ELSE COALESCE(s.section_order, 999999) END ASC,
                   q.question_text ASC,
                   q.question_id ASC
           ) AS new_order
    FROM questions q
    LEFT JOIN questionnaire_sections s ON q.question_section_id = s.section_id;
    
    UPDATE questions q
    INNER JOIN temp_question t ON q.question_id = t.old_id
    SET q.question_order = -t.new_order;
    
    UPDATE questions
    SET question_order = -question_order;
    
    DROP TEMPORARY TABLE temp_question;
END //

-- INSERT QUESTION (Error 1093 fixed + exact duplicate prevention)
DROP PROCEDURE IF EXISTS insert_question//

CREATE PROCEDURE insert_question(
    IN p_question_text TEXT,
    IN p_question_type VARCHAR(50),
    IN p_answer_type VARCHAR(20),
    IN p_question_section_id INT  -- Pass valid section_id or NULL for unsectioned
)
BEGIN
    DECLARE max_order INT DEFAULT 0;

    IF NOT EXISTS (SELECT 1 FROM questions WHERE question_text = p_question_text) THEN
        -- Safe MAX() using derived table to avoid Error 1093
        SELECT COALESCE(MAX(question_order), 0) INTO max_order
        FROM (SELECT question_order FROM questions) AS tmp;
        
        INSERT INTO questions (
            question_order,
            question_text,
            question_type,
            answer_type,
            question_section_id
        )
        VALUES (
            max_order + 1,
            p_question_text,
            p_question_type,
            p_answer_type,
            p_question_section_id
        );
        
        CALL reorder_questions();
    END IF;
END //

-- DELETE QUESTION
DROP PROCEDURE IF EXISTS delete_question//

CREATE PROCEDURE delete_question(IN p_question_id INT)
BEGIN
    DELETE FROM questions WHERE question_id = p_question_id;
    CALL reorder_questions();
END //

-- UPDATE QUESTION (allows moving to different section + duplicate prevention)
DROP PROCEDURE IF EXISTS update_question//

CREATE PROCEDURE update_question(
    IN p_question_id INT,
    IN p_question_text TEXT,
    IN p_question_type VARCHAR(50),
    IN p_answer_type VARCHAR(20),
    IN p_question_section_id INT  -- Can change section (valid ID or NULL)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM questions 
        WHERE question_text = p_question_text 
        AND question_id <> p_question_id
    ) THEN
        UPDATE questions
        SET question_text = p_question_text,
            question_type = p_question_type,
            answer_type = p_answer_type,
            question_section_id = p_question_section_id
        WHERE question_id = p_question_id;
        
        CALL reorder_questions();
    END IF;
END //

DELIMITER ;