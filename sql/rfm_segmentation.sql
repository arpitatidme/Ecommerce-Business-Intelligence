-- RFM Customer Segmentation
USE ecommerce_analytics;

WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM orders),
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS R,
        NTILE(5) OVER (ORDER BY frequency ASC) AS F,
        NTILE(5) OVER (ORDER BY monetary ASC) AS M
    FROM customer_rfm
),
rfm_segmented AS (
    SELECT *,
        CASE
            WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
            WHEN R >= 3 AND F >= 3 AND M >= 3 THEN 'Loyal Customers'
            WHEN R >= 4 AND F <= 2 THEN 'New Customers'
            WHEN R <= 2 AND F >= 3 THEN 'At Risk'
            WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost Customers'
            ELSE 'Regular Customers'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_value
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY total_revenue DESC;
