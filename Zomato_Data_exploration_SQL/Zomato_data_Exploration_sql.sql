==============================================================================================
---------------------------------ZOMATO DATA EXPLORATION------------------------------------
==============================================================================================

use zomato

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

ALTER TABLE product
ALTER COLUMN product_name CHAR(50)

--1.what is the total amount of each customer spent on zomato ?

select userid,sum(price) as total_amnt_spent
from sales a 
join product b on a.product_id =b.product_id 
group by userid

--2.how many days has each customer visited zomato ?

select userid,count(distinct created_date ) as no_of_days_visited
from sales 
group by userid

--3.what was the first product purchased by each customer?

select  *
from
(select *,
rank() over( partition by userid order by created_date) as rk
from sales )x
where rk=1

--4.what is the most purchased item and how many time was it purchased by all customers?

select product_id,count(userid) as userid
from sales
group by product_id
order by count(userid) desc

--5.which item was more popular for each customer?

select * from
(select *,rank() over (partition by userid order by cnt desc)  rk 
from (select userid,product_id,count(1) as cnt 
from sales 
group by userid,product_id)x)y
where rk=1

-----6.which item was purchased first by custoer after they become a member?

select * from 
(select * ,rank() over (partition by userid order by created_date) as rk
from(
select a.userid,created_date,product_name ,gold_signup_date
from sales a 
join product b on a.product_id = b.product_id 
join goldusers_signup c on a.userid=c.userid
where gold_signup_date<created_date)x)y where rk=1

-----7.which item was purchased just before they become a member?

select * from(
select * ,rank() over (partition by userid order by created_date desc) as rk
from
(select a.userid,created_date,product_id ,gold_signup_date
from sales a 
join goldusers_signup b on a.userid=b.userid 
where created_date<gold_signup_date)x)y
where rk=1

--8.what is the total orders and amount spent for each member before they became member?

with cte as
(select a.userid,created_date,product_name,price,gold_signup_date
from sales a
join product b on a.product_id=b.product_id
join goldusers_signup c on a.userid=c.userid
where created_date<=gold_signup_date),
cte1 as
(select *,
count(1) over (partition by userid order by userid ) as cnt,
sum(price) over (partition by userid order by userid) as tot_price
from cte)
select distinct userid,cnt,tot_price from cte1

---9.if buying each product generates points,calculate points collected by each customer
-- p1-->(5 rs=1 point),p2-->(10 rs=5 point),p3-->(5 rs=1 point) .if customer have 2 zomato point,they'll get 5rs cashback.

----------------points collected by each customer----------------------------
with cte as
(select userid,product_name,sum(price) as price
from sales a
join product b on a.product_id=b.product_id
group by userid,product_name),
cte2 as 
(select *,
case when product_name='p1' then price/5  
	 when product_name='p2' then price/10 * 5
	 when product_name='p3' then price/5 
end as points
from cte)
select userid,sum(points)*2.5 as total_cashbacks
from cte2
group by userid
	
----------------points collected by each product----------------------------
with cte as
(select userid,product_name,sum(price) as price
from sales a
join product b on a.product_id=b.product_id
group by userid,product_name),
      cte2 as 
(select *,
case when product_name='p1' then price/5  
	 when product_name='p2' then price/10 * 5
	 when product_name='p3' then price/5 
end as points
from cte),
       cte3 as
(select product_name,sum(points) as total_points
from cte2
group by product_name),
       cte4 as
(select *,
rank() over (order by total_points desc) as rk
from cte3)
select * from cte4 where rk=1

--10.In the first one year after customer joins the gold program (including their join date) irrespective of what customer 
--has purchased they earn 5 points for every 10rs spent. who earned more cus1 or cus3? and what was their points earning 
--in their first year

select * ,rank() over (order by points desc) as rnk
from(
select a.userid,created_date,product_name ,price,gold_signup_date,price*0.5 as points
from sales a 
join product b on a.product_id = b.product_id 
join goldusers_signup c on a.userid=c.userid
where gold_signup_date<=created_date and created_date<=dateadd(day,365,gold_signup_date))x

--11.rank all the transaction of customers 
select * , rank() over (partition by userid order by created_date ) as rank from sales

--12.rank all the transaction after customer become a gold member..mark transaction before gold member as NA
with cte as
(select a.* ,b.gold_signup_date,
case when 
	created_date<gold_signup_date or gold_signup_date is null then 'NA' else 'gold_membership_transaction' 
end as status_
from sales a
LEFT JOIN goldusers_signup b on a.userid=b.userid),
cte2 as
(select * ,rank() over (partition by userid order by created_date ) as rnk
from cte where status_='gold_membership_transaction' )
select * , 
case when rnkk = 0 then 'na' else cast(rnk as varchar) end as rank_
from(
select *,COALESCE(rnk,0) as rnkk 
from(select cte.*,cte2.rnk from cte left join cte2 on cte.created_date=cte2.created_date)x 
)y
order by userid,created_date