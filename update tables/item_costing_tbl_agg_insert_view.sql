create or replace view etl_views.item_costing_tbl_agg_insert_view as 
(
with ici as --item costing table items
( -- find the unique models in the item costing table
select distinct
	model
	,case when description like '%B1' or description like '%B2'
	then 1
	else null
	end as is_multi_box_desc
from item_costing.item_costing_tbl
)
,icg as --item costing models grouped up
( -- trimming characters from the models in order to find similar models
select
	case
	when right(model,2) in ('-A','-B','-C')
	then model
	when (model like '%1' or model like '%2') and model not like '%-%' and model not like '%01' and model not like '%02'
	then left(model,length(model)-1)
	when (model like '%-1' or model like '%-2')
	then left(model,length(model)-2)
	when model like '%LS'
	then left(model,length(model)-2)
	when model like '%S' and model not like '%1S' and model not like '%2S'
	then model
	when model like '%1S' or model like '%2S'
	then left(model,length(model)-2)
	when model like '%A' or model like '%B' or (model like '%C' and model not like '%DC')
	then left(model,length(model)-1)
	when model like '%WC'
	then left(model,length(model)-2)
	when model like '%-X'
	then left(model,length(model)-2)
	when model like '%WDP'
	then left(model,length(model)-2)
	when model like '%-DISP'
	then left(model,length(model)-5)
	when model like '%DISP'
	then left(model,length(model)-4)
	when model like '%HCOM'
	then left(model,length(model)-4) ||'OM'
	when model like '%-GN'
	then left(model,length(model)-3)
	when model like '%-W'
	then left(model,length(model)-2)
	when model like '%WM'
	then left(model,length(model)-2)
	when model like 'S0%' and model like '%W'
	then left(model,length(model)-1) ||'WE'
	when model like '%W'
	then left(model,length(model)-1) ||'WCOM'
	else model
	end as parent_model
	,model
	,right(model,2) last_2
	,right(model,1) last_1
	,right(model,3) as last_3
	,is_multi_box_desc
from ici
)
,dc as 
( -- models in the dorel catalog that are multi relevant
select distinct model
	,internal_item_name
	,carton_weight
	,carton_length
	,carton_width
	,carton_height
	,case
		when internal_item_name like '%Box%'
		then 1
		else 0
		end as is_multi_box_desc
from components.dorel_catalog
where carton_weight is not null
)
,mcdc as --model clean dorel catalog
( --joining the catalog items
	--gets multi box description from items
	--this lets us get the length and weight so we can compare which items are grouped together and which ones are not
		--the dims are not needed later in this query, it's solely a comparison thing
		--if a parent model has a bunch of 0's, we know that item is multi box
		--someitmes items will be 1/2 boxes but not grouped into a parent model. other specific are used to figure it out
	
select   icg.parent_model
	,icg.model
	,icg.last_2
	,icg.last_1
	,icg.last_3
	,coalesce(dc.carton_weight, dc2.carton_weight)carton_weight
	,coalesce(dc.carton_length,dc2.carton_length) carton_length
	,dc.carton_width
	,dc.carton_height
	,coalesce(icg.is_multi_box_desc,dc2.is_multi_box_desc,dc.is_multi_box_desc) as is_multi_box_desc
from icg
left join dc
on icg.parent_model = dc.model
left join dc dc2
on icg.model = dc2.model 
--where icg.new_model like '%WM7891%'
--where last_2 = '2T'
)
,box_find as --finding the different types of boxes and assigning the box_type column
(-- query categorizes the multi box types so we know which price to take
select *
	,case
		when last_2 in ('1S','2S')
		then 'type_S'--multi box ending in 1s or 2s
		when is_multi_box_desc =1
		then 'type_original' -- multi box ending in m1 or m2
		when last_2 in('M1','M2')
		then 'type_M'
		when last_2 in('-1','-2')
		then 'type_dash' -- multi box ending in -1 or -2
		when last_3 in ('2DC','1DC')
		then 'type_multi_dc' -- multi box ending in 1dc or 2dc
		when last_2 in ('1B','2B')
		then 'type_box' -- multi box ending in 1b or 2b
		when last_2 in ('-A','-B','-C')
		then 'full box'
		when last_1 not in ('1','2','A','B','C') -- not a multi box, but may be the parent model for other boxes
		then 'full Box'
		else 'other' -- handful of uncategorized ones that are full box, but should be checked
		end as box_type

from mcdc
)
,details as 
(
select distinct
 ic.model
,bf.parent_model
,ic.cost_date
,ic.warehouse_number
,ic.material_cost
,ic.freight_cost
,ic.duty_cost
,ic.total_overhead_cost as overhead_cost
,ic.labor_cost
,max(bf.box_type)  over (partition by parent_model) as box_type
,max(is_multi_box_desc) over (partition by parent_model) as is_multi_box_desc
from item_costing.item_costing_tbl ic
left join box_find bf
on ic.model = bf.model
where 1=1
--and ic.model like '%1852013COM%'

)


select
	model
	,parent_model
	,cost_date
	,warehouse_number
	,box_type
	,is_multi_box_desc
	,material_cost as single_material_cost
	,sum(material_cost) over (partition by parent_model, warehouse_number, cost_date, box_type) as material_cost
	,sum(duty_cost) over (partition by parent_model, warehouse_number, cost_date, box_type) as duty_cost
	,sum(freight_cost) over (partition by parent_model, warehouse_number, cost_date, box_type) as freight_cost
	,sum(overhead_cost) over (partition by parent_model, warehouse_number, cost_date, box_type) as overhead_cost
    ,sum(labor_cost) over (partition by parent_model, warehouse_number, cost_date, box_type) as labor_cost
from details
order by parent_model,cost_date desc, warehouse_number, model
)
;
truncate item_costing.item_costing_tbl_agg;
insert into item_costing.item_costing_tbl_agg
(model, parent_model, cost_date,warehouse_number, box_type, is_multi_box_desc, single_material_cost,material_cost,duty_cost,freight_cost,overhead_cost,labor_cost)
select model, parent_model, cost_date,warehouse_number, box_type, is_multi_box_desc, single_material_cost,material_cost,duty_cost,freight_cost,overhead_cost,labor_cost
from etl_views.item_costing_tbl_agg_insert_view