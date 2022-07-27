/*Mix of product name and brands*/
create view lookups.tool_pn_brand  as
(
  select t1.tool_id
  	,product_name
  	,case when product_name like '%Queer%'
  	then 'Queery Eye'
  	when product_name like '%Cosmo%'
    then 'CosmoLiving by Cosmopolitan'
    else brand_name end as brand_name
  from lookups.tool_pn_tbl  t1
  left join lookups.tool_brand_tbl t2
  on t1.tool_id = t2.tool_id
)
;