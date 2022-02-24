CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

---------------------------------------------------------------------------------------------
-- REFINING TABLES--
-- drop table runner_orders_new
create table runner_orders_new
as select
    order_id,
    runner_id,
    CASE
        WHEN pickup_time = 'null' THEN NULL
        ELSE cast(pickup_time as timestamp)
    END AS pickup_time,
    CASE
        WHEN distance = 'null' THEN NULL
        ELSE CAST(split_part(distance,'km',1) AS float)
    END AS distance,
    CASE
        WHEN duration = 'null' THEN NULL
        ELSE CAST(split_part(duration,'min',1) AS int)
    END AS duration,
    CASE
        WHEN cancellation = 'null' THEN NULL
        WHEN cancellation = '' THEN NULL
        ELSE cancellation
    END AS cancellation
from runner_orders;

create table customer_orders_new as
select
    order_id,
    customer_id,
    pizza_id,
    CASE
        WHEN exclusions IS NULL THEN NULL
        WHEN exclusions = 'null' THEN NULL
        WHEN exclusions = '' THEN NULL
        ELSE string_to_array(exclusions, ',')
    END AS exclusions,
    CASE
        WHEN extras = '' THEN NULL
        WHEN extras = 'null' THEN NULL
        WHEN extras IS NULL THEN NULL
        ELSE string_to_array(extras, ',')
    END AS extras,
    order_time
from customer_orders;

-------------------------------------------------------------------------------------------
--------- A. Pizza Metrics
-- 1. How many pizzas were ordered?
select count(1) as n_pizzas_ordered
FROM customer_orders_new;

--2. How many unique customer orders were made?
select count(distinct order_id)
from customer_orders_new;

-- 3. how many successful orders were delivered by each runner?
SELECT runner_id, COUNT(1) as successful_orders_delivered
FROM runner_orders_new
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. how many of each type of pizza was delivered?
SELECT pizza_name, count(1)
FROM runner_orders_new ro
INNER JOIN customer_orders_new co
    ON ro.order_id = co.order_id AND cancellation IS NULL
INNER JOIN pizza_names pn
    ON co.pizza_id = pn.pizza_id
GROUP BY pizza_name;

-- 5. How many vegetarian and Meatlovers were ordered by each customer?
WITH temp as (
    SELECT customer_id,
           CASE WHEN pizza_name = 'Meatlovers' THEN 1 ELSE 0 END AS Meatlovers,
           CASE WHEN pizza_name = 'Vegetarian' THEN 1 ELSE 0 END AS Vegetarian
    FROM customer_orders_new co
             INNER JOIN pizza_names pn
                        ON co.pizza_id = pn.pizza_id
)
SELECT customer_id, SUM(Meatlovers) as Meatlovers, SUM(Vegetarian) as Vegetarian
FROM temp
GROUP BY customer_id
ORDER BY 1;

-- 6. What is the max number of pizzas delivered in a single order?
WITH TEMP AS (
    SELECT c_o.order_id, COUNT(1) as pizzas_ordered
    FROM customer_orders_new c_o INNER JOIN runner_orders_new r_o
        ON c_o.order_id = r_o.order_id AND r_o.cancellation IS NULL
    GROUP BY c_o.order_id)
SELECT MAX(pizzas_ordered)
FROM TEMP;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no change?
WITH TEMP AS (
    SELECT customer_id,
        CASE
            WHEN exclusions IS NULL AND extras IS NULL THEN 1
            ELSE 0
        END AS no_change
    FROM runner_orders_new ro inner join customer_orders_new co
        ON ro.order_id = co.order_id AND distance is NOT NULL
    )
SELECT customer_id,COUNT(1)-SUM(no_change) as changed, SUM(no_change) AS not_changed
FROM TEMP
GROUP BY customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(1) as PIZZAS_EXTRA_CUSTOMIZED
FROM runner_orders_new ro INNER JOIN customer_orders_new co
    ON ro.order_id = co.order_id AND ro.distance IS NOT NULL
WHERE co.exclusions IS NOT NULL AND co.extras IS NOT NULL;

-- 9. What are the total volume of pizzas ordered for each hour of the day?
WITH TEMP AS (
    SELECT EXTRACT(HOUR FROM order_time) as hour, 1 as col
    FROM customer_orders_new
)
SELECT hour, COUNT(1)
FROM TEMP
GROUP BY hour;
-- ORDER BY 2 DESC

-- 10. What was the volume of orders for each day of the week?
SELECT to_char(order_time, 'Day') day_of_week, COUNT(1) AS pizzas_ordered
FROM customer_orders_new
GROUP BY 1;

