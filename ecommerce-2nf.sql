USE ecommerce_pbl;

-- 1NF -> 2NF
-- 2NF only matters for relations with a composite key.
--   Order_1NF, Payment_1NF, Return_1NF: single-attribute keys, so they
--     cannot have partial dependencies. Already 2NF, left unchanged.
--   OrderItem_1NF: key (order_id, listing_id), but
--     listing_id -> product_id, product_name, seller_id, seller_name, unit_price
--     depends on PART of the key (partial dependency). Split it.
--
-- Decomposition: R(order_id, listing_id, <listing attrs>, quantity)
--   R1 = Listing_2NF(listing_id, <listing attrs>)   key: listing_id
--   R2 = OrderItem_2NF(order_id, listing_id, quantity)
-- Lossless: R1 ∩ R2 = {listing_id}, which is the key of R1.
-- Dependency preserving: both FDs live wholly inside R1 or R2.

DROP TABLE IF EXISTS OrderItem_2NF, Listing_2NF;

CREATE TABLE Listing_2NF (
    listing_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    seller_id INT NOT NULL,
    seller_name VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL
);

CREATE TABLE OrderItem_2NF (
    order_id INT NOT NULL,
    listing_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, listing_id),
    FOREIGN KEY (listing_id) REFERENCES Listing_2NF(listing_id)
);

-- Plain INSERTs. If the FD listing_id -> attributes were violated,
-- DISTINCT would give two rows for one listing_id and the PK would
-- reject the load with an error instead of hiding it.
INSERT INTO Listing_2NF
    (listing_id, product_id, product_name, seller_id, seller_name, unit_price)
SELECT DISTINCT
    listing_id, product_id, product_name, seller_id, seller_name, unit_price
FROM OrderItem_1NF;

INSERT INTO OrderItem_2NF (order_id, listing_id, quantity)
SELECT order_id, listing_id, quantity
FROM OrderItem_1NF;

-- Verify
SELECT * FROM Listing_2NF ORDER BY listing_id;
SELECT * FROM OrderItem_2NF ORDER BY order_id, listing_id;

-- Lossless-join test: OrderItem_2NF JOIN Listing_2NF must equal OrderItem_1NF.
-- Both queries must return zero rows.
(SELECT o.order_id, o.listing_id, l.product_id, l.product_name,
        l.seller_id, l.seller_name, l.unit_price, o.quantity
 FROM OrderItem_2NF AS o JOIN Listing_2NF AS l USING (listing_id))
EXCEPT
(SELECT order_id, listing_id, product_id, product_name,
        seller_id, seller_name, unit_price, quantity
 FROM OrderItem_1NF);

(SELECT order_id, listing_id, product_id, product_name,
        seller_id, seller_name, unit_price, quantity
 FROM OrderItem_1NF)
EXCEPT
(SELECT o.order_id, o.listing_id, l.product_id, l.product_name,
        l.seller_id, l.seller_name, l.unit_price, o.quantity
 FROM OrderItem_2NF AS o JOIN Listing_2NF AS l USING (listing_id));
