-- E-Commerce Business Intelligence & Customer Analytics
-- Business analysis queries
USE ecommerce_analytics;

-- Order overview
SELECT COUNT(*) AS total_orders FROM orders;

SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

SELECT ROUND(100.0 * SUM(order_status = 'delivered') / COUNT(*), 2)
AS delivery_rate_percent
FROM orders;

-- Revenue and AOV
SELECT ROUND(SUM(price), 2) AS total_product_revenue
FROM order_items;

SELECT ROUND(SUM(price + freight_value), 2) AS total_sales_value
FROM order_items;

SELECT ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)
AS average_order_value
FROM order_items;

-- Monthly revenue
SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    MONTH(o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY year, month;

-- Top categories
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
ORDER BY revenue DESC
LIMIT 10;

-- Customer analysis
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers;

SELECT ROUND(
    100.0 * SUM(order_count > 1) / COUNT(*), 2
) AS repeat_customer_rate
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) customer_orders;

-- Geographic revenue
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- Delivery performance
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'Early'
        WHEN order_delivered_customer_date = order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY delivery_status
ORDER BY order_count DESC;

-- Review distribution
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM reviews
GROUP BY review_score
ORDER BY review_score;

-- Month-over-month revenue
WITH monthly_revenue AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
           ROUND(SUM(oi.price), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        100 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
    ) AS revenue_growth_percent
FROM monthly_revenue
ORDER BY month;

-- Category ranking
WITH category_revenue AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
)
SELECT category, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM category_revenue
ORDER BY revenue_rank;

-- Dashboard views
CREATE OR REPLACE VIEW monthly_sales AS
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales_value,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');

CREATE OR REPLACE VIEW category_performance AS
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name);

CREATE OR REPLACE VIEW state_performance AS
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state;

CREATE OR REPLACE VIEW delivery_performance AS
SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 'Early'
        WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS order_count,
    ROUND(AVG(DATEDIFF(
        o.order_delivered_customer_date, o.order_purchase_timestamp
    )), 2) AS average_delivery_days,
    ROUND(AVG(DATEDIFF(
        o.order_delivered_customer_date, o.order_estimated_delivery_date
    )), 2) AS average_delay_days
FROM orders o
GROUP BY delivery_status;
