create or replace view walmart.core.amazon_pos_3p as 
(
select 
    pkid
    ,vc_asin
    ,pims_model
    ,di.item_name
    ,brand
    ,di.country_list
    ,di.model_number
    ,week_date_start
    ,shipped_units
    ,shipped_revenue
    ,shipped_cogs
    ,ordered_revenue
    ,ordered_units
    ,customer_returns
from external.amazon.amazon_api_b2b_sales as aas
left join dorel_dwh.edw.dim_item di
on aas.pims_model = di.model_number
where week_date_start::date >= current_date() - interval '5 weeks'
)