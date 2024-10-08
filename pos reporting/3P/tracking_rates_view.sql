create or replace view pos_reporting.tracking_rates_view as(
select d.sku as model
,t.*
,ic.weight as internal_weight
,ic.length as internal_length
,ic.width as internal_width
,ic.height as internal_height
from dapl_raw.dsv_3p_tracking_rates t
left join pos_reporting.dsv_orders_3p d
on t.tracking_number = d.tracking_number
left join lookups.dsv_item_cost_3p ic
on d.sku = ic.model
)