with bid1 as (
				select distinct t1.item_id,t2.base_id
				from retail_link_pos t1
				left join 
					(
					select distinct item_id as base_id, base_upc --converts base_upc to base item id 
					from retail_link_pos
					where upc= base_upc 
					) t2
				on t1.base_upc = t2.base_upc		
			
			),
bid2 as (
				select distinct t1.item_id,t2.base_id
				from retail_link_pos t1
				left join 
					(
					select distinct item_id as base_id, base_upc --converts base_upc to base item id 
					from retail_link_pos
					where upc= base_upc 
					) t2
				on t1.base_upc = t2.base_upc
		)
select distinct bid2.item_id as search_item_id,bid1.item_id,bid1.base_id
from bid1
join bid2
on bid1.base_id = bid2.base_id
/*joining base id's finds any instance of an item being a base id.
  search_item_id is used to find all of the items base ID's */
;
