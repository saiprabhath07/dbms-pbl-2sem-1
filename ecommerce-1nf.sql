USE ecommerce_pbl;

-- UNF -> 1NF
-- Each repeating group (order_items, payments, return_details) becomes its
-- own relation carrying order_id. All remaining single-valued order
-- attributes stay together in Order_1NF.
-- (Flattening all groups into one table would cross-multiply
--  items x payments x returns, so they are kept separate.)

DROP TABLE IF EXISTS Return_1NF, Payment_1NF, OrderItem_1NF, Order_1NF;

CREATE TABLE Order_1NF (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(15),
    address_id INT NOT NULL,
    apartment_name VARCHAR(100),
    street VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode CHAR(6) NOT NULL,
    shipment_id INT NOT NULL,
    shipper_id INT NOT NULL,
    shipper_name VARCHAR(100) NOT NULL,
    tracking_id VARCHAR(100) NOT NULL,
    shipping_status VARCHAR(30) NOT NULL,
    shipping_cost DECIMAL(10,2) NOT NULL,
    total_order_amount DECIMAL(12,2) NOT NULL
);

CREATE TABLE OrderItem_1NF (
    order_id INT NOT NULL,
    listing_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    seller_id INT NOT NULL,
    seller_name VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, listing_id),
    FOREIGN KEY (order_id) REFERENCES Order_1NF(order_id)
);

CREATE TABLE Payment_1NF (
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    method VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL,
    transaction_reference VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Order_1NF(order_id)
);

CREATE TABLE Return_1NF (
    return_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    listing_id INT NOT NULL,
    quantity_returned INT NOT NULL CHECK (quantity_returned > 0),
    return_date DATE NOT NULL,
    damage_factor DECIMAL(5,2) NOT NULL,
    refund_percentage DECIMAL(5,2) NOT NULL,
    refund_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id, listing_id)
        REFERENCES OrderItem_1NF(order_id, listing_id)
);

-- Plain INSERTs: any bad row must fail loudly, not be skipped.
INSERT INTO Order_1NF (
    order_id, order_date, order_status,
    customer_id, customer_name, customer_email, customer_phone,
    address_id, apartment_name, street, city, state, pincode,
    shipment_id, shipper_id, shipper_name, tracking_id, shipping_status,
    shipping_cost, total_order_amount
)
SELECT
    order_id, order_date, order_status,
    customer_id, customer_name, customer_email, customer_phone,
    address_id, apartment_name, street, city, state, pincode,
    shipment_id, shipper_id, shipper_name, tracking_id, shipping_status,
    shipping_cost, total_order_amount
FROM Order_UNF;

INSERT INTO OrderItem_1NF (
    order_id, listing_id, product_id, product_name,
    seller_id, seller_name, unit_price, quantity
)
SELECT
    o.order_id, i.listing_id, i.product_id, i.product_name,
    i.seller_id, i.seller_name, i.unit_price, i.quantity
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
) AS i;

INSERT INTO Payment_1NF (
    payment_id, order_id, method, status, transaction_reference, amount
)
SELECT
    p.payment_id, o.order_id, p.method, p.status,
    p.transaction_reference, p.amount
FROM Order_UNF AS o
CROSS JOIN JSON_TABLE(
    o.payments,
    '$[*]' COLUMNS (
        payment_id INT PATH '$.payment_id',
        method VARCHAR(30) PATH '$.method',
        status VARCHAR(30) PATH '$.status',
        transaction_reference VARCHAR(100) PATH '$.transaction_reference',
        amount DECIMAL(12,2) PATH '$.amount'
    )
) AS p;

INSERT INTO Return_1NF (
    return_id, order_id, listing_id, quantity_returned, return_date,
    damage_factor, refund_percentage, refund_amount
)
SELECT
    r.return_id, o.order_id, r.listing_id, r.quantity_returned, r.return_date,
    r.damage_factor, r.refund_percentage, r.refund_amount
FROM Order_UNF AS o
CROSS JOIN JSON_TABLE(
    o.return_details,
    '$[*]' COLUMNS (
        return_id INT PATH '$.return_id',
        listing_id INT PATH '$.listing_id',
        quantity_returned INT PATH '$.quantity_returned',
        return_date DATE PATH '$.return_date',
        damage_factor DECIMAL(5,2) PATH '$.damage_factor',
        refund_percentage DECIMAL(5,2) PATH '$.refund_percentage',
        refund_amount DECIMAL(12,2) PATH '$.refund_amount'
    )
) AS r;

-- Verify
SELECT 'Order_1NF' AS relation_name, COUNT(*) AS row_count FROM Order_1NF
UNION ALL SELECT 'OrderItem_1NF', COUNT(*) FROM OrderItem_1NF
UNION ALL SELECT 'Payment_1NF',   COUNT(*) FROM Payment_1NF
UNION ALL SELECT 'Return_1NF',    COUNT(*) FROM Return_1NF;
