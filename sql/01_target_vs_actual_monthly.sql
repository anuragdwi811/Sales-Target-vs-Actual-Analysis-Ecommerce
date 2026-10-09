/*==============================================================
 Project     : Sales Target vs Actual Performance Analysis
 File        : 01_target_vs_actual_monthly.sql
 Module      : Monthly Target vs Actual Analysis
 Purpose     : Compare monthly sales, order, and unit performance
               against planned targets
 Sales Rule  : Delivered orders are treated as realized sales
 Output      : Monthly target vs actual performance analysis
==============================================================*/



/*==============================================================
 CREATE MONTHLY TARGET VS ACTUAL VIEW
==============================================================*/

CREATE OR REPLACE VIEW analytics.vw_monthly_target_vs_actual AS

WITH sales AS (
		SELECT DATE_TRUNC('month', o.order_date)::DATE AS month,
			   COUNT(DISTINCT o.order_id) AS total_orders,
			   SUM(oi.item_revenue) AS total_revenue,
			   SUM(oi.quantity) AS total_quantity
		FROM sales.orders o
		JOIN sales.order_items oi
			USING (order_id)
		WHERE o.order_status = 'Delivered'
		GROUP BY month),

	target AS (
		SELECT target_month,
			   SUM(sales_target) AS sales_target,
			   SUM(order_target) AS order_target,
			   SUM(unit_target) AS unit_target
		FROM sales.sales_targets
		GROUP BY target_month)
		
SELECT s.month,

	   t.sales_target,
	   s.total_revenue AS actual_sales,
	   s.total_revenue - t.sales_target AS sales_variance,
	   ROUND((s.total_revenue::NUMERIC / NULLIF(t.sales_target, 0)) * 100
	   		, 2) AS achievement_pct,
			   
	   t.order_target,
	   s.total_orders AS actual_orders,
	   s.total_orders - t.order_target AS order_variance,
	   ROUND(s.total_orders::NUMERIC / NULLIF(t.order_target, 0) * 100
	   		, 2) AS order_achievement_pct,
			   
	   t.unit_target,
	   s.total_quantity AS actual_units,
	   s.total_quantity - t.unit_target AS unit_variance,
	   ROUND(s.total_quantity::NUMERIC / NULLIF(t.unit_target, 0) * 100
	   		, 2) AS unit_achievement_pct
FROM sales s
JOIN target t
	ON s.month = t.target_month;
	   


/*==============================================================
 01. MONTHLY TARGET VS ACTUAL
==============================================================*/

SELECT month,
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
FROM analytics.vw_monthly_target_vs_actual
ORDER BY month;



/*==============================================================
 02. MONTHLY TARGET ACHIEVEMENT STATUS
==============================================================*/

SELECT month,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   CASE
	   		WHEN achievement_pct >= 100 THEN 'Target Achieved'
			WHEN achievement_pct BETWEEN 90 AND 99.99 THEN 'Near Target'
			ELSE 'Below Target'
	   END AS target_status
FROM analytics.vw_monthly_target_vs_actual
ORDER BY month;



/*==============================================================
 03. ABOVE-TARGET MONTHS
==============================================================*/

SELECT month,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_monthly_target_vs_actual
WHERE achievement_pct >= 100
ORDER BY month;



/*==============================================================
 04. BELOW-TARGET MONTHS
==============================================================*/

SELECT month,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_monthly_target_vs_actual
WHERE achievement_pct < 100
ORDER BY month;



/*==============================================================
 05. LARGEST POSITIVE SALES VARIANCE
==============================================================*/

SELECT month,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_monthly_target_vs_actual
WHERE sales_variance > 0
ORDER BY sales_variance DESC
LIMIT 1;



/*==============================================================
 06. LARGEST NEGATIVE SALES VARIANCE
==============================================================*/

SELECT month,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct
FROM analytics.vw_monthly_target_vs_actual
WHERE sales_variance < 0
ORDER BY sales_variance
LIMIT 1;



/*==============================================================
 07. MONTHLY ORDER ACHIEVEMENT
==============================================================*/

SELECT month,
	   order_target,
	   actual_orders,
	   order_variance,
	   order_achievement_pct
FROM analytics.vw_monthly_target_vs_actual
ORDER BY month;



/*==============================================================
 08. MONTHLY UNIT ACHIEVEMENT
==============================================================*/

SELECT month,
	   unit_target,
	   actual_units,
	   unit_variance,
	   unit_achievement_pct
FROM analytics.vw_monthly_target_vs_actual
ORDER BY month;



/*==============================================================
 MONTHLY TARGET VS ACTUAL ANALYSIS COMPLETE
 Output: Monthly sales, order, and unit target performance.
==============================================================*/
