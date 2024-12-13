--a report with just the warehouse numbers 
create or replace view power_bi.fact_warehouse_on_hands as 
(
select woh.*
	,cbm.cbm_id
	,din.item_number_id
from inventory.wm_warehouse_on_hands woh
left join clean_data.master_com_list mcl
on woh.walmart_item_number = mcl.item_id
left join cat_by_model cbm 
on mcl.model = cbm.model
left join power_bi.dim_item_number din
on woh.walmart_item_number = din.item_number
limit 1000
)
;
