USE ecommerce_pbl;

-- 1. Row counts at each stage
SELECT 'UNF orders' AS stage, COUNT(*) AS row_count FROM Order_UNF
UNION ALL SELECT '1NF Order_1NF',     COUNT(*) FROM Order_1NF
UNION ALL SELECT '1NF OrderItem_1NF', COUNT(*) FROM OrderItem_1NF
UNION ALL SELECT '1NF Payment_1NF',   COUNT(*) FROM Payment_1NF
UNION ALL SELECT '1NF Return_1NF',    COUNT(*) FROM Return_1NF
UNION ALL SELECT '2NF Listing_2NF',   COUNT(*) FROM Listing_2NF
UNION ALL SELECT '2NF OrderItem_2NF', COUNT(*) FROM OrderItem_2NF
UNION ALL SELECT '3NF/BCNF Customer', COUNT(*) FROM Customer
UNION ALL SELECT '3NF/BCNF Address',  COUNT(*) FROM Address
UNION ALL SELECT '3NF/BCNF Pincode',  COUNT(*) FROM Pincode
UNION ALL SELECT '3NF/BCNF Shipper',  COUNT(*) FROM Shipper
UNION ALL SELECT '3NF/BCNF Product',  COUNT(*) FROM Product
UNION ALL SELECT '3NF/BCNF Seller',   COUNT(*) FROM Seller
UNION ALL SELECT '3NF/BCNF Listing',  COUNT(*) FROM Listing
UNION ALL SELECT '3NF/BCNF Orders',   COUNT(*) FROM Orders
UNION ALL SELECT '3NF/BCNF OrderItem',COUNT(*) FROM OrderItem
UNION ALL SELECT '3NF/BCNF Payment',  COUNT(*) FROM Payment
UNION ALL SELECT '3NF/BCNF ProductReturn', COUNT(*) FROM ProductReturn;

-- 2. Primary keys and column definitions of the final schema
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_KEY, IS_NULLABLE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_pbl'
  AND TABLE_NAME IN ('Customer','Address','Pincode','Shipper','Product','Seller','Listing',
                     'Orders','OrderItem','Payment','ProductReturn')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 3. Foreign keys of the final schema
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ecommerce_pbl'
  AND REFERENCED_TABLE_NAME IS NOT NULL
  AND TABLE_NAME IN ('Customer','Address','Pincode','Shipper','Product','Seller','Listing',
                     'Orders','OrderItem','Payment','ProductReturn')
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- 4. Migration checks: each query must return ZERO rows
-- 4a. UNF items vs final OrderItem (every UNF line item survived, same quantity)
(SELECT o.order_id, i.listing_id, i.quantity
 FROM Order_UNF AS o
 CROSS JOIN JSON_TABLE(o.order_items, '$[*]' COLUMNS (
     listing_id INT PATH '$.listing_id',
     quantity INT PATH '$.quantity')) AS i)
EXCEPT
(SELECT order_id, listing_id, quantity FROM OrderItem);

(SELECT order_id, listing_id, quantity FROM OrderItem)
EXCEPT
(SELECT o.order_id, i.listing_id, i.quantity
 FROM Order_UNF AS o
 CROSS JOIN JSON_TABLE(o.order_items, '$[*]' COLUMNS (
     listing_id INT PATH '$.listing_id',
     quantity INT PATH '$.quantity')) AS i);

-- 4b. UNF order-level data vs final tables (lossless rebuild of the order header)
(SELECT order_id, order_date, order_status, customer_id, customer_name,
        customer_email, customer_phone, address_id, apartment_name, street,
        city, state, pincode, shipment_id, shipper_id, shipper_name,
        tracking_id, shipping_status, shipping_cost, total_order_amount
 FROM Order_UNF)
EXCEPT
(SELECT o.order_id, o.order_date, o.order_status, c.customer_id, c.customer_name,
        c.customer_email, c.customer_phone, a.address_id, a.apartment_name,
        a.street, p.city, p.state, a.pincode, o.shipment_id, s.shipper_id,
        s.shipper_name, o.tracking_id, o.shipping_status, o.shipping_cost,
        o.total_order_amount
 FROM Orders AS o
 JOIN Customer AS c ON c.customer_id = o.customer_id
 JOIN Address  AS a ON a.address_id  = o.address_id
 JOIN Pincode  AS p ON p.pincode     = a.pincode
 JOIN Shipper  AS s ON s.shipper_id  = o.shipper_id);

-- 4c. Payments and returns survived
(SELECT o.order_id, p.payment_id, p.amount
 FROM Order_UNF AS o
 CROSS JOIN JSON_TABLE(o.payments, '$[*]' COLUMNS (
     payment_id INT PATH '$.payment_id',
     amount DECIMAL(12,2) PATH '$.amount')) AS p)
EXCEPT
(SELECT order_id, payment_id, amount FROM Payment);

-- Returns: the refund recomputed from the final tables must equal the
-- refund_amount stored in the UNF data (derived column was dropped).
(SELECT o.order_id, r.return_id, r.listing_id, r.refund_amount
 FROM Order_UNF AS o
 CROSS JOIN JSON_TABLE(o.return_details, '$[*]' COLUMNS (
     return_id INT PATH '$.return_id',
     listing_id INT PATH '$.listing_id',
     refund_amount DECIMAL(12,2) PATH '$.refund_amount')) AS r)
EXCEPT
(SELECT pr.order_id, pr.return_id, pr.listing_id,
        ROUND(l.unit_price * pr.quantity_returned * pr.refund_percentage / 100, 2)
 FROM ProductReturn AS pr
 JOIN Listing AS l ON l.listing_id = pr.listing_id);

-- 5. Meaningful queries on the final schema
-- 5a. Order totals rebuilt from normalized tables: PASS/FAIL per order
SELECT o.order_id, c.customer_name,
       SUM(l.unit_price * oi.quantity) + o.shipping_cost AS recomputed_total,
       o.total_order_amount,
       IF(SUM(l.unit_price * oi.quantity) + o.shipping_cost = o.total_order_amount,
          'PASS', 'FAIL') AS result
FROM Orders AS o
JOIN Customer  AS c  ON c.customer_id = o.customer_id
JOIN OrderItem AS oi ON oi.order_id   = o.order_id
JOIN Listing   AS l  ON l.listing_id  = oi.listing_id
GROUP BY o.order_id, c.customer_name, o.shipping_cost, o.total_order_amount
ORDER BY o.order_id;

-- 5b. What each order contains
SELECT o.order_id, p.product_name, s.seller_name, oi.quantity, l.unit_price
FROM OrderItem AS oi
JOIN Orders  AS o ON o.order_id   = oi.order_id
JOIN Listing AS l ON l.listing_id = oi.listing_id
JOIN Product AS p ON p.product_id = l.product_id
JOIN Seller  AS s ON s.seller_id  = l.seller_id
ORDER BY o.order_id, l.listing_id;

-- 5c. Orders with a failed payment attempt that were later paid
SELECT o.order_id,
       SUM(p.status = 'FAILED')  AS failed_attempts,
       SUM(p.status = 'SUCCESS') AS successful_attempts
FROM Orders AS o
JOIN Payment AS p ON p.order_id = o.order_id
GROUP BY o.order_id
HAVING failed_attempts > 0;


-- 6. Lossless-join and migration summary
-- PASS = both EXCEPT directions return zero rows (nothing lost, nothing invented)
SELECT '2NF: OrderItem_1NF = OrderItem_2NF JOIN Listing_2NF' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT o.order_id, o.listing_id, l.product_id, l.product_name, l.seller_id, l.seller_name, l.unit_price, o.quantity FROM OrderItem_2NF AS o JOIN Listing_2NF AS l USING (listing_id)) EXCEPT (SELECT order_id, listing_id, product_id, product_name, seller_id, seller_name, unit_price, quantity FROM OrderItem_1NF)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT order_id, listing_id, product_id, product_name, seller_id, seller_name, unit_price, quantity FROM OrderItem_1NF) EXCEPT (SELECT o.order_id, o.listing_id, l.product_id, l.product_name, l.seller_id, l.seller_name, l.unit_price, o.quantity FROM OrderItem_2NF AS o JOIN Listing_2NF AS l USING (listing_id))) AS y) = 0,
          'PASS', 'FAIL') AS result
UNION ALL
SELECT '3NF: Order_1NF = Orders JOIN Customer, Address, Pincode, Shipper' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT o.order_id, o.order_date, o.order_status, c.customer_id, c.customer_name, c.customer_email, c.customer_phone, a.address_id, a.apartment_name, a.street, p.city, p.state, a.pincode, o.shipment_id, s.shipper_id, s.shipper_name, o.tracking_id, o.shipping_status, o.shipping_cost, o.total_order_amount FROM Orders AS o JOIN Customer AS c ON c.customer_id = o.customer_id JOIN Address AS a ON a.address_id = o.address_id JOIN Pincode AS p ON p.pincode = a.pincode JOIN Shipper AS s ON s.shipper_id = o.shipper_id) EXCEPT (SELECT order_id, order_date, order_status, customer_id, customer_name, customer_email, customer_phone, address_id, apartment_name, street, city, state, pincode, shipment_id, shipper_id, shipper_name, tracking_id, shipping_status, shipping_cost, total_order_amount FROM Order_1NF)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT order_id, order_date, order_status, customer_id, customer_name, customer_email, customer_phone, address_id, apartment_name, street, city, state, pincode, shipment_id, shipper_id, shipper_name, tracking_id, shipping_status, shipping_cost, total_order_amount FROM Order_1NF) EXCEPT (SELECT o.order_id, o.order_date, o.order_status, c.customer_id, c.customer_name, c.customer_email, c.customer_phone, a.address_id, a.apartment_name, a.street, p.city, p.state, a.pincode, o.shipment_id, s.shipper_id, s.shipper_name, o.tracking_id, o.shipping_status, o.shipping_cost, o.total_order_amount FROM Orders AS o JOIN Customer AS c ON c.customer_id = o.customer_id JOIN Address AS a ON a.address_id = o.address_id JOIN Pincode AS p ON p.pincode = a.pincode JOIN Shipper AS s ON s.shipper_id = o.shipper_id)) AS y) = 0,
          'PASS', 'FAIL') AS result
UNION ALL
SELECT '3NF: Listing_2NF = Listing JOIN Product, Seller' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT l.listing_id, p.product_id, p.product_name, s.seller_id, s.seller_name, l.unit_price FROM Listing AS l JOIN Product AS p ON p.product_id = l.product_id JOIN Seller AS s ON s.seller_id = l.seller_id) EXCEPT (SELECT listing_id, product_id, product_name, seller_id, seller_name, unit_price FROM Listing_2NF)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT listing_id, product_id, product_name, seller_id, seller_name, unit_price FROM Listing_2NF) EXCEPT (SELECT l.listing_id, p.product_id, p.product_name, s.seller_id, s.seller_name, l.unit_price FROM Listing AS l JOIN Product AS p ON p.product_id = l.product_id JOIN Seller AS s ON s.seller_id = l.seller_id)) AS y) = 0,
          'PASS', 'FAIL') AS result
UNION ALL
SELECT 'UNF order headers = final tables joined back' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT order_id, order_date, order_status, customer_id, customer_name, customer_email, customer_phone, address_id, apartment_name, street, city, state, pincode, shipment_id, shipper_id, shipper_name, tracking_id, shipping_status, shipping_cost, total_order_amount FROM Order_UNF) EXCEPT (SELECT o.order_id, o.order_date, o.order_status, c.customer_id, c.customer_name, c.customer_email, c.customer_phone, a.address_id, a.apartment_name, a.street, p.city, p.state, a.pincode, o.shipment_id, s.shipper_id, s.shipper_name, o.tracking_id, o.shipping_status, o.shipping_cost, o.total_order_amount FROM Orders AS o JOIN Customer AS c ON c.customer_id = o.customer_id JOIN Address AS a ON a.address_id = o.address_id JOIN Pincode AS p ON p.pincode = a.pincode JOIN Shipper AS s ON s.shipper_id = o.shipper_id)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT o.order_id, o.order_date, o.order_status, c.customer_id, c.customer_name, c.customer_email, c.customer_phone, a.address_id, a.apartment_name, a.street, p.city, p.state, a.pincode, o.shipment_id, s.shipper_id, s.shipper_name, o.tracking_id, o.shipping_status, o.shipping_cost, o.total_order_amount FROM Orders AS o JOIN Customer AS c ON c.customer_id = o.customer_id JOIN Address AS a ON a.address_id = o.address_id JOIN Pincode AS p ON p.pincode = a.pincode JOIN Shipper AS s ON s.shipper_id = o.shipper_id) EXCEPT (SELECT order_id, order_date, order_status, customer_id, customer_name, customer_email, customer_phone, address_id, apartment_name, street, city, state, pincode, shipment_id, shipper_id, shipper_name, tracking_id, shipping_status, shipping_cost, total_order_amount FROM Order_UNF)) AS y) = 0,
          'PASS', 'FAIL') AS result
UNION ALL
SELECT 'UNF order items = final OrderItem' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT o.order_id, i.listing_id, i.quantity FROM Order_UNF AS o CROSS JOIN JSON_TABLE(o.order_items, '$[*]' COLUMNS (listing_id INT PATH '$.listing_id', quantity INT PATH '$.quantity')) AS i) EXCEPT (SELECT order_id, listing_id, quantity FROM OrderItem)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT order_id, listing_id, quantity FROM OrderItem) EXCEPT (SELECT o.order_id, i.listing_id, i.quantity FROM Order_UNF AS o CROSS JOIN JSON_TABLE(o.order_items, '$[*]' COLUMNS (listing_id INT PATH '$.listing_id', quantity INT PATH '$.quantity')) AS i)) AS y) = 0,
          'PASS', 'FAIL') AS result
UNION ALL
SELECT 'UNF payments = final Payment' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT o.order_id, p.payment_id, p.method, p.status, p.transaction_reference, p.amount FROM Order_UNF AS o CROSS JOIN JSON_TABLE(o.payments, '$[*]' COLUMNS (payment_id INT PATH '$.payment_id', method VARCHAR(30) PATH '$.method', status VARCHAR(30) PATH '$.status', transaction_reference VARCHAR(100) PATH '$.transaction_reference', amount DECIMAL(12,2) PATH '$.amount')) AS p) EXCEPT (SELECT order_id, payment_id, method, status, transaction_reference, amount FROM Payment)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT order_id, payment_id, method, status, transaction_reference, amount FROM Payment) EXCEPT (SELECT o.order_id, p.payment_id, p.method, p.status, p.transaction_reference, p.amount FROM Order_UNF AS o CROSS JOIN JSON_TABLE(o.payments, '$[*]' COLUMNS (payment_id INT PATH '$.payment_id', method VARCHAR(30) PATH '$.method', status VARCHAR(30) PATH '$.status', transaction_reference VARCHAR(100) PATH '$.transaction_reference', amount DECIMAL(12,2) PATH '$.amount')) AS p)) AS y) = 0,
          'PASS', 'FAIL') AS result
UNION ALL
SELECT 'UNF refunds = refunds recomputed from Listing' AS check_name,
       IF((SELECT COUNT(*) FROM ((SELECT o.order_id, r.return_id, r.listing_id, r.refund_amount FROM Order_UNF AS o CROSS JOIN JSON_TABLE(o.return_details, '$[*]' COLUMNS (return_id INT PATH '$.return_id', listing_id INT PATH '$.listing_id', refund_amount DECIMAL(12,2) PATH '$.refund_amount')) AS r) EXCEPT (SELECT pr.order_id, pr.return_id, pr.listing_id, ROUND(l.unit_price * pr.quantity_returned * pr.refund_percentage / 100, 2) FROM ProductReturn AS pr JOIN Listing AS l ON l.listing_id = pr.listing_id)) AS x) = 0
          AND (SELECT COUNT(*) FROM ((SELECT pr.order_id, pr.return_id, pr.listing_id, ROUND(l.unit_price * pr.quantity_returned * pr.refund_percentage / 100, 2) FROM ProductReturn AS pr JOIN Listing AS l ON l.listing_id = pr.listing_id) EXCEPT (SELECT o.order_id, r.return_id, r.listing_id, r.refund_amount FROM Order_UNF AS o CROSS JOIN JSON_TABLE(o.return_details, '$[*]' COLUMNS (return_id INT PATH '$.return_id', listing_id INT PATH '$.listing_id', refund_amount DECIMAL(12,2) PATH '$.refund_amount')) AS r)) AS y) = 0,
          'PASS', 'FAIL') AS result;
