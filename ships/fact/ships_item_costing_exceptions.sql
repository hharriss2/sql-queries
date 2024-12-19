
--adding an exceptions report for item costing and shipment data
create or replace view power_bi.fact_ships_item_costing_exceptions as 
(
with sa as --ships aggregate
( -- bringing in ships item data summed up by month
select
	model
	,tool_id
	,division
	,product_name
	,cat
	,sub_cat
    ,date_shipped
	,date_trunc('month',date_shipped)::date as month_shipped
	,retailer
	,sale_type
	,warehouse
    ,units
    ,sales
    ,sales/units as ship_cost
	-- ,sum(units) as units
	-- ,sum(sales) as sales
from ships_schema.ships_view
where date_shipped >='2024-10-01'
-- and date_shipped <='2024-11-30'
and division !='Cosco Products'
-- group by model
-- 	,tool_id
-- 	,division
-- 	,product_name
-- 	,cat
-- 	,sub_cat
-- 	,date_trunc('month',date_shipped)::date
-- 	,retailer
-- 	,sale_type
-- 	,warehouse
)
,ic as  -- item costing
( -- historical costs of our items
select
	model
	,warehouse_number
	,origin_country
	,container_qty
	,material_cost
	,duty_cost
	,freight_cost
	,cost_date
	,unit_type
	,max(cost_date) over() as recent_cost_date
from item_costing.item_costing_tbl
)
,si as --ships item
(--combining the ships and the item costing
select
	sa.model
	,sa.tool_id
	,sa.division
	,sa.product_name
	,sa.cat
	,sa.sub_cat
	,sa.date_shipped
	,sa.month_shipped
	,sa.retailer
	,sa.sale_type
	,sa.units
	,sa.sales
	,sa.ship_cost
	,sa.warehouse
	,origin_country
	,container_qty
	,material_cost
	,duty_cost
	,freight_cost
	,unit_type
	,lag(origin_country) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped) AS prev_origin_country
	,lag(origin_country) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped desc) AS next_origin_country
	,lag(material_cost) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped) AS prev_material_cost
	,lag(material_cost) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped desc) AS next_material_cost
	,lag(duty_cost) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped) AS prev_duty_cost
	,lag(duty_cost) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped desc) AS next_duty_cost
	,lag(freight_cost) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped) AS prev_freight_cost
	,lag(freight_cost) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped desc) AS next_freight_cost
	,lag(warehouse) OVER (PARTITION BY sa.model, warehouse ORDER BY month_shipped desc) AS next_warehouse
	,recent_cost_date
    ,(material_cost + duty_cost + freight_cost) as cogs
	,(material_cost + duty_cost + freight_cost) * units as net_cost
    ,case
        when ic.model is not null
        then 1
        else 0
        end as has_costing
from sa
left join ic
on ic.model = sa.model
and ic.warehouse_number = sa.warehouse
and ic.cost_date = sa.month_shipped
)
,sic as --ships item conditionals
( --creating conditionals for flagging changes in power bi
select *
    ,case
        when material_cost != prev_material_cost and prev_material_cost is not null
        then 1
        when material_cost !=next_material_cost and next_material_cost is not null
        then 1
        else 0
        end as is_material_change
    ,case
        when duty_cost != prev_duty_cost and prev_duty_cost is not null
        then 1
        when duty_cost !=next_duty_cost and next_duty_cost is not null
        then 1
        else 0
        end as is_duty_change 
    ,case
        when freight_cost != prev_freight_cost and prev_freight_cost is not null
        then 1
        when freight_cost !=next_freight_cost and next_freight_cost is not null
        then 1
        else 0
        end as is_freight_change 
    ,case
        when origin_country != prev_origin_country and prev_origin_country is not null
        then 1
        when origin_country !=next_origin_country and next_origin_country is not null
        then 1
        else 0
        end as is_origin_change 
    ,case
        when month_shipped = recent_cost_date
        then 0
        when next_warehouse is null
        then 1
        else 0
        end as is_missing_warehouse
from si
)
select
	model
	,tool_id
	,division
	,product_name
	,cat
	,sub_cat
	,date_shipped
	,month_shipped
	,retailer
	,sale_type
	,units
	,sales
	,ship_cost
	,warehouse
	,origin_country
	,container_qty
	,material_cost
	,duty_cost
	,freight_cost
	,unit_type
	,is_material_change
	,is_duty_change 
	,is_freight_change 
	,is_origin_change 
    ,is_missing_warehouse
    ,cogs
	,net_cost
	,cast(sales - net_cost as numeric(10,2)) as contribution_margin
    ,case
        when is_material_change -- only care about changes with the item costing report
            +is_duty_change 
            +is_freight_change 
            +is_missing_warehouse
            +is_origin_change >0
        then 1
        else 0
    end as is_exception_change
    ,has_costing
from sic
)
;

