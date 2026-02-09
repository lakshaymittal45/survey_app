ALTER TABLE villages
ADD COLUMN sub_center_id INT AFTER block_id;

ALTER TABLE villages
ADD CONSTRAINT fk_village_subcenter 
FOREIGN KEY (sub_center_id) REFERENCES sub_centers(sub_center_id)
ON DELETE RESTRICT;
