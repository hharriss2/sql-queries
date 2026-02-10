--used in the https://app.powerbi.com/groups/d81c28c1-373d-402a-9522-e5c6d8f31988/reports/9f5edad7-50b7-4919-9e75-759151053a57?ctid=be702899-adb0-4f70-a46a-8c9219608ab8&pbi_source=linkShare
--wm scorecard report
create or replace view power_bi.fact_wm_scorecard as 
(
select
sc.metric_name
,walmart_item_number
,sc.metric_category
,last_week_ty
,last_week_ly
,last_week_diff
,current_month_ty
,current_month_ly
,current_month_diff
,last_month_ty
,last_month_ly
,last_month_diff
,year_ty
,year_ly
,year_diff
,last_week_wm_date_range
,current_month_wm_date_range
,last_month_wm_date_range
,year_wm_date_range
,sc.inserted_at::date as upload_date
,case
	when sc.inserted_at::date = (select max(inserted_at::date) from pos_reporting.wm_scorecards)
	then 1
	else 0
	end as is_current_date
,mo.scorecard_metric_id
,mcl.product_name

from pos_reporting.wm_scorecards sc
JOIN lookups.wm_scorecard_metric_order mo 
ON sc.metric_category = mo.metric_category AND sc.metric_name = mo.metric_name
left join clean_data.master_com_list mcl 
on sc.walmart_item_number = mcl.item_id
where 1=1
)
;
