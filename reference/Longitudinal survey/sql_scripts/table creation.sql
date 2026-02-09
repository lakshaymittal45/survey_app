-- 1. STATES TABLE
CREATE TABLE states (
    state_id INT,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (state_id),
    UNIQUE KEY (name) -- Prevents duplicate state names
) ENGINE=InnoDB;

-- 2. DISTRICTS TABLE
CREATE TABLE districts (
    district_id INT,
    name VARCHAR(255) NOT NULL,
    state_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (district_id),
    CONSTRAINT fk_state FOREIGN KEY (state_id) REFERENCES states(state_id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY (name, state_id), -- Prevents duplicate district names within the same state
    INDEX idx_state_id (state_id)
) ENGINE=InnoDB;

-- 3. BLOCKS TABLE
CREATE TABLE blocks (
    block_id INT,
    name VARCHAR(255) NOT NULL,
    district_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (block_id),
    CONSTRAINT fk_district FOREIGN KEY (district_id) REFERENCES districts(district_id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY (name, district_id), -- Prevents duplicate block names within the same district
    INDEX idx_district_id (district_id)
) ENGINE=InnoDB;

-- TRIGGERS FOR AUTOMATIC UPPERCASE
DELIMITER //
CREATE TRIGGER trg_state_insert BEFORE INSERT ON states FOR EACH ROW SET NEW.name = UPPER(NEW.name);
CREATE TRIGGER trg_state_update BEFORE UPDATE ON states FOR EACH ROW SET NEW.name = UPPER(NEW.name);
CREATE TRIGGER trg_district_insert BEFORE INSERT ON districts FOR EACH ROW SET NEW.name = UPPER(NEW.name);
CREATE TRIGGER trg_district_update BEFORE UPDATE ON districts FOR EACH ROW SET NEW.name = UPPER(NEW.name);
CREATE TRIGGER trg_block_insert BEFORE INSERT ON blocks FOR EACH ROW SET NEW.name = UPPER(NEW.name);
CREATE TRIGGER trg_block_update BEFORE UPDATE ON blocks FOR EACH ROW SET NEW.name = UPPER(NEW.name);
//
DELIMITER ;

-- PROCEDURES
DELIMITER //

-- STATE PROCEDURES
CREATE PROCEDURE reorder_states()
BEGIN
    CREATE TEMPORARY TABLE temp_state (old_id INT, new_id INT);
    INSERT INTO temp_state
    SELECT state_id, ROW_NUMBER() OVER (ORDER BY name ASC) AS new_id FROM states;
    UPDATE states s INNER JOIN temp_state t ON s.state_id = t.old_id SET s.state_id = -t.new_id;
    UPDATE states SET state_id = -state_id;
    DROP TEMPORARY TABLE temp_state;
END //

CREATE PROCEDURE insert_state(IN p_name VARCHAR(255))
BEGIN
    -- Duplicate Check
    IF NOT EXISTS (SELECT 1 FROM states WHERE name = UPPER(p_name)) THEN
        INSERT INTO states (state_id, name) VALUES ((SELECT COALESCE(MAX(state_id), 0) + 1 FROM states), p_name);
        CALL reorder_states();
    END IF;
END //

CREATE PROCEDURE delete_state(IN p_id INT)
BEGIN
    DELETE FROM states WHERE state_id = p_id;
    CALL reorder_states();
END //

CREATE PROCEDURE update_state(IN p_id INT, IN p_new_name VARCHAR(255))
BEGIN
    -- Check if updated name already exists elsewhere
    IF NOT EXISTS (SELECT 1 FROM states WHERE name = UPPER(p_new_name) AND state_id != p_id) THEN
        UPDATE states SET name = p_new_name WHERE state_id = p_id;
        CALL reorder_states();
    END IF;
END //

-- DISTRICT PROCEDURES
CREATE PROCEDURE reorder_districts()
BEGIN
    CREATE TEMPORARY TABLE temp_district (old_id INT, new_id INT);
    INSERT INTO temp_district
    SELECT district_id, ROW_NUMBER() OVER (ORDER BY name ASC) AS new_id FROM districts;
    UPDATE districts d INNER JOIN temp_district t ON d.district_id = t.old_id SET d.district_id = -t.new_id;
    UPDATE districts SET district_id = -district_id;
    DROP TEMPORARY TABLE temp_district;
END //

CREATE PROCEDURE insert_district(IN p_name VARCHAR(255), IN p_state_id INT)
BEGIN
    -- Duplicate Check within the same State
    IF NOT EXISTS (SELECT 1 FROM districts WHERE name = UPPER(p_name) AND state_id = p_state_id) THEN
        INSERT INTO districts (district_id, name, state_id) VALUES ((SELECT COALESCE(MAX(district_id), 0) + 1 FROM districts), p_name, p_state_id);
        CALL reorder_districts();
    END IF;
END //

CREATE PROCEDURE delete_district(IN p_id INT)
BEGIN
    DELETE FROM districts WHERE district_id = p_id;
    CALL reorder_districts();
END //

CREATE PROCEDURE update_district(IN p_id INT, IN p_new_name VARCHAR(255))
BEGIN
    -- Check if updated name already exists in the same state
    IF NOT EXISTS (
        SELECT 1 FROM districts d1
        JOIN districts d2 ON d1.state_id = d2.state_id
        WHERE d2.district_id = p_id AND d1.name = UPPER(p_new_name) AND d1.district_id != p_id
    ) THEN
        UPDATE districts SET name = p_new_name WHERE district_id = p_id;
        CALL reorder_districts();
    END IF;
END //

-- BLOCK PROCEDURES
CREATE PROCEDURE reorder_blocks()
BEGIN
    CREATE TEMPORARY TABLE temp_block (old_id INT, new_id INT);
    INSERT INTO temp_block
    SELECT block_id, ROW_NUMBER() OVER (ORDER BY name ASC) AS new_id FROM blocks;
    UPDATE blocks b INNER JOIN temp_block t ON b.block_id = t.old_id SET b.block_id = -t.new_id;
    UPDATE blocks SET block_id = -block_id;
    DROP TEMPORARY TABLE temp_block;
END //

CREATE PROCEDURE insert_block(IN p_name VARCHAR(255), IN p_district_id INT)
BEGIN
    -- Duplicate Check within the same District
    IF NOT EXISTS (SELECT 1 FROM blocks WHERE name = UPPER(p_name) AND district_id = p_district_id) THEN
        INSERT INTO blocks (block_id, name, district_id) VALUES ((SELECT COALESCE(MAX(block_id), 0) + 1 FROM blocks), p_name, p_district_id);
        CALL reorder_blocks();
    END IF;
END //

CREATE PROCEDURE delete_block(IN p_id INT)
BEGIN
    DELETE FROM blocks WHERE block_id = p_id;
    CALL reorder_blocks();
END //

CREATE PROCEDURE update_block(IN p_id INT, IN p_new_name VARCHAR(255))
BEGIN
    -- Check if updated name already exists in the same district
    IF NOT EXISTS (
        SELECT 1 FROM blocks b1
        JOIN blocks b2 ON b1.district_id = b2.district_id
        WHERE b2.block_id = p_id AND b1.name = UPPER(p_new_name) AND b1.block_id != p_id
    ) THEN
        UPDATE blocks SET name = p_new_name WHERE block_id = p_id;
        CALL reorder_blocks();
    END IF;
END //

DELIMITER ;