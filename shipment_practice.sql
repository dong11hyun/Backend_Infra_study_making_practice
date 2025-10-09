-- =================================================================
--  1. 테이블 생성 (존재할 경우 삭제 후 재생성)
-- =================================================================


-- 고객사 정보 테이블
CREATE TABLE companies (
    company_id INT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(100) NOT NULL
);

-- 창고 정보 테이블
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_name VARCHAR(100) NOT NULL,
    address VARCHAR(255)
);

-- 상품 마스터 정보 테이블
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL
);

-- 화물 정보 테이블
CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT,
    origin_warehouse_id INT,
    destination_warehouse_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(warehouse_id)
);

-- 화물-상품 다대다 관계 테이블
CREATE TABLE shipment_items (
    shipment_id INT,
    product_id INT,
    quantity INT NOT NULL,
    PRIMARY KEY (shipment_id, product_id), -- 복합 기본 키
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 화물 상태 변경 로그 테이블
CREATE TABLE shipment_updates (
    update_id INT PRIMARY KEY AUTO_INCREMENT,
    shipment_id INT,
    status_code VARCHAR(50) NOT NULL,
    notes VARCHAR(255),
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);


-- 고객사 데이터
INSERT INTO companies (company_id, company_name) VALUES
(1, 'FastLogi'),
(2, 'QuickCommerce');

-- 창고 데이터
INSERT INTO warehouses (warehouse_id, warehouse_name, address) VALUES
(10, '서울 물류센터', '서울특별시 강남구 테헤란로'),
(20, '부산 물류센터', '부산광역시 해운대구 센텀중앙로'),
(30, '인천 공항터미널', '인천광역시 중구 공항로');

-- 상품 데이터
INSERT INTO products (product_id, product_name) VALUES
(101, '고성능 노트북'),
(102, '기계식 키보드'),
(103, '4K 모니터');

-- 화물 데이터 (2개의 화물 생성)
INSERT INTO shipments (shipment_id, company_id, origin_warehouse_id, destination_warehouse_id, created_at) VALUES
(1001, 1, 10, 20, '2025-09-26 09:00:00'), -- FastLogi, 서울 -> 부산
(1002, 2, 20, 10, '2025-09-27 11:00:00'); -- QuickCommerce, 부산 -> 서울

-- 화물별 상품 데이터
INSERT INTO shipment_items (shipment_id, product_id, quantity) VALUES
(1001, 101, 2),  -- 화물 1001번은 노트북 2개
(1001, 102, 5),  -- 키보드 5개
(1002, 103, 10); -- 화물 1002번은 모니터 10개

-- 화물 상태 변경 이력 데이터 (1001번 화물의 타임라인)
INSERT INTO shipment_updates (shipment_id, status_code, notes, timestamp) VALUES
(1001, '주문접수', '고객사 시스템 연동 완료', '2025-09-26 09:00:00'),
(1001, '집화완료', '서울센터에서 상품 인수', '2025-09-26 14:30:00'),
(1001, '터미널간이동', '서울 -> 부산 간선차량 출발', '2025-09-26 23:00:00'),
(1001, '배송중', '부산 배송기사에게 인계됨', '2025-09-27 08:15:00'), -- 1001번의 "현재 상태"
(1002, '주문접수', '고객사 요청 확인', '2025-09-27 11:00:00'); -- 1002번의 "현재 상태"




-- 비정규화　진행

ALTER TABLE shipments
ADD COLUMN current_status_code VARCHAR(50),      -- 현재 화물 상태 코드
ADD COLUMN last_updated_at DATETIME,             -- 최종 업데이트 시각
ADD COLUMN origin_warehouse_name VARCHAR(100),   -- 출발지 창고 이름
ADD COLUMN destination_warehouse_address VARCHAR(255), -- 도착지 창고 주소
ADD COLUMN item_count INT,                         -- 포함된 상품 종류의 수
ADD COLUMN total_quantity INT;                     -- 포함된 상품의 총수량  

-- shipment_id = 1001 의 데이터를 채우는 로직
-- 1. 최신 상태 및 시각 가져오기
SELECT status_code, timestamp INTO @current_status, @last_updated
FROM shipment_updates
WHERE shipment_id = 1002
ORDER BY timestamp DESC
LIMIT 1;
-- 2. 출발/도착지 정보 가져오기 (JOIN)
SELECT w1.warehouse_name, w2.address INTO @origin_name, @dest_addr
FROM shipments s
JOIN warehouses w1 ON s.origin_warehouse_id = w1.warehouse_id
JOIN warehouses w2 ON s.destination_warehouse_id = w2.warehouse_id
WHERE s.shipment_id = 1002;
-- 3. 상품 수량 정보 가져오기 (집계)
SELECT COUNT(product_id), SUM(quantity) INTO @item_count, @total_qty
FROM shipment_items
WHERE shipment_id = 1002;
-- 4. 최종적으로 shipments 테이블 업데이트
UPDATE shipments
SET
    current_status_code = @current_status,
    last_updated_at = @last_updated,
    origin_warehouse_name = @origin_name,
    destination_warehouse_address = @dest_addr,
    item_count = @item_count,
    total_quantity = @total_qty
WHERE
    shipment_id = 1002;

-- 비정규화의 이점을 활용하는 새로운 초고속 쿼리
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
    
    