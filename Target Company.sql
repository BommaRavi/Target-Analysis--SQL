/********************************************************************
Name: Business case for Target company
Author : Aspiring Data scientist---Ravindra Reddy
Date  : 15/Nov/2022

Purpose: This script will give Insights and recommendations from data received
			one of the american largest retail company. i.e, Target
************************************************************************/

--Steps followed to import the data
/*********
1.Downloaded the dataset from the google drive and all are those in the .csv format.
2.Changed all the file formats into .xls format in my local drive of my computer.
3.Created the Database in SQL Server as 'Target Company Analysis'
4.Import all the datasets which are converted into .xls format into 'Target Company Analysis'
 database such as customers,geolocation,order_items,
 order_reviews,orders,payments,products,sellers
*****/
USE [ Target Company Analysis] 
GO

select * from [dbo].[customers]
select * from [dbo].[geolocation]
select * from [dbo].[order_items]
select * from [dbo].[order_reviews]
select * from [dbo].[orders]
select * from [dbo].[payments]
select * from [dbo].[products]
select * from [dbo].[sellers]

/**************************************
1. Import the dataset and do usual exploratory analysis steps like 
checking the structure & characteristics of the dataset

1. Data type of columns in a table:-

Customers table,Geolocation,Order_items,Payments,Products and Sellers:- nvarchar and float 
Order_reviews:- nvarchar, float and datetime
Orders:- nvarchar and datetime

****************************************/


--2. Time period for which the data is given
select top (1) [order_purchase_timestamp] from [dbo].[orders]
order by 1 asc
--Customer order first order date:- 2016-09-04 21:15:19.000
select top (1) [order_purchase_timestamp] from [dbo].[orders]
order by 1 desc
--Customer order last order date:- 2018-10-17 17:30:18.000

--3. Cities and States of customers ordered during the given period
select [customer_city], [customer_state]
from [dbo].[customers] as c
join [dbo].[orders] as o 
on c.customer_id = o.customer_id
where o.[order_purchase_timestamp] is not null
group by [customer_city], [customer_state]
order by [customer_city]


--2. In-depth Exploration:
/* 
1. Is there a growing trend on e-commerce in Brazil? 
How can we describe a complete scenario? 
Can we see some seasonality with peaks at specific months? */
select year([order_purchase_timestamp]) as year,
month([order_purchase_timestamp]) as month, count(*) as total_count
from  [dbo].[orders] 
group by year([order_purchase_timestamp]), month([order_purchase_timestamp])
order by year([order_purchase_timestamp]), month([order_purchase_timestamp])

/* What time do Brazilian customers tend to buy (Dawn, Morning, Afternoon or Night)? */
select time, count(time) from (select
case
   when datepart(hour, [order_purchase_timestamp]) between 7 and 12 
      then 'Morning' 
   when datepart(hour,  [order_purchase_timestamp]) between 12 and 18 
      then 'Afternoon' 
	when datepart(hour,  [order_purchase_timestamp]) between 4 and 7 
      then 'Dawn' 
      else 'Night' 
end as time
from  [dbo].[orders] ) as k
group by time



--3. Evolution of E-commerce orders in the Brazil region:

--3.1  Get month on month orders by states
select [customer_state],
		datename(mm, [order_purchase_timestamp]) as month_name,
		datepart(mm, [order_purchase_timestamp]) as month_number, 
		count([order_id]) as orders_count
		
from [dbo].[customers] as c
inner join [dbo].[orders] as o 
on c.customer_id = o.customer_id
group by [customer_state],
		datename(mm, [order_purchase_timestamp]),
		datepart(mm, [order_purchase_timestamp])
order by 1,3



--3.2  Distribution of customers across the states in Brazil

select distinct [customer_state], count(*) as [No of customers]
from [dbo].[customers]
group by [customer_state]
order by 2 asc

/*--4. Impact on Economy: Analyze the money movement by e-commerce 
by looking at order prices, freight and others*/

/*-- 4.1 Get % increase in cost of orders from 2017 to 2018 
(include months between Jan to Aug only) - 
You can use “payment_value” column in payments table*/

select year([order_purchase_timestamp]) As Year, 
		month([order_purchase_timestamp]) As Month,sum([payment_value]) as Payment_value
from [dbo].[payments] p 
join [dbo].[orders] o
on p.order_id = o.order_id
where year([order_purchase_timestamp]) between 2017 and 2018 and 
		month([order_purchase_timestamp]) between 1 and 8
group by year([order_purchase_timestamp]),month([order_purchase_timestamp])
order by 3

--Mean & Sum of price and freight value by customer state
select [customer_state], 
	round (avg(price), 2) as Mean_price,
	round (sum(price), 2) as total_price, 
	round (sum([freight_value]), 2)  as total_freight_value 
from [dbo].[customers] as c
join [dbo].[orders] as o
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state]
order by 1

--5. Analysis on sales, freight and delivery time

--5.1 Calculate days between purchasing, delivering and estimated delivery

select datediff(dd,[order_purchase_timestamp],[order_approved_at]) as purchasing,
DATEDIFF(dd,[order_delivered_carrier_date],[order_delivered_customer_date]) as delivering,
DATEDIFF(dd,[order_delivered_customer_date],[order_estimated_delivery_date]) as estimated_delivery
from [dbo].[orders]

--5.2 Find time_to_delivery & diff_estimated_delivery. Formula for the same given below:

--   5.2.1 time_to_delivery = order_purchase_timestamp-order_delivered_customer_date

select day (order_purchase_timestamp-order_delivered_customer_date) as 
time_to_deleivery from [dbo].[orders] 


--    5.2.1 diff_estimated_delivery = order_estimated_delivery_date-order_delivered_customer_date
select day (order_estimated_delivery_date-order_delivered_customer_date)as diff_estimated_delivery
from [dbo].[orders]
--5.3 Group data by state, take mean of freight_value, time_to_delivery, diff_estimated_delivery
select [customer_state],
	round (avg([freight_value]), 2)  as total_freight_value,
	avg (day (order_purchase_timestamp-order_delivered_customer_date)) as time_to_deleivery,
	avg (day (order_estimated_delivery_date-order_delivered_customer_date))as diff_estimated_delivery
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state]
order by 1
--5.4 Sort the data to get the following:

--5.5 Top 5 states with highest/lowest average freight value - sort in desc/asc limit 5
--Top 5 states with highest average freight value 
select top(5)[customer_state],
	round (avg([freight_value]), 2)  as total_freight_value
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state]
order by  total_freight_value desc
--Top 5 states with lowest average freight value 
select top(5)[customer_state],
	round (avg([freight_value]), 2)  as total_freight_value
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state]
order by  total_freight_value asc


-- Top 5 states with highest average time to delivery
select top (5) [customer_state],
	avg (day (order_purchase_timestamp-order_delivered_customer_date)) as avg_time_to_deleivery
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state]
order by avg_time_to_deleivery desc
--Top 5 states with lowest average time to delivery
select top (5) [customer_state],
	avg (day (order_purchase_timestamp-order_delivered_customer_date)) as avg_time_to_deleivery
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state]
order by avg_time_to_deleivery asc

-- 5.7 Top 5 states where delivery is really fast/ not so fast compared to estimated date
--Top 5 states where delivery is really fast
select top(5)[customer_state],
	avg (day (order_estimated_delivery_date-order_delivered_customer_date))as avg_diff_estimated_delivery
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state] 
order by 2 desc;
--Top 5 states where delivery is really not so fast
select top(5)[customer_state],
	avg (day (order_estimated_delivery_date-order_delivered_customer_date))as avg_diff_estimated_delivery
from [dbo].[orders] o
join [dbo].[customers] as c
on c.customer_id = o.customer_id
join [dbo].[order_items] as oi
on o.order_id = oi.order_id
group by [customer_state] 
order by 2 asc

-- 6. Payment type analysis:

-- 6.1 Month over Month count of orders for different payment types
select [payment_type], 
datename(mm,[order_purchase_timestamp]) as month_name,
datepart(mm,[order_purchase_timestamp]) as month_number, 
count(*) as [count of orders]
from [dbo].[orders] o
join [dbo].[payments] p
on o.order_id = p.order_id
group by [payment_type],datename(mm,[order_purchase_timestamp]),datepart(mm,[order_purchase_timestamp])
order by 1,4

-- 6.2 Count of orders based on the no. of payment installments
select [payment_installments], count(*) as [Count of orders]
from [dbo].[payments]
group by [payment_installments]
order by 1

/*-- 7. Actionable Insights 
1. Brazilian customers are tend purchase more products on afternoon and night.
It means the time around 12PM to 3AM
2. As per data in 10-2016 has more orders , 11-2017 and followed by 01-2018.
3. Customer_state 'SP' has more customers i.e, 27489 and less customers in 'RR' .i,e 30
4. Top one state is 'AC' with highest average freight value 
5. Top one state is 'SP' with lowest average freight value 
6. Top one state is 'SP' with highest average time to delivery the order
7. Top one state is 'AP' with lowest average time to delivery the order
8. In May month credit card payment are high. i,e 3487 
9. In August month debit card payment are high. i,e 122 

Recommendations:
1.Usually Customers are purchasing in afternoon time, so we need to provide some 
offers or some benifits in day time to increase sales in Dawn time.
2. Customers are more intersted in one time installments and
Customers are less intersted with 11,13 & 14 installments
3. Also as per data more custmers are using credit cards for payments and less using debit cards.



