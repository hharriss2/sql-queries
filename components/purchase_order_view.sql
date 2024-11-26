--purchase orders view
with t1 as 
(
select * 
	,coalesce(shipped_date, cancel_by_date - interval' 7 days')::date as new_shipped_date
from components.purchase_orders
)
select order_sk
	,customer_name
	,sale_type
	,warehouse_name
	,warehouse_number
	,is_crossborder
	,model
	,product_name
	,order_line_number
	,new_shipped_date as shipped_date
	,cancel_by_date
	,order_count_key
	,order_line_quantity
	,order_line_bundle_quantity
	,order_line_price
	,order_line_amt
	,order_line_status
	,order_line_performance
	,order_priority
	,truck_id
	,truck_created_datetime
	,truck_left_the_yard_date
	,pick_group
	,building_assigned
	,inserted_at
from t1
where shipped_date >='2024-10-01'
;
