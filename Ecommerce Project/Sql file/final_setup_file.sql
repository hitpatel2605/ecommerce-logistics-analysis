
SET GLOBAL local_infile = 1;
SET sql_mode = '';
SET SQL_SAFE_UPDATES = 0;


CREATE DATABASE IF NOT EXISTS olist_cleaned;
USE olist_cleaned;


DROP TABLE IF EXISTS orders_fact;
CREATE TABLE orders_fact (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    delivery_status VARCHAR(20),
    delivery_delay_days FLOAT,
    is_late INT,
    processing_time_days FLOAT,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5),
    total_items INT,
    total_price DECIMAL(10,2),
    total_freight DECIMAL(10,2)
);


LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/clean_data/orders_fact.csv'
INTO TABLE orders_fact
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @v_purchase, @v_approved, @v_carrier, @v_customer, @v_estimated, delivery_status, @v_delay, @v_is_late, @v_proc, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, @v_items, @v_price, @v_freight)
SET 
    order_purchase_timestamp = NULLIF(@v_purchase, ''),
    order_approved_at = NULLIF(@v_approved, ''),
    order_delivered_carrier_date = NULLIF(@v_carrier, ''),
    order_delivered_customer_date = NULLIF(@v_customer, ''),
    order_estimated_delivery_date = NULLIF(@v_estimated, ''),
    delivery_delay_days = NULLIF(@v_delay, ''),
    is_late = NULLIF(@v_is_late, ''),
    processing_time_days = NULLIF(@v_proc, ''),
    total_items = NULLIF(@v_items, ''),
    total_price = NULLIF(@v_price, ''),
    total_freight = NULLIF(@v_freight, '');
    
    

DROP TABLE IF EXISTS customers_clean;
CREATE TABLE customers_clean (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/clean_data/customers_clean.csv'
INTO TABLE customers_clean
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


DROP TABLE IF EXISTS items_fact;
CREATE TABLE items_fact (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/clean_data/items_fact.csv'
INTO TABLE items_fact
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, @v_limit, @v_price, @v_freight)
SET 
    shipping_limit_date = NULLIF(@v_limit, ''),
    price = NULLIF(@v_price, ''),
    freight_value = NULLIF(@v_freight, '');


DROP TABLE IF EXISTS reviews_clean;
CREATE TABLE reviews_clean (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/clean_data/reviews_clean.csv'
INTO TABLE reviews_clean
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title, review_comment_message, @v_create, @v_answer)
SET 
    review_creation_date = NULLIF(@v_create, ''),
    review_answer_timestamp = NULLIF(@v_answer, '');


DROP TABLE IF EXISTS products_clean;
CREATE TABLE products_clean (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/clean_data/products_clean.csv'
INTO TABLE products_clean
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



DROP TABLE IF EXISTS sellers_clean;
CREATE TABLE sellers_clean (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/clean_data/sellers_clean.csv'
INTO TABLE sellers_clean
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



DROP TABLE IF EXISTS category_translation;
CREATE TABLE category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'D:/PROGRAMMING/DATA SCIENCE/olist_dataset/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- 1: Late delivery rate by state (rolling trend)
WITH monthly_state_delays AS (
  SELECT
    customer_state,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS order_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_orders
  FROM orders_fact
  WHERE order_delivered_customer_date IS NOT NULL
  GROUP BY customer_state, order_month
)
SELECT *,
  ROUND(100.0 * late_orders / total_orders, 2) AS late_rate_pct,
  AVG(100.0 * late_orders / total_orders) OVER (
    PARTITION BY customer_state ORDER BY order_month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_3mo_late_rate
FROM monthly_state_delays
ORDER BY customer_state, order_month;


-- 2: Seller performance ranking

WITH seller_metrics AS (
  SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    AVG(r.review_score) AS avg_review,
    ROUND(AVG(o.is_late) * 100, 2) AS late_rate_pct
  FROM items_fact oi
  JOIN orders_fact o ON oi.order_id = o.order_id
  JOIN reviews_clean r ON o.order_id = r.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
  GROUP BY oi.seller_id
  HAVING COUNT(DISTINCT oi.order_id) >= 20
)
SELECT *,
  RANK() OVER (ORDER BY late_rate_pct DESC) AS worst_delivery_rank,
  RANK() OVER (ORDER BY avg_review ASC) AS worst_satisfaction_rank
FROM seller_metrics
ORDER BY late_rate_pct DESC
LIMIT 25;


-- 3: Category revenue vs. review risk

SELECT
  COALESCE(ct.product_category_name_english, 'unknown') AS category,
  COUNT(DISTINCT oi.order_id) AS orders,
  SUM(oi.price) AS total_revenue,
  AVG(r.review_score) AS avg_review_score,
  SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS num_bad_reviews,
  ROUND(100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT oi.order_id), 2) AS bad_review_pct
FROM items_fact oi
JOIN products_clean p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN reviews_clean r ON oi.order_id = r.order_id
GROUP BY category
ORDER BY total_revenue DESC;