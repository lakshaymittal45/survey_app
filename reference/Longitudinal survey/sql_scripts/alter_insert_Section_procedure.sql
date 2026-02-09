-- Fixed INSERT SECTION procedure to avoid MySQL Error 1093
-- The issue was caused by inserting into a table while selecting from the same table in a subquery.
-- Workaround: Use a derived table to isolate the MAX() calculation.

DELIMITER //

DROP PROCEDURE IF EXISTS insert_section//

CREATE PROCEDURE insert_section(
    IN p_section_title VARCHAR(255)
)
BEGIN
    DECLARE max_order INT DEFAULT 0;

    -- Case-insensitive duplicate check (preserves original casing)
    IF NOT EXISTS (
        SELECT 1 FROM questionnaire_sections 
        WHERE LOWER(section_title) = LOWER(p_section_title)
    ) THEN
        -- Safely get the next section_order using a derived table
        SELECT COALESCE(MAX(section_order), 0) INTO max_order
        FROM (SELECT section_order FROM questionnaire_sections) AS tmp;

        INSERT INTO questionnaire_sections (section_order, section_title)
        VALUES (max_order + 1, p_section_title);
        
        CALL reorder_sections();
    END IF;
END //

DELIMITER ;