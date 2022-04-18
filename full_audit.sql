/*This query finds dupe values for com and stores pos, cat by model sales, and dupes for top gainers and laggers. 
Run this report after uploading pos sales*/
with com as 
	(
	select  1 as pk_com, sum(t1.count) as pos_com_dupe
	from pos_reporting.audit_com t1
	)
, stores as 
	(
	select 1 as pk_stores, count(t1.item_description) as pos_stores_dupe
	from pos_reporting.audit_stores  t1
	)
, cbm as 
	(
  	 select 1 as pk_cbm,sum(s.sales::numeric(10,2)) as cbm_ytd
  	 FROM ships_schema.ships s
     LEFT JOIN pos_reporting.retail_sales rs ON s.tool_id::text = rs.tool_id
     LEFT JOIN cat_by_model cbm ON cbm.model = s.model
     where 1=1
     and cbm.model is null
     and date_shipped >='2022-01-01'
	)
, top_gainer as 
	(
	select 1 as pk_gainer, sum(gainer_dupe) as gainer_dupe
	from(
		select count(t1."Tool ID") as gainer_dupe
		from misc_views.top_gainers t1
		group by t1."Tool ID"
		having count(t1."Tool ID") >1
		) t1
	)
, top_lagger as 
	(
	select 1 as pk_lagger, sum(lagger_dupe) as lagger_dupe
	from(
		select count(t1."Tool ID") as lagger_dupe
		from misc_views.top_laggers t1
		group by t1."Tool ID"
		having count(t1."Tool ID") >1
		) t1
	)		
select pos_com_dupe , pos_stores_dupe, cbm_ytd, gainer_dupe, lagger_dupe
from com 
join stores
on com.pk_com = stores.pk_stores 
join cbm 
on cbm.pk_cbm = stores.pk_stores
join top_gainer 
on top_gainer.pk_gainer = stores.pk_stores
join top_lagger
on top_gainer.pk_gainer = top_lagger.pk_lagger;