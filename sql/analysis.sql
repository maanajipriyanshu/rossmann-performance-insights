select store, round(avg(sales),2) as average_sales
from rossmann_sales
group by store
order by average_sales desc
limit 10;


select promo, round(avg(sales),2) as average_sales,count (*) as total_days
from rossmann_sales
group by promo
order by average_sales desc;

select s.storetype, round(avg(r.sales),2) as average_sales, sum(r.sales) as total_sales
from rossmann_sales r 
join rossmann_store s on r.store = s.store
group by s.storetype
order by average_sales desc;

select month, round(avg(sales),2) as average_sales
from rossmann_sales
group by month
order by month asc;

select store, round(avg(sales),2) as average_sales,
rank() over(order by avg(sales) desc) as sales_rank
from rossmann_sales
group by store
order by average_sales desc
limit 10;

select month, round(avg(sales),1), round(avg(sales) - lag(round(avg(sales),2))
over(order by month),2) as mom_growth
from rossmann_sales
group by month
order by mom_growth asc;


with average_sales as(
select round(avg(sales),2) as overall_average
from rossmann_sales
),
store_sales as (
select store, round(avg(sales),2) as store_average
from rossmann_sales
group by store
)
select s.store,s.store_average,a.overall_average,round(s.store_average - a.overall_average, 2) as difference
from store_sales s
cross join average_sales a
where s.store_average > a.overall_average
order by difference desc
limit 10;


select year,sum(sales) as total_sales, round(sum(sales) - lag(sum(sales))
over (order by year),2) as yoy_growth
from rossmann_sales
group by year
order by year asc;