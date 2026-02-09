DELIMITER //

-- REORDER VILLAGES
CREATE PROCEDURE reorder_villages()
BEGIN
    CREATE TEMPORARY TABLE temp_village (old_lgd INT, new_id INT);
    INSERT INTO temp_village
    SELECT village_lgd_code, ROW_NUMBER() OVER (ORDER BY name ASC) AS new_id FROM villages;
    
    -- Using negative values to avoid unique constraint collisions during swap
    UPDATE villages v INNER JOIN temp_village t ON v.village_lgd_code = t.old_lgd SET v.village_id = -t.new_id;
    UPDATE villages SET village_id = -village_id;
    
    DROP TEMPORARY TABLE temp_village;
END //

-- INSERT VILLAGE (Handles partial data for Excel imports)
CREATE PROCEDURE insert_village(
    IN p_lgd_code INT, 
    IN p_name VARCHAR(255), 
    IN p_district_id INT, 
    IN p_block_id INT -- Can be passed as NULL
)
BEGIN
    -- Duplicate Check on LGD or Name within same District
    IF NOT EXISTS (SELECT 1 FROM villages WHERE village_lgd_code = p_lgd_code OR (name = UPPER(p_name) AND district_id = p_district_id)) THEN
        INSERT INTO villages (village_lgd_code, village_id, name, district_id, block_id) 
        VALUES (
            p_lgd_code, 
            (SELECT COALESCE(MAX(village_id), 0) + 1 FROM villages), 
            p_name, 
            p_district_id, 
            p_block_id
        );
        CALL reorder_villages();
    END IF;
END //

-- DELETE VILLAGE
CREATE PROCEDURE delete_village(IN p_lgd_code INT)
BEGIN
    DELETE FROM villages WHERE village_lgd_code = p_lgd_code;
    CALL reorder_villages();
END //

-- UPDATE VILLAGE
CREATE PROCEDURE update_village(
    IN p_lgd_code INT, 
    IN p_new_name VARCHAR(255), 
    IN p_block_id INT
)
BEGIN
    UPDATE villages 
    SET name = p_new_name, block_id = p_block_id 
    WHERE village_lgd_code = p_lgd_code;
    CALL reorder_villages();
END //

DELIMITER ;