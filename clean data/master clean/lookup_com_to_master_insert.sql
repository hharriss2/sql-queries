--this view is used to upsert the lookup table into master com list 
--if data needds to be corrected on the fly, you can update the lookup_com table and the records should overwrite the ones in POS Reporting on Power BI
create or replace view clean_data.lookup_com_to_master_insert as 
(
with lc as --lookup com 
( -- lookup table that overwrites what will appear in the master com list
select * 
from pos_reporting.lookup_com
)
,lcm as --lookup com max
( --duplicate item id's in this table. find the most recent record of the item id 
select item_id
	,max(date_inserted) as date_compare
from lc
group by lc.item_id
)
,lcd as --lookup com details
( -- makes item id's unique by using the most recent inserted record of an item id
select 
	lc.item_id
	,model
	,product_name
	,division
	,current_item_id
	,brand_name
from lc
join lcm
on lc.item_id = lcm.item_id
and lc.date_inserted = lcm.date_compare
)
,details as 
( -- joins the most recent item in the lookup with master com list
	--if there are any null values in the lookup, master com list will keep its value
	--otherwise, use the lookup value 
select 
	lcd.item_id::bigint as item_id
	,coalesce(lcd.model,mcl.model) as model
	,coalesce(lcd.product_name, mcl.product_name) as product_name
	,coalesce(lcd.division,mcl.division) as division
	,coalesce(lcd.current_item_id::bigint, mcl.current_item_id) as current_item_id
	,coalesce(lcd.brand_name, mcl.brand_name) as brand_name
	,2 as retailer_type_id
	,1 as is_lookup_update
from lcd
left join clean_data.master_com_list mcl 
on lcd.item_id::bigint = mcl.item_id
)
select * 
from details
)
;
