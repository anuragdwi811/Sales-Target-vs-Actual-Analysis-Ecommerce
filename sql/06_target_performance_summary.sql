/*==============================================================
 Project     : Sales Target vs Actual Performance Analysis
 File        : 06_target_performance_summary.sql
 Module      : Final Target Performance Summary
 Purpose     : Create the final analytical dataset combining
               sales, order, and unit target performance
               across months, regions, and categories
 Sales Rule  : Delivered orders are treated as realized sales
 Grain       : Month + Region + Category
 Output      : Power BI-ready analytical dataset for target vs
               actual performance analysis
==============================================================*/



/*==============================================================
 01. FINAL TARGET PERFORMANCE SUMMARY
==============================================================*/

WITH target AS (
	    SELECT t.target_month AS period,
	           t.region,
	           t.category_id,
	           SUM(t.sales_target) AS sales_target,
	           SUM(t.order_target) AS order_target,
	           SUM(t.unit_target) AS unit_target	
	    FROM sales.sales_targets t	
	    GROUP BY t.target_month,
	        	 t.region,
	        	 t.category_id),

	actual AS (
	    SELECT DATE_TRUNC('month', o.order_date)::DATE AS period,
	           c.region,
	           p.category_id,
	           SUM(oi.item_revenue) AS actual_sales,
	           COUNT(DISTINCT o.order_id) AS actual_orders,
	           SUM(oi.quantity) AS actual_units	
	    FROM sales.orders o	
	    JOIN sales.order_items oi
	        ON o.order_id = oi.order_id	
	    JOIN master.customers c
	        ON o.customer_id = c.customer_id	
	    JOIN master.products p
	        ON oi.product_id = p.product_id	
	    WHERE o.order_status = 'Delivered'	
	    GROUP BY DATE_TRUNC('month', o.order_date)::DATE,
	        	 c.region,
	        	 p.category_id),

	final_summary AS (
	    SELECT t.period,
	           t.region,
	           cat.category_name AS category,
	
	           t.sales_target,
	           COALESCE(a.actual_sales, 0) AS actual_sales,
	           COALESCE(a.actual_sales, 0) - t.sales_target AS sales_variance,
	           ROUND(COALESCE(a.actual_sales, 0)::NUMERIC
	            / NULLIF(t.sales_target, 0) * 100
	            	, 2) AS achievement_pct,
	
	           t.order_target,
	           COALESCE(a.actual_orders, 0) AS actual_orders,
	           COALESCE(a.actual_orders, 0) - t.order_target AS order_variance,
	           ROUND(COALESCE(a.actual_orders, 0)::NUMERIC
	            / NULLIF(t.order_target, 0) * 100
	            	, 2) AS order_achievement_pct,
	
	           t.unit_target,
	           COALESCE(a.actual_units, 0) AS actual_units,
	           COALESCE(a.actual_units, 0) - t.unit_target AS unit_variance,
	           ROUND(COALESCE(a.actual_units, 0)::NUMERIC
	            / NULLIF(t.unit_target, 0) * 100
	            	, 2) AS unit_achievement_pct	
	    FROM target t	
	    JOIN master.categories cat
	        ON t.category_id = cat.category_id	
	    LEFT JOIN actual a
	        ON t.period = a.period
	       AND t.region = a.region
	       AND t.category_id = a.category_id)

SELECT period,
       region,
       category,

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
FROM final_summary
ORDER BY period,
         region,
    	 category;

		 

/*==============================================================
 FINAL TARGET PERFORMANCE SUMMARY COMPLETE
 Output: Power BI-ready analytical dataset at Month + Region
         + Category grain with sales, order, and unit target
         performance metrics.
==============================================================*/
