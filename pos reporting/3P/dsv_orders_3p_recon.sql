--get info for dsv orders, commissions, and est shipping cost
create or replace view pos_reporting.dsv_orders_3p_recon as
(
with o as 
(
select 
	dsv_order_id
	,po_id
	,order_date
	,sku as model
	,w.item_id
	,w.product_name
	,qty
	,order_total
	,case
		when status !='Refund'
		then 'Commission'
		else status
	end as commission_status
	,status
	,tracking_number
from pos_reporting.dsv_orders_3p ord
left join clean_data.wm_catalog_3p w
on ord.sku = w.model
where 1=1
and status !='Cancelled'
-- june 1st - 30th. item info. 
--commission, (pos - commission) & calculated ship rate
)
,comm1 as --commission step 1
(
select 
	po_id
	,model
	,amount_dollars
	,commission_amt
	,case
		when transaction_type = 'Refund'
		then 'Refund'
		else 'Commission'
		end as amount_type
from dapl_raw.dsv_orders_3p_rates
where amount_type = 'Commission on Product'
--and po_id = 108916248937833
)
,comm as --commission
(
select
	po_id
	,model
	,amount_type
	,sum(amount_dollars) as commission_amt
from comm1
group by po_id, model, amount_type
)
,rates as
(
select tracking_number
	,rate_amount
from dapl_raw.dsv_3p_tracking_rates
)
,details as 
(
select
	dsv_order_id
	,o.po_id
	,o.tracking_number
	,o.order_date::date
	,o.model
	,o.item_id
	,o.product_name
	,o.status
	,o.qty
	,o.order_total
	,comm.commission_amt
	,rates.rate_amount
from o 
left join comm
on o.po_id = comm.po_id
and o.commission_status = comm.amount_type
and o.model = comm.model
left join rates
on o.tracking_number = rates.tracking_number
)
select *
from details
)
;
