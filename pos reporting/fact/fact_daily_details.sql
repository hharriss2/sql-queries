--used on the daily report. Same logic as the pos_reporting.daily_report but broken up into details, not aggregated
create or replace view power_bi.fact_daily_details as 
(
with t1 as 
(
select
	ssa.id
    ,ssa.pos_qty
    ,ssa.pos_sales
    ,ssa.daily
    ,wcal.wmcal_id
    ,ls.current_item_num
	,mcl.model
	,ls.unit_retail
	,max(ls.item_description) over (partition by current_item_num) as prime_item_desc
	,ls.vendor_stock_number
    ,ls.is_special_buy
    ,ls.item_status
    ,ls.unit_cost
    ,ls.landed_cost
    ,vendor_nbr_dept
    ,coalesce(ls.pack_size,pt.vendor_pack_quantity) as vendor_pack_quantity
   ,max(pt.item_type_code) over (partition by current_item_num) as item_type_code
	, -- week to date units
		case
		when wcal.is_current_wm_week =1  -- store sales are in current wm week
		then 1
        else 0
        end as is_wtd
	, -- week to date for last year
		case 
		when wcal.is_current_wm_week_ly = 1 -- sales are in cyrrent week for last year
			and  wcal.wm_day_of_week <= wcal.current_wm_day_of_week - 1 -- sales are day behind, so find todays date minus a day
		then 1
		else 0 
        end as is_wtd_ly
	,  -- units for the previous walmart week
		case
		when wcal.previous_wm_week = 1
		then 1
		else 0 end as is_last_week
	, -- sales for the previous 4 walmart weeks, not including the current
		case
		when wcal.is_last_4_weeks = 1
		then 1
		else 0 end as is_last_4_weeks
	, -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_13_weeks = 1
		then 1
		else 0 end as is_last_13_weeks
--	,-- avg weekly pos qty = l4 weeks divided by 4
	, -- year to date sales in units
		case
		when wcal.is_ytd_wm_week =1
		then 1
		else 0 end as is_ytd
	, -- year to date sales in dollar
		case
		when wcal.is_ytd_wm_week =1 
		then 1
		else 0 end as is_ytd_sales
    ,mcl.division
    ,cbm.cat
    ,cbm.sub_cat
    ,case
        when vendor_nbr_dept = '71'
        and mcl.division in('Ameriwood','Dorel Home Products')
        then 'D71 - DHF'
        when vendor_nbr_dept = '71'
        and mcl.division = 'Cosco Products'
        then 'D71 - Cosco'
        when vendor_nbr_dept = '12'
        and mcl.division = 'Cosco Products'
        then 'D12 - Cosco'
        when vendor_nbr_dept = '79'
        and mcl.division = 'Dorel Home Products'
        then 'D79 - DHF'
        when vendor_nbr_dept = '71'
        then 'D71 - DF1'
        else null
        end as department_title
     ,wcal.wm_date::integer as wm_date
     ,wcal.wm_week::integer as wm_week
     ,wcal.wm_year::integer as wm_year
from sales_stores_auto ssa
left join power_bi.wm_calendar_view wcal 
on ssa.daily = wcal.date
left join pos_reporting.lookup_stores ls
on ssa.prime_item_nbr::bigint = ls.prime_item_num
left join clean_data.master_com_list mcl
on ls.current_item_num::bigint = mcl.item_id
left join lookups.vendor_number_clean vnc
on ssa.vendor_nbr = vnc.vendor_nbr
left join lookups.store_pack_type_tbl pt
on pt.item_nbr = prime_item_nbr::bigint
left join cat_by_model cbm
on mcl.model = cbm.model
where daily is not null
and daily is not null
and ls.is_daily_item =1
and ls.item_status not like '%Delete%'
-- and vendor_nbr_dept = '71' -- daily is only for department 71
-- and prime_item_nbr = '550955318'
and daily >= current_date - interval '400 days'
)
,t2 as 
(
select
	current_item_num
	,model
	,unit_retail
	,prime_item_desc
	,vendor_stock_number
	,is_special_buy
	,item_status
	,unit_cost
	,landed_cost
	,vendor_nbr_dept
	,vendor_pack_quantity
	,division
	,cat
	,sub_cat
	,wm_date
	,department_title
    ,wm_week
    ,wm_year
	,sum(pos_qty) as pos_qty
	,sum(pos_sales) as pos_sales
from t1
group by current_item_num
	,model
	,unit_retail
	,prime_item_desc
	,vendor_stock_number
	,is_special_buy
	,item_status
	,unit_cost
	,landed_cost
	,vendor_nbr_dept
	,vendor_pack_quantity
	,division
	,cat
	,sub_cat
	,department_title
	,wm_date
	,wm_week
	,wm_year
order by wm_date desc
)
select
	current_item_num
	,model
	,unit_retail
	,prime_item_desc
	,vendor_stock_number
	,is_special_buy
	,item_status
	,unit_cost
	,landed_cost
	,vendor_nbr_dept
	,vendor_pack_quantity
	,division
	,cat
	,sub_cat
	,wm_date
    ,wm_week
    ,wm_year
	,department_title
	,pos_qty as wtd_units
    ,pos_sales as wtd_sales
	,sum(pos_qty) over (partition by current_item_num order by wm_date  rows between 4 preceding and 1 preceding) as last_4_weeks_units
	,sum(pos_qty) over (partition by current_item_num order by wm_date  rows between 13 preceding and 1 preceding) as last_13_weeks_units
	,sum(pos_qty) over (partition by current_item_num order by wm_date  rows between 52 preceding and 1 preceding) as last_52_weeks_units
	,sum(pos_sales) over (partition by current_item_num order by wm_date  rows between 4 preceding and 1 preceding) as last_4_weeks_sales
,sum(pos_sales) over (partition by current_item_num order by wm_date  rows between 13 preceding and 1 preceding) as last_13_weeks_sales
,sum(pos_sales) over (partition by current_item_num order by wm_date  rows between 52 preceding and 1 preceding) as last_52_weeks_sales
from t2
order by current_item_num,wm_date desc
)
;
