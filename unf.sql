CREATE DATABASE IF NOT EXISTS ecommerce_pbl;
USE ecommerce_pbl;

-- Reset: drop every downstream table (children first) so the whole
-- pipeline can be re-run from scratch.
DROP TABLE IF EXISTS ProductReturn, Payment, OrderItem, Orders, Listing,
    Product, Seller, Shipper, Address, Pincode, Customer,
    OrderItem_2NF, Listing_2NF,
    Return_1NF, Payment_1NF, OrderItem_1NF, Order_1NF;

DROP TABLE IF EXISTS Order_UNF;

-- =====================================================
-- INITIAL UNNORMALIZED RELATION
-- One record per order, containing repeating groups.
-- =====================================================

CREATE TABLE Order_UNF (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_status VARCHAR(30),

    -- Customer information
    customer_id INT,
    customer_name VARCHAR(100),
    customer_email VARCHAR(150),
    customer_phone VARCHAR(15),

    -- Shipping address
    address_id INT,
    apartment_name VARCHAR(100),
    street VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode CHAR(6),

    -- Repeating group: products in the order
    order_items JSON,

    -- Repeating group: payment attempts
    payments JSON,

    -- Shipment information
    shipment_id INT,
    shipper_id INT,
    shipper_name VARCHAR(100),
    tracking_id VARCHAR(100),
    shipping_status VARCHAR(30),

    -- Financial information
    shipping_cost DECIMAL(10,2),
    total_order_amount DECIMAL(12,2),

    -- Repeating group: returns and refunds
    return_details JSON
);


-- =====================================================
-- SAMPLE DATA
-- =====================================================

INSERT INTO Order_UNF VALUES (

    1001,
    '2026-10-01',
    'DELIVERED',

    501,
    'Arjun Kumar',
    'arjun@example.com',
    '9876543210',

    701,
    'Flat 302',
    'MG Road',
    'Hyderabad',
    'Telangana',
    '500001',

    JSON_ARRAY(
        JSON_OBJECT(
            'listing_id', 301,
            'product_id', 101,
            'product_name', 'Wireless Headphones',
            'seller_id', 201,
            'seller_name', 'TechWorld',
            'unit_price', 2000.00,
            'quantity', 2
        ),
        JSON_OBJECT(
            'listing_id', 302,
            'product_id', 102,
            'product_name', 'Mechanical Keyboard',
            'seller_id', 202,
            'seller_name', 'KeyZone',
            'unit_price', 3500.00,
            'quantity', 1
        )
    ),

    JSON_ARRAY(
        JSON_OBJECT(
            'payment_id', 9001,
            'method', 'UPI',
            'status', 'SUCCESS',
            'transaction_reference', 'TXN-UPI-9001',
            'amount', 7600.00
        )
    ),

    8001,
    401,
    'BlueDart',
    'BD123456',
    'DELIVERED',

    100.00,
    7600.00,

    JSON_ARRAY(
        JSON_OBJECT(
            'return_id', 6001,
            'listing_id', 301,
            'quantity_returned', 2,
            'return_date', '2026-10-10',
            'damage_factor', 0.00,
            'refund_percentage', 100.00,
            'refund_amount', 4000.00
        )
    )
);


INSERT INTO Order_UNF VALUES (

    1002,
    '2026-10-05',
    'DELIVERED',

    502,
    'Priya Sharma',
    'priya@example.com',
    '9123456780',

    702,
    'Flat 504',
    'Jubilee Hills Road',
    'Hyderabad',
    'Telangana',
    '500033',

    JSON_ARRAY(
        JSON_OBJECT(
            'listing_id', 303,
            'product_id', 101,
            'product_name', 'Wireless Headphones',
            'seller_id', 203,
            'seller_name', 'AudioHub',
            'unit_price', 1850.00,
            'quantity', 1
        )
    ),

    JSON_ARRAY(
        JSON_OBJECT(
            'payment_id', 9002,
            'method', 'CARD',
            'status', 'SUCCESS',
            'transaction_reference', 'TXN-CARD-9002',
            'amount', 1950.00
        )
    ),

    8002,
    402,
    'Delhivery',
    'DL654321',
    'DELIVERED',

    100.00,
    1950.00,

    JSON_ARRAY()
);


-- Order 1003: repeat customer (501), repeat listing (301), repeat shipper (401),
-- same product (101) from two sellers in one order, one failed payment attempt.
INSERT INTO Order_UNF VALUES (

    1003,
    '2026-10-12',
    'SHIPPED',

    501,
    'Arjun Kumar',
    'arjun@example.com',
    '9876543210',

    701,
    'Flat 302',
    'MG Road',
    'Hyderabad',
    'Telangana',
    '500001',

    JSON_ARRAY(
        JSON_OBJECT(
            'listing_id', 301,
            'product_id', 101,
            'product_name', 'Wireless Headphones',
            'seller_id', 201,
            'seller_name', 'TechWorld',
            'unit_price', 2000.00,
            'quantity', 1
        ),
        JSON_OBJECT(
            'listing_id', 303,
            'product_id', 101,
            'product_name', 'Wireless Headphones',
            'seller_id', 203,
            'seller_name', 'AudioHub',
            'unit_price', 1850.00,
            'quantity', 2
        )
    ),

    JSON_ARRAY(
        JSON_OBJECT(
            'payment_id', 9003,
            'method', 'UPI',
            'status', 'FAILED',
            'transaction_reference', 'TXN-UPI-9003',
            'amount', 5800.00
        ),
        JSON_OBJECT(
            'payment_id', 9004,
            'method', 'CARD',
            'status', 'SUCCESS',
            'transaction_reference', 'TXN-CARD-9004',
            'amount', 5800.00
        )
    ),

    8003,
    401,
    'BlueDart',
    'BD789012',
    'IN_TRANSIT',

    100.00,
    5800.00,

    JSON_ARRAY()
);


-- =====================================================
-- INSPECT THE INITIAL UNF DATASET
-- =====================================================

SELECT * FROM Order_UNF;


-- =====================================================
-- INSPECT THE REPEATING ORDER-ITEM GROUP
-- =====================================================

SELECT
    o.order_id,
    o.customer_name,
    item.listing_id,
    item.product_id,
    item.product_name,
    item.seller_id,
    item.seller_name,
    item.unit_price,
    item.quantity,
    item.unit_price * item.quantity AS item_total
FROM Order_UNF AS o
CROSS JOIN JSON_TABLE(
    o.order_items,
    '$[*]' COLUMNS (
        listing_id INT PATH '$.listing_id',
        product_id INT PATH '$.product_id',
        product_name VARCHAR(100) PATH '$.product_name',
        seller_id INT PATH '$.seller_id',
        seller_name VARCHAR(100) PATH '$.seller_name',
        unit_price DECIMAL(10,2) PATH '$.unit_price',
        quantity INT PATH '$.quantity'
    )
) AS item
ORDER BY o.order_id;


-- =====================================================
-- INSPECT THE REPEATING PAYMENT GROUP
-- =====================================================

SELECT
    o.order_id,
    p.payment_id,
    p.method,
    p.status,
    p.amount
FROM Order_UNF AS o
CROSS JOIN JSON_TABLE(
    o.payments,
    '$[*]' COLUMNS (
        payment_id INT PATH '$.payment_id',
        method VARCHAR(30) PATH '$.method',
        status VARCHAR(30) PATH '$.status',
        amount DECIMAL(12,2) PATH '$.amount'
    )
) AS p
ORDER BY o.order_id;


-- =====================================================
-- INSPECT THE REPEATING RETURN GROUP
-- =====================================================

SELECT
    o.order_id,
    r.return_id,
    r.listing_id,
    r.quantity_returned,
    r.damage_factor,
    r.refund_percentage,
    r.refund_amount
FROM Order_UNF AS o
CROSS JOIN JSON_TABLE(
    o.return_details,
    '$[*]' COLUMNS (
        return_id INT PATH '$.return_id',
        listing_id INT PATH '$.listing_id',
        quantity_returned INT PATH '$.quantity_returned',
        damage_factor DECIMAL(5,2) PATH '$.damage_factor',
        refund_percentage DECIMAL(5,2) PATH '$.refund_percentage',
        refund_amount DECIMAL(12,2) PATH '$.refund_amount'
    )
) AS r
ORDER BY o.order_id;
