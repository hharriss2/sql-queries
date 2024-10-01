--view for cleaned up ships data
create or replace view ships_schema.ships_view as 
(
SELECT 
    s.id
    ,s.model
    ,COALESCE(msl.item_id::text, s.tool_id::text) AS tool_id
    ,cbm.cat
    ,ac.category_id
    ,cbm.sub_cat
    ,cbm.cbm_id
    ,ac.account_manager
    ,ac.account_manager_id
    ,g.group_id
    ,g.collection_name
    ,g.group_id_id
    ,retailer
    ,r.retailer_id
    ,s.sale_type
    ,st.sale_type_id
    ,date_shipped
    ,sales
    ,units
    ,s.division
    ,d.division_id
    ,coalesce(msl.product_name, s.product_name) as product_name
    ,w.wm_date
    ,case
		when date_shipped >= date_trunc('month',current_date - interval '13 months')
		and date_trunc('month',date_shipped) !=  date_trunc('month',current_date)
		then 1 else 0
		end as is_l_52 -- boolean to show last 52 weeks sold
	,case
		when date_shipped >= date_trunc('week', current_date - interval '5 weeks')
		and date_trunc('week',date_shipped) !=date_trunc('week',current_date)
		then 1
		else 0
		end as is_l4 -- boolean to show last 4 weeks sold
	,case
		when date_shipped >= date_trunc('week', current_date - interval '13 weeks')
		and date_trunc('week',date_shipped) !=date_trunc('week',current_date)
		then 1
		else 0
		end as is_l12 -- boolean to show if is last 12 for units sold
FROM ships_schema.ships s
left join divisions d
on s.division = d.division_name
left join retailer r
on s.retailer = r.retailer_name
left join sale_type st
on s.sale_type = st.sale_type
LEFT JOIN clean_data.master_ships_list msl 
ON s.model = msl.model
left join cat_by_model cbm 
on s.model = cbm.model
left join account_manager_cat ac
on cbm.cat = ac.category_name
left join group_ids g 
on msl.item_id = g.tool_id
left join wm_calendar w 
on s.date_shipped = w.date
)
;

