-- Safe full reset script for questionnaire_sections (and handles dependent questions table)
-- This temporarily disables foreign key checks to allow dropping tables safely,
-- then recreates everything cleanly. All existing data will be lost (development reset).

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS questionnaire_sections;

SET FOREIGN_KEY_CHECKS = 1;

-- Recreate QUESTIONNAIRE SECTIONS TABLE
CREATE TABLE questionnaire_sections (
    section_id INT AUTO_INCREMENT NOT NULL,
    section_order INT NOT NULL,
    section_title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (section_id),
    UNIQUE KEY uk_section_order (section_order),
    UNIQUE KEY uk_section_title (section_title),
    INDEX idx_section_order (section_order)
) ENGINE=InnoDB;

DELIMITER //

-- REORDER SECTIONS (with safe temp table drop)
DROP PROCEDURE IF EXISTS reorder_sections//

CREATE PROCEDURE reorder_sections()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS temp_section;
    
    CREATE TEMPORARY TABLE temp_section (old_id INT, new_order INT);
    
    INSERT INTO temp_section
    SELECT section_id, ROW_NUMBER() OVER (ORDER BY section_title ASC, section_id ASC) AS new_order
    FROM questionnaire_sections;
    
    UPDATE questionnaire_sections sec
    INNER JOIN temp_section t ON sec.section_id = t.old_id
    SET sec.section_order = -t.new_order;
    
    UPDATE questionnaire_sections
    SET section_order = -section_order;
    
    DROP TEMPORARY TABLE temp_section;
END //

-- INSERT SECTION (Error 1093 fixed)
DROP PROCEDURE IF EXISTS insert_section//

CREATE PROCEDURE insert_section(
    IN p_section_title VARCHAR(255)
)
BEGIN
    DECLARE max_order INT DEFAULT 0;

    IF NOT EXISTS (
        SELECT 1 FROM questionnaire_sections 
        WHERE LOWER(section_title) = LOWER(p_section_title)
    ) THEN
        SELECT COALESCE(MAX(section_order), 0) INTO max_order
        FROM (SELECT section_order FROM questionnaire_sections) AS tmp;

        INSERT INTO questionnaire_sections (section_order, section_title)
        VALUES (max_order + 1, p_section_title);
        
        CALL reorder_sections();
    END IF;
END //

-- UPDATE SECTION
DROP PROCEDURE IF EXISTS update_section//

CREATE PROCEDURE update_section(
    IN p_section_id INT,
    IN p_new_title VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM questionnaire_sections 
        WHERE LOWER(section_title) = LOWER(p_new_title)
        AND section_id <> p_section_id
    ) THEN
        UPDATE questionnaire_sections
        SET section_title = p_new_title
        WHERE section_id = p_section_id;
        
        CALL reorder_sections();
    END IF;
END //

-- DELETE SECTION (cascade deletes questions + reorders)
DROP PROCEDURE IF EXISTS delete_section//

CREATE PROCEDURE delete_section(IN p_section_id INT)
BEGIN
    DELETE FROM questionnaire_sections WHERE section_id = p_section_id;
    CALL reorder_sections();
    CALL reorder_questions();
END //

DELIMITER ;