
 -- FINDING NULLS IN OUR TABLES
SELECT *
  FROM [Walmart Sales Data]
  WHERE Branch IS NULL
  OR City IS NULL
  OR Customer_type IS NULL	
  OR Gender IS NULL
  OR Product_line IS NULL
  OR Unit_price IS NULL
  OR Quantity IS NULL
  OR Unit_price IS NULL
  OR Total IS NULL
  OR Date IS NULL
  OR Time IS NULL
  OR Payment IS NULL
  OR cogs IS NULL
  OR gross_margin_percentage IS NULL
  OR gross_income IS NULL
  OR Rating IS NULL


  -- Fix missing Prices, Tax, Total & gross income
UPDATE [Walmart Sales Data] 
SET Unit_price = Total / Quantity 
WHERE Unit_price IS NULL AND Quantity > 0;

UPDATE [Walmart Sales Data]
SET 
   Unit_price = COALESCE(Unit_price , 72.5), 
   Tax_5 = (Unit_Price * Quantity) * 0.05,
    Total = (Unit_Price * Quantity) + ((Unit_Price * Quantity) * 0.05),
        gross_income = (Unit_Price * Quantity) * 0.05
WHERE Total IS NULL OR Tax_5 IS NULL OR Gross_Income IS NULL;


-- VIEW OF OUR CLEAN TABLE
 SELECT *
 FROM [Walmart Sales Data];


 -- we skip standardizaton cause our data is standard enoung the timestamps,float etc are in corect
 EXEC sp_help
 [Walmart Sales Data];

 --Note i left the invoice id in nvarchar format cause it not use in any calculation


 -- Let remove outliers from the table using a statistical approach (interquartile range)
WITH Stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total) OVER () AS Q3
    FROM [Walmart Sales Data]
),
Bounds AS (
    SELECT DISTINCT
        Q1, 
        Q3,
        (Q3 - Q1) AS IQR,
        (Q1 - (1.5 * (Q3 - Q1))) AS LowerBound,
        (Q3 + (1.5 * (Q3 - Q1))) AS UpperBound
    FROM Stats
)
SELECT * 
FROM [Walmart Sales Data], Bounds
WHERE Total > UpperBound OR Total < LowerBound;

--we had to use the median of sales which is less than the average

SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Total) OVER () AS Median_Sale,
    AVG(Total) OVER () AS Average_Sale
FROM [Walmart Sales Data];


-- we have 9 high value sales which are far above the average so we group them out

ALTER TABLE [Walmart Sales Data] 
ADD Transaction_Category VARCHAR(20);

UPDATE [Walmart Sales Data]
SET Transaction_Category = 'High Value'
WHERE (Unit_price * Quantity) > 800;

UPDATE [Walmart Sales Data]
SET Transaction_Category = 'Normal'
WHERE Transaction_Category IS NULL;

--Our clean averages after rmoving outliers

SELECT 
    Branch, 
    AVG(Total) AS Typical_Average_Sale,
    COUNT(*) AS Number_of_Transactions,
    SUM(Total) AS Total_Revenue_Normal
FROM [Walmart Sales Data]
WHERE Transaction_Category = 'Normal'
GROUP BY Branch
ORDER BY Typical_Average_Sale DESC;


-- Let add atributes like year, months time of the day(morning, noon or night), it will be needed in our EDA and visualization.

ALTER TABLE [Walmart Sales Data] 
ADD Sales_Year INT, Sales_Month VARCHAR(15), Time_Slot VARCHAR(15);

UPDATE [Walmart Sales Data]
SET 
    Sales_Year = YEAR(Date),
    Sales_Month = CONCAT(CAST(YEAR(DATE) AS VARCHAR), '-', DATENAME(MONTH,DATE)),
    Time_Slot = CASE 
        WHEN CAST(Time AS TIME) BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN CAST(Time AS TIME) BETWEEN '12:00:00' AND '16:59:59' THEN 'Afternoon'
        WHEN CAST(Time AS TIME) BETWEEN '17:00:00' AND '21:00:00' THEN 'Evening'
        ELSE 'Night'
    END;

    SELECT *
    FROM [Walmart Sales Data];




