--identify the last 4 weeks & last 52 weeks of ships
--find change % of L4 & L52. If $ is greater than %30, then include in the data set 
create or replace view ships_schema.top_gainers as 
(
with s as --ships
( --aggregate of each item & the total units it did for last 4 weeks and last 52
select
	tool_id
	,group_id
	,model
	,product_name
	,cat
	,account_manager
	,sum
		(
		case
		when is_l4 = 1
		then units
		else 0 end
		) as l4_units
	,sum(
		case
		when is_l_52 = 1
		then units
		else 0 end
		) as l52_units
from ships_schema.ships_view
where model is not null
and date_shipped >=current_date - interval '13 months'

group by 
	tool_id
	,group_id
	,model
	,product_name
	,cat
	,account_manager
)
,details as 
(-- rest of the column details
select
	tool_id
	,group_id
	,model
	,product_name
	,cat
	,account_manager
	,l4_units
	,l52_units
	,cast(
	(l4_units - l52_units)::numeric(10,2) / nullif(l52_units,0)::numeric(10,2)
	as numeric(10,2)) *100
	as l4_52_change
from s
where 1=1
and l4_units >0
)
SELECT 
	tool_id AS "Tool ID"
	,group_id AS "Group ID"
	,model AS "Model"
	,product_name AS "Product Name"
	,cat AS "Category"
	,account_manager AS "Account Manager"
	,l4_units AS "Last 4 Average Units Sold"
	,l52_units AS "Last 52 Average Units Sold"
	,l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
from details
where 1=1 
and l4_52_change  >=30
)
;
