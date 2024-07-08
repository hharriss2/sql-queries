with t1 as 
(select
	t1.tool_id
	,t1.collection_name
	,t1.group_id harris_group
	,t2.group_id traci_group
from group_ids t1
join temp_group_ids t2
on t1.tool_id = t2.tool_id
order by t1.group_id
)
,t2 as 
(
select
	g.tool_id
	,g.collection_name
	,g.group_id
	,case
		when t1.tool_id is not null
		then true
		else false
		end as is_updated
	,min(t1.harris_group) over (partition by g.tool_id) as updated_group
	,traci_group
	,count(g.tool_id) over (partition by g.group_id) as item_group
	,count(t1.tool_id) over (partition by t1.traci_group) as item_added
from group_ids g
left join t1
on g.tool_id = t1.tool_id
order by g.group_id
)
select tool_id "Item ID"
	,collection_name "Collection Name"
	,group_id as "Current Grouping"
	,traci_group as "Traci Group"
	,is_updated as "Updated/ Added Item"
	,item_group as "Items in Group"
	,item_added as "# of Items Added by Traci"
	,case
		when is_updated = false
		then 'No Update to Item'
		when item_group = item_added
		then 'New group Created'
		when item_group > item_added
		then 'Item(s) added to Existing group'
		when item_group < item_added
		then 'Some Item(s) re-grouped'
		end as "Modification Description"
from t2
order by group_id
;