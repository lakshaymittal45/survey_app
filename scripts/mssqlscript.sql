-- Create Database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'survey_1')
BEGIN
    CREATE DATABASE survey_1;
END
GO

USE survey_1;
GO

-- ==========================================================
-- CORE AUTH TABLES
-- ==========================================================
IF OBJECT_ID('users', 'U') IS NULL
CREATE TABLE users (
  user_id INT IDENTITY(1,1) PRIMARY KEY,
  username NVARCHAR(255) NOT NULL UNIQUE,
  password_hash NVARCHAR(255) NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('admins', 'U') IS NULL
CREATE TABLE admins (
  admin_id INT IDENTITY(1,1) PRIMARY KEY,
  username NVARCHAR(255) NOT NULL UNIQUE,
  password NVARCHAR(255) NOT NULL,
  password_hash NVARCHAR(255) NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE()
);
GO

-- ==========================================================
-- GEOGRAPHIC HIERARCHY
-- ==========================================================
IF OBJECT_ID('states', 'U') IS NULL
CREATE TABLE states (
  state_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(255) NOT NULL UNIQUE,
  state_name AS (name) PERSISTED,
  territory_type NVARCHAR(20) DEFAULT 'STATE',
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('districts', 'U') IS NULL
CREATE TABLE districts (
  district_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(255) NOT NULL,
  district_name AS (name) PERSISTED,
  state_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_district_state FOREIGN KEY (state_id) REFERENCES states(state_id) ON DELETE CASCADE,
  CONSTRAINT uk_districts_name_state UNIQUE (name, state_id)
);

IF OBJECT_ID('blocks', 'U') IS NULL
CREATE TABLE blocks (
  block_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(255) NOT NULL,
  block_name AS (name) PERSISTED,
  district_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_block_district FOREIGN KEY (district_id) REFERENCES districts(district_id) ON DELETE CASCADE,
  CONSTRAINT uk_blocks_name_district UNIQUE (name, district_id)
);

IF OBJECT_ID('sub_centers', 'U') IS NULL
CREATE TABLE sub_centers (
  sub_center_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(255) NOT NULL,
  sub_center_name AS (name) PERSISTED,
  block_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_subcenter_block FOREIGN KEY (block_id) REFERENCES blocks(block_id) ON DELETE CASCADE
);

IF OBJECT_ID('villages', 'U') IS NULL
CREATE TABLE villages (
  village_id INT IDENTITY(1,1) PRIMARY KEY,
  village_lgd_code INT NULL UNIQUE,
  name NVARCHAR(255) NOT NULL,
  village_name AS (name) PERSISTED,
  district_id INT NOT NULL,
  block_id INT NOT NULL,
  sub_center_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_village_district FOREIGN KEY (district_id) REFERENCES districts(district_id),
  CONSTRAINT fk_village_block FOREIGN KEY (block_id) REFERENCES blocks(block_id),
  CONSTRAINT fk_village_subcenter FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id),
  CONSTRAINT uk_village_hierarchy UNIQUE (name, district_id, block_id, sub_center_id)
);
GO

-- ==========================================================
-- HOUSEHOLD REGISTRY & HOUSEHOLDS
-- ==========================================================
IF OBJECT_ID('household_registry', 'U') IS NULL
CREATE TABLE household_registry (
  registry_id INT IDENTITY(1,1) PRIMARY KEY,
  household_code NVARCHAR(255) NOT NULL,
  code_ci AS (LOWER(household_code)) PERSISTED UNIQUE,
  village_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_household_registry_village FOREIGN KEY (village_id) REFERENCES villages(village_id)
);

IF OBJECT_ID('households', 'U') IS NULL
CREATE TABLE households (
  household_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(255) NOT NULL,
  household_name AS (name) PERSISTED,
  name_ci AS (LOWER(name)) PERSISTED UNIQUE,
  state_id INT NOT NULL,
  district_id INT NOT NULL,
  block_id INT NOT NULL,
  sub_center_id INT NOT NULL,
  village_id INT NOT NULL,
  user_id INT NOT NULL,
  latitude DECIMAL(10,8) NULL,
  longitude DECIMAL(11,8) NULL,
  location_accuracy DECIMAL(8,2) NULL,
  location_updated_at DATETIME2 DEFAULT GETDATE(),
  location_method NVARCHAR(20) CHECK (location_method IN ('gps','manual','map')),
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_household_state FOREIGN KEY (state_id) REFERENCES states(state_id),
  CONSTRAINT fk_household_district FOREIGN KEY (district_id) REFERENCES districts(district_id),
  CONSTRAINT fk_household_block FOREIGN KEY (block_id) REFERENCES blocks(block_id),
  CONSTRAINT fk_household_subcenter FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id),
  CONSTRAINT fk_household_village FOREIGN KEY (village_id) REFERENCES villages(village_id),
  CONSTRAINT fk_household_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);
GO

-- ==========================================================
-- QUESTIONNAIRE SYSTEM
-- ==========================================================
IF OBJECT_ID('questionnaire_sections', 'U') IS NULL
CREATE TABLE questionnaire_sections (
  section_id INT IDENTITY(1,1) PRIMARY KEY,
  section_order INT NOT NULL UNIQUE,
  section_title NVARCHAR(255) NOT NULL UNIQUE,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('questions', 'U') IS NULL
CREATE TABLE questions (
  question_id INT IDENTITY(1,1) PRIMARY KEY,
  question_order INT NOT NULL UNIQUE,
  question_section_id INT NULL,
  question_text NVARCHAR(MAX) NOT NULL,
  question_type NVARCHAR(50) CHECK (question_type IN ('multiple_choice', 'single_choice', 'open_ended')),
  answer_type NVARCHAR(20) CHECK (answer_type IN ('text', 'numerical')),
  options NVARCHAR(MAX) NULL,
  parent_id INT NULL,
  trigger_value NVARCHAR(255) NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_question_section FOREIGN KEY (question_section_id) REFERENCES questionnaire_sections(section_id) ON DELETE CASCADE,
  CONSTRAINT fk_parent_question FOREIGN KEY (parent_id) REFERENCES questions(question_id)
);

IF OBJECT_ID('individual_questionnaire_sections', 'U') IS NULL
CREATE TABLE individual_questionnaire_sections (
  section_id INT IDENTITY(1,1) PRIMARY KEY,
  section_order INT NOT NULL UNIQUE,
  section_title NVARCHAR(255) NOT NULL UNIQUE,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('individual_questions', 'U') IS NULL
CREATE TABLE individual_questions (
  question_id INT IDENTITY(1,1) PRIMARY KEY,
  question_order INT NOT NULL UNIQUE,
  question_section_id INT NULL,
  question_text NVARCHAR(MAX) NOT NULL,
  question_type NVARCHAR(50) CHECK (question_type IN ('multiple_choice', 'single_choice', 'open_ended')),
  answer_type NVARCHAR(20) CHECK (answer_type IN ('text', 'numerical')),
  options NVARCHAR(MAX) NULL,
  parent_id INT NULL,
  trigger_value NVARCHAR(255) NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_individual_question_section FOREIGN KEY (question_section_id) REFERENCES individual_questionnaire_sections(section_id) ON DELETE CASCADE,
  CONSTRAINT fk_individual_parent_question FOREIGN KEY (parent_id) REFERENCES individual_questions(question_id)
);
GO

-- ==========================================================
-- RESPONSES
-- ==========================================================
IF OBJECT_ID('main_questionnaire_responses', 'U') IS NULL
CREATE TABLE main_questionnaire_responses (
  main_questionnaire_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  household_id INT NOT NULL,
  user_id INT NOT NULL,
  responses NVARCHAR(MAX) CHECK (ISJSON(responses) > 0) NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_main_q_household FOREIGN KEY (household_id) REFERENCES households(household_id) ON DELETE CASCADE,
  CONSTRAINT fk_main_q_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

IF OBJECT_ID('individual_questionnaire_responses', 'U') IS NULL
CREATE TABLE individual_questionnaire_responses (
  individual_questionnaire_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  responses NVARCHAR(MAX) CHECK (ISJSON(responses) > 0) NOT NULL,
  aadhar_hash NVARCHAR(64) NULL,
  created_at DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('main_individual_questionnaire_links', 'U') IS NULL
CREATE TABLE main_individual_questionnaire_links (
  link_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  main_questionnaire_id BIGINT NOT NULL,
  individual_questionnaire_id BIGINT NOT NULL,
  household_id INT NOT NULL,
  filled_by_user_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_link_main FOREIGN KEY (main_questionnaire_id) REFERENCES main_questionnaire_responses(main_questionnaire_id),
  CONSTRAINT fk_link_individual FOREIGN KEY (individual_questionnaire_id) REFERENCES individual_questionnaire_responses(individual_questionnaire_id),
  CONSTRAINT fk_link_household FOREIGN KEY (household_id) REFERENCES households(household_id),
  CONSTRAINT fk_link_user FOREIGN KEY (filled_by_user_id) REFERENCES users(user_id)
);

IF OBJECT_ID('household_response_drafts', 'U') IS NULL
CREATE TABLE household_response_drafts (
  draft_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  household_id INT NOT NULL,
  user_id INT NOT NULL,
  response_data NVARCHAR(MAX) CHECK (ISJSON(response_data) > 0) NULL,
  updated_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_draft_household_user UNIQUE (household_id, user_id),
  CONSTRAINT fk_draft_household FOREIGN KEY (household_id) REFERENCES households(household_id) ON DELETE CASCADE,
  CONSTRAINT fk_draft_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
GO

-- ==========================================================
-- PERSONS & SURVEY ATTEMPTS
-- ==========================================================
IF OBJECT_ID('persons', 'U') IS NULL
CREATE TABLE persons (
  person_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  aadhar NVARCHAR(255) NULL,
  aadhar_hash NVARCHAR(64) NULL,
  household_id INT NOT NULL,
  age INT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_person_household FOREIGN KEY (household_id) REFERENCES households(household_id) ON DELETE CASCADE
);

IF OBJECT_ID('survey_attempts', 'U') IS NULL
CREATE TABLE survey_attempts (
  survey_attempt_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  person_id BIGINT NOT NULL,
  status NVARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress','completed','refused')),
  created_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_attempt_person FOREIGN KEY (person_id) REFERENCES persons(person_id) ON DELETE CASCADE
);
GO

-- ==========================================================
-- TRIGGERS (FIXED AMBIGUITY)
-- ==========================================================

CREATE OR ALTER TRIGGER trg_NormalizeGeography ON states AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.name = UPPER(t.name) 
    FROM states t INNER JOIN inserted i ON t.state_id = i.state_id;
END;
GO

CREATE OR ALTER TRIGGER trg_NormalizeDistricts ON districts AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.name = UPPER(t.name) 
    FROM districts t INNER JOIN inserted i ON t.district_id = i.district_id;
END;
GO

CREATE OR ALTER TRIGGER trg_NormalizeBlocks ON blocks AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.name = UPPER(t.name) 
    FROM blocks t INNER JOIN inserted i ON t.block_id = i.block_id;
END;
GO

CREATE OR ALTER TRIGGER trg_NormalizeSubCenters ON sub_centers AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.name = UPPER(t.name) 
    FROM sub_centers t INNER JOIN inserted i ON t.sub_center_id = i.sub_center_id;
END;
GO

CREATE OR ALTER TRIGGER trg_NormalizeVillages ON villages AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.name = UPPER(t.name) 
    FROM villages t INNER JOIN inserted i ON t.village_id = i.village_id;
END;
GO

CREATE OR ALTER TRIGGER trg_NormalizeHouseholds ON households AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.name = UPPER(t.name) 
    FROM households t INNER JOIN inserted i ON t.household_id = i.household_id;
END;
GO