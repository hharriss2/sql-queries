--get info for dsv orders, commissions, and est shipping cost
create or replace view pos_reporting.dsv_orders_3p_recon as
(
with o as --orders
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
	,case -- new status to join on commissions
		when status !='Refund'
		then 'Commission'
		else status
	end as commission_status
	,status
	,tracking_number
	,state_name as state_abr -- abbreviated state name
from pos_reporting.dsv_orders_3p ord
left join clean_data.wm_catalog_3p w
on ord.sku = w.model
where 1=1
and status !='Cancelled'
-- june 1st - 30th. item info. 
--commission, (pos - commission) & calculated ship rate
)
,sn as --state name
(
select distinct state
,statefullname as state_name
from zipcodes
)
,comm1 as --commission step 1
(
select 
	po_id
	,model
	,amount_dollars
	,commission_amt
	,case-- updating amount type to join on commission status
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
,cs as --calculated shipping cost
(--get the average shipping cost for an item where the zone is 5
select * 
from components.item_shipping_cost
where zone_number = '5' -- average zone
)
,sl as --suppression list
(
select * 
from lookups.model_suppression_list
)
,inv as --inventory
(
select * 
from components.dsv_3p_inventory_agg
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
	,coalesce(comm.commission_amt, o.order_total * -.15) as commission_amt
	,(coalesce(rates.rate_amount,cs.total_shipping_cost) * o.qty::numeric)::numeric(10,2) as rate_amount
	,o.state_abr
	,sn.state_name
	,case
		when sl.model is not null 
		then 1
		else 0
		end as is_suppression_model
from o 
left join comm
on o.po_id = comm.po_id
and o.commission_status = comm.amount_type
and o.model = comm.model
left join rates
on o.tracking_number = rates.tracking_number
left join sn on
o.state_abr = sn.state
left join cs
on o.model = cs.model
and status not in ('Refund','Cancelled')
left join sl
on o.model = sl.model
)
select *
from details
)
;
