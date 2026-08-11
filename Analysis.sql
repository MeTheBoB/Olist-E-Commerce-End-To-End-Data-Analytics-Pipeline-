

	--ord.order_id,
	--	ord.[order_delivered_customer_date],
	--	ord.[order_estimated_delivery_date],
	--	rev.[review_score],
 --       rev.[review_comment_title],
 --       rev.[review_comment_message],
 --       rev.[review_creation_date],
 --       rev.[review_answer_timestamp]



--============= Review score and delivery analysis --=============
WITH reviewAnalysis AS (
  SELECT 
	    ord.order_id,
		rev.[review_score],
        DATEDIFF(DAY, ord.[order_estimated_delivery_date], ord.[order_delivered_customer_date]) AS [Est. vs, Act (Days)]

  FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[reviews] AS rev 
		ON ord.order_id = rev.order_id

  ), reviewAnalysis2 AS(

	SELECT [review_score],
		   AVG([Est. vs, Act (Days)]) AS [avg_del_time]
		   FROM reviewAnalysis
	GROUP BY [review_score]
  ) 
  SELECT * 
  FROM reviewAnalysis2
  WHERE review_score IS NOT NULL
  ORDER BY [review_score]
 



--============= WHEREHOUSE ORDER PROCESS ANALYISIS=============
WITH whereHouseTanalysis AS (
  SELECT 
		cus.customer_state,
        DATEDIFF(DAY,ord.[order_approved_at], ord.[order_delivered_carrier_date]) AS [Warehouse_Time_Days]

  FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus 
		on ord.customer_id = cus.customer_id
  WHERE 
        ord.[order_delivered_carrier_date] IS NOT NULL 
        AND ord.[order_approved_at] IS NOT NULL

  ) SELECT 
	  customer_state,
	  ROUND(AVG(CAST([Warehouse_Time_Days] AS FLOAT)),2) AS [AVG_days]
  FROM whereHouseTanalysis
  GROUP BY customer_state
  ORDER BY customer_state

 

--============= Total reviews per rate --=============

SELECT 
	cus.customer_state,
	COUNT(CASE
		WHEN rev.review_score = '1' then ord.order_id
	END) as [1],
	COUNT(CASE
		WHEN rev.review_score = '2' then ord.order_id
	END) as [2],
	COUNT(CASE
		WHEN rev.review_score = '3' then ord.order_id
	END) as [3],
	COUNT(CASE
		WHEN rev.review_score = '4' then ord.order_id
	END) as [4],
	COUNT(CASE
		WHEN rev.review_score = '5' then ord.order_id
	END) as [5]

FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[reviews] AS rev 
		ON ord.order_id = rev.order_id
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus
        ON ord.customer_id = cus.customer_id
GROUP BY cus.customer_state
ORDER BY 
    cus.customer_state;

--============= Total reviews per rate in percentage --=============

SELECT 
	cus.customer_state,
	CAST(COUNT(CASE
		WHEN rev.review_score = '1' then ord.order_id
	END) * 100.0 / NULLIF(COUNT(rev.review_score),0) AS DECIMAL(10,2))  as [1_ptc],
	CAST(COUNT(CASE
		WHEN rev.review_score = '2' then ord.order_id
	END) * 100.0 / NULLIF(COUNT(rev.review_score),0) AS DECIMAL(10,2))  as [2_ptc],
	CAST(COUNT(CASE
		WHEN rev.review_score = '3' then ord.order_id
	END) * 100.0 / NULLIF(COUNT(rev.review_score),0) AS DECIMAL(10,2))  as [3_ptc],
	CAST(COUNT(CASE
		WHEN rev.review_score = '4' then ord.order_id
	END) * 100.0 / NULLIF(COUNT(rev.review_score),0) AS DECIMAL(10,2))  as [4_ptc],
	CAST(COUNT(CASE
		WHEN rev.review_score = '5' then ord.order_id
	END) * 100.0 / NULLIF(COUNT(rev.review_score),0) AS DECIMAL(10,2))  as [5_ptc]



FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[reviews] AS rev 
		ON ord.order_id = rev.order_id
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus
        ON ord.customer_id = cus.customer_id
GROUP BY cus.customer_state

ORDER BY 
    [1_ptc] desc



--============= Messages Analysis --=============

SELECT 
    cus.customer_state,
	COUNT(CASE WHEN rev.review_comment_message ='No message' THEN ord.order_id END) AS [No_Message],
	COUNT(CASE WHEN rev.review_comment_message != 'No message' 
                AND rev.review_comment_message IS NOT NULL 
                AND rev.review_comment_message != '' 
               THEN ord.order_id END) AS [Review given]

FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[reviews] AS rev 
		ON ord.order_id = rev.order_id
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus
        ON ord.customer_id = cus.customer_id

GROUP BY cus.customer_state
ORDER BY cus.customer_state


SELECT
	cus.customer_state,
	avg(DATEDIFF(DAY, rev.review_creation_date,rev.review_answer_timestamp)) AS [review_responsiveness]
FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[reviews] AS rev 
		ON ord.order_id = rev.order_id
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus
        ON ord.customer_id = cus.customer_id
  GROUP BY cus.customer_state
  ORDER BY cus.customer_state




  --============= Monetary Analysis --=============

--Highest top 10 buyers by state
SELECT top (10)
	cus.customer_state,
	ROUND(sum(pay.payment_value),2) as total_payment

FROM [OlistBEPD].[dbo].[orders] AS ord
  LEFT JOIN [OlistBEPD].[dbo].[payments] AS pay 
		ON ord.order_id = pay.order_id
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus
        ON ord.customer_id = cus.customer_id
GROUP BY cus.customer_state
ORDER BY total_payment desc


---top 5 prodcucts sold by state
 WITH rank_products AS (
 SELECT
	    cus.customer_state,
		prod.product_category_name,
		COUNT(ord.[order_id]) AS [count_of_item_purchased],

        ROW_NUMBER() OVER(PARTITION BY 
		cus.customer_state ORDER BY COUNT(ord.[order_id]) DESC) as [ranks]

  FROM [OlistBEPD].[dbo].[order_Items] AS ord_it
  LEFT JOIN [OlistBEPD].[dbo].[products] AS prod
  ON ord_it.product_id = prod.product_id
  LEFT JOIN [OlistBEPD].[dbo].[orders] AS ord
  ON ord.order_id = ord_it.order_id
  LEFT JOIN [OlistBEPD].[dbo].[customers] AS cus
  on cus.customer_id = ord.customer_id

  WHERE prod.product_category_name IS NOT NULL 

  GROUP BY cus.customer_state, prod.product_category_name
)

SELECT customer_state,
       product_category_name,
	   [count_of_item_purchased],
       ranks
FROM rank_products
WHERE ranks <=5



--- •	Best-Selling Products and •	Highest Grossing Products ----

SELECT TOP (50) 
    prod.product_id,
    prod.product_category_name,
    COUNT(ord_it.order_item_id) AS [Volume_Sold],
    ROUND(SUM(ord_it.price), 2) AS [Total_Revenue]
FROM 
    [OlistBEPD].[dbo].[order_Items] AS ord_it
LEFT JOIN 
    [OlistBEPD].[dbo].[products] AS prod
    ON ord_it.product_id = prod.product_id
GROUP BY 
    prod.product_id,
    prod.product_category_name
ORDER BY 
    [Total_Revenue] DESC;


--- •	Best- sellers and •	Highest revenue ----

SELECT TOP (50) 
    sell.seller_id,
    prod.product_category_name,
    COUNT(ord_it.order_item_id) AS [Volume_Sold],
    ROUND(SUM(ord_it.price), 2) AS [Total_Revenue]
FROM 
    [OlistBEPD].[dbo].[order_Items] AS ord_it
LEFT JOIN 
    [OlistBEPD].[dbo].[products] AS prod
    ON ord_it.product_id = prod.product_id
LEFT JOIN [OlistBEPD].[dbo].[sellers] AS sell
	ON sell.seller_id = ord_it.seller_id

GROUP BY 
    sell.seller_id,
    prod.product_category_name
ORDER BY 
    [Total_Revenue] DESC;




  ----peak seasons--

SELECT 
    FORMAT(order_purchase_timestamp, 'yyyy-MM') AS [Year_Month],
    COUNT(order_id) AS [Total_Orders]
FROM 
    [OlistBEPD].[dbo].[orders]
WHERE 
    order_purchase_timestamp IS NOT NULL
GROUP BY 
    FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY 
    Year_Month ASC;