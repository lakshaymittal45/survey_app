ALTER TABLE households
ADD COLUMN sub_center_id INT AFTER block_id;

ALTER TABLE households
ADD CONSTRAINT fk_household_subcenter
FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id)
ON DELETE RESTRICT;
