--creating view for promo items by their start and end weeks
create or replace view clean_data.item_grouping_by_wm_week as 
(
with ig as --item grouping
(-- first parse out the item id, group name, and the date identifier
select item_id
	,right(group_type,length(group_type) -7) as group_name
	,left(group_type,6) as date_identifier
from clean_data.item_grouping
)
,ed as --end date
(-- finding the current wm date
select wm_date
from power_bi.wm_calendar_view
where date = current_date
)
,pig as --parse item grouping
(-- split out item groups into item id, group name, year, start and end weeks
select 
	item_id
	,group_name
	,20||left(date_identifier,2) as group_year
	,left(right(date_identifier,4),2) as start_week
	,right(right(date_identifier,4),2) as end_week
from ig
)
,ig_details as
( -- lastly, create item name and group with their starting wm date & ending wm date. 
select 
	item_id
	,group_name
	,cast(group_year||start_week as integer)+100 as wm_start_date
	--adding +100 to mimic the current wm week date according to walmarts year
	,case
		when end_week = '00'
		then (select wm_date::integer  from ed)
		else cast(group_year ||end_week as integer) +100
		end as wm_end_date
from pig
--where item_id = '3043462518'
)
select * 
from ig_details
)
;