--1.write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends
with total_amt_cte as
(select sum(cast (amount as bigint)) as total_spend
from credit_card_transactions)
select top 5 city,sum(amount)as spend,total_spend,cast(((sum(amount)*1.0/total_spend)*100.0) as decimal(4,2)) as percentage_contribution
from credit_card_transactions,total_amt_cte
group by city,total_spend
order by sum(amount)desc

--2.write a query to print highest spend month and amount spent in that month for each card type
with card_monthly_spend as
(select card_type,DATEPART(year,transaction_date) as yo,DATENAME(month,transaction_date) as mo,sum(amount)as monthly_spend
from credit_card_transactions
group by card_type,DATEPART(year,transaction_date),DATENAME(month,transaction_date))
select * from
(select *,rank() over(partition by card_type order by monthly_spend desc) rnk
from card_monthly_spend)a
where rnk=1

--3.write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with total_amt_cte as
(select *,sum(cast(amount as bigint)) over (partition by card_type order by transaction_date,transaction_id) as cum_sum
from credit_card_transactions),
rnk_cte as
(select *,row_number()over(partition by card_type order by cum_sum)as rnk
from total_amt_cte
where cum_sum>1000000)
select *
from rnk_cte
where rnk=1

--4.write a query to find city which had lowest percentage spend for gold card type

select top 1 city,
sum(amount)as total_spent,
sum(case when card_type='Gold' then amount else 0 end) as gold_spent,
(sum(case when card_type='Gold' then amount else 0 end) )*1.0/sum(amount)*100 as gold_spent_percent
from credit_card_transactions
group by city
having sum(case when card_type='Gold' then amount else 0 end)>0
order by gold_spent_percent

--5.write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with exp_spent_cte as
(select city,exp_type,sum(amount) exp_spent
from credit_card_transactions
group by city,exp_type),

exp_rank_cte as
(select city,exp_type,rank() over(partition by city order by exp_spent)as low_exp,
rank() over(partition by city order by exp_spent desc)as high_exp
from exp_spent_cte)

select city,
max(case when high_exp=1 then exp_type end) as highest_expense_type,
max(case when low_exp=1 then exp_type end) as lowest_expense_type
from exp_rank_cte
where low_exp=1 or high_exp=1
group by city

--6.write a query to find percentage contribution of spends by females for each expense type
select exp_type,sum(case when gender='F' then amount else 0 end)as female_spend,sum(amount)total_spend,
sum(case when gender='F' then amount else 0 end)*1.0 / sum(amount) *100.0 as female_percent_spend
from credit_card_transactions
group by exp_type
order by female_percent_spend

--7.which card and expense type combination saw highest month over month growth in Jan-2014
with monthly_exp_cte as
(select card_type,exp_type,format(transaction_date,'yyyy') as yr,format(transaction_date,'MM') as mt,sum(amount) as month_exp
from credit_card_transactions
group by card_type,exp_type,format(transaction_date,'yyyy'),format(transaction_date,'MM')),
prev_month_cte as
(select * ,lag(month_exp,1) over(partition by card_type,exp_type order by yr,mt) as  prev_month_exp
from monthly_exp_cte)
select top 1 *,month_exp-prev_month_exp as mom_growth
from prev_month_cte
where yr='2014' and mt='01'
order by mom_growth desc

--8.during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city,sum(amount)as total_spend,count(*) as no_of_trans,sum(amount)*1.0/count(*) as ratio
from credit_card_transactions
where format(transaction_date,'ddd') in ('sat','sun')
group by city
order by ratio desc

--9.which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as
(select *,row_number() over (partition by city order by transaction_date,transaction_id)rn
from credit_card_transactions)
select city,min(transaction_date)first_ransaction,max(transaction_date)last_transaction,
datediff(day,min(transaction_date),max(transaction_date))no_of_days
from cte
where rn in (1,500)
group by city
having count(*)=2
order by no_of_days

