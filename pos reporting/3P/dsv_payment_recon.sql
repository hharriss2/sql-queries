with ss as --service sales
(
select
	po_id
	,case
		when amount_type ='Product Price'
		then amount_dollars
		else null
		end as sale_price
	,case
		when amount_type ='Product Price'
		then units
		else null
		end as units_sold
	,case
		when amount_type ='Product tax'
		then amount_dollars
		else null
		end as sales_tax
	,case
		when amount_type = 'Commission on Product'
		then commission_amt
		else null
		end as comission_amount
	,case
		when amount_type = 'Commission on Product'
		then original_commission_amt
		else null
		end as original_commission_amt
	,case
		when amount_type = 'Commission on Product'
		then commission_saving_amt
		else null
		end as commission_saving_amt
	,commission_rule
from dapl_raw.dsv_orders_3p_rates
where transaction_type = 'Refund'
--order by period_start_date
--and po_id =108915527167053
)
,dsv as 
(
select distinct po_id
	,sale_date
	,model
	,item_id
	,product_name
	,sum(units) as total_units_pos
	,sum(sales) as total_sales_pos
from dapl_raw.dsv_orders_3p_insert_pos_view
group by po_id, sale_date,model,item_id, product_name
)
,dsv_rate as 
(
select po_id
,sum(sale_price) as total_sales_rate
,sum(units_sold) as total_units_rate
,sum(sales_tax) as total_tax
,sum(comission_amount) as total_commission
,sum(original_commission_amt) as total_original_comission
,sum(commission_saving_amt) as total_commission_saving_amt
,commission_rule
from ss
group by po_id
,commission_rule
)
,item_commission as --gives the total amount of service commission for items
(
select
	dsv_rate.po_id
	,item_id
	,model
	,product_name
	,sale_date
	,total_units_pos
	,total_sales_pos
	,total_sales_rate
	,total_units_rate
	,total_tax
	,total_commission
	,total_original_comission
	,total_commission_saving_amt
	,commission_rule
from dsv
right join dsv_rate
on dsv.po_id = dsv_rate.po_id
)
,rf as--return fees
(
select
	po_id
	,transaction_description
	,sum(amount_dollars) as total_service_fee
from dapl_raw.dsv_orders_3p_rates
where amount_type = 'Item Fees'
group by po_id
,transaction_description
)
,item_return as 
(
select
	rf.po_id
	,item_id
	,model
	,product_name
	,total_service_fee
	,transaction_description
	,sale_date
	,total_units_pos
	,total_sales_pos
from rf
left join dsv
on rf.po_id = dsv.po_id
)
select * 
from item_commission
;

select
	po_id
	,transaction_description
	,sum(amount_dollars) as total_service_fee
from dapl_raw.dsv_orders_3p_rates
where amount_type = 'Item Fees'
group by po_id
,transaction_description

;
select *
from dapl_raw.dsv_orders_3p_rates
where transaction_type = 'Refund'