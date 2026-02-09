ALTER TABLE households ADD COLUMN user_id INT;
   ALTER TABLE households ADD FOREIGN KEY (user_id) REFERENCES users(user_id);