USE ecommerce_pbl;

-- FUNCTIONAL DEPENDENCY ANALYSIS (run after 1NF, before 2NF)
-- MySQL 8.4
-- Business rules the FDs rest on:
--   * one order has one customer, one shipping address, one shipment
--   * one shipment belongs to one order and has one shipper
--   * a listing is one product sold by one seller at one price
--   * a listing appears at most once per order (repeat units -> quantity)
--   * a PIN code belongs to one city and state (city = postal district)
--   * a return is for one order line; refund_percentage is free input
--     per return (not derived from damage_factor)
-- Note: sample-data checks can only refute an FD, never prove it.
-- The FDs come from these rules; the tests below check the data obeys them.

-- 1. DOCUMENTED FUNCTIONAL DEPENDENCIES AND CANDIDATE KEYS
SELECT 'Order_1NF' AS relation_name,
       'order_id -> all other attributes' AS functional_dependency,
       'order_id (also shipment_id, since 1 order = 1 shipment)' AS candidate_keys
UNION ALL SELECT 'Order_1NF', 'customer_id -> customer_name, customer_email, customer_phone', '(not a key)'
UNION ALL SELECT 'Order_1NF', 'address_id -> apartment_name, street, city, state, pincode', '(not a key)'
UNION ALL SELECT 'Order_1NF', 'pincode -> city, state', '(not a key)'
UNION ALL SELECT 'Order_1NF', 'shipper_id -> shipper_name', '(not a key)'
UNION ALL SELECT 'OrderItem_1NF', '(order_id, listing_id) -> quantity', '(order_id, listing_id)'
UNION ALL SELECT 'OrderItem_1NF', 'listing_id -> product_id, product_name, seller_id, seller_name, unit_price', '(partial: part of key)'
UNION ALL SELECT 'OrderItem_1NF', 'product_id -> product_name; seller_id -> seller_name', '(not a key)'
UNION ALL SELECT 'Payment_1NF', 'payment_id -> order_id, method, status, transaction_reference, amount', 'payment_id'
UNION ALL SELECT 'Return_1NF', 'return_id -> order_id, listing_id, quantity_returned, return_date, damage_factor, refund_percentage, refund_amount', 'return_id';

-- 2. TEST EACH FD AGAINST THE SOURCE (1NF) DATA
--    A row returned by a "violations" query means the FD is broken.

SELECT 'listing_id -> product/seller/price' AS fd_tested,
       IF(NOT EXISTS (
           SELECT 1 FROM OrderItem_1NF
           GROUP BY listing_id
           HAVING COUNT(DISTINCT product_id, product_name,
                        seller_id, seller_name, unit_price) > 1
       ), 'PASS', 'FAIL') AS result
UNION ALL
SELECT 'product_id -> product_name',
       IF(NOT EXISTS (
           SELECT 1 FROM OrderItem_1NF
           GROUP BY product_id HAVING COUNT(DISTINCT product_name) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT 'seller_id -> seller_name',
       IF(NOT EXISTS (
           SELECT 1 FROM OrderItem_1NF
           GROUP BY seller_id HAVING COUNT(DISTINCT seller_name) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT 'customer_id -> name/email/phone',
       IF(NOT EXISTS (
           SELECT 1 FROM Order_1NF
           GROUP BY customer_id
           HAVING COUNT(DISTINCT customer_name, customer_email,
                        customer_phone) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT 'address_id -> address attributes',
       IF(NOT EXISTS (
           SELECT 1 FROM Order_1NF
           GROUP BY address_id
           HAVING COUNT(DISTINCT apartment_name, street, city,
                        state, pincode) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT 'shipment_id -> shipper/tracking/status',
       IF(NOT EXISTS (
           SELECT 1 FROM Order_1NF
           GROUP BY shipment_id
           HAVING COUNT(DISTINCT shipper_id, tracking_id,
                        shipping_status) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT 'pincode -> city, state',
       IF(NOT EXISTS (
           SELECT 1 FROM Order_1NF
           GROUP BY pincode HAVING COUNT(DISTINCT city, state) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT 'shipper_id -> shipper_name',
       IF(NOT EXISTS (
           SELECT 1 FROM Order_1NF
           GROUP BY shipper_id HAVING COUNT(DISTINCT shipper_name) > 1
       ), 'PASS', 'FAIL')
UNION ALL
SELECT '1 order = 1 shipment (shipment_id -> order_id)',
       IF(NOT EXISTS (
           SELECT 1 FROM Order_1NF
           GROUP BY shipment_id HAVING COUNT(DISTINCT order_id) > 1
       ), 'PASS', 'FAIL');
