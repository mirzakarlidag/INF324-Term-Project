-- QUERY 1: Lists all markets where a specific product is available with plug type and energy class
SELECT
    p.sku,
    p.model,
    m.country,
    m.region,
    pt.name AS plug_type,
    ec.name AS energy_class
FROM PRODUCT p
JOIN PRODUCT_MARKET pm ON p.sku = pm.sku
JOIN MARKET m ON pm.market_id = m.market_id
JOIN PLUG_TYPE pt ON pm.plug_type_id = pt.plug_type_id
JOIN ENERGY_CLASS ec ON pm.energy_class_id = ec.energy_class_id
WHERE p.sku = '1234567890'
ORDER BY m.country, m.region;


-- QUERY 2: All Products Sold to United Kingdom with Energy Class C
SELECT
    p.sku,
    p.model,
    ptype.name AS product_type,
    p.volume,
    p.color,
    m.country,
    m.region,
    ec.name AS energy_class,
    pt.name AS plug_type
FROM PRODUCT p
JOIN PRODUCT_TYPE ptype ON p.product_type_id = ptype.product_type_id
JOIN PRODUCT_MARKET pm ON p.sku = pm.sku
JOIN MARKET m ON pm.market_id = m.market_id
JOIN ENERGY_CLASS ec ON pm.energy_class_id = ec.energy_class_id
JOIN PLUG_TYPE pt ON pm.plug_type_id = pt.plug_type_id
WHERE m.country = 'UK'
  AND ec.name = 'C'
ORDER BY p.model;


-- QUERY 3: All Countries with Type E Plug and Orders for Energy Class B Products
SELECT DISTINCT
    m.country,
    m.region,
    pt.name AS plug_type,
    ec.name AS energy_class
FROM MARKET m
JOIN PRODUCT_MARKET pm ON m.market_id = pm.market_id
JOIN PLUG_TYPE pt ON pm.plug_type_id = pt.plug_type_id
JOIN ENERGY_CLASS ec ON pm.energy_class_id = ec.energy_class_id
JOIN CUSTOMER c ON m.market_id = c.market_id
JOIN "ORDER" o ON c.customer_id = o.customer_id
JOIN ORDER_PRODUCT op ON o.order_id = op.order_id
WHERE pt.name LIKE '%E Class%'
  AND ec.name = 'B'
ORDER BY m.country;


-- QUERY 4: Products Produced in Production Line 4, Inox Color, Ordered by Italy
SELECT DISTINCT
    p.sku,
    p.model,
    ptype.name AS product_type,
    p.volume,
    p.color,
    pl.name AS production_line,
    m.country AS customer_country
FROM PRODUCT p
JOIN PRODUCT_TYPE ptype ON p.product_type_id = ptype.product_type_id
JOIN PRODUCTION_LINE_PRODUCT plp ON p.sku = plp.sku
JOIN PRODUCTION_LINE pl ON plp.prod_line_id = pl.prod_line_id
JOIN ORDER_PRODUCT op ON p.sku = op.sku
JOIN "ORDER" o ON op.order_id = o.order_id
JOIN CUSTOMER c ON o.customer_id = c.customer_id
JOIN MARKET m ON c.market_id = m.market_id
WHERE pl.prod_line_id = 4
  AND LOWER(p.color) = 'inox'
  AND m.country = 'Italy'
ORDER BY p.model;


-- QUERY 5: Count of Products sold to all Markets that are transported by Sea and have Energy Class A
SELECT
    m.country,
    m.region,
    COUNT(DISTINCT op.sku) AS product_count,
    SUM(op.quantity) AS total_quantity
FROM ORDER_PRODUCT op
JOIN "ORDER" o ON op.order_id = o.order_id
JOIN TRANSPORTATION t ON o.order_id = t.order_id
JOIN TRANSPORTATION_TYPE tt ON t.transportation_type_id = tt.transportation_type_id
JOIN CUSTOMER c ON o.customer_id = c.customer_id
JOIN MARKET m ON c.market_id = m.market_id
JOIN PRODUCT_MARKET pm ON op.sku = pm.sku AND m.market_id = pm.market_id
JOIN ENERGY_CLASS ec ON pm.energy_class_id = ec.energy_class_id
WHERE tt.name = 'Maritime'
  AND ec.name = 'A'
GROUP BY m.country, m.region
ORDER BY product_count DESC, m.country;
