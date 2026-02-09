DELIMITER //

-- ==========================================
-- 1. STATES PROCEDURES
-- ==========================================

-- Reorder States: Added safety drop and Safe Mode handling
DROP PROCEDURE IF EXISTS reorder_states//
CREATE PROCEDURE reorder_states()
BEGIN
    SET SQL_SAFE_UPDATES = 0;
    -- Fix for Error 1050: Ensure old temp table is cleared from session
    DROP TEMPORARY TABLE IF EXISTS temp_state; 
    
    CREATE TEMPORARY TABLE temp_state (old_id INT, new_id INT);
    INSERT INTO temp_state SELECT state_id, ROW_NUMBER() OVER (ORDER BY name ASC) FROM states;
    
    UPDATE states s INNER JOIN temp_state t ON s.state_id = t.old_id SET s.state_id = -t.new_id;
    UPDATE states SET state_id = ABS(state_id);
    
    DROP TEMPORARY TABLE temp_state;
    SET SQL_SAFE_UPDATES = 1;
END //

-- Insert State: Added Duplicate Prevention
DROP PROCEDURE IF EXISTS insert_state//
CREATE PROCEDURE insert_state(IN p_name VARCHAR(255))
BEGIN
    DECLARE next_id INT;
    -- Duplicate Check: Only proceed if name doesn't exist
    IF NOT EXISTS (SELECT 1 FROM states WHERE name = UPPER(p_name)) THEN
        SELECT COALESCE(MAX(state_id), 0) + 1 INTO next_id FROM states;
        INSERT INTO states (state_id, name) VALUES (next_id, p_name);
        CALL reorder_states();
    END IF;
END //

-- ==========================================
-- 2. DISTRICTS PROCEDURES
-- ==========================================

-- Reorder Districts: Added safety drop and Safe Mode handling
DROP PROCEDURE IF EXISTS reorder_districts//
CREATE PROCEDURE reorder_districts()
BEGIN
    SET SQL_SAFE_UPDATES = 0;
    -- Fix for Error 1050
    DROP TEMPORARY TABLE IF EXISTS temp_district;
    
    CREATE TEMPORARY TABLE temp_district (old_id INT, new_id INT);
    INSERT INTO temp_district SELECT district_id, ROW_NUMBER() OVER (ORDER BY name ASC) FROM districts;
    
    UPDATE districts d INNER JOIN temp_district t ON d.district_id = t.old_id SET d.district_id = -t.new_id;
    UPDATE districts SET district_id = ABS(district_id);
    
    DROP TEMPORARY TABLE temp_district;
    SET SQL_SAFE_UPDATES = 1;
END //

-- Insert District: Added Duplicate Prevention (Unique per State)
DROP PROCEDURE IF EXISTS insert_district//
CREATE PROCEDURE insert_district(IN p_name VARCHAR(255), IN p_state_id INT)
BEGIN
    DECLARE next_id INT;
    -- Duplicate Check: Prevents same district name in the same state
    IF NOT EXISTS (SELECT 1 FROM districts WHERE name = UPPER(p_name) AND state_id = p_state_id) THEN
        SELECT COALESCE(MAX(district_id), 0) + 1 INTO next_id FROM districts;
        INSERT INTO districts (district_id, name, state_id) VALUES (next_id, p_name, p_state_id);
        CALL reorder_districts();
    END IF;
END //

-- ==========================================
-- 3. BLOCKS PROCEDURES
-- ==========================================

-- Reorder Blocks
DROP PROCEDURE IF EXISTS reorder_blocks//
CREATE PROCEDURE reorder_blocks()
BEGIN
    SET SQL_SAFE_UPDATES = 0;
    DROP TEMPORARY TABLE IF EXISTS temp_block;
    
    CREATE TEMPORARY TABLE temp_block (old_id INT, new_id INT);
    INSERT INTO temp_block SELECT block_id, ROW_NUMBER() OVER (ORDER BY name ASC) FROM blocks;
    
    UPDATE blocks b INNER JOIN temp_block t ON b.block_id = t.old_id SET b.block_id = -t.new_id;
    UPDATE blocks SET block_id = ABS(block_id);
    
    DROP TEMPORARY TABLE temp_block;
    SET SQL_SAFE_UPDATES = 1;
END //

-- Insert Block: Added Duplicate Prevention (Unique per District)
DROP PROCEDURE IF EXISTS insert_block//
CREATE PROCEDURE insert_block(IN p_name VARCHAR(255), IN p_district_id INT)
BEGIN
    DECLARE next_id INT;
    IF NOT EXISTS (SELECT 1 FROM blocks WHERE name = UPPER(p_name) AND district_id = p_district_id) THEN
        SELECT COALESCE(MAX(block_id), 0) + 1 INTO next_id FROM blocks;
        INSERT INTO blocks (block_id, name, district_id) VALUES (next_id, p_name, p_district_id);
        CALL reorder_blocks();
    END IF;
END //

DELIMITER ;