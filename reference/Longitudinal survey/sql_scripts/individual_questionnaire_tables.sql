USE survey_1;

-- =========================================================
-- INDIVIDUAL QUESTIONNAIRE (sections + questions)
-- =========================================================
CREATE TABLE IF NOT EXISTS individual_questionnaire_sections (
    section_id INT AUTO_INCREMENT NOT NULL,
    section_order INT NOT NULL,
    section_title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (section_id),
    UNIQUE KEY uk_individual_section_order (section_order),
    UNIQUE KEY uk_individual_section_title (section_title),
    INDEX idx_individual_section_order (section_order)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS individual_questions (
    question_id INT AUTO_INCREMENT NOT NULL,
    question_order INT NOT NULL,
    question_section_id INT DEFAULT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL,
    answer_type VARCHAR(20) NOT NULL,
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
) ENGINE=InnoDB;

-- =========================================================
-- MAIN & INDIVIDUAL QUESTIONNAIRE RESPONSES + LINK TABLE
-- =========================================================
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
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS individual_questionnaire_responses (
    individual_questionnaire_id BIGINT NOT NULL AUTO_INCREMENT,
    responses JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (individual_questionnaire_id)
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

