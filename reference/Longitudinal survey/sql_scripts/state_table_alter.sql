ALTER TABLE states
ADD COLUMN territory_type VARCHAR(20) DEFAULT 'STATE' 
CHECK (territory_type IN ('STATE', 'UT'));

UPDATE states
SET territory_type = 'STATE' 
WHERE name = 'PUNJAB';