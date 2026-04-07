-- Full schema for the survey application (generated)
-- Creates database, tables, relationships, constraints, and triggers used by the app.

CREATE DATABASE IF NOT EXISTS survey_1
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE survey_1;

-- ==========================================================
-- CORE AUTH TABLES
-- ==========================================================
CREATE TABLE IF NOT EXISTS users (
  user_id INT NOT NULL AUTO_INCREMENT,
  username VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uk_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS admins (
  admin_id INT NOT NULL AUTO_INCREMENT,
  username VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (admin_id),
  UNIQUE KEY uk_admins_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ==========================================================
-- GEOGRAPHIC HIERARCHY
-- ==========================================================
CREATE TABLE IF NOT EXISTS states (
  state_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  state_name VARCHAR(255) GENERATED ALWAYS AS (name) STORED,
  territory_type VARCHAR(20) DEFAULT 'STATE',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (state_id),
  UNIQUE KEY uk_states_name (name),
  INDEX idx_states_state_name (state_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS districts (
  district_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  district_name VARCHAR(255) GENERATED ALWAYS AS (name) STORED,
  state_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (district_id),
  UNIQUE KEY uk_districts_name_state (name, state_id),
  INDEX idx_districts_state (state_id),
  INDEX idx_districts_district_name (district_name),
  CONSTRAINT fk_district_state
    FOREIGN KEY (state_id) REFERENCES states(state_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS blocks (
  block_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  block_name VARCHAR(255) GENERATED ALWAYS AS (name) STORED,
  district_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (block_id),
  UNIQUE KEY uk_blocks_name_district (name, district_id),
  INDEX idx_blocks_district (district_id),
  INDEX idx_blocks_block_name (block_name),
  CONSTRAINT fk_block_district
    FOREIGN KEY (district_id) REFERENCES districts(district_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sub_centers (
  sub_center_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  sub_center_name VARCHAR(255) GENERATED ALWAYS AS (name) STORED,
  block_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (sub_center_id),
  INDEX idx_sub_centers_block (block_id),
  INDEX idx_sub_centers_name (sub_center_name),
  CONSTRAINT fk_subcenter_block
    FOREIGN KEY (block_id) REFERENCES blocks(block_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS villages (
  village_id INT NOT NULL AUTO_INCREMENT,
  village_lgd_code INT NULL,
  name VARCHAR(255) NOT NULL,
  village_name VARCHAR(255) GENERATED ALWAYS AS (name) STORED,
  district_id INT NOT NULL,
  block_id INT NOT NULL,
  sub_center_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (village_id),
  UNIQUE KEY uk_village_lgd_code (village_lgd_code),
  UNIQUE KEY uk_village_name_hierarchy (name, district_id, block_id, sub_center_id),
  INDEX idx_villages_district (district_id),
  INDEX idx_villages_block (block_id),
  INDEX idx_villages_subcenter (sub_center_id),
  INDEX idx_villages_village_name (village_name),
  CONSTRAINT fk_village_district
    FOREIGN KEY (district_id) REFERENCES districts(district_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_village_block
    FOREIGN KEY (block_id) REFERENCES blocks(block_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_village_subcenter
    FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS household_registry (
  registry_id INT NOT NULL AUTO_INCREMENT,
  household_code VARCHAR(255) NOT NULL,
  code_ci VARCHAR(255) GENERATED ALWAYS AS (LOWER(household_code)) STORED,
  village_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (registry_id),
  UNIQUE KEY uk_household_registry_code_ci (code_ci),
  INDEX idx_household_registry_village (village_id),
  CONSTRAINT fk_household_registry_village
    FOREIGN KEY (village_id) REFERENCES villages(village_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS households (
  household_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  household_name VARCHAR(255) GENERATED ALWAYS AS (name) STORED,
  name_ci VARCHAR(255) GENERATED ALWAYS AS (LOWER(name)) STORED,

  state_id INT NOT NULL,
  district_id INT NOT NULL,
  block_id INT NOT NULL,
  sub_center_id INT NOT NULL,
  village_id INT NOT NULL,
  user_id INT NOT NULL,
  latitude DECIMAL(10,8) NULL,
  longitude DECIMAL(11,8) NULL,
  location_accuracy DECIMAL(8,2) NULL,
  location_updated_at TIMESTAMP 
      DEFAULT CURRENT_TIMESTAMP 
      ON UPDATE CURRENT_TIMESTAMP,
  location_method ENUM('gps','manual','map') NULL,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (household_id),

  UNIQUE KEY uk_households_name_ci (name_ci),

  INDEX idx_households_state (state_id),
  INDEX idx_households_district (district_id),
  INDEX idx_households_block (block_id),
  INDEX idx_households_subcenter (sub_center_id),
  INDEX idx_households_village (village_id),
  INDEX idx_households_user (user_id),
  INDEX idx_households_location (latitude, longitude),

  CONSTRAINT fk_household_state
    FOREIGN KEY (state_id) REFERENCES states(state_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT fk_household_district
    FOREIGN KEY (district_id) REFERENCES districts(district_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT fk_household_block
    FOREIGN KEY (block_id) REFERENCES blocks(block_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT fk_household_subcenter
    FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT fk_household_village
    FOREIGN KEY (village_id) REFERENCES villages(village_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT fk_household_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ==========================================================
-- QUESTIONNAIRE (MAIN + INDIVIDUAL)
-- ==========================================================
CREATE TABLE IF NOT EXISTS questionnaire_sections (
  section_id INT AUTO_INCREMENT NOT NULL,
  section_order INT NOT NULL,
  section_title VARCHAR(255) NOT NULL,
  show_on_user_end TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (section_id),
  UNIQUE KEY uk_section_order (section_order),
  UNIQUE KEY uk_section_title (section_title),
  INDEX idx_section_order (section_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS questions (
  question_id INT AUTO_INCREMENT NOT NULL,
  question_order INT NOT NULL,
  question_section_id INT DEFAULT NULL,
  question_text TEXT NOT NULL,
  question_type VARCHAR(50) NOT NULL,
  answer_type VARCHAR(20) NOT NULL,
  is_mandatory TINYINT(1) NULL,
  options TEXT NULL,
  parent_id INT NULL,
  trigger_value VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (question_id),
  UNIQUE KEY uk_question_order (question_order),
  INDEX idx_question_order (question_order),
  INDEX idx_question_section_id (question_section_id),
  INDEX idx_questions_parent (parent_id),
  CONSTRAINT fk_question_section
    FOREIGN KEY (question_section_id)
    REFERENCES questionnaire_sections(section_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_parent_question
    FOREIGN KEY (parent_id)
    REFERENCES questions(question_id)
    ON DELETE CASCADE,
  CHECK (question_type IN ('multiple_choice', 'single_choice', 'open_ended')),
  CHECK (answer_type IN ('text', 'numerical'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS individual_questionnaire_sections (
  section_id INT AUTO_INCREMENT NOT NULL,
  section_order INT NOT NULL,
  section_title VARCHAR(255) NOT NULL,
  show_on_user_end TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (section_id),
  UNIQUE KEY uk_individual_section_order (section_order),
  UNIQUE KEY uk_individual_section_title (section_title),
  INDEX idx_individual_section_order (section_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS individual_questions (
  question_id INT AUTO_INCREMENT NOT NULL,
  question_order INT NOT NULL,
  question_section_id INT DEFAULT NULL,
  question_text TEXT NOT NULL,
  question_type VARCHAR(50) NOT NULL,
  answer_type VARCHAR(20) NOT NULL,
  is_mandatory TINYINT(1) NULL,
  options TEXT NULL,
  parent_id INT NULL,
  trigger_value VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (question_id),
  UNIQUE KEY uk_individual_question_order (question_order),
  INDEX idx_individual_question_order (question_order),
  INDEX idx_individual_question_section_id (question_section_id),
  INDEX idx_individual_questions_parent (parent_id),
  CONSTRAINT fk_individual_question_section
    FOREIGN KEY (question_section_id)
    REFERENCES individual_questionnaire_sections(section_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_individual_parent_question
    FOREIGN KEY (parent_id)
    REFERENCES individual_questions(question_id)
    ON DELETE CASCADE,
  CHECK (question_type IN ('multiple_choice', 'single_choice', 'open_ended')),
  CHECK (answer_type IN ('text', 'numerical'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS main_questionnaire_responses (
  main_questionnaire_id BIGINT NOT NULL AUTO_INCREMENT,
  household_id INT NOT NULL,
  user_id INT NOT NULL,
  responses JSON NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (main_questionnaire_id),
  INDEX idx_main_questionnaire_household (household_id),
  INDEX idx_main_questionnaire_user (user_id),
  CONSTRAINT fk_main_questionnaire_household
    FOREIGN KEY (household_id) REFERENCES households(household_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_main_questionnaire_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS individual_questionnaire_responses (
  individual_questionnaire_id BIGINT NOT NULL AUTO_INCREMENT,
  responses JSON NOT NULL,
  aadhar_hash VARCHAR(64) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (individual_questionnaire_id),
  INDEX idx_iqr_aadhar_hash (aadhar_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS main_individual_questionnaire_links (
  link_id BIGINT NOT NULL AUTO_INCREMENT,
  main_questionnaire_id BIGINT NOT NULL,
  individual_questionnaire_id BIGINT NOT NULL,
  household_id INT NOT NULL,
  filled_by_user_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (link_id),
  INDEX idx_link_main (main_questionnaire_id),
  INDEX idx_link_individual (individual_questionnaire_id),
  INDEX idx_link_household (household_id),
  CONSTRAINT fk_link_main
    FOREIGN KEY (main_questionnaire_id)
    REFERENCES main_questionnaire_responses(main_questionnaire_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_link_individual
    FOREIGN KEY (individual_questionnaire_id)
    REFERENCES individual_questionnaire_responses(individual_questionnaire_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_link_household
    FOREIGN KEY (household_id) REFERENCES households(household_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_link_user
    FOREIGN KEY (filled_by_user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS household_response_drafts (
  draft_id BIGINT NOT NULL AUTO_INCREMENT,
  household_id INT NOT NULL,
  user_id INT NOT NULL,
  response_data JSON NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (draft_id),
  UNIQUE KEY uk_draft_household_user (household_id, user_id),
  INDEX idx_draft_household (household_id),
  INDEX idx_draft_user (user_id),
  CONSTRAINT fk_draft_household
    FOREIGN KEY (household_id) REFERENCES households(household_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_draft_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ==========================================================
-- PERSONS + SURVEY ATTEMPTS (used by /api/initialize-survey)
-- ==========================================================
CREATE TABLE IF NOT EXISTS persons (
  person_id BIGINT NOT NULL AUTO_INCREMENT,
  aadhar VARCHAR(255) DEFAULT NULL,
  aadhar_hash VARCHAR(64) DEFAULT NULL,
  household_id INT NOT NULL,
  age INT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (person_id),
  INDEX idx_persons_household (household_id),
  INDEX idx_persons_aadhar_hash (aadhar_hash),
  CONSTRAINT fk_person_household
    FOREIGN KEY (household_id) REFERENCES households(household_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS survey_attempts (
  survey_attempt_id BIGINT NOT NULL AUTO_INCREMENT,
  person_id BIGINT NOT NULL,
  status ENUM('in_progress','completed','refused') NOT NULL DEFAULT 'in_progress',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (survey_attempt_id),
  INDEX idx_attempts_person (person_id),
  INDEX idx_attempts_status (status),
  CONSTRAINT fk_attempt_person
    FOREIGN KEY (person_id) REFERENCES persons(person_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ==========================================================
-- COMPATIBILITY MIGRATIONS (safe for existing DBs)
-- ==========================================================
SET @sql = IF(
  EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'questions'
      AND column_name = 'is_mandatory'
  ),
  'SELECT ''questions.is_mandatory already exists'' AS msg',
  'ALTER TABLE questions ADD COLUMN is_mandatory TINYINT(1) NULL'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'questionnaire_sections'
      AND column_name = 'show_on_user_end'
  ),
  'SELECT ''questionnaire_sections.show_on_user_end already exists'' AS msg',
  'ALTER TABLE questionnaire_sections ADD COLUMN show_on_user_end TINYINT(1) NOT NULL DEFAULT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'individual_questionnaire_sections'
      AND column_name = 'show_on_user_end'
  ),
  'SELECT ''individual_questionnaire_sections.show_on_user_end already exists'' AS msg',
  'ALTER TABLE individual_questionnaire_sections ADD COLUMN show_on_user_end TINYINT(1) NOT NULL DEFAULT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'individual_questions'
      AND column_name = 'is_mandatory'
  ),
  'SELECT ''individual_questions.is_mandatory already exists'' AS msg',
  'ALTER TABLE individual_questions ADD COLUMN is_mandatory TINYINT(1) NULL'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================
-- TRIGGERS (UPPERCASE NORMALIZATION)
-- ==========================================================
DELIMITER //

DROP TRIGGER IF EXISTS trg_state_insert //
DROP TRIGGER IF EXISTS trg_state_update //
DROP TRIGGER IF EXISTS trg_district_insert //
DROP TRIGGER IF EXISTS trg_district_update //
DROP TRIGGER IF EXISTS trg_block_insert //
DROP TRIGGER IF EXISTS trg_block_update //
DROP TRIGGER IF EXISTS trg_village_insert //
DROP TRIGGER IF EXISTS trg_village_update //
DROP TRIGGER IF EXISTS trg_subcenter_insert //
DROP TRIGGER IF EXISTS trg_subcenter_update //
DROP TRIGGER IF EXISTS trg_household_insert //
DROP TRIGGER IF EXISTS trg_household_update //

CREATE TRIGGER trg_state_insert BEFORE INSERT ON states
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_state_update BEFORE UPDATE ON states
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_district_insert BEFORE INSERT ON districts
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_district_update BEFORE UPDATE ON districts
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_block_insert BEFORE INSERT ON blocks
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_block_update BEFORE UPDATE ON blocks
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_subcenter_insert BEFORE INSERT ON sub_centers
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_subcenter_update BEFORE UPDATE ON sub_centers
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_village_insert BEFORE INSERT ON villages
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_village_update BEFORE UPDATE ON villages
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_household_insert BEFORE INSERT ON households
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

CREATE TRIGGER trg_household_update BEFORE UPDATE ON households
FOR EACH ROW SET NEW.name = UPPER(NEW.name) //

DELIMITER ;