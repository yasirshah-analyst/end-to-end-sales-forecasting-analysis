create table weekly_sales_raw(
	store INT,
    sale_date_text VARCHAR(20),
    weekly_sales NUMERIC(12,2),
    holiday_flag INT,
    temperature NUMERIC(5,2),
    fuel_price NUMERIC(5,3),
    cpi NUMERIC(10,4),
    unemployment NUMERIC(5,2)
);

select * from weekly_sales_raw;

CREATE TABLE weekly_sales AS
SELECT
    store,
    TO_DATE(sale_date_text, 'DD-MM-YYYY') AS sale_date,
    weekly_sales,
    holiday_flag::BOOLEAN,
    temperature,
    fuel_price,
    cpi,
    unemployment
FROM weekly_sales_raw;

select * from weekly_sales;

-- Add the composite key back (store + date together must be unique)
alter table weekly_sales
add primary key (store,sale_date);

-- Each store should only have one row per week
select store,sale_date,count(*)
from weekly_sales
group by store,sale_date
having count(*) > 1;

select count(*) from weekly_sales;

select min(sale_date),max(sale_date)
from weekly_sales;

SELECT * FROM weekly_sales ORDER BY sale_date LIMIT 5;

-- Check 1: Missing values
SELECT
    COUNT(*) FILTER (WHERE store IS NULL) AS missing_store,
    COUNT(*) FILTER (WHERE sale_date IS NULL) AS missing_date,
    COUNT(*) FILTER (WHERE weekly_sales IS NULL) AS missing_sales,
    COUNT(*) FILTER (WHERE holiday_flag IS NULL) AS missing_holiday_flag,
    COUNT(*) FILTER (WHERE temperature IS NULL) AS missing_temp,
    COUNT(*) FILTER (WHERE fuel_price IS NULL) AS missing_fuel,
    COUNT(*) FILTER (WHERE cpi IS NULL) AS missing_cpi,
    COUNT(*) FILTER (WHERE unemployment IS NULL) AS missing_unemployment
FROM weekly_sales;

-- Check 2: Negative or impossible values
SELECT * FROM weekly_sales WHERE weekly_sales <= 0;
SELECT * FROM weekly_sales WHERE fuel_price <= 0;
SELECT * FROM weekly_sales WHERE unemployment < 0 OR unemployment > 30;
SELECT * FROM weekly_sales WHERE temperature < -30 OR temperature > 120;  -- extreme outlier bounds, not "negative = bad"
SELECT * FROM weekly_sales WHERE cpi <= 0;

-- Check 3: Row count per store
select store,count(*) as weeks_recorded
from weekly_sales
group by store;

-- How has total company-wide revenue changed month by month?
-- Is there a repeating pattern across the year?
select
	date_trunc('month',sale_date) as month,
	sum(weekly_sales) as total_sales
from weekly_sales
group by date_trunc('month',sale_date)
order by month;

-- Are sales actually higher on the specific weeks marked as holidays, compared to regular weeks?
-- and if so, by how much?
select
	holiday_flag,
	avg(weekly_sales) as avg_weekly_sales,
	count(*) as num_weeks
from weekly_sales
group by holiday_flag;

-- The overall 'holiday effect' was only 8%
-- Is that because every holiday adds a small bump?
-- Or because one big holiday is doing most of the work and the rest add almost nothing?
select 
	sale_date,
	avg(weekly_sales)
from weekly_sales
where holiday_flag = 'true'
group by sale_date
order by sale_date;

-- Does the same monthly pattern (December high, January low) repeat consistently every year?
-- Or could 2010's pattern have been a one-time fluke?
select
	extract (year from sale_date) as year,
	extract (month from sale_date) as month,
	sum(weekly_sales) as total_sales
from weekly_sales
group by 
	extract (year from sale_date),
	extract (month from sale_date)
order by
	month,year;

-- Find Top 5 and stores
select
	store, 
	avg(weekly_sales) as avg_sales
from weekly_sales
group by store
order by avg_sales desc
limit 5;

-- Find bottom 5 and stores
select
	store, 
	avg(weekly_sales) as avg_sales
from weekly_sales
group by store
order by avg_sales asc
limit 5;