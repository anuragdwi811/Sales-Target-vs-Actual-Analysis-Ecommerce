/*==============================================================
 Project     : Sales Target vs Actual Performance Analysis
 File        : 04_target_achievement_analysis.sql
 Module      : Target Achievement Analysis
 Purpose     : Classify and rank monthly, regional, and category
               sales performance based on target achievement
 Sales Rule  : Delivered orders are treated as realized sales
 Classification: >= 100%  → Target Achieved
                 90–99.99% → Near Target
                 < 90%    → Below Target
 Output      : Achievement classification, ranking, status
               summary, and performance opportunity analysis
==============================================================*/



/*==============================================================
 CREATE TARGET ACHIEVEMENT ANALYSIS VIEW
==============================================================*/

CREATE OR REPLACE VIEW analytics.vw_target_achievement_analysis AS

WITH achievement_data AS (
	    SELECT 'Month' AS level_type,
			   month,
			   TO_CHAR(month, 'Mon-YYYY') AS entity,
			   sales_target,
			   actual_sales,
			   sales_variance,
			   achievement_pct
	    FROM analytics.vw_monthly_target_vs_actual

UNION ALL

	    SELECT 'Region' AS level_type,
	           NULL::DATE AS month,
	           region AS entity,
	           sales_target,
	           actual_sales,
	           sales_variance,
	           achievement_pct
	    FROM analytics.vw_region_target_vs_actual

UNION ALL

	    SELECT 'Category' AS level_type,
	           NULL::DATE AS month,
	           category AS entity,
	           sales_target,
	           actual_sales,
	           sales_variance,
	           achievement_pct
	    FROM analytics.vw_category_target_vs_actual)

SELECT level_type,
       month,
       entity,
       sales_target,
       actual_sales,
       sales_variance,
       achievement_pct,
       CASE
        	WHEN achievement_pct >= 100 THEN 'Target Achieved'
        	WHEN achievement_pct >= 90 THEN 'Near Target'
        	ELSE 'Below Target'
       END AS achievement_status
FROM achievement_data;



/*==============================================================
 01. ACHIEVEMENT CLASSIFICATION OVERVIEW
==============================================================*/

SELECT level_type,
	   entity,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
ORDER BY CASE level_type
             WHEN 'Month' THEN 1
             WHEN 'Region' THEN 2
             WHEN 'Category' THEN 3
         END,
         achievement_pct DESC;


/*==============================================================
 02. MONTHLY ACHIEVEMENT CLASSIFICATION
==============================================================*/

SELECT month,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE level_type = 'Month'
ORDER BY month;



/*==============================================================
 03. REGIONAL ACHIEVEMENT CLASSIFICATION
==============================================================*/

SELECT entity AS region,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE level_type = 'Region'
ORDER BY achievement_pct DESC;



/*==============================================================
 04. CATEGORY ACHIEVEMENT CLASSIFICATION
==============================================================*/

SELECT entity AS category,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE level_type = 'Category'
ORDER BY achievement_pct DESC;



/*==============================================================
 05. MONTHLY ACHIEVEMENT RANKING
==============================================================*/

SELECT month,
	   achievement_pct,
	   RANK() 
	   		OVER (ORDER BY achievement_pct DESC)	   
	   			AS achievement_rank,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE level_type = 'Month'
ORDER BY achievement_rank,
         month;



/*==============================================================
 06. REGIONAL ACHIEVEMENT RANKING
==============================================================*/

SELECT entity AS region,
	   achievement_pct,
	   DENSE_RANK()
	   		OVER(ORDER BY achievement_pct DESC)
			   AS achievement_rank,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE level_type = 'Region'
ORDER BY achievement_rank,
         region;
		 


/*==============================================================
 07. CATEGORY ACHIEVEMENT RANKING
==============================================================*/

SELECT entity AS category,
	   achievement_pct,
	   ROW_NUMBER()
	   		OVER(ORDER BY achievement_pct DESC, entity)
			   AS achievement_rank,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE level_type = 'Category'
ORDER BY achievement_rank;


/*==============================================================
 08. ACHIEVEMENT STATUS SUMMARY
==============================================================*/

SELECT level_type,
	   achievement_status,
	   COUNT(*) AS entity_count
FROM analytics.vw_target_achievement_analysis
GROUP BY level_type,
		 achievement_status
ORDER BY level_type,
         achievement_status;


/*==============================================================
 09. BELOW TARGET ANALYSIS
==============================================================*/

SELECT level_type,
	   entity,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE achievement_pct < 90
ORDER BY achievement_pct;



/*==============================================================
 10. NEAR TARGET OPPORTUNITY ANALYSIS
==============================================================*/

SELECT level_type,
	   entity,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE achievement_pct >= 90
  	AND achievement_pct < 100
ORDER BY achievement_pct DESC;



/*==============================================================
 11. TOP ACHIEVEMENT PERFORMERS
==============================================================*/

SELECT level_type,
	   entity,
	   sales_target,
	   actual_sales,
	   sales_variance,
	   achievement_pct,
	   achievement_status
FROM analytics.vw_target_achievement_analysis
WHERE achievement_pct >= 100
ORDER BY achievement_pct DESC;



/*==============================================================
 TARGET ACHIEVEMENT ANALYSIS COMPLETE
 Output: Achievement classification, ranking, status summary,
         and target performance opportunity analysis.
==============================================================*/
