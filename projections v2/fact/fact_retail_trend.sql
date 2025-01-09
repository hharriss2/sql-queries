create or replace view power_bi.fact_retail_trend as 
(
select rt.*
	,di.item_id_id
from projections.retail_trend rt
left join dim_sources.dim_wm_item_id di
on rt.item_id = di.item_id
)
;