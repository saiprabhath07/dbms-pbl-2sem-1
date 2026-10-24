USE ecommerce_pbl;

-- Validate the UNF data before normalization.

SELECT COUNT(*) AS total_orders
FROM Order_UNF;

-- Check 1: item subtotal + shipping = total_order_amount
SELECT
    o.order_id,
    s.item_subtotal,
    o.shipping_cost,
    o.total_order_amount,
    IF(s.item_subtotal + o.shipping_cost = o.total_order_amount,
       'PASS', 'FAIL') AS total_check
FROM Order_UNF AS o
JOIN (
    SELECT
        u.order_id,
        SUM(i.unit_price * i.quantity) AS item_subtotal
    FROM Order_UNF AS u
    CROSS JOIN JSON_TABLE(
        u.order_items,
        '$[*]' COLUMNS (
            unit_price DECIMAL(10,2) PATH '$.unit_price',
            quantity   INT           PATH '$.quantity'
        )
    ) AS i
    GROUP BY u.order_id
) AS s ON s.order_id = o.order_id
ORDER BY o.order_id;

-- Check 2: successful payments add up to total_order_amount
SELECT
    o.order_id,
    COALESCE(SUM(p.amount), 0) AS paid_amount,
    o.total_order_amount,
    IF(COALESCE(SUM(p.amount), 0) = o.total_order_amount,
       'PASS', 'FAIL') AS payment_check
FROM Order_UNF AS o
LEFT JOIN JSON_TABLE(
    o.payments,
    '$[*]' COLUMNS (
        status VARCHAR(30)   PATH '$.status',
        amount DECIMAL(12,2) PATH '$.amount'
    )
) AS p ON p.status = 'SUCCESS'
GROUP BY o.order_id, o.total_order_amount
ORDER BY o.order_id;
