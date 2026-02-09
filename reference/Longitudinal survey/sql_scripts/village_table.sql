-- 4. VILLAGES TABLE
CREATE TABLE villages (
    village_lgd_code INT NOT NULL, -- Primary Key as requested
    village_id INT NOT NULL,       -- For reordering logic
    name VARCHAR(255) NOT NULL,
    district_id INT NOT NULL,
    block_id INT DEFAULT NULL,     -- Nullable for initial Excel imports
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (village_lgd_code),
    UNIQUE KEY (village_id),
    CONSTRAINT fk_village_district FOREIGN KEY (district_id) REFERENCES districts(district_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_village_block FOREIGN KEY (block_id) REFERENCES blocks(block_id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY (name, district_id, block_id), -- Prevents duplicates in same hierarchy
    INDEX idx_district_id (district_id),
    INDEX idx_block_id (block_id)
) ENGINE=InnoDB;

DELIMITER //
CREATE TRIGGER trg_village_insert BEFORE INSERT ON villages FOR EACH ROW SET NEW.name = UPPER(NEW.name);
CREATE TRIGGER trg_village_update BEFORE UPDATE ON villages FOR EACH ROW SET NEW.name = UPPER(NEW.name);
//
DELIMITER ;



