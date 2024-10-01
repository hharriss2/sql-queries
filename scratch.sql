update dapl_raw.dsv_3p_tracking_rates t1
set 
rate_type = t2.rate_type
,rate_amount = t2.rate_amount
,rate_zone = t2.rate_zone
,rate_method = t2.rate_method
,origin_postal_code = t2.origin_postal_code
,dest_postal_code = t2.dest_postal_code
,weight_lbs = t2.weight_lbs
,length = t2.length
,width = t2.width
,height = t2.height
,updated_on = t2.updated_on
,dims_source = t2.dims_source
from dapl_raw.temp_dsv_tracking_rates t2
where t1.tracking_number = t2.tracking_number
and t2.dims_source = 'Internal'
and t2.length !=0