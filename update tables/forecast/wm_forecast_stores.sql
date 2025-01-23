--puts the raw into production table
insert into forecast.wm_forecast_stores
(vendor_number
,item_number
,product_name
,upc
,gtin
,vendor_stock_number
,store_count
,forecast_units
,forecast_date)
select
vendor_number
,item_number
,product_name
,upc
,gtin
,vendor_stock_number
,store_count
,forecast_units
,forecast_date
from  dapl_raw.wm_forecast_stores