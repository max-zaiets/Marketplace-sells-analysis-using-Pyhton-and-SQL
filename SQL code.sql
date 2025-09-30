-- Creating a new table with optimized data types to reduce memory usage before loading data from the dataset

CREATE TABLE df_orders (             
    order_id INT PRIMARY KEY,
    order_date DATE,
    ship_mode VARCHAR(20),
    segment VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(20),
    state VARCHAR(20),
    postal_code VARCHAR(20),
    region VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_id VARCHAR(50),
    quantity INT,
    discount DECIMAL(7,2),
    sale_price DECIMAL(7,2),
    profit DECIMAL(7,2)
);

----------------------------------------------------------
-- 1. Find top 10 products by revenue
----------------------------------------------------------
select top 10 
       product_id, 
       sum(sale_price) as sales
from df_orders
group by product_id
order by sum(sale_price) desc;


----------------------------------------------------------
-- 2. Find top 5 best-selling products in each region
----------------------------------------------------------
with cte as (
    select region,
           product_id,
           sum(sale_price) as sales
    from df_orders
    group by region, product_id
)
select region, product_id, sales
from (
    select *,
           row_number() over(partition by region order by sales desc) as rn
    from cte
) a
where rn <= 5;


----------------------------------------------------------
-- 3. Compare month-over-month sales for 2022 vs 2023
----------------------------------------------------------
with cte as (
    select year(order_date) as order_year,
           month(order_date) as order_month,
           sum(sale_price) as sales
    from df_orders
    group by year(order_date), month(order_date)
)
select order_month,
       sum(case when order_year = 2022 then sales else 0 end) as sales_2022,
       sum(case when order_year = 2023 then sales else 0 end) as sales_2023
from cte
group by order_month
order by order_month;


----------------------------------------------------------
-- 4. For each category, find the month with the highest sales
--    (use numeric year*100+month instead of FORMAT for performance)
----------------------------------------------------------
with cte as (
    select category,
           year(order_date) * 100 + month(order_date) as order_year_month,
           sum(sale_price) as sales
    from df_orders
    group by category, year(order_date), month(order_date)
)
select category, order_year_month, sales
from (
    select *,
           row_number() over(partition by category order by sales desc) as rn
    from cte
) a
where rn = 1;


----------------------------------------------------------
-- 5. Find the sub-category with the highest revenue growth
--    in 2023 compared to 2022
--    (replace sale_price with profit if profit growth is needed)
----------------------------------------------------------
with cte as (
    select sub_category,
           year(order_date) as order_year,
           sum(sale_price) as sales
    from df_orders
    group by sub_category, year(order_date)
)
, cte2 as (
    select sub_category,
           sum(case when order_year = 2022 then sales else 0 end) as sales_2022,
           sum(case when order_year = 2023 then sales else 0 end) as sales_2023
    from cte 
    group by sub_category
)
select top 1 
       sub_category,
       sales_2022,
       sales_2023,
       (sales_2023 - sales_2022) as growth
from cte2
order by growth desc;