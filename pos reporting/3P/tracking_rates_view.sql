--used as a more detailed view for the tracking data in daple raw
--includes model & prices for multi packaged items
create or replace view pos_reporting.tracking_rates_view as(

with mb as --multi box
(
select
	tracking_number
	,'Multi Box' as rate_type
	,sum(rate_amount)::numeric(10,2) as rate_amount
	,sum(weight_lbs)::numeric(10,2) as weight_lbs
	,sum(length)::numeric(10,2) as length
	,sum(width)::numeric(10,2) as width
	,sum(height)::numeric(10,2) as height
	,'Internal' as dims_source
from components.multi_box_shipping_rate
group by tracking_number
)
select 
d.sku as model
,tr.tracking_number
,coalesce(mb.rate_type,tr.rate_type) as rate_type
,coalesce(mb.rate_amount,tr.rate_amount) as rate_amount
,tr.rate_zone
,tr.rate_method
,tr.origin_postal_code
,tr.dest_postal_code
,coalesce(mb.weight_lbs,tr.weight_lbs) as weight_lbs
,coalesce(mb.length,tr.length) as length
,coalesce(mb.width,tr.width) as width
,coalesce(mb.height,tr.height) as height
,tr.inserted_at
,tr.rate_error_message
,tr.address_type
,tr.updated_on
,tr.tracking_error_message
,coalesce(mb.dims_source,tr.dims_source) as dims_source 
,ic.weight as internal_weight
,ic.length as internal_length
,ic.width as internal_width
,ic.height as internal_height
from dapl_raw.dsv_3p_tracking_rates tr
left join pos_reporting.dsv_orders_3p d
on tr.tracking_number = d.tracking_number
left join lookups.dsv_item_cost_3p ic
on d.sku = ic.model
left join mb
on tr.tracking_number = mb.tracking_number
)