USE ecommerce_pbl;

-- 2NF -> 3NF  (this is also the FINAL schema; see ecommerce-bcnf.sql)
-- 3NF removes transitive dependencies: non-key -> non-key.
--
-- Order_1NF (key order_id):
--   order_id -> customer_id -> customer_name, customer_email, customer_phone
--   order_id -> address_id  -> apartment_name, street, city, state, pincode
--   address_id -> pincode -> city, state   (second-level transitive)
--   order_id -> shipper_id  -> shipper_name
--   => split out Customer, Address, Pincode, Shipper.
--   NOT split: shipment_id -> shipper_id, tracking_id, shipping_status.
--   Under "1 order = 1 shipment", shipment_id is itself a candidate key of
--   Orders, so that FD is not a violation. Shipment data stays in Orders.
-- Listing_2NF (key listing_id):
--   listing_id -> product_id -> product_name
--   listing_id -> seller_id  -> seller_name
--   => split out Product, Seller.
-- OrderItem, Payment, Return_1NF: no non-key determinants, already 3NF.
--   Housekeeping (not a normal-form rule): refund_amount is derivable as
--   unit_price * quantity_returned * refund_percentage / 100, so it is not
--   stored in ProductReturn. The report recomputes it and checks it matches.
--
-- Every split is on a determinant that becomes the key of the new relation,
-- so each join is lossless. Each FD sits inside one relation, so all are
-- preserved (listing_id -> product_name follows by transitivity).

DROP TABLE IF EXISTS ProductReturn, Payment, OrderItem, Orders, Listing,
    Product, Seller, Shipper, Address, Pincode, Customer;

CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(15)
);

CREATE TABLE Pincode (
    pincode CHAR(6) PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL
);

CREATE TABLE Address (
    address_id INT PRIMARY KEY,
    apartment_name VARCHAR(100),
    street VARCHAR(150) NOT NULL,
    pincode CHAR(6) NOT NULL,
    FOREIGN KEY (pincode) REFERENCES Pincode(pincode)
);

CREATE TABLE Shipper (
    shipper_id INT PRIMARY KEY,
    shipper_name VARCHAR(100) NOT NULL
);

CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL
);

CREATE TABLE Seller (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(100) NOT NULL
);

CREATE TABLE Listing (
    listing_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    seller_id INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES Product(product_id),
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    customer_id INT NOT NULL,
    address_id INT NOT NULL,
    shipment_id INT NOT NULL UNIQUE,
    shipper_id INT NOT NULL,
    tracking_id VARCHAR(100) NOT NULL,
    shipping_status VARCHAR(30) NOT NULL,
    shipping_cost DECIMAL(10,2) NOT NULL,
    total_order_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (address_id)  REFERENCES Address(address_id),
    FOREIGN KEY (shipper_id)  REFERENCES Shipper(shipper_id)
);

CREATE TABLE OrderItem (
    order_id INT NOT NULL,
    listing_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, listing_id),
    FOREIGN KEY (order_id)   REFERENCES Orders(order_id),
    FOREIGN KEY (listing_id) REFERENCES Listing(listing_id)
);

CREATE TABLE Payment (
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    method VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL,
    transaction_reference VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TABLE ProductReturn (
    return_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    listing_id INT NOT NULL,
    quantity_returned INT NOT NULL CHECK (quantity_returned > 0),
    return_date DATE NOT NULL,
    damage_factor DECIMAL(5,2) NOT NULL,
    refund_percentage DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (order_id, listing_id)
        REFERENCES OrderItem(order_id, listing_id)
);

-- Load (plain INSERTs, parents before children)
INSERT INTO Customer
SELECT DISTINCT customer_id, customer_name, customer_email, customer_phone
FROM Order_1NF;

INSERT INTO Pincode
SELECT DISTINCT pincode, city, state
FROM Order_1NF;

INSERT INTO Address
SELECT DISTINCT address_id, apartment_name, street, pincode
FROM Order_1NF;

INSERT INTO Shipper
SELECT DISTINCT shipper_id, shipper_name
FROM Order_1NF;

INSERT INTO Product
SELECT DISTINCT product_id, product_name
FROM Listing_2NF;

INSERT INTO Seller
SELECT DISTINCT seller_id, seller_name
FROM Listing_2NF;

INSERT INTO Listing (listing_id, product_id, seller_id, unit_price)
SELECT listing_id, product_id, seller_id, unit_price
FROM Listing_2NF;

INSERT INTO Orders (
    order_id, order_date, order_status, customer_id, address_id,
    shipment_id, shipper_id, tracking_id, shipping_status,
    shipping_cost, total_order_amount
)
SELECT
    order_id, order_date, order_status, customer_id, address_id,
    shipment_id, shipper_id, tracking_id, shipping_status,
    shipping_cost, total_order_amount
FROM Order_1NF;

INSERT INTO OrderItem (order_id, listing_id, quantity)
SELECT order_id, listing_id, quantity
FROM OrderItem_2NF;

INSERT INTO Payment (
    payment_id, order_id, method, status, transaction_reference, amount
)
SELECT payment_id, order_id, method, status, transaction_reference, amount
FROM Payment_1NF;

INSERT INTO ProductReturn (
    return_id, order_id, listing_id, quantity_returned, return_date,
    damage_factor, refund_percentage
)
SELECT
    return_id, order_id, listing_id, quantity_returned, return_date,
    damage_factor, refund_percentage
FROM Return_1NF;

-- Lossless-join tests: every query below must return ZERO rows.

-- Order_1NF = Orders JOIN Customer JOIN Address JOIN Pincode JOIN Shipper
(SELECT o.order_id, o.order_date, o.order_status,
        c.customer_id, c.customer_name, c.customer_email, c.customer_phone,
        a.address_id, a.apartment_name, a.street, p.city, p.state, a.pincode,
        o.shipment_id, s.shipper_id, s.shipper_name, o.tracking_id,
        o.shipping_status, o.shipping_cost, o.total_order_amount
 FROM Orders AS o
 JOIN Customer AS c ON c.customer_id = o.customer_id
 JOIN Address  AS a ON a.address_id  = o.address_id
 JOIN Pincode  AS p ON p.pincode     = a.pincode
 JOIN Shipper  AS s ON s.shipper_id  = o.shipper_id)
EXCEPT
(SELECT order_id, order_date, order_status,
        customer_id, customer_name, customer_email, customer_phone,
        address_id, apartment_name, street, city, state, pincode,
        shipment_id, shipper_id, shipper_name, tracking_id,
        shipping_status, shipping_cost, total_order_amount
 FROM Order_1NF);

(SELECT order_id, order_date, order_status,
        customer_id, customer_name, customer_email, customer_phone,
        address_id, apartment_name, street, city, state, pincode,
        shipment_id, shipper_id, shipper_name, tracking_id,
        shipping_status, shipping_cost, total_order_amount
 FROM Order_1NF)
EXCEPT
(SELECT o.order_id, o.order_date, o.order_status,
        c.customer_id, c.customer_name, c.customer_email, c.customer_phone,
        a.address_id, a.apartment_name, a.street, p.city, p.state, a.pincode,
        o.shipment_id, s.shipper_id, s.shipper_name, o.tracking_id,
        o.shipping_status, o.shipping_cost, o.total_order_amount
 FROM Orders AS o
 JOIN Customer AS c ON c.customer_id = o.customer_id
 JOIN Address  AS a ON a.address_id  = o.address_id
 JOIN Pincode  AS p ON p.pincode     = a.pincode
 JOIN Shipper  AS s ON s.shipper_id  = o.shipper_id);

-- Listing_2NF = Listing JOIN Product JOIN Seller
(SELECT l.listing_id, p.product_id, p.product_name,
        s.seller_id, s.seller_name, l.unit_price
 FROM Listing AS l
 JOIN Product AS p ON p.product_id = l.product_id
 JOIN Seller  AS s ON s.seller_id  = l.seller_id)
EXCEPT
(SELECT listing_id, product_id, product_name,
        seller_id, seller_name, unit_price
 FROM Listing_2NF);

(SELECT listing_id, product_id, product_name,
        seller_id, seller_name, unit_price
 FROM Listing_2NF)
EXCEPT
(SELECT l.listing_id, p.product_id, p.product_name,
        s.seller_id, s.seller_name, l.unit_price
 FROM Listing AS l
 JOIN Product AS p ON p.product_id = l.product_id
 JOIN Seller  AS s ON s.seller_id  = l.seller_id);

-- Row counts
SELECT 'Customer' AS table_name, COUNT(*) AS row_count FROM Customer
UNION ALL SELECT 'Address',       COUNT(*) FROM Address
UNION ALL SELECT 'Pincode',       COUNT(*) FROM Pincode
UNION ALL SELECT 'Shipper',       COUNT(*) FROM Shipper
UNION ALL SELECT 'Product',       COUNT(*) FROM Product
UNION ALL SELECT 'Seller',        COUNT(*) FROM Seller
UNION ALL SELECT 'Listing',       COUNT(*) FROM Listing
UNION ALL SELECT 'Orders',        COUNT(*) FROM Orders
UNION ALL SELECT 'OrderItem',     COUNT(*) FROM OrderItem
UNION ALL SELECT 'Payment',       COUNT(*) FROM Payment
UNION ALL SELECT 'ProductReturn', COUNT(*) FROM ProductReturn;
