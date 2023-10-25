CREATE TABLE churn_data (
  customer_id INT,
  churn INT,
  tenure INT,
  preferred_login_device TEXT,
  city_tier INT,
  warehouse_to_home INT,
  preferred_payment_mode TEXT,
  gender TEXT,
  hour_spend_on_app INT,
  number_of_device_registered INT,
  prefered_order_cat TEXT,
  satisfaction_score INT,
  marital_status TEXT,
  number_of_address FLOAT,
  complain FLOAT,
  order_amount_hike_from_last_year FLOAT,
  coupon_used FLOAT,
  order_count float,
  day_since_last_order float,
  cashback_amount FLOAT
  );

select *
from churn_data

--DATA CLEANING

-- 1. Find the total number of customers
select count(customer_id) as total_customers
from churn_data;
-- there are 5630 customers

-- 2. Check duplicate rows
select 
	customer_id,
	count(customer_id)
from churn_data
group by 1
having count(customer_id) > 1;
-- there are no duplicate rows

-- 3. Check for null values count for columns with null values
SELECT 'tenure' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE tenure IS NULL 
UNION
SELECT 'warehouse_to_home' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE warehouse_to_home IS NULL 
UNION
SELECT 'hour_spend_on_app' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE hour_spend_on_app IS NULL
UNION
SELECT 'order_amount_hike_from_last_year' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE order_amount_hike_from_last_year IS NULL 
UNION
SELECT 'coupon_used' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE coupon_used IS NULL 
UNION
SELECT 'order_count' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE order_count IS NULL 
UNION
SELECT 'day_since_last_order' as column_name, COUNT(*) AS NullCount 
FROM churn_data
WHERE day_since_last_order IS NULL; 

--3.1 Handle null values and fill it with their mean
UPDATE churn_data
SET tenure = (SELECT AVG(tenure) FROM churn_data)
WHERE tenure IS NULL

UPDATE churn_data
SET warehouse_to_home = (SELECT AVG(warehouse_to_home) FROM churn_data)
WHERE warehouse_to_home IS NULL

UPDATE churn_data
SET hour_spend_on_app = (SELECT AVG(hour_spend_on_app) FROM churn_data)
WHERE hour_spend_on_app IS NULL

UPDATE churn_data
SET order_amount_hike_from_last_year = (SELECT AVG(order_amount_hike_from_last_year) FROM churn_data)
WHERE order_amount_hike_from_last_year IS NULL

UPDATE churn_data
SET coupon_used = (SELECT AVG(coupon_used) FROM churn_data)
WHERE coupon_used IS NULL

UPDATE churn_data
SET order_count = (SELECT AVG(order_count) FROM churn_data)
WHERE order_count IS NULL

UPDATE churn_data
SET day_since_last_order = (SELECT AVG(day_since_last_order) FROM churn_data)
WHERE day_since_last_order IS NULL

-- 4. Create new column
-- 4a. customer_status
alter table churn_data
add customer_status text;

update churn_data
set customer_status = 
case 
    when Churn = 1 then 'Churned' 
    when Churn = 0 then 'Stayed'
end;

-- 4b. customer complain_recieved
alter table churn_data
add complain_recieved text;

update churn_data
set complain_recieved =
case
	when complain = 1 then 'Yes'
	when complain = 0 then 'No'
end;

-- 5. Check values in each column for correctness and accuracy
-- 5a. Inspect preferred_login_device column
select distinct preferred_login_device
from churn_data;
-- there are mobile phone and phone whic is the same
update churn_data
set preferred_login_device = 'Phone'
where preferred_login_device = 'Mobile Phone';

-- 5b. Inspect prefered_order_cat column
select distinct prefered_order_cat
from churn_data;
--replace mobile to mobile phone
update churn_data
set prefered_order_cat = 'Mobile Phone'
where prefered_order_cat = 'Mobile';

--5c. Inspect preferred_payment_mode column
select distinct preferred_payment_mode
from churn_data;
--replace COD to Cash on Delivery
update churn_data
set preferred_payment_mode = 'Cash on Delivery'
where preferred_payment_mode = 'COD';

-- 5d. Inspect warehouse_to_home column
select distinct warehouse_to_home
from churn_data;

-- how to find outlier
with Quartiles as (
select 
    percentile_cont(0.25) within (order by warehouse_to_home) as Q1,
	percentile_cont(0.75) within group (order by warehouse_to_home) as Q3
from churn_data
)

select
    round(Q1 - k * (Q3 - Q1)) as Lower_Threshold,
    round(Q3 + k * (Q3 - Q1)) as Upper_Threshold
from
    Quartiles
cross join
    (select 1.5 as k) as Multiplier;
-- Lower_Threshold = -8 and Upper_Threshold = 36
--## A cross join generates a result set 
--## where each row from table1 is combined 
--## with every row from table2. If table1 has m rows 
--## and table2 has n rows, the result will contain m * n rows.

-- check outlier where warehouse_to_home > upper_threshold (36) 
select warehouse_to_home 
from churn_data
where warehouse_to_home > 36;

-- we can see two values 126 and 127 that are outliers, it could be a data entry error, so we can correct it to 26 & 27 respectively
update churn_data
set warehouse_to_home = 26
where warehouse_to_home = 126;

update churn_data
set warehouse_to_home = 27
where warehouse_to_home = 127;

-- Exploratory Data Analysis

--1. What is the overall customer churn rate?
--Churn Rate = ((Number of Customers at the Beginning of the Period - Number of Customers at the End of the Period) 
--/ Number of Customers at the Beginning of the Period)*100
select 
	NumberofCustomers,
	TotalNumberofCustomersChurn,
	round((TotalNumberofCustomersChurn*1.0/NumberofCustomers*1.0)*100, 2) AS ChurnRate
	--(1.0)performed as a floating-point division rather than integer division, which helps retain decimal places in the result.
from
(SELECT COUNT(customer_id) as NumberofCustomers
from churn_data) as Total,
(select count(customer_id) as TotalNumberofCustomersChurn
from churn_data 
where customer_status = 'Churned') as Churned
-- Churnrate 16.84%

-- 2. How does the churn rate vary based on the preferred login device?
select 
	preferred_login_device,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1;
-- churnrate computer = 19.83%, phone = 15.26%

-- 3. What is the distribution of customers across different city tiers?
select 
	city_tier,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
--city_tier3 = 21.37% city_tier2 = 19.83% city_tier1 = 14.51%

-- 4. Is there any correlation between the warehouse-to-home distance and customer churn?
-- create another column by the range of the warehouse-to-home
alter table churn_data
add warehousetohome_range TEXT;

update churn_data
set warehousetohome_range =
case
	when warehouse_to_home <= 10 then 'Very close distance'
	when warehouse_to_home > 10 and warehouse_to_home <= 20 then 'Close distance'
	when warehouse_to_home > 20 and warehouse_to_home <= 30 then 'Moderate distance'
	when warehouse_to_home > 30 then 'Far distance'
end;

select 
	warehousetohome_range,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- as the range increase the churnrate increase

-- 5. Which is the most prefered payment mode among churned customers?
select 
	preferred_payment_mode,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
--most preferred payment mode is Cash on Delivery

-- 6. What is the typical tenure for churned customers?
alter table churn_data
add tenure_range text;

update churn_data
set tenure_range =
case
	when tenure <= 6 then '6 Months'
	when tenure >6 and tenure <= 12 then '1 Years'
	when tenure >= 12 and tenure <= 24 then '2 Years'
	when tenure >24 then 'more than 2 Years'
end;

select 
	tenure_range,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- moset customer churn with in 6 months

-- 7. Is there any difference in churn rate between male and female customers?
select 
	gender,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- more male customers churn than female 

-- 8. How does the average time spent on the app differ for churned and non-churned customers?
select 
	customer_status,
	avg(hour_spend_on_app) as hourspendonapp
from churn_data
group by 1;
--There is no different time spent on app between churned and non-churned customer
	
-- 9. Does the number of registered devices impact the likelihood of churn?
select 
	number_of_device_registered,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
--as the number of registered devices increase the churn rate increase

-- 10. Which order category is most prefered among churned customers?
select 
	prefered_order_cat,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
--most prefered order category is Mobile Phone

-- 11. Is there any relationship between customer satisfaction scores and churn?
select 
	satisfaction_score,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- as icrease of satisfaction score the churn rate increase

-- 12. Does the marital status of customers influence churn behavior?
select 
	marital_status,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- single marital status have the highest churn rate while married customers have the lowest churn rate

-- 13. How many addresses do churned customers have on average?
select 
	avg(number_of_address) as Averagenumofchurnedcustomeraddress
from churn_data
where customer_status = 'Churned';
-- on average, churned customers have 4 addresses


-- 14. Does customer complaints influence churned behavior?
select 
	complain,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- customers with complains had the highest churn rate

-- 15. How does the usage of coupons differ between churned and non-churned customers?
select 
	customer_status,
	sum(coupon_used)
from churn_data
group by 1;
-- churned customers used less coupons in comparison to non-churned customers

-- 16. What is the average number of days since the last order for churned customers?
select 
	avg(day_since_last_order)
from churn_data
where customer_status = 'Churned'
-- the average number of days since last order for churned customer is 3

-- 17. Is there any correlation between cashback amount and churn rate?
alter table churn_data
add cashbackamount_range text;

update churn_data
set cashbackamount_range =
CASE 
    when cashback_amount <= 100 then 'Low Cashback Amount'
    when cashback_amount > 100 and cashback_amount <= 200 then 'Moderate Cashback Amount'
    when cashback_amount > 200 and cashback_amount <= 300 then 'High Cashback Amount'
    when cashback_amount > 300 then 'Very High Cashback Amount'
end

select 
	cashbackamount_range,
	count(customer_id) as total_customer,
	sum(churn) as churncustomer,
	round((sum(churn)*1.0/count(customer_id)*1.0)*100,2) as ChurnRate
from churn_data
group by 1
order by 4 desc;
-- customers with a 'Moderate Cashback Amount' have the highest churn rate, follwed by
-- high cashback amount, then very high cashback amount and finally low cashback amount
-- there are no corellation of increasing cashbcak amount and churn rate