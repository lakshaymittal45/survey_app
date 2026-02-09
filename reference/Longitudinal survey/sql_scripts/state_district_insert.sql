-- This will insert Punjab and automatically assign it an ID (likely 1 if the table is empty)
CALL insert_state('PUNJAB');

SELECT * FROM states;
-- Inserting Districts for Punjab (State ID: 1)
CALL insert_district('AMRITSAR', 1);
CALL insert_district('BARNALA', 1);
CALL insert_district('BATHINDA', 1);
CALL insert_district('FARIDKOT', 1);
CALL insert_district('FATEHGARH SAHIB', 1);
CALL insert_district('FAZILKA', 1);
CALL insert_district('FIROZPUR', 1);
CALL insert_district('GURDASPUR', 1);
CALL insert_district('HOSHIARPUR', 1);
CALL insert_district('JALANDHAR', 1);
CALL insert_district('KAPURTHALA', 1);
CALL insert_district('LUDHIANA', 1);
CALL insert_district('MALERKOTLA', 1);
CALL insert_district('MANSA', 1);
CALL insert_district('MOGA', 1);
CALL insert_district('PATHANKOT', 1);
CALL insert_district('PATIALA', 1);
CALL insert_district('RUP NAGAR', 1);
CALL insert_district('S.A.S. NAGAR', 1);
CALL insert_district('SANGRUR', 1);
CALL insert_district('SHAHEED BHAGAT SINGH NAGAR', 1);
CALL insert_district('SHRI MUKSTAR SAHIB', 1);
CALL insert_district('TARN TARAN', 1);
