## RECORD COUNTS & DISTINCT VALUES

> 1. Which `actor_id` has the most number of unique `film_id` records in the `dvd_rentals.film_actor` table?
```postgresql
SELECT
    actor_id,
    COUNT(DISTINCT film_id) as film_count
FROM
     dvd_rentals.film_actor
GROUP BY
    actor_id
ORDER BY
    film_count DESC
LIMIT
    5;
```

> 2. How many distinct `fid` values are there for the 3rd most common `price` value in the `dvd_rentals.nicer_but_slower_film_list` table?
```postgresql
SELECT
    price,
    COUNT(DISTINCT fid) as number_of_fid
FROM
     dvd_rentals.nicer_but_slower_film_list
GROUP BY
    price
ORDER BY
    number_of_fid DESC
LIMIT
    3;
```

> 3. How many unique `country_id` values exist in the `dvd_rentals.city` table?
 ```postgresql
 SELECT
    COUNT(DISTINCT country_id) AS unique_country_count
FROM
    dvd_rentals.city;
 ```

> 4. What percentage of overall `total_sales` does the Sports `category` make up in the `dvd_rentals.sales_by_film_category` table?
```postgresql
SELECT
    category,
    ROUND(
        100.0 * total_sales / SUM(total_sales) OVER (),
        2) as percentage_sale
FROM
     dvd_rentals.sales_by_film_category;
```

> 5. What percentage of unique `fid` values are in the Children `category` in the `dvd_rentals.film_list` table?
```postgresql
SELECT
    category,
    ROUND(
        100.0 * COUNT(DISTINCT fid) / SUM(COUNT(DISTINCT fid)) OVER(),
        2) as unique_fid_percentage
FROM
    dvd_rentals.film_list
GROUP BY
    category
ORDEr BY
    category;
```