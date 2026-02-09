-- =============================================
-- Survey System - Stored Procedures
-- Database: survey_1
-- =============================================

USE survey_1;

DELIMITER $$

-- =============================================
-- STATE PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_state$$
CREATE PROCEDURE insert_state(
    IN p_name VARCHAR(100),
    IN p_territory_type ENUM('STATE', 'UT')
)
BEGIN
    INSERT INTO states (name, territory_type) 
    VALUES (p_name, p_territory_type);
END$$

DROP PROCEDURE IF EXISTS update_state$$
CREATE PROCEDURE update_state(
    IN p_state_id INT,
    IN p_name VARCHAR(100),
    IN p_territory_type ENUM('STATE', 'UT')
)
BEGIN
    UPDATE states 
    SET name = p_name, territory_type = p_territory_type 
    WHERE state_id = p_state_id;
END$$

DROP PROCEDURE IF EXISTS delete_state$$
CREATE PROCEDURE delete_state(IN p_state_id INT)
BEGIN
    DELETE FROM states WHERE state_id = p_state_id;
END$$

-- =============================================
-- DISTRICT PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_district$$
CREATE PROCEDURE insert_district(
    IN p_name VARCHAR(100),
    IN p_state_id INT
)
BEGIN
    INSERT INTO districts (name, state_id) 
    VALUES (p_name, p_state_id);
END$$

DROP PROCEDURE IF EXISTS update_district$$
CREATE PROCEDURE update_district(
    IN p_district_id INT,
    IN p_name VARCHAR(100),
    IN p_state_id INT
)
BEGIN
    UPDATE districts 
    SET name = p_name, state_id = p_state_id 
    WHERE district_id = p_district_id;
END$$

DROP PROCEDURE IF EXISTS delete_district$$
CREATE PROCEDURE delete_district(IN p_district_id INT)
BEGIN
    DELETE FROM districts WHERE district_id = p_district_id;
END$$

-- =============================================
-- BLOCK PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_block$$
CREATE PROCEDURE insert_block(
    IN p_name VARCHAR(100),
    IN p_district_id INT
)
BEGIN
    INSERT INTO blocks (name, district_id) 
    VALUES (p_name, p_district_id);
END$$

DROP PROCEDURE IF EXISTS update_block$$
CREATE PROCEDURE update_block(
    IN p_block_id INT,
    IN p_name VARCHAR(100),
    IN p_district_id INT
)
BEGIN
    UPDATE blocks 
    SET name = p_name, district_id = p_district_id 
    WHERE block_id = p_block_id;
END$$

DROP PROCEDURE IF EXISTS delete_block$$
CREATE PROCEDURE delete_block(IN p_block_id INT)
BEGIN
    DELETE FROM blocks WHERE block_id = p_block_id;
END$$

-- =============================================
-- VILLAGE PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_village$$
CREATE PROCEDURE insert_village(
    IN p_village_lgd_code BIGINT,
    IN p_name VARCHAR(100),
    IN p_district_id INT,
    IN p_block_id INT
)
BEGIN
    INSERT INTO villages (village_lgd_code, name, district_id, block_id) 
    VALUES (p_village_lgd_code, p_name, p_district_id, p_block_id);
END$$

DROP PROCEDURE IF EXISTS update_village$$
CREATE PROCEDURE update_village(
    IN p_village_lgd_code BIGINT,
    IN p_name VARCHAR(100),
    IN p_district_id INT,
    IN p_block_id INT
)
BEGIN
    UPDATE villages 
    SET name = p_name, district_id = p_district_id, block_id = p_block_id 
    WHERE village_lgd_code = p_village_lgd_code;
END$$

DROP PROCEDURE IF EXISTS delete_village$$
CREATE PROCEDURE delete_village(IN p_village_lgd_code BIGINT)
BEGIN
    DELETE FROM villages WHERE village_lgd_code = p_village_lgd_code;
END$$

-- =============================================
-- HOUSEHOLD PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_household$$
CREATE PROCEDURE insert_household(
    IN p_name VARCHAR(200),
    IN p_state_id INT,
    IN p_district_id INT,
    IN p_block_id INT,
    IN p_village_id BIGINT,
    IN p_user_id INT
)
BEGIN
    INSERT INTO households (name, state_id, district_id, block_id, village_id, user_id) 
    VALUES (p_name, p_state_id, p_district_id, p_block_id, p_village_id, p_user_id);
END$$

-- =============================================
-- QUESTIONNAIRE SECTION PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_section$$
CREATE PROCEDURE insert_section(
    IN p_section_title VARCHAR(200)
)
BEGIN
    DECLARE next_order INT;
    
    SELECT COALESCE(MAX(section_order), 0) + 1 INTO next_order 
    FROM questionnaire_sections;
    
    INSERT INTO questionnaire_sections (section_order, section_title) 
    VALUES (next_order, p_section_title);
END$$

DROP PROCEDURE IF EXISTS update_section$$
CREATE PROCEDURE update_section(
    IN p_section_id INT,
    IN p_section_title VARCHAR(200)
)
BEGIN
    UPDATE questionnaire_sections 
    SET section_title = p_section_title 
    WHERE section_id = p_section_id;
END$$

DROP PROCEDURE IF EXISTS delete_section$$
CREATE PROCEDURE delete_section(IN p_section_id INT)
BEGIN
    -- Delete associated questions first
    DELETE FROM questions WHERE question_section_id = p_section_id;
    -- Delete section
    DELETE FROM questionnaire_sections WHERE section_id = p_section_id;
END$$

DROP PROCEDURE IF EXISTS reorder_sections$$
CREATE PROCEDURE reorder_sections(
    IN p_section_id INT,
    IN p_new_order INT
)
BEGIN
    DECLARE current_order INT;
    
    SELECT section_order INTO current_order 
    FROM questionnaire_sections 
    WHERE section_id = p_section_id;
    
    IF current_order < p_new_order THEN
        UPDATE questionnaire_sections 
        SET section_order = section_order - 1 
        WHERE section_order > current_order AND section_order <= p_new_order;
    ELSE
        UPDATE questionnaire_sections 
        SET section_order = section_order + 1 
        WHERE section_order >= p_new_order AND section_order < current_order;
    END IF;
    
    UPDATE questionnaire_sections 
    SET section_order = p_new_order 
    WHERE section_id = p_section_id;
END$$

-- =============================================
-- QUESTION PROCEDURES
-- =============================================

DROP PROCEDURE IF EXISTS insert_question$$
CREATE PROCEDURE insert_question(
    IN p_section_id INT,
    IN p_question_text TEXT,
    IN p_answer_type ENUM('text', 'numerical', 'mcq', 'multiple')
)
BEGIN
    DECLARE next_order INT;
    
    SELECT COALESCE(MAX(question_order), 0) + 1 INTO next_order 
    FROM questions 
    WHERE question_section_id = p_section_id;
    
    INSERT INTO questions (question_order, question_section_id, question_text, answer_type) 
    VALUES (next_order, p_section_id, p_question_text, p_answer_type);
END$$

DROP PROCEDURE IF EXISTS update_question$$
CREATE PROCEDURE update_question(
    IN p_question_id INT,
    IN p_section_id INT,
    IN p_question_text TEXT,
    IN p_answer_type ENUM('text', 'numerical', 'mcq', 'multiple')
)
BEGIN
    UPDATE questions 
    SET question_section_id = p_section_id, 
        question_text = p_question_text, 
        answer_type = p_answer_type 
    WHERE question_id = p_question_id;
END$$

DROP PROCEDURE IF EXISTS delete_question$$
CREATE PROCEDURE delete_question(IN p_question_id INT)
BEGIN
    DELETE FROM questions WHERE question_id = p_question_id;
END$$

DROP PROCEDURE IF EXISTS reorder_questions$$
CREATE PROCEDURE reorder_questions(
    IN p_question_id INT,
    IN p_new_order INT
)
BEGIN
    DECLARE current_order INT;
    DECLARE section_id INT;
    
    SELECT question_order, question_section_id INTO current_order, section_id 
    FROM questions 
    WHERE question_id = p_question_id;
    
    IF current_order < p_new_order THEN
        UPDATE questions 
        SET question_order = question_order - 1 
        WHERE question_section_id = section_id 
          AND question_order > current_order 
          AND question_order <= p_new_order;
    ELSE
        UPDATE questions 
        SET question_order = question_order + 1 
        WHERE question_section_id = section_id 
          AND question_order >= p_new_order 
          AND question_order < current_order;
    END IF;
    
    UPDATE questions 
    SET question_order = p_new_order 
    WHERE question_id = p_question_id;
END$$

-- =============================================
-- LINK VILLAGE TO BLOCK PROCEDURE
-- =============================================

DROP PROCEDURE IF EXISTS link_village_to_block$$
CREATE PROCEDURE link_village_to_block(
    IN p_village_lgd_code BIGINT,
    IN p_block_id INT
)
BEGIN
    UPDATE villages 
    SET block_id = p_block_id 
    WHERE village_lgd_code = p_village_lgd_code;
END$$

DELIMITER ;

-- =============================================
-- VERIFY PROCEDURES CREATED
-- =============================================

SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM 
    information_schema.ROUTINES
WHERE 
    ROUTINE_SCHEMA = 'survey_1'
    AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY 
    ROUTINE_NAME;