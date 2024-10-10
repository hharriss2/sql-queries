update  components.item_shipping_cost_tbl t1
set weight = t2.weight
,length = t2.length
,height = t2.height
,shipping_cost = t2.total_shipping_cost
,is_multi_box = 1
from temp_mb t2
where
t1.model = t2.model and t1.zone_number = t2.zone_number
;