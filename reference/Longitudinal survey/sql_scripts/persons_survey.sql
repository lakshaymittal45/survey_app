USE survey_1;

-- =========================================================
-- 1) person  (NEW)
--   Links to: households(household_id)
-- =========================================================
CREATE TABLE IF NOT EXISTS person (
  person_id        BIGINT NOT NULL AUTO_INCREMENT,
  aadhaar_number   VARCHAR(20) DEFAULT NULL,
  household_id     INT NOT NULL,

  first_name       VARCHAR(100) NOT NULL,
  middle_name      VARCHAR(100) DEFAULT NULL,
  surname          VARCHAR(100) DEFAULT NULL,
  age              INT DEFAULT NULL,
  gender           ENUM('Male','Female','Other') NOT NULL,

  relation_to_head VARCHAR(100) DEFAULT NULL,
  is_eligible      TINYINT(1) DEFAULT 0,
  earning_status   ENUM('Earning','Non-earning') DEFAULT 'Non-earning',
  income_in_rs     DECIMAL(10,2) DEFAULT NULL,

  chronic_illness  TEXT,
  remark           TEXT,
  survey_complete  TINYINT(1) NOT NULL DEFAULT 0,

  PRIMARY KEY (person_id),
  UNIQUE KEY uq_person_aadhaar (aadhaar_number),
  KEY idx_person_household_id (household_id),

  CONSTRAINT fk_person_household
    FOREIGN KEY (household_id) REFERENCES households(household_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- 2) survey_attempt  (NEW)
--   Links to: person(person_id)
-- =========================================================
CREATE TABLE IF NOT EXISTS survey_attempt (
  survey_attempt_id BIGINT NOT NULL AUTO_INCREMENT,
  person_id         BIGINT NOT NULL,

  status           ENUM('Draft','Completed','Refused') NOT NULL DEFAULT 'Draft',
  refusal_reason   TEXT,
  response_data    JSON DEFAULT NULL,

  started_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  last_updated     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (survey_attempt_id),
  KEY idx_attempt_person_id (person_id),

  CONSTRAINT fk_attempt_person
    FOREIGN KEY (person_id) REFERENCES person(person_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- 3) survey_contributors  (NEW)
--   Links to: survey_attempt(survey_attempt_id), users(user_id)
-- =========================================================
CREATE TABLE IF NOT EXISTS survey_contributors (
  contributor_id    BIGINT NOT NULL AUTO_INCREMENT,
  survey_attempt_id BIGINT NOT NULL,
  user_id           INT NOT NULL,

  session_start     TIMESTAMP NULL DEFAULT NULL,
  session_end       TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (contributor_id),
  KEY idx_contrib_attempt (survey_attempt_id),
  KEY idx_contrib_user (user_id),

  CONSTRAINT fk_contrib_attempt
    FOREIGN KEY (survey_attempt_id) REFERENCES survey_attempt(survey_attempt_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_contrib_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
