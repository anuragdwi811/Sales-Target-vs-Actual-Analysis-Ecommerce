/*==============================================================
 Project     : Sales Target vs Actual Performance Analysis
 File        : 05_underperformance_analysis.sql
 Module      : Underperformance Analysis
 Purpose     : Identify, rank, and analyze regions and categories
               that are performing below sales targets
 Sales Rule  : Delivered orders are treated as realized sales
 Focus       : Negative variance, achievement %, repeated
               underperformance, and near-target opportunities
 Output      : Underperforming regions, categories, rankings,
               repeated underperformance, and recovery opportunities
==============================================================*/



/*==============================================================
 CREATE UNDERPERFORMANCE ANALYSIS VIEW
==============================================================*/

CREATE OR REPLACE VIEW analytics.vw_underperformance_analysis AS

WITH underperformance AS (
	    SELECT 'Region' AS level_type,
	           entity,
	           sales_target,
	           actual_sales,
	           sales_variance,
	           achievement_pct
	    FROM analytics.vw_target_achievement_analysis
	    WHERE level_type = 'Region'
	      	AND achievement_pct < 100

UNION ALL

	    SELECT 'Category' AS level_type,
	           entity,
	           sales_target,
	           actual_sales,
	           sales_variance,
	           achievement_pct
	    FROM analytics.vw_target_achievement_analysis
	    WHERE level_type = 'Category'
	      	AND achievement_pct < 100)

SELECT level_type,
       entity,
       sales_target,
       actual_sales,
       sales_variance,
       achievement_pct,
       100 - achievement_pct AS achievement_gap_pct
FROM underperformance;



/*==============================================================
 01. UNDERPERFORMING REGIONS
==============================================================*/

SELECT entity AS region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_Gap_pct
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Region'
ORDER BY achievement_pct;



/*==============================================================
 02. UNDERPERFORMING CATEGORIES
==============================================================*/

SELECT entity AS category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_Gap_pct
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Category'
ORDER BY achievement_pct;



/*==============================================================
 03. REGIONS WITH LARGEST SALES TARGET GAPS
==============================================================*/

SELECT entity AS region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   RANK()
	   		OVER(ORDER BY sales_variance) AS variance_rank
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Region'
ORDER BY variance_rank;



/*==============================================================
 04. CATEGORIES WITH LARGEST SALES TARGET GAPS
==============================================================*/

SELECT entity AS category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   RANK()
	   		OVER(ORDER BY sales_variance) AS variance_rank
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Category'
ORDER BY variance_rank;



/*==============================================================
 05. REGIONAL UNDERPERFORMANCE RANKING
==============================================================*/

SELECT entity AS region,
	   achievement_pct,
	   sales_variance,
	   RANK()
	   		OVER(ORDER BY achievement_pct) AS achievement_rank
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Region'
ORDER BY achievement_rank;



/*==============================================================
 06. CATEGORY UNDERPERFORMANCE RANKING
==============================================================*/

SELECT entity AS category,
	   achievement_pct,
	   sales_variance,
	   RANK()
	   		OVER(ORDER BY achievement_pct) AS achievement_rank
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Category'
ORDER BY achievement_rank;



/*==============================================================
 07. REPEATEDLY UNDERPERFORMING REGIONS
==============================================================*/

WITH monthly_region_target AS (
		SELECT target_month AS month,
               region,
               SUM(sales_target) AS sales_target
        FROM sales.sales_targets
        GROUP BY target_month,
                 region),

monthly_region_actual AS (
        SELECT DATE_TRUNC('month', o.order_date)::DATE AS month,
               c.region,
               SUM(oi.item_revenue) AS actual_sales
        FROM master.customers c
        JOIN sales.orders o
          	ON c.customer_id = o.customer_id
        JOIN sales.order_items oi
          	ON o.order_id = oi.order_id
        WHERE o.order_status = 'Delivered'
        GROUP BY DATE_TRUNC('month', o.order_date)::DATE,
                 c.region),

monthly_region_performance AS (
        SELECT t.month,
               t.region,
               t.sales_target,
               COALESCE(a.actual_sales, 0) AS actual_sales,
               COALESCE(a.actual_sales, 0) - t.sales_target AS sales_variance,
               ROUND(COALESCE(a.actual_sales, 0)::NUMERIC
                   / NULLIF(t.sales_target, 0) * 100
				   	, 2) AS achievement_pct
        FROM monthly_region_target t
        LEFT JOIN monthly_region_actual a
          	ON t.month = a.month
         	AND t.region = a.region)

SELECT region,
       COUNT(*) AS total_months,
       COUNT(*) FILTER(WHERE achievement_pct < 100) AS below_target_months,
       ROUND(COUNT(*) FILTER(WHERE achievement_pct < 100)::NUMERIC
           / NULLIF(COUNT(*), 0) * 100
           	, 2) AS below_target_pct
FROM monthly_region_performance
GROUP BY region
ORDER BY below_target_months DESC,
         below_target_pct DESC,
         region;
		 


/*==============================================================
 08. REPEATEDLY UNDERPERFORMING CATEGORIES
==============================================================*/

WITH monthly_category_target AS (
        SELECT target_month AS month,
               category_id,
               SUM(sales_target) AS sales_target
        FROM sales.sales_targets
        GROUP BY target_month,
                 category_id),

monthly_category_actual AS (
        SELECT DATE_TRUNC('month', o.order_date)::DATE AS month,
               p.category_id,
               SUM(oi.item_revenue) AS actual_sales
        FROM sales.orders o
        JOIN sales.order_items oi
          	ON o.order_id = oi.order_id
        JOIN master.products p
          	ON oi.product_id = p.product_id
        WHERE o.order_status = 'Delivered'
        GROUP BY DATE_TRUNC('month', o.order_date)::DATE,
                 p.category_id),

monthly_category_performance AS (
        SELECT t.month,
               t.category_id,
               t.sales_target,
               COALESCE(a.actual_sales, 0) AS actual_sales,
               COALESCE(a.actual_sales, 0) - t.sales_target AS sales_variance,
               ROUND(COALESCE(a.actual_sales, 0)::NUMERIC
                   / NULLIF(t.sales_target, 0) * 100
                   	, 2) AS achievement_pct
        FROM monthly_category_target t
        LEFT JOIN monthly_category_actual a
          	ON t.month = a.month
         	AND t.category_id = a.category_id)

SELECT cat.category_name AS category,
       COUNT(*) AS total_months,
       COUNT(*) FILTER(WHERE p.achievement_pct < 100) AS below_target_months,
       ROUND(COUNT(*) FILTER(WHERE p.achievement_pct < 100)::NUMERIC
           / NULLIF(COUNT(*), 0) * 100
           	, 2) AS below_target_pct
FROM monthly_category_performance p
JOIN master.categories cat
  	ON p.category_id = cat.category_id
GROUP BY cat.category_id,
         cat.category_name
ORDER BY below_target_months DESC,
         below_target_pct DESC,
         category;
		 


/*==============================================================
 09. NEAREST TARGET REGIONS
==============================================================*/

SELECT entity AS region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_gap_pct
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Region'
ORDER BY achievement_pct DESC;



/*==============================================================
 10. NEAREST TARGET CATEGORIES
==============================================================*/

SELECT entity AS category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_gap_pct
FROM analytics.vw_underperformance_analysis
WHERE level_type = 'Category'
ORDER BY achievement_pct DESC;



/*==============================================================
 UNDERPERFORMANCE ANALYSIS COMPLETE
 Output: Underperforming regions and categories, target-gap
         rankings, repeated underperformance, and near-target
         recovery opportunities.
==============================================================*/