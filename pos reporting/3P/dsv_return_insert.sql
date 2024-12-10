--creates a template to convert rate information into pos information. 
--this one specifically looks for refunded items and adds them to 3P POS
--DSV Data inserts, then this is used to insert refunds, then all the data is uploaded to retail_link_pos tabl 
create or replace view dapl_raw.dsv_return_3p_insert as 
(
with orders1 as  -- first step in making the recon rates data the same as orders data
(
select po_id
,model as sku
,transaction_posted_date as order_date
,transaction_type
	,sum(units) as qty
	,sum(amount_dollars) as order_total
	,'Delivered' as status
	,'DELIVERY' as ship_type
from dapl_raw.dsv_orders_3p_rates
where 1=1
and amount_type = 'Product Price'
and transaction_type ='Refund'
and po_id not in (select po_id from pos_reporting.dsv_orders_3p where order_total <0)
group by po_id, model,transaction_posted_date, transaction_type
,model
)
,orders2 as -- 2nd step in making recon rates data modeled like orders
(
select 
	po_id
	,order_date
	,sku
	,case
		when transaction_type = 'Refund'
		then qty * -1
		else qty
		end as qty
	,case
		when transaction_type = 'Sale'
		then status
		else 'Refund'
		end as status
	,ship_type
	,order_total
	,row_number() over (partition by po_id order by order_total desc) as line_number -- creating a line number
	--ordering by desc to give the lowest amount the highest line number. helps with negative numbers 
from orders1
)
,ml as --max line number
( -- finding the max line number for the po_id so we can add on the line number calculated in orders2
select po_id
	,max(line_number) as max_line_number
from pos_reporting.dsv_orders_3p
group by po_id
) -- 
select 
	(o2.po_id::text || coalesce(line_number + max_line_number, line_number))::bigint as dsv_order_id
	,o2.po_id
	,order_date
	,sku
	,qty
	,status
	,ship_type
	,order_total
	,coalesce(line_number + max_line_number, line_number) as line_number
    ,now() as updated_on
from orders2 o2
left join ml 
on o2.po_id = ml.po_id

)
;

