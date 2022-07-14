/*This report is for people to view historical scrapes.
We break it down into id's to make effecient for power bi
will need to re work for production status and lead times
had to create new DIM tables because scrape data has names that are not in our normal DIM tables due to scraping competitor information*/

create or replace view power_bi.buy_box_report_pbix as (
select distinct t1.id
	,iid.item_id_id
	,bid.base_id_id
	,mod.model_name_id
	,d.division_id
	,cbm.cbm_id
	,pn.product_name_id
	,pdc.price_display_code_id
	,sn.seller_name_id
	,t1.url
	,t1.available
	,t1.price_was
	,t1.price_retail
	,t1.review_rating
	,t1.review_count
	,t1.date_inserted
	, man.manufacturer_name_id
from scrape_data.scrape_tbl t1
left join clean_data.master_com_list ml
on t1.item_id = ml.item_id
left join power_bi.buy_box_item_id iid
on t1.item_id = iid.item_id
left join power_bi.buy_box_base_id bid
on t1.base_id = bid.base_id
left join power_bi.buy_box_model_name mod
on t1.model_name = mod.model_name
left join cat_by_model cbm
on ml.model = cbm.model
left join power_bi.buy_box_product_name pn
on t1.product_name = pn.product_name
left join power_bi.buy_box_price_display_code pdc
on t1.price_display_code = pdc.price_display_code
left join power_bi.buy_box_seller_name sn 
on t1.seller_name = sn.seller_name
left join power_bi.divisions_view d
on d.division_name = ml.division
left join power_bi.buy_box_manufacturer_name man
on t1.manufacturer_name = man.manufacturer_name

)
;