--used to report on walmart promotional fundings for now. might expand later. included on the DHF shipmetns data schema but only brought in on the omni ships report.
create or replace view walmart.power_bi.fact_item_groupings as 
(
select
    ig.item_group_id
,cbm.cbm_id
,cbm.group_id_id
,dc.cal_id as cal_start_date_id
,dc2.cal_id as cal_end_date_id
,ig.funding_amount
,ig.suggested_retail
,ig.group_type
,ig.funding_type
from walmart.components.item_groupings ig
join walmart.dim_sources.dim_cat_by_model cbm
on ig.model_name = cbm.model
left join walmart.dim_sources.dim_calendar dc
on ig.start_date = dc.cal_date
left join walmart.dim_sources.dim_calendar dc2
on ig.end_date = dc2.cal_date
)
;
