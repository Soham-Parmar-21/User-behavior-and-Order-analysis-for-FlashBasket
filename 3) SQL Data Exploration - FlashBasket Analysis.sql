-- To check number of records imported 
Select Count(*) from orders;
Select Count(*) from users;

-- To view complete table
Select * from orders;
Select * from users;

-- Total number of orders and users
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM users;
SELECT COUNT(DISTINCT user_id) FROM orders; -- To check whether all users have made orders this month

SELECT * 
FROM users
WHERE user_id NOT IN (SELECT DISTINCT user_id FROM orders); -- Output Null

-- Orders by location
SELECT location, count(*) as count
FROM orders
GROUP BY location
ORDER BY count(*) DESC;

-- Total orders and total spend by gender
SELECT u.gender, count(o.order_id) as total_orders,
   ROUND(sum(o.total_price),2) as total_spent
FROM users u right join orders o on u.user_id=o.user_id
GROUP BY u.gender;


-- Gender wise preference order of payment methods
SELECT u.gender, o.payment_type, count(*) as usage_count 
FROM orders o left join users u on o.user_id = u.user_id
GROUP BY u.gender, o.payment_type
ORDER BY u.gender ASC, usage_count DESC;


-- Top 10 customers by total_amount_spent
SELECT user_id, user_name, ROUND(SUM(total_price),2) as total_amount_spent
FROM orders
GROUP BY user_id, user_name
ORDER BY sum(total_price) DESC
LIMIT 10;

-- Average order value by city
With city_orders as (
SELECT location, 
DATE_FORMAT(STR_TO_DATE(order_datetime,"%c/%e/%Y %H:%i"), "%Y-%m") as month,
total_price
FROM orders
)
SELECT location as city, month,
 ROUND(AVG(total_price),2) as avg_order_value
FROM city_orders
GROUP BY city, month
ORDER BY avg_order_value DESC;

-- Average delivery time per city
SELECT 
  location as city, 
  AVG(
  TIMESTAMPDIFF(
      MINUTE, 
      STR_TO_DATE(order_datetime, '%c/%e/%Y %H:%i'), 
      STR_TO_DATE(delivery_time, '%c/%e/%Y %H:%i')
    )
  ) AS avg_delivery_time_in_minutes
FROM orders
WHERE order_datetime IS NOT NULL AND delivery_time IS NOT NULL  -- to only consider completed deliveries for this month
GROUP BY location;

-- Count of Repeat vs One time users
SELECT  
  CASE 
    WHEN total_orders=1 THEN 'One-Time User'
    ELSE 'Repeat Users'
   END AS user_type, 
   count(*) as user_count
FROM (SELECT user_id, count(*) as total_orders FROM orders GROUP BY user_id) as temp
GROUP BY user_type;


-- Top 10 high spending users along with their user details
SELECT u.user_id, u.user_name, u.email, u.phone, u.dob, 
       u.gender, Round(sum(o.total_price),2) as total_amount_spent
FROM orders o left join users u 
ON o.user_id = u.user_id
GROUP BY u.user_id, u.user_name, u.email, u.phone, u.dob, u.gender
ORDER BY total_amount_spent DESC
LIMIT 10;

-- Rank users by monthly spent using window functions
WITH req_cte as (
SELECT user_id, user_name, DATE_FORMAT(STR_TO_DATE(order_datetime,'%c/%e/%Y %H:%i'),'%Y-%m') as month, 
       ROUND(SUM(total_price),2) as total_monthly_spent
FROM orders
GROUP BY user_id, user_name, month
)
SELECT user_id, user_name, month, total_monthly_spent,
      RANK() OVER ( PARTITION BY month ORDER BY total_monthly_spent DESC) As monthly_spent_rank
FROM req_cte;


-- Monthly orders trend
SELECT 
  DATE_FORMAT(STR_TO_DATE(order_datetime, '%c/%e/%Y %H:%i'), '%Y-%m') AS month,
  COUNT(*) AS total_orders
FROM orders
WHERE order_datetime IS NOT NULL
GROUP BY month
ORDER BY month;

-- Average order value by payment method by gender
SELECT  o.payment_type, round(sum(o.total_price),2) as avg_order_value
FROM orders o left join users u 
ON o.user_id = u.user_id
GROUP BY o.payment_type;

-- First and Last order dates per user
SELECT user_id, user_name, MIN(order_datetime) as first_order_date,
	MAX(order_datetime) as last_order_date, COUNT(*) as total_orders
FROM orders 
GROUP BY user_id, user_name
ORDER BY total_orders DESC;

-- Most popular purchase day
SELECT DAYNAME(STR_TO_DATE(order_datetime, '%c/%e/%Y %H:%i')) AS Day_name,
       count(*) as total_orders
FROM orders
GROUP BY Day_name
ORDER BY total_orders DESC;

-- User Activiy Since Signup 
SELECT o.user_id, o.user_name,
DATEDIFF(
MAX(STR_TO_DATE(o.order_datetime,'%c/%e/%Y %H:%i' )),  
STR_TO_DATE(u.signup_date,'%c/%e/%Y %H:%i' )) 
AS days_active
FROM orders  o left join users u
on o.user_id = u.user_id
GROUP BY o.user_id, o.user_name, u.signup_date
ORDER BY days_active DESC;

-- Age wise user analysis
WITH cte as (
SELECT o.user_id, o.user_name, o.total_price,
     FLOOR(DATEDIFF(CURDATE(),STR_TO_DATE(dob,"%c/%e/%Y %H:%i"))/365) as user_age
FROM orders o left join users u on o.user_id = u.user_id
)
SELECT  
  CASE 
     WHEN user_age <=25 THEN "Young Ones"
     WHEN user_age > 40 THEN "Senior"
     ELSE "Adult"
END AS user_age_group, count(*) as user_count, ROUND(AVG(total_price),2) as average_spent
FROM cte
GROUP BY user_age_group
ORDER BY user_count DESC;


