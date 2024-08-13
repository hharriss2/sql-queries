--inserts the dapl raw table into the clean item grouping table
insert into clean_data.item_grouping 
	(item_group_key,item_id, model, group_type,funding_amount, suggested_retail, start_date, end_date, updated_on)
select
	item_group_key 
	,item_id
	,model
	,group_type
	,case
	when suggested_retail like '%$%'
	then right(suggested_retail,length(suggested_retail) -1)::numeric(10,2)
	else suggested_retail::numeric(10,2)
	end as suggested_retail
	,case
		when funding_amount like '%$%'
		then right(funding_amount, length(funding_amount)-1)::numeric(10,2)
		else funding_amount::numeric(10,2)
	end as funding_amount
	,start_date
	,end_date
	,now() as updated_on
from dapl_raw.item_grouping


;

