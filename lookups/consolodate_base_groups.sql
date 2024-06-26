--STEP 1:
	--INSERT ITEM ID'S WITH MISSING GROUP ID # INTO TEMP_TOOL_IDS TABLE
--after running search tool ids, you can plug the values into temp_tool_ids and consolodate the tool id's that appear with other group ids
select distinct item_id, base_id
from misc_views.search_tool_ids t1
where t1.search_item_id in
(
select tool_id::bigint
from  temp_tool_ids

)
;
--STEP 2:
	--upload new temp tool id's from query ran above
	-- RUN QUERY AND CLEAN IN EXCEL
with t1 as 
(
select tool_id
	,base_id
	,group_id
	,min(group_id) over (partition by tool_id) as first_group_id -- find the first case of the group id by tool id
from temp_tool_ids
)
,con as --consolodated base id's
( -- consolodation piece to gind earliest group id for the tool id 
select distinct 
t1.tool_id::bigint as tooL_id
,t1.first_group_id
from t1 
left join t1 t2
on t1.group_id = t2.first_group_id
)
,g as --group ids
( --bringing in group ids to compare 
select tool_id
	,group_id
	,collection_name
from group_ids

)
,gfind as --finding if the new group id already has a group id assigned to it 
( -- comparing consolodated list to existing group id's 
select  distinct
	first_group_id
	,min(group_id) over (partition by first_group_id) as actual_grouping
from con
left join g
on con.tool_id = g.tool_id
)
,details  as 
( -- you could inesr the non null collection names where tool id isn't in the group id table 
select distinct
	con.tool_id
	,coalesce(actual_grouping, con.first_group_id) as group_id
	,collection_name
from con
left join gfind 
on con.first_group_id = gfind.first_group_id
left join g
on gfind.actual_grouping = g.group_id
)
;