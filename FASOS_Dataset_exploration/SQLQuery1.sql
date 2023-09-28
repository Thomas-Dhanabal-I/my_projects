==============================================================================================================
--------------------------FASOS Micro Dataset cleaning and exploration----------------------------------------
==============================================================================================================

USE FASOS

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1.How many rolls were ordered?
select count(roll_id) as cnt from  customer_orders 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--2.How many unique customer orders were made ?
select count(distinct(customer_id)) from customer_orders

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--3.How many successful orderes delivered by each driver ?
select driver_id,count(order_id) as total_orders
from driver_order
where cancellation not in ('Cancellation' , 'Customer Cancellation') group by driver_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--4.How many of each type of rolls was delivered?

select roll_id,count(order_id) as tot from(
select * from
(select a.order_id,a.roll_id,b.cancellation,
case when cancellation  in ('Cancellation' , 'Customer Cancellation') then 'c' else 'nc'  end as cx_status
from customer_orders a left join driver_order b on a.order_id=b.order_id) x
where cx_status <>'c')y
group by roll_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--5.How many veg and non beg rolls were ordered by each customer?
select x.*,y.roll_name from(
select customer_id,roll_id,count(1) as cnt from customer_orders group by customer_id,roll_id 
)x
left join rolls y on x.roll_id=y.roll_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--6.What was the maximum number of rolls delivered in single order?

select order_id,count(1) as cnt
from(
select a.order_id,b.cancellation,
case when cancellation  in ('Cancellation' , 'Customer Cancellation') then 'c' else 'nc'  end as cx_status
from customer_orders a left join driver_order b on a.order_id=b.order_id )x
where cx_status='nc' 
group by order_id)y

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--7.For each customer,How many delivered rolls had atleast 1 change and how many had no change ?

with temp_customer_orders as
		(select order_id	,customer_id,roll_id,
		case when not_include_items is null or not_include_items=' ' then '0' else not_include_items end as not_include_items,
		case when extra_items_included is null or extra_items_included=' ' or extra_items_included='NaN' then '0' else extra_items_included end as extra_items_included
		from customer_orders),
    temp_driver_order as
		(select order_id,driver_id,pickup_time,distance,duration,
		case when cancellation is null or cancellation ='NaN' or cancellation=' ' then 0 else 1 end as cancellation
		from driver_order)

select customer_id,sts,count(1) as total
from
(select a.*,b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,
case when not_include_items='0' and extra_items_included='0' then 'usual' else 'change' end as sts
from temp_customer_orders a 
left join  temp_driver_order b on a.order_id=b.order_id)x
group by customer_id,sts order by customer_id,sts

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--8.How many rolls were delivered with both inclusions and exclusions in ingredients?
with temp_customer_orders as
		(select order_id	,customer_id,roll_id,
		case when not_include_items is null or not_include_items=' ' then '0' else not_include_items end as not_include_items,
		case when extra_items_included is null or extra_items_included=' ' or extra_items_included='NaN' then '0' else extra_items_included end as extra_items_included
		from customer_orders),
    temp_driver_order as
		(select order_id,driver_id,pickup_time,distance,duration,
		case when cancellation is null or cancellation ='NaN' or cancellation=' ' then 0 else 1 end as cancellation
		from driver_order)
select count(*) as 'No of rolls were delivered with both inclusions and exclusions in ingredients'
from temp_customer_orders a 
left join  temp_driver_order b on a.order_id=b.order_id
where not_include_items <> '0' and extra_items_included <> '0'

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--9.What was the total number of rolls ordered for each hour of the day ?
select hr_bucket,count(1) as tot
from
(select *,concat(cast(DATEPART(hour,order_date) as varchar),'-',cast(DATEPART(hour,order_date)+1 as varchar)) as hr_bucket
from customer_orders)x
group by hr_bucket

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--10.What was the total orders for each day of week ?

select day_,count(distinct order_id) as tot
from
(select *,DATEPART(dw,order_date) as day_
from customer_orders)x
group by day_

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

----some values are printed mistaken..so changing as per that
UPDATE driver_order
SET pickup_time = DATEADD(year, 1, pickup_time)
WHERE order_id IN (
    SELECT TOP 4 order_id
    FROM driver_order
    ORDER BY order_id DESC
)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--11.What was the average time in minutes it took for each driver to arrive at the FASOOS HQ 
--to pick up the order ?

select AVG(diff) avg_min from
(select datediff(minute,a.order_date,b.pickup_time) diff
from customer_orders a
join driver_order b on a.order_id=b.order_id
where pickup_time is not null)x

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--12.Is there any relationship between no.of rolls and how long the order takes to prepare?

select order_id,count(roll_id) cnt,avg(diff) time_
from(
select a.* ,b.pickup_time,datediff(minute,a.order_date,b.pickup_time) diff
from customer_orders a
join driver_order b on a.order_id=b.order_id
where b.pickup_time is not null)x
group by order_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--13.What was the avg distance travelled for each customer?

select customer_id,avg(distance) as avg_distance from
(select a.customer_id,
cast(trim(replace(lower(b.distance),'km','')) as float) as distance
from customer_orders a 
join driver_order b on a.order_id=b.order_id
where b.distance is not null)x
group by customer_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--14.What was the difference between the longest and shortest delivery times for all orders?

select max(time_diff)-min(time_diff) as diff from
(select order_id,cast(time_diff as float) time_diff
from(
select order_id,
case 
	when duration like '%min%' then left(duration,CHARINDEX('m',duration)-1) else duration
end as time_diff
from driver_order
where duration is not null)x)y

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--15.What was the avg speed of driver for each delivery?Do u notice any trends?
select a.*,b.cnt_of_rolls from(
select order_id,driver_id,distance/cast(duration as float) as speed from(
select order_id,driver_id,cast(trim(replace(distance,'km','')) as float) as distance,
case 
	when duration like '%min%' then left(duration,CHARINDEX('m',duration)-1) else duration
end as duration
from
(select order_id,driver_id,distance,duration
from driver_order
where duration is not null )x)y)a
join 
(select order_id,count(roll_id) as cnt_of_rolls
from customer_orders
group by order_id)b on a.order_id=b.order_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--16.What is the successfull delivery percentage of each driver ?

with t1 as
(select * ,
case 
	when cancellation in ('Cancellation' , 'Customer Cancellation') then 0 else 1
end as cancel_sts
from driver_order ),
t2 as
(select  driver_id,cast(count(cancel_sts)as float) as cnt,cast(sum(cancel_sts) as float)as tot
from t1
group by driver_id)
select driver_id,tot/cnt*100  from t2
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

