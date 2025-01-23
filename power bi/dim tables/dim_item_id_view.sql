--used for wm pos fact tables. includes every id used in these tables
create or replace view dim_sources.dim_item_id_view_pos as 
(
with com as --com item ids
(
select distinct tool_id::bigint as item_id
from pos_reporting.retail_sales
)
,stores as --store item ids
(
select distinct prime_item_nbr as item_id
from pos_reporting.store_sales
)
,master as --master item ids 
(
select distinct item_id
from clean_data.master_com_list

)
,details as 
(
select 
	item_id
from com
union all
select item_id
from stores 
union all
select item_id
from master
)
select distinct
	dense_rank() over (order by item_id) as item_id_id
	,item_id
from details
)
;
