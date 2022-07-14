/*1- start off with com product list*/
insert into clean_data.master_com_list(item_id, model, division) 
select item_id, model, division 
from clean_data.com_product_list; 

/*2. put in store data, with conditions*/
insert into clean_data.master_com_list (item_id, model, division) 
select item_id::integer, model, division 
from clean_data.stores_product_list 
where item_id !='\N' --has to be a number
and item_id !='N/A' 
and item_id !='n/a'
and item_id not like '%  %' --cannot have a space in it
and item_id::integer not in (--item not in com list
							select item_id 
							from clean_data.com_product_list) 
and item_id not in ( -- not a duplicate from stores list
			select item_id 
			from clean_data.stores_product_list 
			group by item_id 
			having count(item_id) >1
					)
and model not in (--model not in com list
				  select model
				  from clean_data.com_product_list
				  )
				  ;

/*3. put in the remainder of model tools not found from either com or store list*/
insert into clean_data.master_com_list(item_id, model,division) 
select tool_id, model, division 
from misc_views.model_tool_division 
where tool_id not in (select item_id 
						from clean_data.master_com_list
					 )
and model not in (select model
				from clean_data.master_com_list
				); 