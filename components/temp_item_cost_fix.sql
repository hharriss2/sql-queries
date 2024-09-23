--trying to find parent skus to these children
create or replace view temp_item_cost_fix as 
(
select
	case
	when (model like '%1' or model like '%2') and model not like '%-%' and model not like '%01' and model not like '%02'
	then left(model,length(model)-1)
	when (model like '%-1' or model like '%-2')
	then left(model,length(model)-2)
	when model like '%LS'
	then left(model,length(model)-2)
	when model like '%S' and model not like '%1S' and model not like '%2S'
	then left(model,length(model)-1)
	when model like '%1S' or model like '%2S'
	then left(model,length(model)-2)
	when model like '%A' or model like '%B'
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
	end as new_model
	
	,model old_model
	,right(model,2) last_2
from components.item_costing
where model not in (select model from lookups.dsv_item_cost_3p)
--and model like 'S0%'
)
;
