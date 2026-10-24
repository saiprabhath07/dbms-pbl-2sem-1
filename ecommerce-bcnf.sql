USE ecommerce_pbl;

-- 3NF -> BCNF
-- BCNF rule: for every non-trivial FD X -> Y, X must be a superkey.
-- Checked relation by relation against the documented FDs.
-- Result: the 3NF schema from ecommerce-3nf.sql ALREADY satisfies BCNF,
-- so no further decomposition is done and no new tables are created.
-- (3NF only allows a non-superkey determinant when the dependent attribute
--  is part of a candidate key; none of these relations has overlapping
--  composite candidate keys, so 3NF and BCNF coincide here.)

SELECT 'Customer' AS relation_name,
       'customer_id -> customer_name, customer_email, customer_phone' AS fd,
       'customer_id' AS determinant_is_key, 'BCNF' AS verdict
UNION ALL SELECT 'Address',  'address_id -> apartment_name, street, pincode', 'address_id', 'BCNF'
UNION ALL SELECT 'Pincode',  'pincode -> city, state', 'pincode', 'BCNF'
UNION ALL SELECT 'Shipper',  'shipper_id -> shipper_name', 'shipper_id', 'BCNF'
UNION ALL SELECT 'Product',  'product_id -> product_name', 'product_id', 'BCNF'
UNION ALL SELECT 'Seller',   'seller_id -> seller_name', 'seller_id', 'BCNF'
UNION ALL SELECT 'Listing',  'listing_id -> product_id, seller_id, unit_price', 'listing_id', 'BCNF'
UNION ALL SELECT 'Orders',   'order_id -> all attributes', 'order_id', 'BCNF'
UNION ALL SELECT 'Orders',   'shipment_id -> all attributes (1 order = 1 shipment)', 'shipment_id (UNIQUE)', 'BCNF'
UNION ALL SELECT 'OrderItem','(order_id, listing_id) -> quantity', '(order_id, listing_id)', 'BCNF'
UNION ALL SELECT 'Payment',  'payment_id -> order_id, method, status, transaction_reference, amount', 'payment_id', 'BCNF'
UNION ALL SELECT 'ProductReturn', 'return_id -> order_id, listing_id, quantity_returned, return_date, damage_factor, refund_percentage', 'return_id', 'BCNF';

-- Confirm the keys the argument relies on are really declared
SELECT TABLE_NAME, CONSTRAINT_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) AS key_columns
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ecommerce_pbl'
  AND REFERENCED_TABLE_NAME IS NULL
  AND TABLE_NAME IN ('Customer','Address','Pincode','Shipper','Product','Seller','Listing',
                     'Orders','OrderItem','Payment','ProductReturn')
GROUP BY TABLE_NAME, CONSTRAINT_NAME
ORDER BY TABLE_NAME, CONSTRAINT_NAME;
