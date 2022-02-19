CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');


CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

--------------------------------------------------------------------------------------------------

-- Case Study Questions
-- 1. What is the total amount each customer spent at the restaurant
SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
--ORDER BY 2 DESC
;


-- 2. how many days has each customer visited the restaurant
SELECT customer_id, COUNT( DISTINCT order_date) n_days
FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer
WITH cte as (
    SELECT customer_id, product_id,
           row_number() over(partition by customer_id order by order_date) as row_number
    FROM sales )
SELECT c.customer_id, m.product_name
FROM cte c INNER JOIN menu m
ON c.product_id = m.product_id AND c.row_number = 1
;

--4. What is the most purchased item on the menu and How many times was it purchased by all customers?
SELECT m.product_name, COUNT(1) as total_order_count
FROM sales s INNER JOIN menu m on s.product_id = m.product_id
GROUP BY m.product_name;

--5. Which item was the most popular for each customer
WITH CTE AS (
    SELECT customer_id,
           product_name,
           COUNT(1) as total_orders,
        rank() over (partition by customer_id order by COUNT(product_name) desc) as row_num
    FROM sales s INNER JOIN dannys_diner.menu m
        ON s.product_id = m.product_id
    GROUP BY customer_id, product_name
)
SELECT customer_id, product_name, total_orders
FROM CTE
WHERE row_num = 1;

--6. Which item was purchased first by customer after they became a member?
SELECT customer_id, product_name, order_date, join_date
FROM (
     SELECT s.customer_id,
            product_name,
            order_date, join_date,
            rank() over (partition by s.customer_id order by order_date) as rank
     FROM sales s
              INNER JOIN dannys_diner.menu m
                  ON s.product_id = m.product_id
              INNER JOIN members mb
                  ON s.customer_id = mb.customer_id AND s.order_date >= mb.join_date
     ) S
WHERE rank = 1;

--7. Which item was purchased just before the became a member
SELECT customer_id, product_name, order_date, join_date
FROM (
     SELECT s.customer_id,
            product_name,
            order_date, join_date,
            rank() over (partition by s.customer_id order by order_date desc) as rank
     FROM sales s
              INNER JOIN dannys_diner.menu m
                  ON s.product_id = m.product_id
              INNER JOIN members mb
                  ON s.customer_id = mb.customer_id AND s.order_date < mb.join_date
     ) S
WHERE rank = 1;

--8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,
       COUNT(1) as total_items,
       SUM(price) as total_spend
FROM sales s INNER JOIN menu m
        ON s.product_id = m.product_id
    INNER JOIN members mb
        ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id
ORDER BY 1;

--9. How many points does each customer have, if for each $1 spent gets 10 points and sushi has 2x
--   points multiplier
WITH CTE AS (
    SELECT customer_id,
       product_name,
       price,
       CASE
            WHEN product_name = 'sushi' THEN 2
            ELSE 1
       END as multiplier
    FROM sales s INNER JOIN menu m
        ON s.product_id = m.product_id)
SELECT customer_id, SUM(price * multiplier * 10) as points
FROM CTE
GROUP BY customer_id
ORDER BY 2 DESC
;

--10. In the first week after a customer joins the program(including their joindate) They earn
--   2x points on all the items , not just sushi - how many points do customers A and B have at
--   end of January?
SELECT customer_id, SUM(price * multiplier * 10)
FROM
    (SELECT s.customer_id, product_name,
           price, order_date, join_date,
           CASE
                WHEN s.order_date - mb.join_date >= 0 AND s.order_date - mb.join_date < 7 THEN 2
                WHEN m.product_name = 'sushi' THEN 2
                ELSE 1
           END AS multiplier
    FROM sales s INNER JOIN menu m
            ON s.product_id = m.product_id
        INNER JOIN members mb
            ON mb.customer_id = s.customer_id) S
WHERE EXTRACT(month FROM order_date) = '01'
GROUP BY customer_id
ORDER BY 2 DESC ;


------------------------------------- Bonus Questions ----------------------------------------

-- Joining All the Things
WITH temp AS (
SELECT s.customer_id, s.order_date, m.product_name, m.price, mb.join_date
FROM sales s INNER JOIN menu m
        ON s.product_id = m.product_id
    LEFT JOIN members mb
        ON mb.customer_id = s.customer_id AND s.order_date >= mb.join_date)
SELECT customer_id, order_date, product_name,
       CASE
            WHEN join_date IS NOT NULL THEN 'Y'
            ELSE 'N'
       END AS member, price
FROM temp
ORDER BY 1,2;


-- Rank All the Things
WITH temp AS (
    SELECT s.customer_id,
           s.order_date,
           m.product_name,
           m.price,
           mb.join_date
    FROM sales s INNER JOIN menu m
            ON s.product_id = m.product_id
        LEFT JOIN members mb
            ON mb.customer_id = s.customer_id AND s.order_date >= mb.join_date),
temp2 AS (
    SELECT customer_id,
           order_date,
           product_name,
           price,
           join_date,
           CASE
                WHEN join_date IS NOT NULL THEN 'Y'
                ELSE 'N'
           END AS member
    FROM temp)
SELECT customer_id,
       order_date,
       product_name,
       price,
       member,
       CASE
            WHEN member ='Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
       END AS ranking
FROM temp2