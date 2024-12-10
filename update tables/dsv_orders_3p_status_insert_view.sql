--used to log the status change date & time for orders
--view is executed before the dsv_orders_insert_view
create or replace view dapl_raw.dsv_orders_3p_status_insert_view as 
(
with os as --insert status
(--finds the status from the recently inserted dsv ordres
select dsv_order_id
	,status
from dapl_raw.dsv_order_insert_view
)
,details as 
(-- looks for different statuses from the dsv order prod table and soon to be inserted dapl_raw
select o.dsv_order_id
	,o.status as prev_status -- what the status currently is 
	,os.status as updated_status -- what the status will change to after the upsert
	,delivered_on
	,shipped_on
	,acknowledged_on
	,cancelled_on
from pos_reporting.dsv_orders_3p o
join os
on o.dsv_order_id = os.dsv_order_id
where 1=1
)
-- final part
-- if the status changes, take the current timestamp
--the created on will alwys be order_date
--refunded on can be order_date
--delivered, aknowledges, shipped, cancelled will be the columns below
--criteria: if the timestamp is not null, we don't overwrite with a new time
    --update the timestamp column based on the updated status
    --if no update, null
select 
dsv_order_id
,case
    when delivered_on is not null
    then delivered_on
    when updated_status = 'Delivered'
    then now()
    else null
    end as delivered_on_update
,case
    when shipped_on is not null
    then shipped_on
    when updated_status = 'Shipped'
    then now()
    else null
    end as shipped_on_update
,case
    when acknowledged_on is not null
    then acknowledged_on
    when updated_status = 'Acknowledged'
    then now()
    else null
    end as acknowledged_on_update
,case
    when cancelled_on is not null
    then cancelled_on
    when updated_status = 'Cancelled'
    then now()
    else null
    end as cancelled_on_update
from details
)
;

