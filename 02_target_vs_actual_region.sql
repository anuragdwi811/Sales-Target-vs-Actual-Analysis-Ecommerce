/*==============================================================
 Project     : Sales Target vs Actual Performance Analysis
 File        : 02_target_vs_actual_region.sql
 Module      : Region Target vs Actual Analysis
 Purpose     : Compare regional sales, order, and unit performance
               against planned targets
 Sales Rule  : Delivered orders are treated as realized sales
 Output      : Region-wise target vs actual performance analysis
==============================================================*/



/*==============================================================
 CREATE REGION TARGET VS ACTUAL VIEW
==============================================================*/

CREATE OR REPLACE VIEW analytics.vw_region_target_vs_actual AS

WITH actual AS (
		SELECT c.region,
			   SUM(oi.item_revenue) AS total_revenue,
			   COUNT(DISTINCT oi.order_id) AS total_orders,
			   SUM(oi.quantity) AS total_quantity
		FROM master.customers c
		JOIN sales.orders o
			ON c.customer_id = o.customer_id
		JOIN sales.order_items oi
			ON o.order_id = oi.order_id
		WHERE o.order_status = 'Delivered'
		GROUP BY c.region),

	target AS (
		SELECT region,
			   SUM(sales_target) AS sales_target,
			   SUM(order_target) AS order_target,
			   SUM(unit_target) AS unit_target
		FROM sales.sales_targets
		GROUP BY region)

SELECT a.region,

	   t.sales_target AS sales_target,
	   a.total_revenue AS actual_sales,
	   a.total_revenue - t.sales_target AS sales_variance,
	   ROUND(a.total_revenue / t.sales_target * 100
	   		, 2) AS achievement_pct,

	   t.order_target AS order_target,
	   a.total_orders AS actual_orders,
	   a.total_orders - t.order_target AS order_variance,
	   ROUND(a.total_orders::NUMERIC / t.order_target * 100
	   		, 2) AS order_achievement_pct,

	   t.unit_target AS unit_target,
	   a.total_quantity AS actual_units,
	   a.total_quantity - t.unit_target AS unit_variance,
	   ROUND(a.total_quantity::NUMERIC / t.unit_target * 100
	   		, 2) AS unit_achievement_pct
FROM actual a
JOIN target t
	ON a.region = t.region;



/*==============================================================
 01. REGION TARGET VS ACTUAL
==============================================================*/

SELECT region,
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
FROM analytics.vw_region_target_vs_actual;



/*==============================================================
 02. REGIONS ACHIEVING SALES TARGET
==============================================================*/

SELECT region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_region_target_vs_actual
WHERE achievement_pct >= 100
ORDER BY achievement_pct DESC;



/*==============================================================
 03. REGIONS BELOW SALES TARGET
==============================================================*/

SELECT region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_region_target_vs_actual
WHERE achievement_pct < 100
ORDER BY achievement_pct;



/*==============================================================
 04. HIGHEST SALES ACHIEVEMENT REGION
==============================================================*/

SELECT region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_region_target_vs_actual
ORDER BY achievement_pct DESC
LIMIT 1;


/*==============================================================
 05. LARGEST NEGATIVE SALES VARIANCE REGION
==============================================================*/

SELECT region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_region_target_vs_actual
WHERE sales_variance < 0
ORDER BY sales_variance
LIMIT 1;



/*==============================================================
 06. SALES TARGET ACHIEVED BUT ORDER TARGET NOT ACHIEVED
==============================================================*/

SELECT region,
	   sales_target,
	   actual_sales,
	   achievement_pct,
	   order_target,
	   actual_orders,
	   order_achievement_pct
FROM analytics.vw_region_target_vs_actual
WHERE achievement_pct >= 100
	AND order_achievement_pct < 100;



/*==============================================================
 07. ORDER TARGET ACHIEVED BUT UNIT TARGET NOT ACHIEVED
==============================================================*/

SELECT region,
	   order_target,
	   actual_orders,
	   order_achievement_pct,
	   unit_target,
	   actual_units,
	   unit_achievement_pct
FROM analytics.vw_region_target_vs_actual
WHERE order_achievement_pct >= 100
	AND unit_achievement_pct < 100;



/*==============================================================
 REGION TARGET VS ACTUAL ANALYSIS COMPLETE
 Output: Regional sales, order, and unit target performance.
==============================================================*/