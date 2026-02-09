ALTER TABLE households
MODIFY COLUMN user_id INT AFTER village_id;

ALTER TABLE households
ADD CONSTRAINT fk_households_user
FOREIGN KEY (user_id) REFERENCES users(user_id);
