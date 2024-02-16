--a)
CREATE OR REPLACE FUNCTION GET_AGE_GROUP(p_birth_date IN DATE)
RETURN VARCHAR2
IS
    age NUMBER;
BEGIN
    -- Ypologismos age
    age := TRUNC(MONTHS_BETWEEN(SYSDATE, p_birth_date) / 12);

    -- Kathorismos tou age group
    IF age < 40 THEN
        RETURN 'under 40';
    ELSIF age BETWEEN 40 AND 50 THEN
        RETURN '40-50';
    ELSIF age BETWEEN 50 AND 60 THEN
        RETURN '50-60';
    ELSIF age BETWEEN 60 AND 70 THEN
        RETURN '60-70';
    ELSE
        RETURN 'above 70';
    END IF;
END;
/


--b
  
CREATE OR REPLACE FUNCTION GET_INCOME_LEVEL(p_income IN VARCHAR2)
RETURN VARCHAR2
IS
    v_income_low NUMBER;
BEGIN
    -- Kano Extract numerical value apo to income string
    BEGIN
        -- Vgazo non-numeric xaraktires kai kano extract tin timi
        SELECT TO_NUMBER(REGEXP_SUBSTR(REPLACE(p_income, ',', ''), '\d+', 1, 1)) INTO v_income_low FROM dual;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'unknown';
    END;

    -- Katigoriopoio income me vasi ta sigkekrimena ranges
    IF v_income_low <= 129999 THEN
        RETURN 'low';
    ELSIF v_income_low <= 249999 THEN
        RETURN 'medium';
    ELSE
        RETURN 'high';
    END IF;
END;
/



--c
CREATE OR REPLACE FUNCTION FIX_STATUS(p_status IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
    CASE UPPER(p_status)
        WHEN 'MARRIED' THEN
            RETURN 'Married';
        WHEN 'WIDOWED' THEN
            RETURN 'Single';
        WHEN 'SEPAR.' THEN
            RETURN 'Single';
        WHEN 'DIVORCED' THEN
            RETURN 'Single';
        WHEN 'NEVERM' THEN
            RETURN 'Single';
        WHEN 'SINGLE' THEN
            RETURN 'Single';
        WHEN 'DIVORC.' THEN
            RETURN 'Single';
        WHEN '(NULL)' THEN
            RETURN 'Unknown';
        ELSE
            RETURN 'Unknown';  -- Diaxeirisi oti allo case os 'Unknown'
    END CASE;
END;
/


--protos pinakas customers
CREATE TABLE Customers (
    customer_id NUMBER,
    gender VARCHAR(30),
    AGEGROUP VARCHAR(60),
    MARITAL_STATUS VARCHAR (40),
    INCOME_LEVEL VARCHAR(20)
);

insert into customers (customer_id, gender, agegroup,marital_status,income_level) 
select ID, gender, GET_AGE_GROUP(BIRTH_DATE) as agegroup,fix_status(marital_status)as marital_status,GET_INCOME_LEVEL(INCOME_LEVEL)
as income_level from xsales.customers;

select * from customers;  
drop table customers;


--pinakas orders
CREATE TABLE ORDERS(

    ORDER_ID NUMBER,
    PRODUCT_ID NUMBER,
    CUSTOMER_ID NUMBER,
    DAYS_TO_PROCESS NUMBER,
    PRICE NUMBER,
    COST NUMBER,
    CHANNEL VARCHAR(60)

);


INSERT INTO ORDERS(order_id,product_id,customer_id,days_to_process,price,cost,channel) SELECT
    order_id, product_id, customer_id, days_to_proc(order_finished, order_date) as days_to_process, amount as price, cost, channel
    from xsales.order_items ord JOIN xsales.orders o ON ord.order_id = o.id;
    
select * from orders;
drop table orders;

--pinakas products 

CREATE TABLE products(

    PRODUCT_ID NUMBER,
    PRODUCT_NAME VARCHAR(100),
    CATEGORY_NAME VARCHAR(90),
    
    LIST_PRICE NUMBER
   

);


drop table products;

insert into products (product_id, product_name,category_name, list_price)
SELECT pr.IDENTIFIER as PRODUCT_ID, pr.name as product_name, ct.description as category_name, pr.list_price
from xsales.products pr JOIN xsales.categories ct ON pr.subcategory_reference = ct.id ; 



select * from products;
select * from xsales.products;

select * from xsales.categories;








--ignore just for some testing
SELECT GET_AGE_GROUP(BIRTH_DATE) AS AGEGROUP from xsales.customers where ID = 31164;
SELECT GET_INCOME_LEVEL(INCOME_LEVEL) AS INCOME_LEVEL from xsales.customers where ID = 16979;
SELECT fix_status(marital_status) AS marital_status from xsales.customers where ID = 456;

select get_income_level(income_level) as income_level from xsales.customers;
select * from XSALES.customers;
SELECT income_level from xsales.customers;





--DAYS_TO_PROCESS

CREATE OR REPLACE FUNCTION days_to_proc(
    p_order_finished IN DATE, p_order_date IN DATE)
RETURN NUMBER
IS
    v_days_to_process NUMBER;
BEGIN

    v_days_to_process := p_order_finished - p_order_date;
    
    RETURN v_days_to_process;
END days_to_proc;
/
--kai vlepoume tin days_to_process stin stili tou talbe orders
select * from orders;






--ignore just for some testing
SELECT days_to_proc(order_finished, order_date)  from xsales.orders,xsales.order_items
where ID = order_id;

SELECT amount as price from xsales.order_items;





--Ipoloipa ipoerotimata (i - v)

--i
--(price = amount apo pinaka order_items)
--(arxika days_to_process)

CREATE TABLE order_delays AS
SELECT order_id, MAX(CASE 
                        WHEN days_to_proc(order_finished, order_date) > 20
                        THEN days_to_proc(order_finished, order_date)
                        ELSE 0
                    END
                ) AS max_delay
FROM xsales.orders JOIN xsales.order_items ON xsales.orders.ID = xsales.order_items.order_id
GROUP by order_id
ORDER BY max_delay DESC;


select * from order_delays;
DROP TABLE ORDER_DELAYS;


--ii

CREATE TABLE final_profit as
SELECT
    
    amount,
    cost + (0.001 * list_price * max_delay) as final_cost,
    amount - (cost +(0.001 * list_price * max_delay)) as final_profit
FROM
    xsales.order_items oi
    JOIN xsales.products pr ON oi.product_id = pr.identifier
    JOIN order_delays d ON oi.order_id = d.order_id;
    
    
    
 select * from final_profit;
 drop table final_profit;



--iii

CREATE TABLE deficit(

    orderid NUMBER,
    customerid NUMBER,
    channel VARCHAR(60),
    amount NUMBER


);
select * from deficit;

CREATE TABLE profit(

    orderid NUMBER,
    customerid NUMBER,
    channel VARCHAR(60),
    amount NUMBER


);
select * from profit;

drop table deficit;
drop table profit;


 
        
   
DECLARE
    -- Kanoume Declare ta variables gia na kano store ta cursor values
    v_order_id xsales.orders.id%TYPE;
    v_customer_id xsales.orders.customer_id%TYPE;
    v_channel xsales.orders.channel%TYPE;
    v_final_profit NUMBER;

    -- Declare ton cursor
    CURSOR order_cursor IS
        SELECT DISTINCT
            o.ID AS order_id,
            o.customer_id,
            o.channel,
            SUM(oi.amount - (oi.cost + (0.001 * p.list_price * od.max_delay))) AS final_profit
        FROM
            xsales.orders o
            JOIN xsales.order_items oi ON o.ID = oi.order_id
            JOIN xsales.products p ON oi.product_id = p.identifier
            JOIN order_delays od ON o.ID = od.order_id
        GROUP BY o.ID, o.customer_id, o.channel;

BEGIN
    -- Open cursor
    OPEN order_cursor;

    -- Fetch to proto row
    FETCH order_cursor INTO v_order_id, v_customer_id, v_channel, v_final_profit;

    -- Loop ston cursor
    WHILE order_cursor%FOUND LOOP
        IF v_final_profit < 0 THEN
            -- Negative profit --> insert into deficit table
            INSERT INTO deficit (orderid, customerid, channel, amount)
            VALUES (v_order_id, v_customer_id, v_channel, ABS(v_final_profit));
        ELSE
            -- Positive profit --> insert into profit table
            INSERT INTO profit (orderid, customerid, channel, amount)
            VALUES (v_order_id, v_customer_id, v_channel, v_final_profit);
        END IF;

        -- Fetch epomeno row
        FETCH order_cursor INTO v_order_id, v_customer_id, v_channel, v_final_profit;
    END LOOP;

    -- Kleisimo Cursor
    CLOSE order_cursor;
END;
/


UPDATE deficit 
SET amount = ABS(amount);
select * from deficit;
DROP TABLE deficit;

select * from profit;

DROP TABLE profit;

--iv 
--Revenues or losses - esoda - kostos
/*
SELECT
    gender,
    SUM(CASE WHEN amount - cost >= 0 THEN amount - cost ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN amount - cost < 0 THEN amount - cost ELSE 0 END) AS total_losses
FROM
    xsales.customers c
    JOIN xsales.orders o ON c.ID = o.customer_id
    JOIN xsales.order_items oi ON o.ID = oi.order_id
    JOIN xsales.products p ON oi.product_id = p.identifier
GROUP BY gender;
*/
--auto edo san lisi tou iv
SELECT
    c.gender,
    SUM(CASE WHEN p.amount - d.amount >= 0 THEN p.amount ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN p.amount - d.amount< 0 THEN d.amount ELSE 0 END) AS total_losses
FROM
    customers c join profit p ON c.customer_id = p.customerid
    JOIN deficit d ON c.customer_id = d.customerid
GROUP BY c.gender;


--v
--peripoy to idio apla tora ana kanali paraggelion (px Internet etc etc)

/*
SELECT
    channel,
    SUM(CASE WHEN amount - cost >= 0 THEN amount - cost ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN amount - cost < 0 THEN amount - cost ELSE 0 END) AS total_losses
FROM
    xsales.customers c
    JOIN xsales.orders o ON c.ID = o.customer_id
    JOIN xsales.order_items oi ON o.ID = oi.order_id
    JOIN xsales.products p ON oi.product_id = p.identifier
GROUP BY channel;
*/
--auto san lisi tou v  (argei 6-7 seconds na treksei)
SELECT
    o.channel,
    SUM(CASE WHEN p.amount - d.amount >= 0 THEN p.amount ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN p.amount - d.amount< 0 THEN d.amount ELSE 0 END) AS total_losses
FROM
    orders o join profit p ON o.customer_id = p.customerid
    JOIN deficit d ON o.customer_id = d.customerid
GROUP BY  o.channel;






--3o
DELETE FROM PLAN_TABLE;
EXPLAIN plan for
select order_id, price-cost,days_to_process
from products p join orders o on o.product_id=p.product_id
join customers c on o.customer_id=c.customer_id
where p.category_name='Accessories' and o.channel='Internet'
and c.gender='Male' and c.income_level='high' and days_to_process=0;

-- gia na vro pragmatikes pleiades
select count(*) from products p join orders o on o.product_id=p.product_id
join customers c on o.customer_id=c.customer_id
where p.category_name='Accessories' and o.channel='Internet'
and c.gender='Male' and c.income_level='high' and days_to_process=0;



select id, parent_id,depth,operation,options,object_name,access_predicates, filter_predicates, projection, cost, cardinality
from plan_table;

select * from table(dbms_xplan.display());
SELECT * FROM plan_TABLE;

--1513 COST, depth --> depth = 0. CPU COST  355339030 kai IO_COST 1504.



--Xrisi Euretirion gia veltistopoiisi

-- Products Table
CREATE  INDEX idx_products_category_name ON products(category_name,product_id);
--Orders Table
CREATE INDEX idx_orders_order_id ON orders(channel,customer_id);
-- Customers Table

CREATE  INDEX idx_customers_income_level ON customers(income_level,gender,customer_id);


DROP INDEX idx_products_category_name;
DROP INDEX idx_customers_income_level;
DROP INDEX idx_orders_order_id;

--CREATE  INDEX idx_customers_income_level ON customers(income_level);


--Paratiro meiosi --> COST  1419, alla kai sto CPU_COST 342742926, IO_COST 1410






--4o
DELETE FROM PLAN_TABLE;
EXPLAIN plan for
select order_id, price-cost,days_to_process
from products p join orders o on o.product_id=p.product_id
join customers c on o.customer_id=c.customer_id
where p.category_name='Accessories' and o.channel='Internet'
and c.gender='Male' and c.income_level='high' and days_to_process>100;

select id, parent_id,depth,operation,options,object_name,access_predicates, filter_predicates, projection, cost, cardinality
from plan_table;

select * from table(dbms_xplan.display());
SELECT * FROM plan_TABLE;

--1ο)  1513  COST.
-- fainetai na einai to CPU_COST 361706238 kai IO_COST 1504


--Meta tin xrisi Indexes:
-- fainetai na einai to COST 1419 (μειωση), 364822653 CPU_COST, 1410 (IO_COST).


-- Products Table

CREATE INDEX idx_products_category_name ON products(category_name,product_id);

CREATE INDEX idx_cid on customers(customer_id);

-- Orders Table
CREATE INDEX idx_orders_days_to_process ON orders(days_to_process,customer_id);

-- Customers Table

CREATE INDEX idx_customers_income_level ON customers(income_level,gender,customer_id);

DROP INDEX idx_customers_income_level;
DROP INDEX idx_orders_days_to_process;
DROP INDEX idx_products_category_name;
DROP INDEX idx_cid;



