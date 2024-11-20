
create or replace view walmart.componenets.dorel_catalog as 
(
-- this view creates a catalog by combining the internal item info with the provided wm info
select
    ir.item_sk -- synthetic key. unique identifier for an item
    ,ir.retailer_model_number -- item number provided on the retailer side
    ,di.model_number -- item number provided internally
    ,case
        when retailer_seq_id is null
        then 404
        else retailer_seq_id
        end as retailer_id
    ,dr.retailer_name
    ,retailer_upc as item_id -- item id is classified as upc in this source
    ,retailer_item_name -- the product name provided on walmart
    ,di.item_name as internal_item_name -- product name given by dorel
    ,retailer_item_collection -- not quite sure. makes up a collection of similar brands or purposes for itmes. 
    ,division_name 
    ,carton_weight -- shipping dim 
    ,carton_length
    ,carton_width
    ,carton_height
    ,carton_size
    ,ship_method
    ,sourcing_type
    ,brand
    ,item_color
    ,item_finish
    ,item_fabric
    ,item_status
    ,item_status_date
    ,launch_date
    ,live_on_site_date
from dorel_dwh.edw.dim_item  di
left join dorel_dwh.edw.xref_item_retailer ir
left join walmart.lookups.dim_retailers dr
on ir.retailer_sk = dr.retailer_id
on ir.item_sk = di.item_sk
where 1=1
-- and retailer_sk in ('c9e1074f5b3f9fc8ea15d152add07294','38b3eff8baf56627478ec76a704e9b52')
)
;