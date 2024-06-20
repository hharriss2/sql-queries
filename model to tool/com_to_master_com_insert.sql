--this view manipulates the com product list a little more before transitioning it into master com
create or replace view clean_data.com_to_master_com_insert as 
(
with sm as -- ship max
( -- fin's out if the model has been shipped
 select model
 	,max(date_shipped) as latest_ship
 from ships_schema.ships
 group by model
)
  select
  	cpl.item_id
  	,case -- choosing the right model to update
  		when length(cpl.model) <4 -- if new model has 3 or less characters, don't use it
  		then mcl.model
  		when latest_ship is null --if the model has never appeared in shipments, choose the old model
  		then coalesce(mcl.model,cpl.model)
  		else coalesce(cpl.model,mcl.model) -- otherwise, we want the newest model to update 
  	end as model
  	,case
  		when cpl.division = '' -- rather the division be null than a blank
  		then mcl.division -- will be a value or null
  		else coalesce(cpl.division, mcl.division) -- if cpl is null, then mcl, otherwise override 
  		end as division_name
  	,cpl.product_name
  	,cpl.is_scrape_product_name
  from clean_data.com_product_list cpl
  left join clean_data.master_com_list mcl
  on cpl.item_id = mcl.item_id
  left join sm
  on mcl.model = sm.model
  )
  ;

 