/*==============================================================
 Project     : Sales Target vs Actual Performance Analysis
 File        : 03_target_vs_actual_category.sql
 Module      : Category & Subcategory Performance Analysis
 Purpose     : Analyze category-level target vs actual performance
               and subcategory-level actual sales performance
 Sales Rule  : Delivered orders are treated as realized sales
 Output      : Category target performance and subcategory
               actual performance analysis
==============================================================*/



/*==============================================================
 CREATE CATEGORY TARGET VS ACTUAL VIEW
==============================================================*/

CREATE OR REPLACE VIEW analytics.vw_category_target_vs_actual AS

WITH target AS (
		SELECT category_id,
			   SUM(sales_target) AS sales_target,
			   SUM(order_target) AS order_target,
			   SUM(unit_target) AS unit_target
		FROM sales.sales_targets
		GROUP BY category_id),

	actual AS (
		SELECT cat.category_id,
			   cat.category_name AS category,
			   COALESCE(SUM(CASE
			   			WHEN o.order_status = 'Delivered'
						THEN oi.item_revenue
				   END), 0) AS total_revenue,
			   COALESCE(COUNT(DISTINCT
			   	   CASE
					  	WHEN o.order_status = 'Delivered'
						THEN oi.order_id
				   END), 0) AS total_orders,
			   COALESCE(SUM(CASE
			   			WHEN o.order_status = 'Delivered'
						THEN oi.quantity
				   END), 0) AS total_quantity
		FROM master.categories cat
		LEFT JOIN master.products p
			ON cat.category_id = p.category_id
		LEFT JOIN sales.order_items oi
			ON p.product_id = oi.product_id
		LEFT JOIN sales.orders o
			ON oi.order_id = o.order_id
		GROUP BY cat.category_id)

SELECT a.category,

	   t.sales_target,
	   a.total_revenue AS actual_sales,
	   a.total_revenue - t.sales_target AS sales_variance,
	   ROUND(a.total_revenue / t.sales_target * 100
	   		, 2) AS achievement_pct,
	
	   t.order_target,
	   a.total_orders AS actual_orders,
	   a.total_orders - t.order_target AS order_variance,
	   ROUND(a.total_orders::NUMERIC / t.order_target * 100
	   		, 2) AS order_achievement_pct,
	
	   t.unit_target,
	   a.total_quantity AS actual_units,
	   a.total_quantity - t.unit_target AS unit_variance,
	   ROUND(a.total_quantity::NUMERIC / t.unit_target * 100
	   		, 2) AS unit_achievement_pct
FROM target t
JOIN actual a
	ON t.category_id = a.category_id;



/*==============================================================
 01. CATEGORY TARGET VS ACTUAL
==============================================================*/

SELECT category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   order_target,
	   actual_orders,
	   order_variance,
	   order_achievement_pct,
	   unit_target,
	   actual_units,
	   unit_variance,
	   unit_achievement_pct
FROM analytics.vw_category_target_vs_actual
ORDER BY category;



/*==============================================================
 02. CATEGORIES ACHIEVING SALES TARGET
==============================================================*/

SELECT category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_category_target_vs_actual
WHERE achievement_pct >= 100
ORDER BY achievement_pct DESC;



/*==============================================================
 03. CATEGORIES BELOW SALES TARGET
==============================================================*/

SELECT category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_category_target_vs_actual
WHERE achievement_pct < 100
ORDER BY achievement_pct;



/*==============================================================
 04. HIGHEST POSITIVE SALES VARIANCE CATEGORY
==============================================================*/

SELECT category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_category_target_vs_actual
WHERE sales_variance > 0
ORDER BY sales_variance DESC
LIMIT 1;



/*==============================================================
 05. LARGEST NEGATIVE SALES VARIANCE CATEGORY
==============================================================*/

SELECT category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_category_target_vs_actual
WHERE sales_variance < 0
ORDER BY sales_variance
LIMIT 1;



/*==============================================================
 06. SALES VS UNIT ACHIEVEMENT GAP
==============================================================*/

SELECT category,
	   achievement_pct AS sales_achievement_pct,
	   unit_achievement_pct,
	   achievement_pct - unit_achievement_pct
	   		AS achievement_gap_pct
FROM analytics.vw_category_target_vs_actual
ORDER BY achievement_gap_pct DESC;



/*==============================================================
 07. ORDER VS SALES ACHIEVEMENT GAP
==============================================================*/

SELECT category,
	   achievement_pct AS sales_achievement_pct,
	   order_achievement_pct,
	   achievement_pct - order_achievement_pct
	   		AS achievement_gap_pct
FROM analytics.vw_category_target_vs_actual
ORDER BY achievement_gap_pct DESC;



/*==============================================================
 CREATE SUBCATEGORY ACTUAL PERFORMANCE VIEW
==============================================================*/

CREATE OR REPLACE VIEW analytics.vw_subcategory_actual_performance AS

WITH subcategory_performance AS (
		SELECT cat.category_name AS category,
			   scat.subcategory_name AS subcategory,
			   COALESCE(SUM(
					CASE 
						WHEN o.order_status = 'Delivered'
						THEN oi.item_revenue
						ELSE 0
					END), 0) AS actual_sales,
			   COALESCE(COUNT(DISTINCT
			   		CASE
					   	WHEN o.order_status = 'Delivered'
						THEN oi.order_id
					END), 0) AS actual_orders,
			   COALESCE(SUM(
					CASE
						WHEN o.order_status = 'Delivered'
						THEN oi.quantity
					END), 0) AS actual_units
		FROM master.categories cat
		LEFT JOIN master.subcategories scat
			ON cat.category_id = scat.category_id
		LEFT JOIN master.products p
			ON scat.subcategory_id = p.subcategory_id
		LEFT JOIN sales.order_items oi
			ON p.product_id = oi.product_id
		LEFT JOIN sales.orders o
			ON oi.order_id = o.order_id
		GROUP BY cat.category_name,
				 scat.subcategory_name)
	   
SELECT category,
	   subcategory,
	   actual_sales,
	   actual_orders,
	   actual_units,
	   ROUND(actual_sales / 
	   		NULLIF(SUM(actual_sales) OVER(PARTITION BY category), 0)
	   		* 100, 2) AS sales_contribution
FROM subcategory_performance;



/*==============================================================
 08. SUBCATEGORY ACTUAL PERFORMANCE
==============================================================*/

SELECT category,
	   subcategory,
	   actual_sales,
	   actual_orders,
	   actual_units,
	   sales_contribution
FROM analytics.vw_subcategory_actual_performance
ORDER BY category,
		 actual_sales DESC;



/*==============================================================
 09. SUBCATEGORIES WITHIN UNDERPERFORMING CATEGORIES
==============================================================*/

SELECT category,
	   subcategory,
	   actual_sales,
	   actual_orders,
	   actual_units,
	   sales_contribution
FROM analytics.vw_subcategory_actual_performance
WHERE category IN (SELECT category
				   FROM analytics.vw_category_target_vs_actual
				   WHERE achievement_pct < 100)
ORDER BY category,
		 actual_sales DESC;



/*==============================================================
 10. HIGHEST SUBCATEGORY SALES CONTRIBUTION
==============================================================*/

SELECT category,
	   subcategory,
	   actual_sales,
	   sales_contribution
FROM analytics.vw_subcategory_actual_performance
ORDER BY sales_contribution DESC;



/*==============================================================
 11. CATEGORY SALES VARIANCE WITH SUBCATEGORY PERFORMANCE
==============================================================*/

SELECT s.category,
	   c.sales_variance AS category_sales_variance,
	   s.subcategory,
	   s.actual_sales,
	   s.sales_contribution
FROM analytics.vw_subcategory_actual_performance s
JOIN analytics.vw_category_target_vs_actual c
	USING (category)
ORDER BY s.category,
         s.actual_sales DESC;



/*==============================================================
 CATEGORY & SUBCATEGORY PERFORMANCE ANALYSIS COMPLETE
 Output: Category target performance and subcategory actual
         performance analysis.
==============================================================*/