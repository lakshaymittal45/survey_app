DELIMITER //

-- DELETE SECTION 
-- Deletes the section and (due to ON DELETE CASCADE on the foreign key) 
-- automatically deletes all corresponding questions.
-- Then reorders remaining sections and remaining questions.
CREATE PROCEDURE delete_section(IN p_section_id INT)
BEGIN
    DELETE FROM questionnaire_sections WHERE section_id = p_section_id;
    CALL reorder_sections();
    CALL reorder_questions();
END //

DELIMITER ;