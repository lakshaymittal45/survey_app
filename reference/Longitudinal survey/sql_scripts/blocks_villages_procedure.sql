DELIMITER //

CREATE PROCEDURE link_village_to_block(
    IN p_lgd_code INT, 
    IN p_block_id INT
)
BEGIN
    -- Verify the block exists before updating
    IF EXISTS (SELECT 1 FROM blocks WHERE block_id = p_block_id) THEN
        UPDATE villages 
        SET block_id = p_block_id 
        WHERE village_lgd_code = p_lgd_code;
    END IF;
END //

DELIMITER ;