-- ============================================================
-- MSSQL schema for the survey application
-- Equivalent of survey_schema_full.sql (MySQL) converted to
-- Transact-SQL (SQL Server 2016+).
-- Run this once against an empty database before starting the app.
-- ============================================================

-- Create database if it doesn't exist
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
  user_id      INT IDENTITY(1,1) PRIMARY KEY,
  username     NVARCHAR(255) NOT NULL,
  password_hash NVARCHAR(255) NOT NULL,
  created_at   DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_users_username UNIQUE (username)
);
GO

IF OBJECT_ID('admins', 'U') IS NULL
CREATE TABLE admins (
  admin_id      INT IDENTITY(1,1) PRIMARY KEY,
  username      NVARCHAR(255) NOT NULL,
  password      NVARCHAR(255) NOT NULL,
  password_hash NVARCHAR(255) NOT NULL,
  created_at    DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_admins_username UNIQUE (username)
);
GO

-- ==========================================================
-- GEOGRAPHIC HIERARCHY
-- ==========================================================
IF OBJECT_ID('states', 'U') IS NULL
CREATE TABLE states (
  state_id       INT IDENTITY(1,1) PRIMARY KEY,
  name           NVARCHAR(255) NOT NULL,
  state_name     AS (name) PERSISTED,          -- mirrors MySQL GENERATED ALWAYS AS
  territory_type NVARCHAR(20) DEFAULT 'STATE',
  created_at     DATETIME2 DEFAULT GETDATE(),
  updated_at     DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_states_name UNIQUE (name)
);
CREATE INDEX idx_states_state_name ON states (state_name);
GO

IF OBJECT_ID('districts', 'U') IS NULL
CREATE TABLE districts (
  district_id   INT IDENTITY(1,1) PRIMARY KEY,
  name          NVARCHAR(255) NOT NULL,
  district_name AS (name) PERSISTED,
  state_id      INT NOT NULL,
  created_at    DATETIME2 DEFAULT GETDATE(),
  updated_at    DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_districts_name_state  UNIQUE (name, state_id),
  CONSTRAINT fk_district_state        FOREIGN KEY (state_id) REFERENCES states(state_id) ON DELETE CASCADE
);
CREATE INDEX idx_districts_state         ON districts (state_id);
CREATE INDEX idx_districts_district_name ON districts (district_name);
GO

IF OBJECT_ID('blocks', 'U') IS NULL
CREATE TABLE blocks (
  block_id    INT IDENTITY(1,1) PRIMARY KEY,
  name        NVARCHAR(255) NOT NULL,
  block_name  AS (name) PERSISTED,
  district_id INT NOT NULL,
  created_at  DATETIME2 DEFAULT GETDATE(),
  updated_at  DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_blocks_name_district UNIQUE (name, district_id),
  CONSTRAINT fk_block_district       FOREIGN KEY (district_id) REFERENCES districts(district_id) ON DELETE CASCADE
);
CREATE INDEX idx_blocks_district  ON blocks (district_id);
CREATE INDEX idx_blocks_block_name ON blocks (block_name);
GO

IF OBJECT_ID('sub_centers', 'U') IS NULL
CREATE TABLE sub_centers (
  sub_center_id   INT IDENTITY(1,1) PRIMARY KEY,
  name            NVARCHAR(255) NOT NULL,
  sub_center_name AS (name) PERSISTED,
  block_id        INT NOT NULL,
  created_at      DATETIME2 DEFAULT GETDATE(),
  updated_at      DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_subcenter_block FOREIGN KEY (block_id) REFERENCES blocks(block_id) ON DELETE CASCADE
);
CREATE INDEX idx_sub_centers_block ON sub_centers (block_id);
CREATE INDEX idx_sub_centers_name  ON sub_centers (sub_center_name);
GO

IF OBJECT_ID('villages', 'U') IS NULL
CREATE TABLE villages (
  village_id      INT IDENTITY(1,1) PRIMARY KEY,
  village_lgd_code INT NULL,
  name            NVARCHAR(255) NOT NULL,
  village_name    AS (name) PERSISTED,
  district_id     INT NOT NULL,
  block_id        INT NOT NULL,
  sub_center_id   INT NOT NULL,
  created_at      DATETIME2 DEFAULT GETDATE(),
  updated_at      DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_village_lgd_code    UNIQUE (village_lgd_code),
  CONSTRAINT uk_village_hierarchy   UNIQUE (name, district_id, block_id, sub_center_id),
  CONSTRAINT fk_village_district    FOREIGN KEY (district_id)   REFERENCES districts(district_id)  ON DELETE CASCADE,
  CONSTRAINT fk_village_block       FOREIGN KEY (block_id)      REFERENCES blocks(block_id),
  CONSTRAINT fk_village_subcenter   FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id)
);
CREATE INDEX idx_villages_district    ON villages (district_id);
CREATE INDEX idx_villages_block       ON villages (block_id);
CREATE INDEX idx_villages_subcenter   ON villages (sub_center_id);
CREATE INDEX idx_villages_village_name ON villages (village_name);
GO

-- ==========================================================
-- HOUSEHOLD REGISTRY
-- ==========================================================
IF OBJECT_ID('household_registry', 'U') IS NULL
CREATE TABLE household_registry (
  registry_id    INT IDENTITY(1,1) PRIMARY KEY,
  household_code NVARCHAR(255) NOT NULL,
  -- NOTE: computed columns cannot have inline UNIQUE in T-SQL; use a separate CONSTRAINT
  code_ci        AS (LOWER(household_code)) PERSISTED,
  village_id     INT NOT NULL,
  created_at     DATETIME2 DEFAULT GETDATE(),
  updated_at     DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_household_registry_code_ci UNIQUE (code_ci),      -- must be separate
  CONSTRAINT fk_household_registry_village FOREIGN KEY (village_id) REFERENCES villages(village_id)
);
CREATE INDEX idx_household_registry_village ON household_registry (village_id);
GO

-- ==========================================================
-- HOUSEHOLDS
-- ==========================================================
IF OBJECT_ID('households', 'U') IS NULL
CREATE TABLE households (
  household_id      INT IDENTITY(1,1) PRIMARY KEY,
  name              NVARCHAR(255) NOT NULL,
  household_name    AS (name) PERSISTED,
  -- NOTE: computed columns cannot have inline UNIQUE in T-SQL; use a separate CONSTRAINT
  name_ci           AS (LOWER(name)) PERSISTED,
  state_id          INT NOT NULL,
  district_id       INT NOT NULL,
  block_id          INT NOT NULL,
  sub_center_id     INT NOT NULL,
  village_id        INT NOT NULL,
  user_id           INT NOT NULL,
  latitude          DECIMAL(10,8) NULL,
  longitude         DECIMAL(11,8) NULL,
  location_accuracy DECIMAL(8,2)  NULL,
  location_updated_at DATETIME2   DEFAULT GETDATE(),
  location_method   NVARCHAR(20)  NULL CHECK (location_method IN ('gps','manual','map')),
  created_at        DATETIME2     DEFAULT GETDATE(),
  updated_at        DATETIME2     DEFAULT GETDATE(),
  CONSTRAINT uk_households_name_ci   UNIQUE (name_ci),            -- must be separate
  CONSTRAINT fk_household_state      FOREIGN KEY (state_id)      REFERENCES states(state_id),
  CONSTRAINT fk_household_district   FOREIGN KEY (district_id)   REFERENCES districts(district_id),
  CONSTRAINT fk_household_block      FOREIGN KEY (block_id)      REFERENCES blocks(block_id),
  CONSTRAINT fk_household_subcenter  FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id),
  CONSTRAINT fk_household_village    FOREIGN KEY (village_id)    REFERENCES villages(village_id),
  CONSTRAINT fk_household_user       FOREIGN KEY (user_id)       REFERENCES users(user_id)
);
CREATE INDEX idx_households_state     ON households (state_id);
CREATE INDEX idx_households_district  ON households (district_id);
CREATE INDEX idx_households_block     ON households (block_id);
CREATE INDEX idx_households_subcenter ON households (sub_center_id);
CREATE INDEX idx_households_village   ON households (village_id);
CREATE INDEX idx_households_user      ON households (user_id);
CREATE INDEX idx_households_location  ON households (latitude, longitude);
GO

-- ==========================================================
-- QUESTIONNAIRE SYSTEM
-- ==========================================================
IF OBJECT_ID('questionnaire_sections', 'U') IS NULL
CREATE TABLE questionnaire_sections (
  section_id    INT IDENTITY(1,1) PRIMARY KEY,
  section_order INT NOT NULL,
  section_title NVARCHAR(255) NOT NULL,
  created_at    DATETIME2 DEFAULT GETDATE(),
  updated_at    DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_section_order UNIQUE (section_order),
  CONSTRAINT uk_section_title UNIQUE (section_title)
);
CREATE INDEX idx_section_order ON questionnaire_sections (section_order);
GO

IF OBJECT_ID('questions', 'U') IS NULL
CREATE TABLE questions (
  question_id       INT IDENTITY(1,1) PRIMARY KEY,
  question_order    INT NOT NULL,
  question_section_id INT NULL,
  question_text     NVARCHAR(MAX) NOT NULL,
  question_type     NVARCHAR(50)  NOT NULL CHECK (question_type IN ('multiple_choice','single_choice','open_ended')),
  answer_type       NVARCHAR(20)  NOT NULL CHECK (answer_type IN ('text','numerical')),
  options           NVARCHAR(MAX) NULL,
  parent_id         INT NULL,
  trigger_value     NVARCHAR(255) NULL,
  created_at        DATETIME2 DEFAULT GETDATE(),
  updated_at        DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_question_order    UNIQUE (question_order),
  CONSTRAINT fk_question_section  FOREIGN KEY (question_section_id) REFERENCES questionnaire_sections(section_id) ON DELETE CASCADE,
  CONSTRAINT fk_parent_question   FOREIGN KEY (parent_id) REFERENCES questions(question_id)
);
CREATE INDEX idx_question_order      ON questions (question_order);
CREATE INDEX idx_question_section_id ON questions (question_section_id);
CREATE INDEX idx_questions_parent    ON questions (parent_id);
GO

IF OBJECT_ID('individual_questionnaire_sections', 'U') IS NULL
CREATE TABLE individual_questionnaire_sections (
  section_id    INT IDENTITY(1,1) PRIMARY KEY,
  section_order INT NOT NULL,
  section_title NVARCHAR(255) NOT NULL,
  created_at    DATETIME2 DEFAULT GETDATE(),
  updated_at    DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_individual_section_order UNIQUE (section_order),
  CONSTRAINT uk_individual_section_title UNIQUE (section_title)
);
CREATE INDEX idx_individual_section_order ON individual_questionnaire_sections (section_order);
GO

IF OBJECT_ID('individual_questions', 'U') IS NULL
CREATE TABLE individual_questions (
  question_id         INT IDENTITY(1,1) PRIMARY KEY,
  question_order      INT NOT NULL,
  question_section_id INT NULL,
  question_text       NVARCHAR(MAX) NOT NULL,
  question_type       NVARCHAR(50)  NOT NULL CHECK (question_type IN ('multiple_choice','single_choice','open_ended')),
  answer_type         NVARCHAR(20)  NOT NULL CHECK (answer_type IN ('text','numerical')),
  options             NVARCHAR(MAX) NULL,
  parent_id           INT NULL,
  trigger_value       NVARCHAR(255) NULL,
  created_at          DATETIME2 DEFAULT GETDATE(),
  updated_at          DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_individual_question_order   UNIQUE (question_order),
  CONSTRAINT fk_individual_question_section FOREIGN KEY (question_section_id) REFERENCES individual_questionnaire_sections(section_id) ON DELETE CASCADE,
  CONSTRAINT fk_individual_parent_question  FOREIGN KEY (parent_id) REFERENCES individual_questions(question_id)
);
CREATE INDEX idx_individual_question_order      ON individual_questions (question_order);
CREATE INDEX idx_individual_question_section_id ON individual_questions (question_section_id);
CREATE INDEX idx_individual_questions_parent    ON individual_questions (parent_id);
GO

-- ==========================================================
-- RESPONSES
-- ==========================================================
IF OBJECT_ID('main_questionnaire_responses', 'U') IS NULL
CREATE TABLE main_questionnaire_responses (
  main_questionnaire_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  household_id          INT NOT NULL,
  user_id               INT NOT NULL,
  responses             NVARCHAR(MAX) NOT NULL CHECK (ISJSON(responses) > 0),
  created_at            DATETIME2 DEFAULT GETDATE(),
  -- Avoid multiple-cascade-path: household cascade ON DELETE CASCADE is sufficient;
  -- user_id FK is NO ACTION so deleting a user does not force-delete responses.
  CONSTRAINT fk_main_questionnaire_household FOREIGN KEY (household_id) REFERENCES households(household_id)  ON DELETE CASCADE,
  CONSTRAINT fk_main_questionnaire_user      FOREIGN KEY (user_id)      REFERENCES users(user_id)
);
CREATE INDEX idx_main_questionnaire_household ON main_questionnaire_responses (household_id);
CREATE INDEX idx_main_questionnaire_user      ON main_questionnaire_responses (user_id);
GO

-- survey_contributors: tracks which users contributed to a main questionnaire
IF OBJECT_ID('survey_contributors', 'U') IS NULL
CREATE TABLE survey_contributors (
  contributor_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
  main_questionnaire_id BIGINT NOT NULL,
  user_id               INT NOT NULL,
  contributed_at        DATETIME2 DEFAULT GETDATE(),
  -- NO ACTION on user_id to avoid multiple cascade paths
  -- (households already cascades -> main_questionnaire_responses -> survey_contributors)
  CONSTRAINT uk_contributor_main_user UNIQUE (main_questionnaire_id, user_id),
  CONSTRAINT fk_contrib_main FOREIGN KEY (main_questionnaire_id) REFERENCES main_questionnaire_responses(main_questionnaire_id) ON DELETE CASCADE,
  CONSTRAINT fk_contrib_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);
CREATE INDEX idx_contrib_main ON survey_contributors (main_questionnaire_id);
CREATE INDEX idx_contrib_user ON survey_contributors (user_id);
GO

IF OBJECT_ID('individual_questionnaire_responses', 'U') IS NULL
CREATE TABLE individual_questionnaire_responses (
  individual_questionnaire_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  responses                   NVARCHAR(MAX) NOT NULL CHECK (ISJSON(responses) > 0),
  aadhar_hash                 NVARCHAR(64) NULL,
  created_at                  DATETIME2 DEFAULT GETDATE()
);
CREATE INDEX idx_iqr_aadhar_hash ON individual_questionnaire_responses (aadhar_hash);
GO

IF OBJECT_ID('main_individual_questionnaire_links', 'U') IS NULL
CREATE TABLE main_individual_questionnaire_links (
  link_id                     BIGINT IDENTITY(1,1) PRIMARY KEY,
  main_questionnaire_id       BIGINT NOT NULL,
  individual_questionnaire_id BIGINT NOT NULL,
  household_id                INT NOT NULL,
  filled_by_user_id           INT NOT NULL,
  created_at                  DATETIME2 DEFAULT GETDATE(),
  -- All NO ACTION to avoid multiple cascade path errors from the same parent table
  CONSTRAINT fk_link_main       FOREIGN KEY (main_questionnaire_id)       REFERENCES main_questionnaire_responses(main_questionnaire_id),
  CONSTRAINT fk_link_individual FOREIGN KEY (individual_questionnaire_id) REFERENCES individual_questionnaire_responses(individual_questionnaire_id),
  CONSTRAINT fk_link_household  FOREIGN KEY (household_id)                REFERENCES households(household_id),
  CONSTRAINT fk_link_user       FOREIGN KEY (filled_by_user_id)           REFERENCES users(user_id)
);
CREATE INDEX idx_link_main       ON main_individual_questionnaire_links (main_questionnaire_id);
CREATE INDEX idx_link_individual ON main_individual_questionnaire_links (individual_questionnaire_id);
CREATE INDEX idx_link_household  ON main_individual_questionnaire_links (household_id);
GO

IF OBJECT_ID('household_response_drafts', 'U') IS NULL
CREATE TABLE household_response_drafts (
  draft_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
  household_id  INT NOT NULL,
  user_id       INT NOT NULL,
  response_data NVARCHAR(MAX) NULL CHECK (response_data IS NULL OR ISJSON(response_data) > 0),
  updated_at    DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT uk_draft_household_user UNIQUE (household_id, user_id),
  -- NO ACTION on user_id to avoid multiple cascade path from users
  CONSTRAINT fk_draft_household FOREIGN KEY (household_id) REFERENCES households(household_id) ON DELETE CASCADE,
  CONSTRAINT fk_draft_user      FOREIGN KEY (user_id)      REFERENCES users(user_id)
);
CREATE INDEX idx_draft_household ON household_response_drafts (household_id);
CREATE INDEX idx_draft_user      ON household_response_drafts (user_id);
GO

-- ==========================================================
-- PERSONS & SURVEY ATTEMPTS
-- ==========================================================
IF OBJECT_ID('persons', 'U') IS NULL
CREATE TABLE persons (
  person_id    BIGINT IDENTITY(1,1) PRIMARY KEY,
  aadhar       NVARCHAR(255) NULL,
  aadhar_hash  NVARCHAR(64)  NULL,
  household_id INT NOT NULL,
  age          INT NULL,
  created_at   DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_person_household FOREIGN KEY (household_id) REFERENCES households(household_id) ON DELETE CASCADE
);
CREATE INDEX idx_persons_household   ON persons (household_id);
CREATE INDEX idx_persons_aadhar_hash ON persons (aadhar_hash);
GO

IF OBJECT_ID('survey_attempts', 'U') IS NULL
CREATE TABLE survey_attempts (
  survey_attempt_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  person_id         BIGINT NOT NULL,
  -- ENUM replaced with NVARCHAR + CHECK (MSSQL has no ENUM type)
  status            NVARCHAR(20) NOT NULL DEFAULT 'in_progress'
                        CHECK (status IN ('in_progress','completed','refused')),
  created_at        DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT fk_attempt_person FOREIGN KEY (person_id) REFERENCES persons(person_id) ON DELETE CASCADE
);
CREATE INDEX idx_attempts_person ON survey_attempts (person_id);
CREATE INDEX idx_attempts_status ON survey_attempts (status);
GO

-- ==========================================================
-- TRIGGERS  (UPPERCASE NORMALIZATION)
-- MSSQL uses AFTER INSERT/UPDATE; the trigger fires after the row is
-- written, then updates the same row.  RECURSIVE_TRIGGERS is OFF by
-- default so the UPDATE inside the trigger does NOT re-fire the trigger.
-- Persisted computed columns (state_name, name_ci, …) are recalculated
-- automatically when the base column is updated.
-- ==========================================================
CREATE OR ALTER TRIGGER trg_NormalizeStates ON states AFTER INSERT, UPDATE AS
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

-- ============================================================
-- ADDITIVE MIGRATIONS (safe to re-run on existing databases)
-- Run this section on environments where base schema already exists
-- and app-level features added new columns/tables.
-- ============================================================

-- 1) Questionnaire visibility + mandatory flags
IF COL_LENGTH('dbo.questionnaire_sections', 'show_on_user_end') IS NULL
BEGIN
  ALTER TABLE dbo.questionnaire_sections
  ADD show_on_user_end BIT NOT NULL CONSTRAINT DF_questionnaire_sections_show_on_user_end DEFAULT(1);
END
GO

IF COL_LENGTH('dbo.individual_questionnaire_sections', 'show_on_user_end') IS NULL
BEGIN
  ALTER TABLE dbo.individual_questionnaire_sections
  ADD show_on_user_end BIT NOT NULL CONSTRAINT DF_individual_questionnaire_sections_show_on_user_end DEFAULT(1);
END
GO

IF COL_LENGTH('dbo.questions', 'is_mandatory') IS NULL
BEGIN
  ALTER TABLE dbo.questions
  ADD is_mandatory BIT NULL;
END
GO

IF COL_LENGTH('dbo.individual_questions', 'is_mandatory') IS NULL
BEGIN
  ALTER TABLE dbo.individual_questions
  ADD is_mandatory BIT NULL;
END
GO

-- 2) Aadhaar hash backfill/index safety
IF COL_LENGTH('dbo.persons', 'aadhar_hash') IS NULL
BEGIN
  ALTER TABLE dbo.persons
  ADD aadhar_hash NVARCHAR(64) NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes i
  WHERE i.object_id = OBJECT_ID('dbo.persons')
    AND i.name = 'idx_persons_aadhar_hash'
)
BEGIN
  CREATE INDEX idx_persons_aadhar_hash ON dbo.persons (aadhar_hash);
END
GO

IF COL_LENGTH('dbo.individual_questionnaire_responses', 'aadhar_hash') IS NULL
BEGIN
  ALTER TABLE dbo.individual_questionnaire_responses
  ADD aadhar_hash NVARCHAR(64) NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes i
  WHERE i.object_id = OBJECT_ID('dbo.individual_questionnaire_responses')
    AND i.name = 'idx_iqr_aadhar_hash'
)
BEGIN
  CREATE INDEX idx_iqr_aadhar_hash ON dbo.individual_questionnaire_responses (aadhar_hash);
END
GO

-- 3) Edit history retention tables
IF OBJECT_ID('dbo.main_questionnaire_response_history', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.main_questionnaire_response_history (
    history_id BIGINT IDENTITY(1,1) NOT NULL,
    main_questionnaire_id BIGINT NOT NULL,
    household_id INT NULL,
    changed_by_user_id INT NULL,
    changed_by_username NVARCHAR(255) NULL,
    change_action NVARCHAR(100) NOT NULL,
    previous_responses NVARCHAR(MAX) NULL,
    changed_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT PK_main_questionnaire_response_history PRIMARY KEY (history_id)
  );
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes i
  WHERE i.object_id = OBJECT_ID('dbo.main_questionnaire_response_history')
    AND i.name = 'idx_mqrh_main_id'
)
BEGIN
  CREATE INDEX idx_mqrh_main_id ON dbo.main_questionnaire_response_history (main_questionnaire_id);
END
GO

IF OBJECT_ID('dbo.household_response_draft_history', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.household_response_draft_history (
    history_id BIGINT IDENTITY(1,1) NOT NULL,
    draft_id BIGINT NULL,
    household_id INT NOT NULL,
    changed_by_user_id INT NULL,
    changed_by_username NVARCHAR(255) NULL,
    change_action NVARCHAR(100) NOT NULL,
    previous_response_data NVARCHAR(MAX) NULL,
    changed_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT PK_household_response_draft_history PRIMARY KEY (history_id)
  );
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes i
  WHERE i.object_id = OBJECT_ID('dbo.household_response_draft_history')
    AND i.name = 'idx_hrdh_household_id'
)
BEGIN
  CREATE INDEX idx_hrdh_household_id ON dbo.household_response_draft_history (household_id);
END
GO
