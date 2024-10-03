
--view used in the fed ex api. 
--purpose is to replace the dims with internal dims vs what fed ex provides.
--if dims are zeroed out, use fed ex's
create or replace view dapl_raw.dsv_3p_tracking_rates_py_view as 
(
with tr as 
(
select * 
from dapl_raw.dsv_3p_tracking_rates
)
,o as 
(
select tracking_number, sku
from pos_reporting.dsv_orders_3p
)
,ic as 
(
select *
from lookups.dsv_item_cost_3p
where length !=0
)
select 
	tr.tracking_number
	,origin_postal_code
	,dest_postal_code
	,coalesce(ic.weight, tr.weight_lbs) as weight_lbs
	,coalesce(ic.length, tr.length) as length
	,coalesce(ic.width, tr.width) width
	,coalesce(ic.height, tr.height) height
	,case
		when tr.length = ic.length
		and tr.width = ic.width
		and tr.height = ic.height
		then 'Both'
		when (tr.length = 0 or tr.length is null) and ic.length !=0
		then 'Internal'
		else 'FedEx'
		end as dims_source
	,tr.rate_amount
	,tracking_error_message
from tr
join o
on tr.tracking_number = o.tracking_number
left join ic
on o.sku = ic.model
)