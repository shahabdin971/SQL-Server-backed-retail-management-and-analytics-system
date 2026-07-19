-- Drop existing tables if they exist (for re-runnable script)
IF OBJECT_ID('ORDER_ITEMS', 'U') IS NOT NULL DROP TABLE ORDER_ITEMS;
IF OBJECT_ID('ORDERS', 'U') IS NOT NULL DROP TABLE ORDERS;
IF OBJECT_ID('REVIEWS', 'U') IS NOT NULL DROP TABLE REVIEWS;

IF OBJECT_ID('GRAND_TOTALS', 'U') IS NOT NULL DROP TABLE GRAND_TOTALS;
IF OBJECT_ID('TAX_TOTALS', 'U') IS NOT NULL DROP TABLE TAX_TOTALS;
IF OBJECT_ID('SHIPPING_TOTALS', 'U') IS NOT NULL DROP TABLE SHIPPING_TOTALS;

IF OBJECT_ID('ADDRESSES', 'U') IS NOT NULL DROP TABLE ADDRESSES;
IF OBJECT_ID('PRODUCTS', 'U') IS NOT NULL DROP TABLE PRODUCTS;
IF OBJECT_ID('CATEGORIES', 'U') IS NOT NULL DROP TABLE CATEGORIES;
IF OBJECT_ID('PARENT_CATEGORIES', 'U') IS NOT NULL DROP TABLE PARENT_CATEGORIES;
IF OBJECT_ID('CUSTOMERS', 'U') IS NOT NULL DROP TABLE CUSTOMERS;
GO


CREATE TABLE PARENT_CATEGORIES (
    parent_category_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE CATEGORIES (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    parent_category_id INT FOREIGN KEY REFERENCES PARENT_CATEGORIES(parent_category_id),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PRODUCTS (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT FOREIGN KEY REFERENCES CATEGORIES(category_id),
    name VARCHAR(100),
    brand VARCHAR(50),
    price DECIMAL(18, 2),
    stock_on_hand INT DEFAULT 0,
    stock_reserved INT DEFAULT 0
);

CREATE TABLE CUSTOMERS (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    created_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE ADDRESSES (
    address_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES CUSTOMERS(customer_id),
    label VARCHAR(20) CHECK (label IN ('Home', 'Office', 'Other')),
    house_no VARCHAR(20),
    street VARCHAR(100),
    town VARCHAR(50),
    city VARCHAR(50),
    country VARCHAR(50),
    created_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE SHIPPING_TOTALS (
    country VARCHAR(50) PRIMARY KEY,
    shipping_total DECIMAL(18, 2) NOT NULL
);

CREATE TABLE TAX_TOTALS (
    subtotal DECIMAL(18, 2) PRIMARY KEY,
    tax_total DECIMAL(18, 2)
);

CREATE TABLE GRAND_TOTALS (
    subtotal DECIMAL(18, 2),
    shipping_total DECIMAL(18, 2),
    grand_total DECIMAL(18, 2),
    PRIMARY KEY (subtotal, shipping_total),
    FOREIGN KEY (subtotal) REFERENCES TAX_TOTALS(subtotal)
);

CREATE TABLE ORDERS (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES CUSTOMERS(customer_id),
    order_date DATETIME,
    status VARCHAR(20) CHECK (status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled')),
    payment_method VARCHAR(20) CHECK (payment_method IN ('Cash', 'Card')),
    payment_status VARCHAR(20) CHECK (payment_status IN ('Pending', 'Success', 'Failed')),
    item_count INT,

    house_no VARCHAR(20),
    street VARCHAR(100),
    town VARCHAR(50),
    city VARCHAR(50),
    country VARCHAR(50),
    subtotal DECIMAL(18, 2)
);

CREATE TABLE ORDER_ITEMS (
    order_item_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT FOREIGN KEY REFERENCES ORDERS(order_id),
    product_id INT FOREIGN KEY REFERENCES PRODUCTS(product_id),
    unit_price_snapshot DECIMAL(18, 2),
    quantity INT
);

CREATE TABLE REVIEWS (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT FOREIGN KEY REFERENCES PRODUCTS(product_id),
    customer_id INT FOREIGN KEY REFERENCES CUSTOMERS(customer_id),
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comment VARCHAR(500),
    created_date DATETIME DEFAULT GETDATE()
);

SET NOCOUNT ON;

--code for inserting one million rows

INSERT INTO PARENT_CATEGORIES (name) 
VALUES ('Electronics'), ('Clothing'), ('Home');

INSERT INTO CATEGORIES (parent_category_id, name) 
VALUES (1, 'Laptops'), (1, 'Phones'), (2, 'Shirts'), (3, 'Decor');

WITH Tally AS (
    SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N 
    FROM sys.all_columns
)
INSERT INTO PRODUCTS (category_id, name, brand, price, stock_on_hand)
SELECT 
    (N % 4) + 1, 
    'Product ' + CAST(N AS VARCHAR), 
    'Brand ' + CAST((N % 5) + 1 AS VARCHAR), 
    (N * 10.00) + 0.99, 
    1000
FROM Tally;


WITH E1(N) AS (SELECT 1 FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(N)),
     E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
     E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
     R  AS (
        SELECT TOP 10000
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM E4
     )
INSERT INTO CUSTOMERS (name, email, phone)
SELECT
    'Customer ' + CAST(rn AS VARCHAR),
    'user' + CAST(rn AS VARCHAR) + '@mail.com',
    '555-' + RIGHT('000000' + CAST(rn AS VARCHAR), 6)
FROM R;

INSERT INTO SHIPPING_TOTALS (country, shipping_total) VALUES 
('USA', 15.00), ('UK', 10.00), ('Canada', 20.00), ('Pakistan', 5.00), ('Germany', 12.00);

DECLARE @start_date DATETIME = '2020-01-01';

WITH 
    E1(N) AS (SELECT 1 FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(N)),
    E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
    E3(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
    E6(N) AS (SELECT 1 FROM E3 a CROSS JOIN E2 b)
INSERT INTO ORDERS (
    customer_id, order_date, status, payment_method, payment_status, 
    item_count, house_no, street, town, city, country, subtotal
)
SELECT TOP 1000000
    ABS(CHECKSUM(NEWID()) % 10000) + 1,
    DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 1500), @start_date),
    CASE ABS(CHECKSUM(NEWID()) % 3) 
        WHEN 0 THEN 'Pending' WHEN 1 THEN 'Shipped' ELSE 'Delivered' END,
    CASE ABS(CHECKSUM(NEWID()) % 2) 
        WHEN 0 THEN 'Cash' ELSE 'Card' END,
    CASE ABS(CHECKSUM(NEWID()) % 3) 
        WHEN 0 THEN 'Pending' WHEN 1 THEN 'Success' ELSE 'Failed' END,
    ABS(CHECKSUM(NEWID()) % 5) + 1,
    CAST(ABS(CHECKSUM(NEWID()) % 999) AS VARCHAR),
    'Main Street', 'Downtown', 'Metropolis',
    CASE ABS(CHECKSUM(NEWID()) % 5)
        WHEN 0 THEN 'USA' WHEN 1 THEN 'UK' WHEN 2 THEN 'Canada' WHEN 3 THEN 'Pakistan' ELSE 'Germany' END,
    CAST((ABS(CHECKSUM(NEWID()) % 500) + 10) AS DECIMAL(18,2))
FROM E6;

INSERT INTO TAX_TOTALS (subtotal, tax_total)
SELECT DISTINCT subtotal, CAST(subtotal * 0.05 AS DECIMAL(18,2))
FROM ORDERS
WHERE subtotal NOT IN (SELECT subtotal FROM TAX_TOTALS);

INSERT INTO GRAND_TOTALS (subtotal, shipping_total, grand_total)
SELECT DISTINCT 
    o.subtotal, 
    st.shipping_total,
    CAST((o.subtotal * 1.05) + st.shipping_total AS DECIMAL(18,2))
FROM ORDERS o
JOIN SHIPPING_TOTALS st ON o.country = st.country
WHERE NOT EXISTS (
    SELECT 1 FROM GRAND_TOTALS gt 
    WHERE gt.subtotal = o.subtotal AND gt.shipping_total = st.shipping_total
);

INSERT INTO ORDER_ITEMS (order_id, product_id, unit_price_snapshot, quantity)
SELECT 
    order_id,
    ABS(CHECKSUM(NEWID()) % 100) + 1,
    ABS(CHECKSUM(NEWID()) % 100) + 10,
    1
FROM ORDERS;

PRINT 'Database Created and 1 Million Rows Inserted Successfully.';
GO

/* VIEWS*/

-- View 1: Product catalog to view all products
CREATE VIEW ProductCatalogue AS
SELECT
    p.product_id,
    p.name AS product_name,
    p.brand,
    p.price,
    c.category_id,
    c.name AS category_name,
    pc.parent_category_id,
    pc.name AS parent_category_name,
    (p.stock_on_hand - p.stock_reserved) AS available_stock
FROM Products p
JOIN Categories c ON c.category_id = p.category_id
JOIN Parent_Categories pc ON pc.parent_category_id = c.parent_category_id;
GO

-- View 2: Pending orders that are either 'Pending' or 'Shipped'
CREATE VIEW PendingOrders AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    o.customer_id,
    cu.name AS customer_name,
    cu.email,
    SUM(oi.unit_price_snapshot * oi.quantity) AS order_total
FROM Orders o
JOIN Customers cu ON cu.customer_id = o.customer_id
JOIN ORDER_ITEMS oi ON oi.order_id = o.order_id
WHERE o.status IN ('Pending', 'Shipped')
GROUP BY
    o.order_id, o.order_date, o.status,
    o.customer_id, cu.name, cu.email;
GO

-- /* CTEs */

-- CTE 1: Category listing under each parent category
WITH AllCategories AS (
    SELECT
        pc.parent_category_id,
        pc.name AS parent_name,
        c.category_id,
        c.name AS category_name
    FROM Parent_Categories pc
    JOIN Categories c
        ON c.parent_category_id = pc.parent_category_id
)
SELECT *
FROM AllCategories
ORDER BY parent_name, category_name;
GO

-- CTE 2: Units sold and total revenue per product for delivered orders
WITH ProductSales AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.unit_price_snapshot * oi.quantity) AS total_revenue
    FROM Order_Items oi
    JOIN Orders o ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY oi.product_id
)
SELECT
    p.product_id,
    p.name,
    ps.total_units_sold,
    ps.total_revenue
FROM ProductSales ps
JOIN Products p ON p.product_id = ps.product_id
ORDER BY ps.total_units_sold DESC;
GO


-- CTE 3: Top 5 customers by revenue from delivered orders
 WITH CustomerRevenue AS (
    SELECT
        o.customer_id,
        SUM(oi.unit_price_snapshot * oi.quantity) AS total_revenue
    FROM Orders o
    JOIN Order_Items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
)
SELECT TOP 5
    cu.customer_id,
    cu.name AS customer_name,
    cr.total_revenue
FROM CustomerRevenue cr
JOIN Customers cu ON cu.customer_id = cr.customer_id
ORDER BY cr.total_revenue DESC;
GO

--stored procedures

-- stored procedure 1
CREATE OR ALTER PROCEDURE dbo.usp_GetTopSellingAndTopRatedProducts
    @since_date  DATETIME,        
    @top_n       INT = 10,        
    @category_id INT = NULL  
AS
BEGIN
    SET NOCOUNT ON;
    IF @top_n IS NULL OR @top_n <= 0
        THROW 53001, 'top_n must be a positive integer.', 1;

    IF @since_date IS NULL
        SET @since_date = '1900-01-01';   

    ;WITH Sales AS
    (
        SELECT
            oi.product_id,
            units_sold = SUM(oi.quantity),
            revenue    = SUM(oi.unit_price_snapshot * oi.quantity)
        FROM ORDER_ITEMS oi
        JOIN ORDERS o
            ON o.order_id = oi.order_id
        WHERE o.order_date >= @since_date
          AND o.status IN ('Shipped','Delivered')
        GROUP BY oi.product_id
    ),
    Ratings AS
    (
        SELECT
            r.product_id,
            avg_rating   = CAST(AVG(CAST(r.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)),
            review_count = COUNT(*)
        FROM REVIEWS r
        GROUP BY r.product_id
    )
    SELECT TOP (@top_n)
        p.product_id,
        p.name,
        p.brand,
        c.category_id,
        COALESCE(s.units_sold, 0) AS units_sold,
        COALESCE(CAST(s.revenue AS DECIMAL(18,2)), 0) AS revenue,
        COALESCE(rt.avg_rating, 0)   AS avg_rating,
        COALESCE(rt.review_count, 0) AS review_count,
        p.stock_on_hand AS available_stock

    FROM PRODUCTS p
    LEFT JOIN CATEGORIES c
        ON c.category_id = p.category_id
    LEFT JOIN Sales s
        ON s.product_id = p.product_id
    LEFT JOIN Ratings rt
        ON rt.product_id = p.product_id

    WHERE (@category_id IS NULL OR p.category_id = @category_id)

    ORDER BY
        COALESCE(s.units_sold, 0) DESC,  
        COALESCE(rt.avg_rating, 0) DESC, 
        COALESCE(s.revenue, 0) DESC;     
END;
GO

-- 2nd stored procedure
CREATE OR ALTER PROCEDURE dbo.usp_AddVerifiedReview
    @product_id  INT,
    @customer_id INT,
    @rating      INT,
    @comment     VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;
        IF @rating < 1 OR @rating > 5
            THROW 54001, 'Rating must be an integer between 1 and 5.', 1;
        IF NOT EXISTS (SELECT 1 FROM PRODUCTS WHERE product_id = @product_id)
            THROW 54002, 'Invalid product_id.', 1;

        IF NOT EXISTS (SELECT 1 FROM CUSTOMERS WHERE customer_id = @customer_id)
            THROW 54003, 'Invalid customer_id.', 1;
        DECLARE @latest_status VARCHAR(20);

        SELECT TOP (1)
            @latest_status = o.status
        FROM ORDERS o
        JOIN ORDER_ITEMS oi
            ON oi.order_id = o.order_id
        WHERE o.customer_id = @customer_id
          AND oi.product_id = @product_id
        ORDER BY o.order_date DESC, o.order_id DESC;

        IF @latest_status IS NULL
            THROW 54004, 'Customer has never purchased this product.', 1;

        IF @latest_status <> 'Delivered'
            THROW 54004, 'Customer can only review products which are delivered to them', 1;

        IF EXISTS (
            SELECT 1
            FROM REVIEWS
            WHERE product_id = @product_id
              AND customer_id = @customer_id
        )
        BEGIN
            UPDATE REVIEWS
            SET
                rating = @rating,
                comment = @comment,
                created_date = GETDATE()
            WHERE product_id = @product_id
              AND customer_id = @customer_id;
        END
        ELSE
        BEGIN
            INSERT INTO REVIEWS(product_id, customer_id, rating, comment)
            VALUES(@product_id, @customer_id, @rating, @comment);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

--indexes


-- all the primary keys of all the tables are clustered indexes by default
-- below are some non-clustered indexes to improve query performance

-- non-unique and non-filtered
-- Used to quickly lookup reviews for a particular product
CREATE NONCLUSTERED INDEX Reviews_ProductId
ON REVIEWS(product_id);

-- non-unique and non-filtered
-- used to quickly lookup all orders for a particular customer sorted by date (newest first)
CREATE NONCLUSTERED INDEX Orders_CustomerId_OrderDate
ON ORDERS(customer_id, order_date DESC);

-- non-unique and non-filtered
-- used to quickly lookup products in a particular category
CREATE NONCLUSTERED INDEX Products_CategoryId
ON PRODUCTS(category_id);

-- unique and non-filtered
-- used to quickly lookup a customer by their phone number
CREATE UNIQUE NONCLUSTERED INDEX Customers_Phone
ON CUSTOMERS(phone);

-- non-unique and filtered
-- used to quickly find all pending orders by date
CREATE NONCLUSTERED INDEX Orders_Pending_ByDate
ON ORDERS(order_date)
WHERE status = 'Pending';

-- partitions

-- Partition function for ORDERS based on order date(by year)
CREATE PARTITION FUNCTION Orders_OrderDate_Function (DATETIME)
AS RANGE RIGHT FOR VALUES (
    ('2021-01-01'),
    ('2022-01-01'),
    ('2023-01-01'),
    ('2024-01-01')
);

-- Partition scheme to store the 'orders' partitions in the primary filegroup
CREATE PARTITION SCHEME Orders_OrderDate_Scheme
AS PARTITION Orders_OrderDate_Function
ALL TO ([PRIMARY]);

-- Partitioned non-clustered index on 'orders' used to speed up queries filtering orders by order_date
CREATE NONCLUSTERED INDEX Orders_OrderDate_Index
ON ORDERS(order_date)
ON Orders_OrderDate_Scheme(order_date);

-- Partition function for 'order_items' based on order id
CREATE PARTITION FUNCTION OrderItems_OrderId_Function (INT)
AS RANGE RIGHT FOR VALUES (200000, 400000, 600000, 800000
);

-- Partition scheme to store the 'order_items' partitions in the primary filegroup
CREATE PARTITION SCHEME OrderItems_OrderId_Scheme
AS PARTITION OrderItems_OrderId_Function
ALL TO ([PRIMARY]);

-- Partitioned non-clustered index on 'order_items' used to speed up queries filtering order items by order id
CREATE NONCLUSTERED INDEX OrderItems_OrderId_Index
ON ORDER_ITEMS(order_id)
ON OrderItems_OrderId_Scheme(order_id);
GO


-- functions

-- function 1
CREATE OR ALTER FUNCTION dbo.fn_OrderItemsWithLineTotals
(
    @order_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        oi.order_item_id,
        oi.product_id,
        oi.unit_price_snapshot,
        oi.quantity,
        CAST(oi.unit_price_snapshot * oi.quantity AS DECIMAL(18,2)) AS line_total
    FROM ORDER_ITEMS oi
    WHERE oi.order_id = @order_id
);
GO

--function 2

CREATE OR ALTER FUNCTION dbo.fn_OrderTotals
(
    @order_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        o.order_id,
        o.subtotal,
        COALESCE(t.tax_total, ROUND(o.subtotal * 0.05, 2)) AS tax_total,
        COALESCE(s.shipping_total, 0) AS shipping_total,
        COALESCE(
            g.grand_total,
            o.subtotal
            + COALESCE(t.tax_total, ROUND(o.subtotal * 0.05, 2))
            + COALESCE(s.shipping_total, 0)
        ) AS grand_total

    FROM dbo.ORDERS o
    LEFT JOIN dbo.TAX_TOTALS t
        ON t.subtotal = o.subtotal
    LEFT JOIN dbo.SHIPPING_TOTALS s
        ON s.country = o.country
    LEFT JOIN dbo.GRAND_TOTALS g
        ON g.subtotal = o.subtotal
       AND g.shipping_total = s.shipping_total
    WHERE o.order_id = @order_id
);
GO

--triggers 

--trigger 1

CREATE OR ALTER TRIGGER dbo.trg_ORDER_ITEMS_AI_ComputeTotals
ON dbo.ORDER_ITEMS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    UPDATE oi
    SET oi.unit_price_snapshot = COALESCE(oi.unit_price_snapshot, p.price)
    FROM dbo.ORDER_ITEMS oi
    JOIN inserted i 
        ON i.order_item_id = oi.order_item_id
    JOIN dbo.PRODUCTS p 
        ON p.product_id = oi.product_id;
    DECLARE @AffectedOrders TABLE (
        order_id INT PRIMARY KEY
    );

    INSERT INTO @AffectedOrders(order_id)
    SELECT DISTINCT i.order_id
    FROM inserted i
    WHERE i.order_id IS NOT NULL;
    DECLARE @Sums TABLE
    (
        order_id INT PRIMARY KEY,
        subtotal DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Sums(order_id, subtotal)
    SELECT
        oi.order_id,
        CAST(SUM(oi.quantity * COALESCE(oi.unit_price_snapshot, p.price)) AS DECIMAL(18,2)) AS subtotal
    FROM dbo.ORDER_ITEMS oi
    JOIN dbo.PRODUCTS p 
        ON p.product_id = oi.product_id
    JOIN @AffectedOrders a 
        ON a.order_id = oi.order_id
    GROUP BY oi.order_id;
    UPDATE o
    SET o.subtotal = s.subtotal
    FROM dbo.ORDERS o
    JOIN @Sums s 
        ON s.order_id = o.order_id;

    DECLARE @tax_rate DECIMAL(5,4) = 0.05;
    UPDATE t
    SET t.tax_total = CAST(ROUND(t.subtotal * @tax_rate, 2) AS DECIMAL(18,2))
    FROM dbo.TAX_TOTALS t
    JOIN (SELECT DISTINCT subtotal FROM @Sums) s
        ON s.subtotal = t.subtotal;
    INSERT INTO dbo.TAX_TOTALS (subtotal, tax_total)
    SELECT
        s.subtotal,
        CAST(ROUND(s.subtotal * @tax_rate, 2) AS DECIMAL(18,2))
    FROM (SELECT DISTINCT subtotal FROM @Sums) s
    LEFT JOIN dbo.TAX_TOTALS t 
        ON t.subtotal = s.subtotal
    WHERE t.subtotal IS NULL;

    DECLARE @Data TABLE
    (
        order_id INT PRIMARY KEY,
        subtotal DECIMAL(18,2) NOT NULL,
        tax_total DECIMAL(18,2) NOT NULL,
        shipping_total DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Data(order_id, subtotal, tax_total, shipping_total)
    SELECT
        s.order_id,
        s.subtotal,
        CAST(ROUND(s.subtotal * @tax_rate, 2) AS DECIMAL(18,2)) AS tax_total,
        CAST(ISNULL(st.shipping_total, 0) AS DECIMAL(18,2))     AS shipping_total
    FROM @Sums s
    JOIN dbo.ORDERS o 
        ON o.order_id = s.order_id
    LEFT JOIN dbo.SHIPPING_TOTALS st 
        ON st.country = o.country;
    UPDATE gt
    SET gt.grand_total =
        CAST(ROUND(d.subtotal + d.tax_total + d.shipping_total, 2) AS DECIMAL(18,2))
    FROM dbo.GRAND_TOTALS gt
    JOIN @Data d
        ON d.subtotal = gt.subtotal
       AND d.shipping_total = gt.shipping_total;
    INSERT INTO dbo.GRAND_TOTALS (subtotal, shipping_total, grand_total)
    SELECT DISTINCT
        d.subtotal,
        d.shipping_total,
        CAST(ROUND(d.subtotal + d.tax_total + d.shipping_total, 2) AS DECIMAL(18,2))
    FROM @Data d
    LEFT JOIN dbo.GRAND_TOTALS gt
        ON gt.subtotal = d.subtotal
       AND gt.shipping_total = d.shipping_total
    WHERE gt.subtotal IS NULL;

END;
GO

--trigger 2 
CREATE OR ALTER TRIGGER dbo.trg_ORDER_ITEMS_AI_stock
ON dbo.ORDER_ITEMS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @to_reserve TABLE (
        product_id INT PRIMARY KEY,
        qty INT NOT NULL
    );

    INSERT INTO @to_reserve(product_id, qty)
    SELECT 
        i.product_id,
        SUM(i.quantity) AS qty
    FROM inserted i
    JOIN dbo.ORDERS o 
        ON o.order_id = i.order_id
    WHERE ISNULL(o.payment_status,'') <> 'Success'
      AND o.status IN ('Pending','Shipped')   
    GROUP BY i.product_id;

    IF NOT EXISTS (SELECT 1 FROM @to_reserve)
        RETURN;
    IF EXISTS (
        SELECT 1
        FROM dbo.PRODUCTS p WITH (UPDLOCK, HOLDLOCK)
        JOIN @to_reserve r ON r.product_id = p.product_id
        WHERE ISNULL(p.stock_on_hand,0) < r.qty
           OR ISNULL(p.stock_reserved,0) < 0
    )
    BEGIN
        RAISERROR('Insufficient stock to reserve for this order.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    UPDATE p
    SET 
        p.stock_reserved = ISNULL(p.stock_reserved,0) + r.qty,
        p.stock_on_hand  = ISNULL(p.stock_on_hand,0)  - r.qty
    FROM dbo.PRODUCTS p
    JOIN @to_reserve r 
        ON r.product_id = p.product_id;
    IF EXISTS (
        SELECT 1 
        FROM dbo.PRODUCTS 
        WHERE stock_on_hand < 0 OR stock_reserved < 0
    )
    BEGIN
        RAISERROR('Stock went negative after reservation. Transaction cancelled.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- trigger 3 


CREATE OR ALTER TRIGGER dbo.trg_ORDER_ITEMS_AU_stock
ON dbo.ORDER_ITEMS
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  ;WITH old_unpaid AS (
    SELECT d.product_id, SUM(d.quantity) AS qty
    FROM deleted d
    JOIN dbo.ORDERS o ON o.order_id = d.order_id
    WHERE ISNULL(o.payment_status,'') <> 'Success'
      AND ISNULL(o.status,'') <> 'Cancelled'
    GROUP BY d.product_id
  )
  UPDATE p
  SET p.stock_reserved = p.stock_reserved - ou.qty,
      p.stock_on_hand  = p.stock_on_hand  + ou.qty
  FROM dbo.PRODUCTS p
  JOIN old_unpaid ou ON ou.product_id = p.product_id;

  ;WITH new_unpaid AS (
    SELECT i.product_id, SUM(i.quantity) AS qty
    FROM inserted i
    JOIN dbo.ORDERS o ON o.order_id = i.order_id
    WHERE ISNULL(o.payment_status,'') <> 'Success'
      AND ISNULL(o.status,'') <> 'Cancelled'
    GROUP BY i.product_id
  )
  UPDATE p
  SET p.stock_reserved = p.stock_reserved + nu.qty,
      p.stock_on_hand  = p.stock_on_hand  - nu.qty
  FROM dbo.PRODUCTS p
  JOIN new_unpaid nu ON nu.product_id = p.product_id;
  IF EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE stock_reserved < 0)
  BEGIN
    RAISERROR('stock_reserved would become negative after update.',16,1);
    ROLLBACK TRANSACTION; RETURN;
  END;

  IF EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE stock_on_hand < 0)
  BEGIN
    RAISERROR('Insufficient stock_on_hand after update.',16,1);
    ROLLBACK TRANSACTION; RETURN;
  END;
END;
GO

--trigger 4

CREATE OR ALTER TRIGGER dbo.trg_ORDER_ITEMS_AD_stock
ON dbo.ORDER_ITEMS
AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH to_release AS (
    SELECT d.product_id, SUM(d.quantity) AS qty
    FROM deleted d
    JOIN ORDERS o ON o.order_id = d.order_id
    WHERE ISNULL(o.payment_status,'') <> 'Success'
      AND ISNULL(o.status,'') <> 'Cancelled'
    GROUP BY d.product_id
  )
  UPDATE p
  SET p.stock_reserved = p.stock_reserved - r.qty,
      p.stock_on_hand  = p.stock_on_hand  + r.qty
  FROM PRODUCTS p
  JOIN to_release r ON r.product_id = p.product_id;

  IF EXISTS (SELECT 1 FROM PRODUCTS WHERE stock_reserved < 0)
  BEGIN
    RAISERROR('stock_reserved would become negative after delete.',16,1);
    ROLLBACK TRANSACTION; RETURN;
  END;
END;
GO

--trigger 5 

CREATE OR ALTER TRIGGER dbo.trg_ORDERS_AU_stock
ON dbo.ORDERS
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH shipped_now AS (
    SELECT i.order_id
    FROM inserted i
    LEFT JOIN deleted d ON d.order_id = i.order_id
    WHERE i.status = 'Shipped'
      AND (d.status IS NULL OR d.status <> 'Shipped')
  ),
  qty_ship AS (
    SELECT oi.product_id, SUM(oi.quantity) AS qty
    FROM dbo.ORDER_ITEMS oi
    JOIN shipped_now sn ON sn.order_id = oi.order_id
    GROUP BY oi.product_id
  )
  UPDATE p
  SET p.stock_reserved = p.stock_reserved - qs.qty
  FROM dbo.PRODUCTS p
  JOIN qty_ship qs ON qs.product_id = p.product_id;

  ;WITH cancelled_now AS (
    SELECT i.order_id
    FROM inserted i
    LEFT JOIN deleted d ON d.order_id = i.order_id
    WHERE i.status = 'Cancelled'
      AND (d.status IS NULL OR d.status <> 'Cancelled')
      AND (d.status IS NULL OR (d.status <> 'Shipped' AND d.status <> 'Delivered'))
  ),
  qty_cancel AS (
    SELECT oi.product_id, SUM(oi.quantity) AS qty
    FROM dbo.ORDER_ITEMS oi
    JOIN cancelled_now cn ON cn.order_id = oi.order_id
    GROUP BY oi.product_id
  )
  UPDATE p
  SET p.stock_reserved = p.stock_reserved - qc.qty,
      p.stock_on_hand  = p.stock_on_hand  + qc.qty
  FROM dbo.PRODUCTS p
  JOIN qty_cancel qc ON qc.product_id = p.product_id;

  IF EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE stock_reserved < 0 OR stock_on_hand < 0)
  BEGIN
    RAISERROR('Inventory would go negative after status change.',16,1);
    ROLLBACK TRANSACTION; RETURN;
  END;
END;
GO
 

--trigger 6
CREATE TRIGGER trg_Orders_InsteadOfDelete_Cancel
ON ORDERS
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE o
    SET o.status = 'Cancelled'
    FROM ORDERS o
    INNER JOIN deleted d
        ON o.order_id = d.order_id;
END;
GO
