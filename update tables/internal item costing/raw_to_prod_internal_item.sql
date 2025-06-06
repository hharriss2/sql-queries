
--inserting the raw excel file into the production table, components schema
insert into item_costing.item_costing_tbl
	(
	model_wh_country_key
	,model
	,warehouse_number
	,description
	,origin_country
	,hts_code
	,duty_free
	,container_qty
	,material_cost
	,duty_cost
	,freight_cost
	,purchase_overhead_cost
	,labor_cost
	,total_overhead_cost
	,setup_labor_cost
	,material_overhead_cost
	,imp_status
	,unit_type
	)
select distinct
	right(model,length(model) -2) ||'-'||warehouse_number::text||'-'||coalesce(origin_country,'N/A') ||'-'
	||'-'||to_char(inserted_at,'YYMM') -- date that needs to be changed
	--^composite key to find unqiue record based off model, warehouse & origin country
	,right(model,length(model) -2)
	,warehouse_number
	,description
	,coalesce(origin_country,'N/A')
	,hts_code
	,duty_free
	,container_qty
	,material_cost
	,duty_cost
	,freight_cost
	,purchase_overhead_cost
	,labor_cost
	,total_overhead_cost
	,setup_labor_cost
	,material_overhead_cost
	,imp_status
	,unit_type
from dapl_raw.internal_item_costing
;
--fix the blank space  issue with the warehouse numbers
update item_costing.item_costing_tbl
set warehouse_number = rtrim(warehouse_number,' ') 