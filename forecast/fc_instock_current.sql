--most recent instock report for it's month 
create or replace view forecast.fc_instock_current as (
select * 
from 
	(
select distinct dense_rank() over (partition by date_part('month',report_date) order by report_date desc) as is_recent_report
	,vendor_stock_id
	, end_of_week_oh_unit
	, on_order_unit
	, report_date
	, item_id
from forecast.fc_instock
	) t1
where is_recent_report = 1
)
;
