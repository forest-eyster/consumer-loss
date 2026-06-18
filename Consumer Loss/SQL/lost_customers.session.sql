-- SETTING UP THE DATA

-- Creating an empty table to insert my data from csv files
CREATE TABLE orders(
  order_id VARCHAR(10),
  customer_id VARCHAR(10),
  product_id VARCHAR(10),
  order_date DATE,
  quantity INTEGER,
  unit_price NUMERIC,
  discount_pct NUMERIC,
  total_revenue NUMERIC,
  order_status VARCHAR(15),
  sales_channel VARCHAR(20),
  payment_method VARCHAR(20),
  shipping_days INTEGER
);

-- Only use to reset TABLE
-- DROP TABLE orders;

-- insert csv data into my empty orders table
COPY orders
FROM '/Users/forest/Self Case Studies/lost_customers/DATA/order_table_raw.csv'
DELIMITER ','
CSV HEADER;

-- Test orders TABLE
SELECT *
FROM orders
LIMIT 20;

-- Creating an empty table to insert my data from csv files
CREATE TABLE customers(
  customer_id VARCHAR(10),
  customer_name VARCHAR(100),
  sales_region VARCHAR(25),
  email VARCHAR(225),
  customer_tier VARCHAR(25),
  join_date DATE,
  phone VARCHAR(25),
  loyalty_points INTEGER,
  subscribed BOOLEAN
);

-- insert csv data into my empty customers table
COPY customers
FROM '/Users/forest/Self Case Studies/lost_customers/DATA/customer_table_raw.csv'
DELIMITER ','
CSV HEADER;

-- Test customers TABLE
SELECT *
FROM customers
LIMIT 20;

-- Creating an empty table to insert my data from csv files
CREATE TABLE products(
  product_id VARCHAR(10),
  product_name VARCHAR(50),
  product_category VARCHAR(50),
  manufacturing_city VARCHAR(50),
  size VARCHAR(10),
  weight_kg NUMERIC,
  retail_price NUMERIC,
  cost_price NUMERIC,
  sku VARCHAR(20),
  supplier VARCHAR(50),
  active BOOLEAN,
  quantity INTEGER
);

-- insert csv data into my empty customers table
COPY products
FROM '/Users/forest/Self Case Studies/lost_customers/DATA/product_table_raw.csv'
DELIMITER ','
CSV HEADER;

-- Test customers TABLE
SELECT *
FROM products
LIMIT 20;





-- CHECKING THE DATA
-- What is the SHAPE and STRUCTURE of the data?
-- How many rows are in each table?

SELECT COUNT(*)
FROM orders;
-- 9585 rows

SELECT COUNT(*)
FROM customers;
-- 9567 rows

SELECT COUNT(*)
FROM products;
-- 9567 rows

-- Null Analysis
SELECT 
  COUNT(*) - COUNT(order_id) AS order_id_nullss,
  COUNT(*) - COUNT(customer_id) AS customer_id_nulls,
  COUNT(*) - COUNT(product_id) AS product_id_nulls,
  COUNT(*) - COUNT(order_date) AS order_date_nulls,
  COUNT(*) - COUNT(quantity) AS quantity_nulls,
  COUNT(*) - COUNT(unit_price) AS unit_price_nulls,
  COUNT(*) - COUNT(discount_pct) AS discount_pct_nulls,
  COUNT(*) - COUNT(total_revenue) AS total_revenue_nulls,
  COUNT(*) - COUNT(order_status) AS order_status_nulls,
  COUNT(*) - COUNT(sales_channel) AS sales_channel_nulls,
  COUNT(*) - COUNT(payment_method) AS payment_method_nulls,
  COUNT(*) - COUNT(shipping_days) AS shipping_days_nulls
FROM orders;
-- from orders TABLE 
-- order status null count = 188
-- sales channel null count = 192
-- payment method null count = 231

SELECT  
  COUNT(*) - COUNT(customer_id) AS customer_id_nulls,
  COUNT(*) - COUNT(customer_name) AS customer_name_nulls,
  COUNT(*) - COUNT(sales_region) AS sales_region_nulls,
  COUNT(*) - COUNT(email) AS email_nulls,
  COUNT(*) - COUNT(customer_tier) AS customer_tier_nulls,
  COUNT(*) - COUNT(join_date) AS join_date_nulls,
  COUNT(*) - COUNT(phone) AS phone_nulls,
  COUNT(*) - COUNT(loyalty_points) AS loyalty_points_nulls,
  COUNT(*) - COUNT(subscribed) AS subscribed_nulls
FROM customers;
-- from customers TABLE
-- customer name null count = 202
-- sales region null count = 131
-- email null count = 342
-- phone null count = 534

SELECT
  COUNT(*) - COUNT(product_id) AS product_id_nulls,
  COUNT(*) - COUNT(product_name) AS product_name_nulls,
  COUNT(*) - COUNT(product_category) AS product_category_nulls,
  COUNT(*) - COUNT(manufacturing_city) AS manufacturing_city_nulls,
  COUNT(*) - COUNT(size) AS size_nulls,
  COUNT(*) - COUNT(weight_kg) AS weight_kg_nulls,
  COUNT(*) - COUNT(retail_price) AS retail_price_nulls,
  COUNT(*) - COUNT(cost_price) AS cost_price_nulls,
  COUNT(*) - COUNT(sku) AS sku_nulls,
  COUNT(*) - COUNT(supplier) AS supplier_nulls,
  COUNT(*) - COUNT(active) AS active_nulls,
  COUNT(*) - COUNT(quantity) AS quantity_nulls
FROM products;
-- from products TABLE
-- product name null count = 270
-- manufacturing null count = 247
-- size null count = 462
-- supplier null count = 189

-- Finding Duplicates
SELECT 
  order_id, 
  customer_id, 
  product_id, 
  order_date,
  COUNT(*) AS duplicate_count
FROM orders
GROUP BY 
  order_id,
  customer_id,
  product_id,
  order_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- 18 duplicates in orders TABLE

-- Outliers and Invalid Values
-- Are there are negative total_revenue?
SELECT 
  order_id,
  total_revenue
FROM orders
WHERE total_revenue < 0
ORDER BY order_id;
-- We have 25 rows where total revenue is negative

-- Are there any orders with quantity <= 0?
SELECT
  order_id,
  quantity
FROM orders
WHERE quantity <= 0
ORDER BY order_id;
-- We have 10 rows where the quantity <= 0

-- Are there any order_dates in the future?
SELECT COUNT(*)
FROM orders
WHERE order_date > CURRENT_DATE;

SELECT COUNT(*)
FROM orders
WHERE order_date::date > CURRENT_DATE;
-- No future dates

-- Referential Integrity
-- How many order customer_ids don't exist in the customer table?
SELECT
  COUNT(*) AS orphan_customer_ids
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- We have 3 non-exist customers

-- How many order product_ids don't exist in the product table?
SELECT
  COUNT(*) AS orphan_product_ids
FROM orders o
LEFT JOIN products p ON o.product_id = p.product_id
WHERE p.product_id IS NULL;
-- We have 3 non-exist products

-- How many customers have never placed an order?
SELECT
  COUNT(*) AS customer_no_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;
-- 3619 customers never placed an order

-- How many products have never been ordered?
SELECT
  COUNT(*) AS product_not_ordered
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
WHERE o.product_id IS NULL;
-- 3608 products have never been ordered





-- CLEANING DATA
-- cleaning orders data
CREATE TABLE orders_clean AS
SELECT DISTINCT *              -- handles excat duplicate rows
FROM orders
WHERE total_revenue > 0           -- removes negative revnue
  AND quantity > 0                -- removes negative quantity
  AND order_date <= CURRENT_DATE  -- removes future dates
  AND customer_id IN (SELECT customer_id FROM customers)            -- removes ghost customer IDs
  AND product_id IN (SELECT product_id FROM products);             -- removes ghost product IDs

-- update orders_clean/order_status standardization
UPDATE orders_clean
SET order_status = CASE
  WHEN order_status IN ('shipped','Shipped','SHIPPED') THEN 'Shipped'
  WHEN order_status IN ('returned','Returned','RETURNED') THEN 'Returned'
  WHEN order_status IN ('refunded','Refunded','REFUNDED') THEN 'Refunded'
  WHEN order_status IN ('processing','Processing','PROCESSING') THEN 'Processing'
  WHEN order_status IN ('pending','Pending','PENDING') THEN 'Pending'
  WHEN order_status IN ('delivered','Delivered','DELIVERED') THEN 'Delivered'
  WHEN order_status IN ('cancelled', 'Cancelled','CANCELLED') THEN 'Cancelled'
  ELSE 'Unknown'
END;

-- update orders_clean/sales_channel standardization
UPDATE orders_clean
SET sales_channel = 'Unknown'
WHERE sales_channel IS NULL;

-- update orders_clean/payment_method standardization
UPDATE orders_clean
SET payment_method = CASE
  WHEN payment_method IN ('paypal','PayPal','PAYPAL') THEN 'PayPal'
  WHEN payment_method IN ('gift card','Gift Card','GIFT CARD') THEN 'Gift Card'
  WHEN payment_method IN ('debit card','Debit Card','DEBIT CARD') THEN 'Debit Card'
  WHEN payment_method IN ('crypto','Crypto','CRYPTO') THEN 'Crypto'
  WHEN payment_method IN ('credit card','Credit Card','CREDIT CARD') THEN 'Credit Card'
  WHEN payment_method IN ('bank transfer','Bank Transfer','BANK TRANSFER') THEN 'Bank Transfer'
  WHEN payment_method IN ('apple pay','Apple Pay','APPLE PAY') THEN 'Apple Pay'
  ELSE 'Unknown'
END;

-- test
SELECT *
FROM orders_clean;



-- cleaning customers data
CREATE TABLE customers_clean AS
SELECT
    customer_id,
    TRIM(customer_name) AS customer_name,
    COALESCE(sales_region, 'Unknown') AS sales_region,
    CASE
        WHEN email LIKE '%@%' THEN email
        ELSE 'Invalid'
    END AS email,
    customer_tier,
    join_date,
    phone,
    loyalty_points,
    subscribed
FROM customers
WHERE customer_id IS NOT NULL;

-- update customers_clean/customer_name nulls
UPDATE customers_clean
SET customer_name = CASE
  WHEN customer_name IS NULL THEN 'Unknown' ELSE customer_name
END;

-- update customers_clean/sales_region standardization
UPDATE customers_clean
SET sales_region = CASE
  WHEN sales_region IN ('west coast','West Coast','WEST COAST') THEN 'West Coast'
  WHEN sales_region IN ('southwest','Southwest','SOUTHWEST') THEN 'Southwest'
  WHEN sales_region IN ('southeast','Southeast','SOUTHEAST') THEN 'Southeast'
  WHEN sales_region IN ('northwest','Northwest','NORHTWEST') THEN 'Northwest'
  WHEN sales_region IN ('northeast','Northeast','NORTHEAST') THEN 'Northeast'
  WHEN sales_region IN ('midwest','Midwest','MIDWEST') THEN 'Midwest'
  WHEN sales_region IN ('international','International','INTERNATIONAL') THEN 'International'
  ELSE 'Unknown'
END;

-- update customers_clean/subscribed standardization
UPDATE customers_clean
SET subscribed = CASE
    WHEN CAST(subscribed AS TEXT) IN ('1','1.0','Y','y','True','TRUE','yes') THEN 'Yes'
    WHEN CAST(subscribed AS TEXT) IN ('0','0.0','N','n','False','FALSE','no') THEN 'No'
    ELSE 'Unknown'
END;

SELECT COUNT(*), subscribed
FROM customers_clean
WHERE subscribed = TRUE
GROUP BY subscribed
ORDER BY subscribed DESC;
-- TRUE 6653
-- FALSE 2914

-- update customers_clean/phone nulls
UPDATE customers_clean
SET phone = CASE
  WHEN phone IS NULL THEN 'Invalid' ELSE phone
END;

-- check customers_clean/customer_name standardization
UPDATE customers_clean
SET customer_name = INITCAP(LOWER(customer_name));

SELECT COUNT(*), customer_tier
FROM customers_clean
GROUP BY customer_tier
ORDER BY customer_tier DESC;

-- check null amount for each column
SELECT
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
  SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS customer_name_nulls,
  SUM(CASE WHEN sales_region IS NULL THEN 1 ELSE 0 END) AS sales_region_nulls,
  SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS email_nulls,
  SUM(CASE WHEN customer_tier IS NULL THEN 1 ELSE 0 END) AS customer_tier_nulls,
  SUM(CASE WHEN join_date IS NULL THEN 1 ELSE 0 END) AS join_date_nulls,
  SUM(CASE WHEN phone IS NULL THEN 1 ELSE 0 END) AS phone_nulls,
  SUM(CASE WHEN loyalty_points IS NULL THEN 1 ELSE 0 END) AS loyalty_points_nulls,
  SUM(CASE WHEN subscribed IS NULL THEN 1 ELSE 0 END) AS subscribed_nulls
FROM customers_clean;

-- test
SELECT *
FROM customers_clean;



-- cleaning products data
CREATE TABLE products_clean AS
SELECT DISTINCT *
FROM products
WHERE quantity > 0;

DELETE FROM orders_clean
WHERE NOT EXISTS (
    SELECT 1 FROM products_clean  -- raw table
    WHERE products_clean.product_id = orders_clean.product_id
);

-- update products_clean/product_name nulls
UPDATE products_clean
SET product_name = CASE
  WHEN product_name IS NULL THEN 'Unknown' ELSE product_name
END

-- update products_clean/size nulls
UPDATE products_clean
SET size = CASE
  WHEN size IS NULL THEN 'Unknown' ELSE size
END

SELECT
  SUM(CASE WHEN size IS NULL THEN 1 ELSE 0 END) AS size_nulls
FROM products_clean;

-- update products_clean/manufacturing_city standardization
UPDATE products_clean
SET manufacturing_city = CASE
  WHEN manufacturing_city IS NULL THEN 'Unknown' ELSE manufacturing_city
END

UPDATE products_clean
SET manufacturing_city = INITCAP(LOWER(manufacturing_city));

-- update products_clean/supplier nulls
UPDATE products_clean
SET supplier = CASE
  WHEN supplier IS NULL THEN 'Unknown' ELSE supplier
END

SELECT COUNT(*), manufacturing_city
FROM products_clean
GROUP BY manufacturing_city
ORDER BY manufacturing_city DESC;

-- Fix active in products_clean
UPDATE products_clean
SET active = CASE
    WHEN CAST(active AS TEXT) IN ('1','1.0','Y','y','True','TRUE','yes') THEN 'Yes'
    WHEN CAST(active AS TEXT) IN ('0','0.0','N','n','False','FALSE','no') THEN 'No'
    ELSE 'Unknown'
END;

SELECT COUNT(*), active
FROM products_clean
WHERE active = FALSE
GROUP BY active
ORDER BY active DESC;
-- 7767 TRUE
-- 1765 FALSE

-- test clean products data
DROP TABLE products_clean;

SELECT
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
  SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS product_name_nulls,
  SUM(CASE WHEN product_category IS NULL THEN 1 ELSE 0 END) AS product_category_nulls,
  SUM(CASE WHEN manufacturing_city IS NULL THEN 1 ELSE 0 END) AS manufacturing_city_nulls,
  SUM(CASE WHEN size IS NULL THEN 1 ELSE 0 END) AS size_nulls,
  SUM(CASE WHEN weight_kg IS NULL THEN 1 ELSE 0 END) AS weight_kg_nulls,
  SUM(CASE WHEN retail_price IS NULL THEN 1 ELSE 0 END) AS retail_price_nulls,
  SUM(CASE WHEN cost_price IS NULL THEN 1 ELSE 0 END) AS cost_price_nulls,
  SUM(CASE WHEN sku IS NULL THEN 1 ELSE 0 END) AS sku_nulls,
  SUM(CASE WHEN supplier IS NULL THEN 1 ELSE 0 END) AS supplier_nulls,
  SUM(CASE WHEN active IS NULL THEN 1 ELSE 0 END) AS active_nulls,
  SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS quantity_nulls
FROM products_clean;

-- test
SELECT *
FROM products_clean;




-- ANALYSIS
-- H1 Southwest & West Coast have higher cancellation and return rates
SELECT
  c.sales_region AS sales_region,
  COUNT(*) AS total_orders,
  ROUND(AVG(CASE WHEN o.order_status = 'Delivered' THEN o.shipping_days END), 1) AS avg_shipping_days,
  ROUND(SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)::DECIMAL / COUNT(*), 2) AS cancel_rate,
  ROUND(SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END)::DECIMAL / COUNT(*), 2) AS return_rate,
  ROUND(SUM(o.total_revenue), 2) AS total_revenue
FROM orders_clean AS o
  LEFT JOIN customers_clean AS c ON o.customer_id = c.customer_id
GROUP BY sales_region
ORDER BY cancel_rate DESC;



-- H2 Order volume and revenue dropped after March navigation redesign
SELECT
  DATE_TRUNC('month', order_date::date) AS order_month,
  COUNT(*) AS total_orders,
  ROUND(SUM(total_revenue)/COUNT(*), 2) AS avg_order_value,
  ROUND(SUM(total_revenue), 2) AS total_revenue
FROM orders_clean
WHERE 
  sales_channel = 'Online' 
  OR sales_channel = 'Mobile App'
GROUP BY DATE_TRUNC('month', order_date::date)
ORDER BY order_month ASC;

SELECT
    p.product_category,
    ROUND(AVG(CASE WHEN o.order_date < '2023-03-01' THEN o.unit_price ELSE NULL END)::NUMERIC, 2) AS avg_price_pre_march,
    ROUND(AVG(CASE WHEN o.order_date >= '2023-03-01' THEN o.unit_price ELSE NULL END)::NUMERIC, 2) AS avg_price_post_march,
    ROUND(SUM(CASE WHEN o.order_date < '2023-03-01' THEN o.total_revenue ELSE 0 END)::NUMERIC, 2) AS revenue_pre_march,
    ROUND(SUM(CASE WHEN o.order_date >= '2023-03-01' THEN o.total_revenue ELSE 0 END)::NUMERIC, 2) AS revenue_post_march
FROM orders_clean AS o
JOIN products_clean AS p ON o.product_id = p.product_id
WHERE o.sales_channel IN ('Online', 'Mobile App')
GROUP BY p.product_category
ORDER BY revenue_post_march DESC;

-- Monthly digital orders post March
-- Multiply by $25.55 avg order value gap
-- That's your monthly revenue opportunity

SELECT
    COUNT(*) / COUNT(DISTINCT DATE_TRUNC('month', order_date::date)) AS avg_monthly_orders,
    ROUND(COUNT(*) / COUNT(DISTINCT DATE_TRUNC('month', order_date::date)) * 25.55, 2) AS monthly_revenue_opportunity
FROM orders_clean
WHERE sales_channel IN ('Online', 'Mobile App')
  AND order_date >= '2023-03-01';


-- H3 Loyalty program members are not returning to purchase
WITH customer_orders AS(
  SELECT
    c.customer_id,
    c.customer_tier,
    COUNT(o.order_id) AS orders_placed,
    SUM(o.total_revenue) AS revenue
  FROM customers_clean AS c
  LEFT JOIN orders_clean AS o ON o.customer_id = c.customer_id
  GROUP BY c.customer_id, c.customer_tier
)
SELECT
  customer_tier,
  COUNT(customer_id) AS customer_count,
  ROUND(AVG(orders_placed)::NUMERIC, 2) AS avg_orders_per_customer,
  SUM(orders_placed) AS total_orders,
  ROUND(SUM(revenue)::NUMERIC / NULLIF(SUM(orders_placed), 0), 2) AS avg_order_value,
  ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue
FROM customer_orders
WHERE customer_tier IS NOT NULL
GROUP BY customer_tier
ORDER BY avg_orders_per_customer DESC;



-- KPI's for Dashboard

-- AVG Order Value Drop
SELECT 
  -- Baseline Average Order Value Pre-Redesign
  ROUND(AVG(CASE WHEN order_date < '2023-03-01' AND order_date > '2022-02-01' THEN total_revenue END)::NUMERIC, 2) AS aov_baseline_oneYear,
  -- Current Average Order Value Post-Redesign
  ROUND(AVG(CASE WHEN order_date >= '2023-03-01' AND order_date < '2024-03-01' THEN total_revenue END)::NUMERIC, 2) AS aov_current_oneYear,
  -- AOV Drop %
  ROUND((AVG(CASE WHEN order_date < '2023-03-01' AND order_date > '2022-02-01' THEN total_revenue END)::NUMERIC - AVG(CASE WHEN order_date >= '2023-03-01' AND order_date < '2024-03-01' THEN total_revenue END)::NUMERIC) / AVG(CASE WHEN order_date < '2023-03-01' AND order_date > '2022-02-01' THEN total_revenue END)::NUMERIC * 100, 2) AS aov_drop_oneYear
FROM orders_clean
WHERE sales_channel IN ('Online','Moblie App');

-- Baseline AOV Pre-Redesign - $299.43

-- Current AOV Post-Redesign - $266.46

-- AOV Drop - 11.01%

-- Monthly Order Volume
WITH amo AS (
SELECT
  ROUND(
    SUM(CASE WHEN order_date >= '2022-03-01' AND order_date < '2023-03-01' THEN 1 ELSE 0 END)::NUMERIC / COUNT(DISTINCT CASE WHEN order_date >= '2022-03-01' AND order_date < '2023-03-01' THEN DATE_TRUNC('month', order_date::date) END),1) AS pre_redesign_amo,
  ROUND(
    SUM(CASE WHEN order_date >= '2023-03-01' AND order_date < '2024-03-01' THEN 1 ELSE 0 END)::NUMERIC / COUNT(DISTINCT CASE WHEN order_date >= '2023-03-01' AND order_date < '2024-03-01' THEN DATE_TRUNC('month', order_date::date) END), 1) AS post_redesign_amo
FROM orders_clean
WHERE sales_channel IN ('Online', 'Mobile App')
)
SELECT
  pre_redesign_amo,
  post_redesign_amo,
  ROUND(((pre_redesign_amo - post_redesign_amo)/pre_redesign_amo) * 100, 1) AS average_monthly_order_volume
FROM amo;

-- pre redesign 139.8

-- post redesign 137

-- pct difference -2.0%

-- Annual Revenue at Risk
WITH aov AS(
  SELECT
    ROUND(AVG(CASE WHEN order_date < '2023-03-01' AND order_date > '2022-02-01' THEN total_revenue END)::NUMERIC, 2) AS pre_aov,
    ROUND(AVG(CASE WHEN order_date >= '2023-03-01' AND order_date < '2024-03-01' THEN total_revenue END)::NUMERIC, 2) AS post_aov
  FROM orders_clean
  WHERE sales_channel In ('Online', 'Moblie App')
),
monthly_vol AS(
  SELECT
    ROUND(COUNT(order_id)::NUMERIC / COUNT(DISTINCT DATE_TRUNC('month', order_date::date)), 1) AS avg_monthly_orders
  FROM orders_clean
  WHERE sales_channel IN ('Online', 'Mobile App')
    AND order_date >= '2023-03-01'
    AND order_date < '2024-03-01'
)

SELECT 
  ROUND((a.pre_aov - a.post_aov) * m.avg_monthly_orders * 12, 2) AS annual_revenue_risk
FROM aov a, monthly_vol m;

-- Annual Revenue at Risk $54,202.68

-- Cart Abandonment
-- This came from CMO reporting at a  68% -> 76%. I can however approximate using cancelled and pending orders as a proxy.
SELECT
  ROUND(SUM(CASE WHEN order_status IN ('Cancelled','Pending') THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS abandonment_proxy_pct
FROM orders_clean
WHERE sales_channel IN ('Online', 'Mobile App');

-- Average Order per Customer Tier
SELECT
  customer_tier,
  COUNT(DISTINCT customer_id) AS aoct
FROM customers_clean
GROUP BY customer_tier;


-- Never Ordered Rate
WITH customer_orders AS (
  SELECT
    c.customer_id,
    c.customer_tier,
    COUNT(o.order_id) AS orders_placed
    FROM customers_clean c
      LEFT JOIN orders_clean o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_tier
)
SELECT
  COUNT(*) AS total_enrolled,
  SUM(CASE WHEN orders_placed = 0 THEN 1 ELSE 0 END) AS never_ordered,
  ROUND(SUM(CASE WHEN orders_placed = 0 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS never_ordered_pct
FROM customer_orders
WHERE customer_tier IS NOT NULL;

-- total enrolled 9567

-- never ordered 3644

-- never ordered pct 38.1%

-- Redemption Rate
-- This was a CMO reporting at 11%. This is not in our dataset.

-- Avg Orders Per Customer by Tier
WITH customer_orders AS (
  SELECT
    c.customer_id,
    c.customer_tier,
    COUNT(o.order_id) AS orders_placed
  FROM customers_clean c
    LEFT JOIN orders_clean o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id, c.customer_tier
)
SELECT
  customer_tier,
  ROUND(AVG(orders_placed)::NUMERIC, 2) AS avg_orders_per_customer
FROM customer_orders
WHERE customer_tier IS NOT NULL
GROUP BY customer_tier
ORDER BY avg_orders_per_customer DESC;

-- Avg Orders Per Customer by Tier is about 1 order

-- Avg Delivery Time 
SELECT
  ROUND(AVG(CASE WHEN order_status = 'Delivered' THEN shipping_days END)::NUMERIC, 1) AS avg_delivery_days,
  5 AS promised_max_days,
  ROUND(AVG(CASE WHEN order_status = 'Delivered' THEN shipping_days END)::NUMERIC - 5, 1) AS days_over_promise
FROM orders_clean;

-- avg delivery days 7.0

-- promised max days 5

-- days over promise 2

-- Delivery Rate
SELECT
  COUNT(*) AS total_orders,
  SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
  ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS delivery_rate_pct
FROM orders_clean;

-- total orders 9500

-- delivered orders 4736

-- delivery rate 49.9%

-- Cancellation Rate
-- Overall 
SELECT
  ROUND(SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS cancellation_rate_pct
FROM orders_clean;

-- By Region
SELECT
  c.sales_region,
  COUNT(o.order_id) AS total_orders,
  ROUND(SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS cancellation_rate_pct
FROM orders_clean o
  LEFT JOIN customers_clean c ON o.customer_id = c.customer_id
WHERE c.sales_region IS NOT NULL
GROUP BY c.sales_region
ORDER BY cancellation_rate_pct DESC;

-- overall cancellation rate 7.2%

-- Return Rate
-- Overall
SELECT
  ROUND(SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS return_rate_pct
FROM orders_clean;

-- By Region
SELECT
  c.sales_region,
  COUNT(o.order_id) AS total_orders,
  ROUND(SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS return_rate_pct
FROM orders_clean o
  LEFT JOIN customers_clean c ON o.customer_id = c.customer_id
WHERE c.sales_region IS NOT NULL
GROUP BY c.sales_region
ORDER BY return_rate_pct DESC;

-- overall return rate 6.8%