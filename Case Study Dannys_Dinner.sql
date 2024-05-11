--1. What is the total amount each customer spent at the restaurant?

Select 
S.customer_id,
Sum(m.price) as Amount_Spent
From sales S
join menu M on S.customer_id = s.customer_id
group by S.customer_id

--2. How many days has each customer visited the restaurant?
Select customer_id, count(distinct(order_date)) as DaysVisited
From Sales
Group by customer_id


--3. What was the first item from the menu purchased by each customer?

With Product as (
Select 
customer_id,
order_date,
s.product_id,
product_name,
price ,
ROW_NUMBER() over(partition By customer_id Order by customer_id) as RowNo
From sales S
Join menu M on s.product_id = m.product_id
) 
Select customer_id,product_name From Product where RowNo = 1


--4. What is the most purchased item on the menu and how many times was it purchased by allcustomers?

Select top 1
s.product_id,
product_name,
Count(s.product_id) as Purchased_Count
From sales S
Join menu M on s.product_id = m.product_id
group by s.product_id,product_name
Order by Purchased_Count desc

--5. Which item was the most popular for each customer?

with Product as(
Select 
customer_id,
--s.product_id,
product_name,
Count(s.product_id) as Purchased_Count
From sales S
Join menu M on s.product_id = m.product_id
group by s.product_id,product_name,customer_id
--Order by Purchased_Count desc
)
Select customer_id,product_name,MAX(Purchased_Count)as PurchaseCount From Product Group by customer_id, product_name order by PurchaseCount desc

--6.Which item was purchased first by the customer after they became a member?

With Item as(
Select 
s.customer_id,
ROW_NUMBER() over(partition By s.customer_id Order by s.customer_id) as RowNo,
s.product_id,
m.product_name,
s.order_date,
mb.join_date
From sales s
join menu m on m.product_id = s.product_id
join members Mb on Mb.customer_id = s.customer_id
where s.order_date > mb.join_date
)
Select customer_id,product_name From Item Where RowNo = 1


--7. Which item was purchased just before the customer became a member?

With Item as(
Select 
s.customer_id,
ROW_NUMBER() over(partition By s.customer_id Order by s.customer_id desc) as RowNo,
s.product_id,
m.product_name,
s.order_date,
mb.join_date
From sales s
join menu m on m.product_id = s.product_id
join members Mb on Mb.customer_id = s.customer_id
where s.order_date < mb.join_date
)
Select customer_id,product_name,RowNo From Item Where RowNo = 1

--8. What is the total items and amount spent for each member before they became a member?

With Item as(
Select 
s.customer_id,
count(s.product_id) as ProductCount,
m.price,
s.order_date,
mb.join_date
From sales s
join menu m on m.product_id = s.product_id
join members Mb on Mb.customer_id = s.customer_id
where s.order_date < mb.join_date
Group by s.customer_id,m.price,s.order_date,mb.join_date
)
Select customer_id,sum(ProductCount) as TotalItems,sum(price) as AmountSpent From Item Group By customer_id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

With Details as (
Select
customer_id,
product_name,
price,
Case 
When product_name = 'sushi' then price*20
Else price*10 End as CustomerPoints
From sales s
join menu m on m.product_id = s.product_id
Group by product_name,price,customer_id
)
Select customer_id,Sum(CustomerPoints) as Points From Details Group by customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have 
--at the end of January?

Select
s.customer_id
,Sum(CASE When (DATEDIFF(DAY, me.join_date, s.order_date) between 0 and 7) 
Then m.price * 20
Else m.price * 10
END) As Points
From members as me
Join sales as s on s.customer_id = me.customer_id
Join menu as m on m.product_id = s.product_id
where 
--s.order_date >= me.join_date 
--and 
s.order_date <= '2021-01-31'
Group by s.customer_id

