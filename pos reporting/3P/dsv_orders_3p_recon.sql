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
	,acknowledged_on
	,shipped_on
	,delivered_on
	,coalesce(w.item_status,'Not Found') as item_status
	,est_ship_date
from pos_reporting.dsv_orders_3p ord
left join clean_data.current_wm_catalog_3p w -- list of all models that have ran dsv
on ord.sku = w.model
-- left join components.wm_catalog_3p wc
-- on ord.sku = wc.model
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
select distinct tracking_number
	,rate_amount
	,rate_type
	,origin_postal_code
from pos_reporting.tracking_rates_view
)
,cs as --calculated shipping cost
(--get the average shipping cost for an item where the zone is 5
select * 
from components.item_shipping_cost_tbl
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
,icd as --item costing dates
(
select distinct cost_date, max(cost_date) over() as latest_cost_date
from item_costing.item_costing_tbl

)
,dim_model as 
(
	select * 
	from dim_sources.dim_models
)
,details as (
select
	dsv_order_id
	,o.po_id
	,o.tracking_number
	,o.order_date::date as order_date
	,o.model
	,o.item_id
	,o.product_name
	,o.status
	,o.qty
	,o.order_total
	,coalesce(comm.commission_amt, o.order_total * -.15) as commission_amt
	,(coalesce(rates.rate_amount,cs.shipping_cost) * o.qty::numeric)::numeric(10,2) as rate_amount
	,o.state_abr
	,sn.state_name
	,case
		when sl.model is not null 
		then 1
		else 0
		end as is_suppression_model
	,case 
		when rate_type = 'Multi Box'
		then 1
		else 0
		end as is_multi_box
	,rates.origin_postal_code
	,acknowledged_on
	,shipped_on
	,delivered_on
	,item_status
	,o.est_ship_date
	,o.order_date as order_date_time
	,case
		when icd.cost_date is not null
		then icd.cost_date 
		when o.order_date::date <='2024-10-01'
		then '2024-10-01'::date
		else max(latest_cost_date) over ()
		end as cost_date
	,dim_model.model_id
from o 
left join dim_model
on o.model = dim_model.model_name
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
left join icd
on date_trunc('month',o.order_date)::date = icd.cost_date
)
select *
from details
)
;
