EXPLAIN ANALYZE
SELECT
    s.shipment_id,
    ow.warehouse_name AS origin_warehouse,
    dw.address AS destination_address
    -- ... (other columns)
FROM
    shipments s
JOIN
    warehouses ow ON s.origin_warehouse_id = ow.warehouse_id
JOIN
    warehouses dw ON s.destination_warehouse_id = dw.warehouse_id
-- ... (JOINs for current status, items, etc.)
WHERE
    s.shipment_id = 1001; -- 특정 화물 ID로 테스트
    
    
-- 비정규화의 이점을 활용하는 새로운 고속 쿼리
EXPLAIN ANALYZE
SELECT
    shipment_id,
    origin_warehouse_name,
    destination_warehouse_address,
    current_status_code,
    last_updated_at,
    item_count,
    total_quantity
FROM
    shipments
WHERE
    shipment_id = 1001;