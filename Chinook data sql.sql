
use chinook_data;
select * from invoice_line;

-- Q-1

select * from employee 
where last_name is NULL 
or first_name is NULL 
or title is NULL
or reports_to is NULL 
or birthdate is NULL 
or hire_date is NULL 
or address is NULL 
or city is NULL 
or state is NULL 
or country is NULL
or fax is NULL
or email is NULL;

select employee_id,coalesce(reports_to,"NA") as reports_to from employee;




-- Q-2
select il.track_id,t.name as track_name,at.name as artist_name,g.name as genre_name,count(il.quantity) as most_selling from 
invoice_line il join invoice i on i.invoice_id=il.invoice_id
join track t on il.track_id=t.track_id
join album ab on ab.album_id=t.album_id
join artist at on at.artist_id=ab.artist_id
join genre g on g.genre_id=t.genre_id
where i.billing_country='USA'
group by track_id,at.name
order by most_selling desc
limit 10;
 
-- Q-3

select country,count(customer_id) as total_customers from customer 
group by country
order by count(customer_id) desc;


-- Q-4

select billing_country, billing_state, billing_city, COUNT(invoice_id) as count_of_invoices, SUM(total) as total_revenue
from invoice
group by billing_city,billing_state,billing_country
order by count(invoice_id) desc, sum(total) desc;

-- Q-5
select billing_country,sum(total) from invoice
group by billing_country;

with cte as 
(select billing_country,customer_id,sum(total) as revenue,
dense_rank() over(partition by billing_country order by sum(total) desc) as sales_rank from invoice
group by billing_country,customer_id

)
select * from cte where sales_rank<=5
order by billing_country;


-- Q-6

with cte as 
(
select c.customer_id,sum(il.quantity) as total from customer c
join invoice i on c.customer_id=i.customer_id 
join invoice_line il on il.invoice_id=i.invoice_id 
join track t on t.track_id=il.track_id
group by customer_id
),
rank_track as (select cte.customer_id,t.track_id as track_id,t.name as track_name,cte.total,
row_number() over(partition by customer_id order by cte.total desc) as rnk from cte
join invoice i on i.customer_id=cte.customer_id 
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id)

select customer_id,track_id,track_name,total from rank_track where rnk=1;


-- Q-7


select customer_id, avg(total) as avg_order_value, count(invoice_id)as num_of_orders
from invoice
group by customer_id
order by avg(total);



-- Q-8
with cte as (
select max(invoice_date) as recent_inovice_date from invoice
),

last_year as (
select date_sub(recent_inovice_date,INTERVAL 1 YEAR) as last_year_dt from cte
),

churn_customers as 
( 
select c.customer_id,coalesce(first_name," ",last_name) as full_name,max(invoice_date) as recent_date
from customer c join invoice i on c.customer_id=i.customer_id 
group by customer_id,full_name
having max(invoice_date) and max(invoice_date)<(select last_year_dt from last_year)
)

select (select count(*) from churn_customers)/(select count(*) from customer) * 100 as churn_rate;



-- Q-9

with genre_usa_sales as (select g.genre_id,g.name as genre_name,sum(il.unit_price * il.quantity) as genre_revenue from invoice i 
join invoice_line il on i.invoice_id=il.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id
where billing_country="USA"
group by g.genre_id,g.name),

totalsales as (select sum(genre_revenue) as total_revenue from genre_usa_sales)

select genre_id,genre_name,round((genre_revenue*100/(select total_revenue from totalsales)),2) as percentage
from genre_usa_sales
order by percentage desc;


-- Q-10
-- Find customers who have purchased tracks from at least 3 different genres

select c.customer_id,concat(c.first_name," ",c.last_name) as full_name,count(distinct g.genre_id) as unique_genre 
from customer c
join invoice i on i.customer_id=c.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id 
join genre g on g.genre_id=t.genre_id
group by c.customer_id,full_name	
having count(distinct g.genre_id) >=3
order by unique_genre desc; 

-- Q-11
-- Rank genres based on their sales performance in the USA

select g.genre_id,g.name as genre_name,sum(il.unit_price * il.quantity) as genre_revenue,
dense_rank() over(order by sum(il.unit_price * il.quantity) desc) as sales_rank from invoice i 
join invoice_line il on i.invoice_id=il.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id
where billing_country="USA"
group by g.genre_id,g.name;



-- 12.	Identify customers who have not made a purchase in the last 3 months 

select c.customer_id,concat(c.first_name," ",c.last_name) full_name from customer c 
left join invoice i 
on c.customer_id=i.customer_id
and invoice_date>date_sub(current_date(),interval 3 month)
where invoice_date is NULL;






 













-- with cte as (select billing_country,customer_id,sum(total) as revenue ,
-- dense_rank() over(partition by billing_country order by sum(total) desc) as sales_rank
-- from invoice 
-- group by billing_country,customer_id)


-- select * from cte where sales_rank <=5
-- order by billing_country;


-- select g.name,sum(il.unit_price*il.quantity) as total_sales from genre g join track t on g.genre_id=t.genre_id
-- join invoice_line il on il.track_id=t.track_id
-- group by 1
-- order by total_sales desc;


-- 1 SUBJECTIVE QUESTIONS

select a.album_id,a.title,g.name as genre_name,sum(il.unit_price * il.quantity) as genre_revenue,
dense_rank() over(order by sum(il.unit_price * il.quantity) desc) as sales_rank from invoice i 
join invoice_line il on i.invoice_id=il.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id
join album a on a.album_id=t.album_id
where billing_country="USA" 
group by a.album_id,a.title,g.name
limit 10;


-- Q-2

select g.name as genre_name,sum(il.unit_price*il.quantity) as total_sales,
dense_rank() over(order by sum(il.unit_price*il.quantity) desc) as sales_rank
from invoice i join invoice_line il on i.invoice_id=il.invoice_id
join track t on t.track_id=il.track_id
join genre g on t.genre_id=g.genre_id
where i.billing_country != "USA"
group by g.name;



-- Subjective Question 3

with cte as 
(select customer_id,
	count(i.invoice_id) as purchases,
    sum(total) as total_sales,
    avg(total) as avg_sales,
    sum(il.quantity) as total_quantity,
    datediff(max(invoice_date),min(invoice_date)) as tenure_days
    from invoice i
    join invoice_line il on i.invoice_id=il.invoice_id
    group by customer_id
),
    cte_2 as 
    (select customer_id,purchases,total_sales,avg_sales,total_quantity,
    case when tenure_days > (select avg(tenure_days) from cte) then "long term"
    else "Short term " end as term from cte
    )
    
    select term, 
    round(avg(purchases),2) as frequency,
    round(avg(total_quantity),2) as basket_size,
    round(avg(total_sales),2) as amount,
    round(avg(avg_sales),2) as avg_value, 
    count(customer_id) as total_customers
    from cte_2 
    group by term;
    
-- Q-4



with cte as 
(select il.invoice_id as invoice_id,g.name
from invoice_line il
left join track t on t.track_id = il.track_id
left join genre g on  g.genre_id = t.genre_id
group by il.invoice_id,g.name)

select name,count(invoice_id) as num_of_invoice from cte group by 1;



with cte as 
(select il.invoice_id, al.title
from invoice_line il
left join track t on t.track_id = il.track_id
left join album al on  al.album_id = t.album_id
group by il.invoice_id, al.title)

select title,count(invoice_id) as num_of_invoice from cte group by 1;



with cte as 
(select il.invoice_id,a.name 
from invoice_line il 
left join track t on t.track_id = il.track_id
left join album al on  al.album_id = t.album_id
left join artist a on a.artist_id = al.artist_id
group by il.invoice_id,a.name)

select name,count(invoice_id) as num_of_invoice from cte group by 1;




-- Q-5



with cte as 
(
	select billing_country,count(distinct customer_id) as total_customers,count(quantity) as total_quantity from invoice i
	join  invoice_line il on i.invoice_id=il.invoice_id
	group by 1
),
churned as (
	with churn_rate as 
    (
		select max(invoice_date) as recent ,date_sub(max(invoice_date),interval 1 year) as last_year from invoice
	)
	
	select billing_country,count(distinct customer_id) as churned_customers 
	from invoice where invoice_date < (select last_year from churn_rate) 
	group by billing_country
    
)

select cte.billing_country,cte.total_customers,cte.total_quantity,c.churned_customers from cte 
join churned c on cte.billing_country=c.billing_country;
 
 
 



-- select billing_country,sum(quantity) as total from invoice i
-- join invoice_line il on i.invoice_id=il.invoice_id
-- group by billing_country;







-- Q-6


select count(distinct customer_id) as customer_count from invoice; 
-- last 6 months
select count(distinct customer_id) as customer_count from invoice
where invoice_date>date_sub((select max(invoice_date) from invoice),interval 6 month);

-- Q-7


select customer_id, avg(total) as avg_order_value, count(invoice_id)as num_of_orders,sum(total) as totals
from invoice
group by customer_id
order by totals desc;







-- Q-10

alter table album add column Releaseyear int; 

select * from album;
	
    
-- Q-11
select * from invoice;

with tracks_per_customer as 
(
select customer_id , sum(quantity) as total_customer_track  from invoice i 
join invoice_line il on i.invoice_id=il.invoice_id
group by customer_id
),

customer_wise_spent as (
select billing_country,total_customer_track,i.customer_id,sum(total) as sum_total_spent
from invoice i join tracks_per_customer tc on i.customer_id=tc.customer_id
group by billing_country ,i.customer_id,total_customer_track
)

select billing_country,count(distinct customer_id) as customers,avg(sum_total_spent) as avg_per_customer,
avg(total_customer_track) as avg_tracks_purchased from customer_wise_spent
group by billing_country
order by avg_per_customer desc






 
-- select count(distinct customer_id) from customer;
-- select count(track_id) from track;
-- select count(genre_id) from genre;
-- select count(distinct artist_id) from artist;
-- select count(distinct album_id) from album;


