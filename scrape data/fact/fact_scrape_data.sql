create or replace view power_bi.fact_scrape_data as 
(
with mcl as --master com list
(
select 
	mcl.item_id
	,g.group_id_id
	,i.item_id_id
	,pn.product_name_id
	,m.model_id
	,d.division_id
	,br.brand_id::bigint as brand_id
	,cbm.cbm_id
	,mcl.is_top_100_item
from clean_data.master_com_list mcl
join dim_sources.dim_wm_item_id i
on mcl.item_id = i.item_id
left join group_ids g 
on mcl.item_id = g.tool_id
left join dim_sources.dim_brand_name br
on mcl.brand_name = br.brand_name
left join dim_sources.dim_models m 
on mcl.model = m.model_name
left join cat_by_model cbm
on mcl.model = cbm.model
left join divisions d
on mcl.division = d.division_name
left join dim_sources.dim_product_names pn
on mcl.product_name = pn.product_name
)

select 
	s.id as scrape_id
	,mcl.item_id_id
	,mcl.group_id_id
	,mcl.product_name_id
	,mcl.model_id
	,mcl.cbm_id
	,mcl.brand_id
	,num_of_variants
	,price_retail
	,price_was
	,review_rating
	,review_count
	,pdc1.price_display_code_id as price_display_code_id_1
	,pdc2.price_display_code_id as price_display_code_id_2
	,wmcal_id
	,case when date_inserted = (select max(date_inserted) from scrape_data.scrape_tbl)
	then 1
	else 0
	end as is_most_recent_scrape -- for a filter on power bi later
	,mcl.is_top_100_item
from scrape_data.scrape_tbl s
join mcl
on s.item_id = mcl.item_id
join power_bi.wm_calendar_view wcal
on s.date_inserted = wcal.date
left join dim_sources.dim_price_display_code pdc1
on s.price_display_code = pdc1.price_display_code
left join dim_sources.dim_price_display_code pdc2
on s.price_display_code_2  = pdc2.price_display_code
where s.item_id in (select item_id from dapl_raw.blue_cart_item_scrape)
)
;