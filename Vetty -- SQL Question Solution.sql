CREATE TABLE transactions (
    buyer_id INT,                          -- Unique identifier for the buyer
    purchase_time TIMESTAMP,               -- Timestamp of the purchase (in UTC)
    refund_time TIMESTAMP,                 -- Timestamp of the refund (in UTC, can be NULL if no refund)
    store_id CHAR(1),                      -- Store identifier (e.g., 'a', 'b', etc.)
    item_id CHAR(2),                       -- Item identifier (e.g., 'a1', 'b2', etc.)
    gross_transaction_value DECIMAL(10, 2) -- Gross transaction value in dollars
);

CREATE TABLE items (
    store_id CHAR(1),       -- Store identifier (e.g., 'a', 'b', etc.)
    item_id CHAR(2),        -- Item identifier (e.g., 'a1', 'b2', etc.)
    item_category VARCHAR(50), -- Category of the item (e.g., 'Electronics', 'Clothing')
    item_name VARCHAR(100)  -- Name of the item (e.g., 'Smartphone', 'T-Shirt')
);


INSERT INTO transactions (buyer_id, purchase_time, refund_time, store_id, item_id, gross_transaction_value)
VALUES
(3, '2019-09-19 21:19:06.544', NULL, 'a', 'a1', 58.00),
(12, '2019-12-10 20:10:14.324', '2019-12-15 23:19:06.544', 'b', 'b2', 475.00),
(3, '2020-09-01 23:59:46.561', '2020-09-02 21:22:06.331', 'f', 'f9', 33.00),
(2, '2020-04-30 21:19:06.544', NULL, 'd', 'd3', 250.00),
(1, '2020-10-22 22:20:06.531', NULL, 'f', 'f2', 91.00),
(8, '2020-04-16 21:10:22.214', NULL, 'e', 'e7', 24.00),
(5, '2019-09-23 12:09:35.542', '2019-09-27 02:55:02.114', 'g', 'g6', 61.00);

INSERT INTO items (store_id, item_id, item_category, item_name)
VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f5', 'chair', 'lounge chair'),
('f', 'f6', 'chair', 'armchair'),
('d', 'd2', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');



-- Question 1) What is the count of purchases per month (excluding refunded purchases)?

--> SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS month,  
    COUNT(*) AS purchase_count
FROM 
    transactions
WHERE 
    refund_time IS NULL                            
GROUP BY 
    DATE_FORMAT(purchase_time, '%Y-%m')            
ORDER BY 
    month;
    
-- Question 2) How many stores receive at least 5 orders/transactions in October 2020?

--> SELECT 
    store_id,
    COUNT(*) AS order_count
FROM 
    transactions
WHERE 
    DATE_FORMAT(purchase_time, '%Y-%m') = '2020-10' 
GROUP BY 
    store_id
HAVING 
    COUNT(*) >= 5;        
    
-- Question 3) For each store, what is the shortest interval (in min) from purchase to refund time?

--> SELECT 
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS shortest_interval_min
FROM 
    transactions
WHERE 
    refund_time IS NOT NULL  -- Only consider refunded transactions
GROUP BY 
    store_id;

-- Question 4)  What is the gross_transaction_value of every store’s first order?

--> WITH first_order AS (
    SELECT 
        store_id,
        MIN(purchase_time) AS first_order_time  
    FROM 
        transactions
    GROUP BY 
        store_id
)
SELECT 
    t.store_id,
    t.gross_transaction_value
FROM 
    transactions t
JOIN 
    first_order fo
ON 
    t.store_id = fo.store_id AND t.purchase_time = fo.first_order_time;

-- Question 5) What is the most popular item name that buyers order on their first purchase?

--> WITH first_purchase AS (
    SELECT 
        buyer_id,
        MIN(purchase_time) AS first_purchase_time 
    FROM 
        transactions
    GROUP BY 
        buyer_id
)
SELECT 
    i.item_name,
    COUNT(*) AS order_count
FROM 
    items i
JOIN 
    transactions t ON i.store_id = t.store_id AND i.item_id = t.item_id
JOIN 
    first_purchase fp ON t.buyer_id = fp.buyer_id AND t.purchase_time = fp.first_purchase_time
GROUP BY 
    i.item_name
ORDER BY 
    order_count DESC
LIMIT 1;  

-- Questions 6) Create a flag in the transaction items table indicating whether the refund can be processed or
                not. The condition for a refund to be processed is that it has to happen within 72 of Purchase
                time.

--> ALTER TABLE transactions ADD COLUMN refund_processable BOOLEAN;

UPDATE transactions
SET refund_processable = CASE 
    WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_time) <= 72 THEN TRUE
    ELSE FALSE
END
WHERE refund_time IS NOT NULL;  


-- Question 7)  Create a rank by buyer_id column in the transaction items table and filter for only the second
                purchase per buyer. (Ignore refunds here)
 
--> WITH ranked_transactions AS (
    SELECT 
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM 
        transactions
    WHERE 
        refund_time IS NULL 
)
SELECT 
    buyer_id,
    purchase_time
FROM 
    ranked_transactions
WHERE 
    purchase_rank = 2;  

-- Question 8)  How will you find the second transaction time per buyer (don’t use min/max; assume there
                were more transactions per buyer in the table)

--> WITH ranked_transactions AS (
    SELECT 
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS transaction_rank
    FROM 
        transactions
)
SELECT 
    buyer_id,
    purchase_time
FROM 
    ranked_transactions
WHERE 
    transaction_rank = 2;  