create or replace view walmart.dim_sources.dim_items as 
( -- creating a link for dim tables to the fact product table
select
item_sk
,item_name
,model_number
,msrp
,db.brand_id
,dc.category_id
,dd.department_id
,dis.item_status_id
from dorel_dwh.edw.dim_item di
left join walmart.dim_sources.dim_brands db
on di.brand = db.brand_name
left join walmart.dim_sources.dim_category dc
on di.category_name = dc.category_name
left join walmart.dim_sources.dim_department dd
on di.department_name = dd.department_name
left join walmart.dim_sources.dim_item_status dis
on di.item_status = dis.item_status
)
;