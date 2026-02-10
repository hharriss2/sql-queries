--report used to replicate the daily report sent out every day
create or replace view pos_reporting.daily_report as 
(
with sa as --stores aggregate
( -- aggregating units and sales for stores 
select
	ls.current_item_num
	,mcl.model
	,ls.unit_retail
	,max(ls.item_description) as prime_item_desc
	,ls.vendor_stock_number
    ,ls.is_special_buy
    ,ls.item_status
    ,ls.unit_cost
    ,ls.landed_cost
    ,vendor_nbr_dept
    ,coalesce(ls.pack_size,pt.vendor_pack_quantity) as vendor_pack_quantity
   ,max(pt.item_type_code) as item_type_code
	,sum( -- week to date units
		case
		when wcal.is_current_wm_week =1  -- store sales are in current wm week
		then pos_qty
		else null end
		) as wtd_units
	,sum(-- week to date sales
		case 
		when wcal.is_current_wm_week =1  -- store sales are in current wm week
		then pos_sales
		else null end
		) as wtd_sales
	,sum( -- week to date for last year
		case 
		when wcal.is_current_wm_week_ly = 1 -- sales are in cyrrent week for last year
			and  wcal.wm_day_of_week <= wcal.current_wm_day_of_week - 1 -- sales are day behind, so find todays date minus a day
		then pos_qty
		else null end
		) as wtd_ly_units
	,sum(
		case 
		when wcal.is_current_wm_week_ly = 1
			and  wcal.wm_day_of_week <= wcal.current_wm_day_of_week - 1
		then pos_sales
		else null end
		) as wtd_ly_sales
	,sum 
		( -- units for the previous walmart week
		case
		when wcal.previous_wm_week = 1
		then pos_qty
		else null end
		) as last_week_units
	,sum 
		( -- sales for the previous walmart week
		case
		when wcal.previous_wm_week = 1
		then pos_sales
		else null end
		) as last_week_sales
	,sum 
		( -- units for the previous walmart week
		case
		when wcal.previous_wm_week_ly = 1
		then pos_qty
		else null end
		) as last_week_units_ly
	,sum 
		( -- sales for the previous walmart week
		case
		when wcal.previous_wm_week_ly = 1
		then pos_sales
		else null end
		) as last_week_sales_ly
	,sum
		( -- sales for the previous 4 walmart weeks, not including the current
		case
		when wcal.is_last_4_weeks = 1
		then pos_qty
		else null end 
		) as last_4_weeks_units
	,sum
		( -- sales for the previous 4 walmart weeks, not including the current
		case
		when wcal.is_last_4_weeks = 1
		then pos_sales
		else null end 
		) as last_4_weeks_sales
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_13_weeks = 1
		then pos_qty
		else null end 
		) as last_13_weeks_units
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_13_weeks = 1
		then pos_sales
		else null end 
		) as last_13_weeks_sales
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_52_weeks = 1
		then pos_qty
		else null end 
		) as last_52_weeks_units
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_52_weeks = 1
		then pos_sales
		else null end 
		) as last_52_weeks_sales
--IS LAST X WEEKS LAST YEAR
	,sum
		( -- sales for the previous 4 walmart weeks, not including the current
		case
		when wcal.is_last_4_weeks_ly = 1
		then pos_qty
		else null end 
		) as last_4_weeks_units_ly
	,sum
		( -- sales for the previous 4 walmart weeks, not including the current
		case
		when wcal.is_last_4_weeks_ly = 1
		then pos_sales
		else null end 
		) as last_4_weeks_sales_ly
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_13_weeks_ly = 1
		then pos_qty
		else null end 
		) as last_13_weeks_units_ly
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_13_weeks_ly = 1
		then pos_sales
		else null end 
		) as last_13_weeks_sales_ly
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_52_weeks_ly = 1
		then pos_qty
		else null end 
		) as last_52_weeks_units_ly
	,sum
		( -- sales for the previous 13 walmart weeks, not including the current
		case
		when wcal.is_last_52_weeks_ly = 1
		then pos_sales
		else null end 
		) as last_52_weeks_sales_ly
--	,-- avg weekly pos qty = l4 weeks divided by 4
	,sum
		( -- year to date sales in units
		case
		when wcal.is_ytd_wm_week =1
		then pos_qty
		else null end
		) as ytd_units
	,sum
		( -- year to date sales in dollar
		case
		when wcal.is_ytd_wm_week =1 
		then pos_sales
		else null end
		) as ytd_sales
	,sum
		( -- year to date sales in units
		case
		when wcal.is_ytd_wm_week_ly =1
		then pos_qty
		else null end
		) as ytd_units_ly
	,sum
		( -- year to date sales in dollar
		case
		when wcal.is_ytd_wm_week_ly =1 
		then pos_sales
		else null end
		) as ytd_sales_ly
	,sum
		(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_defective_and_overstock_this_year
		else null end 
		) as ytd_store_returns_quantity_defective_and_overstock_ytd
	,sum
		(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_recall_this_year
		else null end 
		) as ytd_store_returns_quantity_recall_ytd
	,sum
		(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_to_dc_this_year
		else null end 
		) as ytd_store_returns_quantity_to_dc_ytd
	,sum
		(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_to_return_center_this_year
		else null end 
		) as ytd_store_returns_quantity_to_return_center_ytd
	,sum
		(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_to_vendor_this_year
		else null end 
		) as ytd_store_returns_quantity_to_vendor_ytd
	,count   --counts the number of days that have occured for the walmart year.
		(
		distinct
		case
		when wcal.is_ytd_wm_week = 1
		then wcal.wm_week
		else null end
		) as ytd_num_of_weeks
	,count(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_defective_and_overstock_this_year
		else null end
		) as store_returns_quantity_defective_and_overstock_this_year_ytd
	,count(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_recall_this_year
		else null end
		) as store_returns_quantity_recall_this_year_ytd
	,count(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_to_dc_this_year
		else null end
		) as store_returns_quantity_to_dc_this_year_ytd
	,count(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_to_return_center_this_year
		else null end
		) as store_returns_quantity_to_return_center_this_year_ytd
	,count(
		case
		when wcal.is_ytd_wm_week = 1
		then store_returns_quantity_to_vendor_this_year
		else null end
		) as store_returns_quantity_to_vendor_this_year_ytd
    ,mcl.division
    ,cbm.cat
    ,cbm.sub_cat
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
where 1=1
and daily is not null
and ls.is_daily_item =1
and ls.item_status not like '%Delete%'
-- and vendor_nbr_dept = '71' -- daily is only for department 71
-- and prime_item_nbr = '550955318'
--and daily >= current_date - interval '400 days'
group by 
	ls.current_item_num
    ,vendor_nbr_dept
	,mcl.model
--	,ls.prime_item_desc
    ,ls.unit_cost
	,ls.vendor_stock_number
	,ls.unit_retail
    ,ls.is_special_buy
    ,ls.item_status
    ,ls.landed_cost
    ,coalesce(ls.pack_size,pt.vendor_pack_quantity)
--    ,coalesce(ls.item_type_code,pt.item_type_code)
    ,mcl.division
    ,cbm.cat
    ,cbm.sub_cat
)

,sia as --stores inventory aggregate
(
select
	all_links_item_number 
	,sum(on_hand_qty) as store_on_hand
	,sum(in_warehouse_qty) as store_in_warehouse
	,sum(in_transit_qty) as store_in_transit
    ,sum(on_order_qty) as store_on_order
	,sum(on_hand_qty 
	+ in_warehouse_qty
	+ in_transit_qty)
	 as store_inventory
	,sum(traited_store_count_this_year) as traited_store_count_this_year
	,sum(traited_store_count_last_year) as traited_store_count_last_year
	,max(curr_repl_instock) as curr_repl_instock
	,max(repl_instock_percentage_last_year ) as repl_instock_percentage_last_year 
from pos_reporting.inventory_stores
group by all_links_item_number
)
,wia as --warehosue inventory aggregate
(
select 
	walmart_item_number
	,sum(w.on_hand_warehouse_inventory_in_units_this_year) as warehouse_inventory
	,sum(w.on_order_warehouse_quantity_in_units_this_year) as warehouse_on_order
from inventory.wm_warehouse_on_hands w
group by walmart_item_number
)
,sfc as --store forecast
(
select
	prime_item_number
	,sum(forecast_quantity) as forecast_n13w
from forecast.wm_store_forecast
group by prime_item_number
)
select
	-- sa.prime_item_nbr
    sa.current_item_num
	,vendor_stock_number
	,sa.model
	,sa.prime_item_desc
	,sa.item_status
	,sa.is_special_buy
	,sa.item_type_code
    ,sa.vendor_pack_quantity
	,sa.unit_retail
	,cast(ytd_sales/ ytd_units as numeric(10,2)) as average_retail
	,sa.unit_cost
	,sa.landed_cost
	,wtd_units --wtd pos qty
	,wtd_ly_units --ly wtd pos qty
	,cast((wtd_units - wtd_ly_units)/nullif(wtd_ly_units::numeric(10,2),0) as numeric(10,2)) as ly_wtd_pos_units_change
	--^last wtd pos qty % change (current wtd - ly wtd) / ly wtd
	,last_week_units
	,last_4_weeks_units -- l4 wks pos qty
	,last_4_weeks_units::numeric(10,2)/4 as average_weekly_units --avg weekly pos qty
    ,ytd_units
	,ytd_sales --ty fytd pos sales
	,wtd_sales --wtd pos sales
	,wtd_ly_sales --ly wtd pos sales
	,cast((wtd_sales - wtd_ly_sales)/nullif(wtd_ly_sales::numeric(10,2),0) as numeric(10,2)) as ly_wtd_pos_sales_change
	--^ ly wtd pos $ % change (current wtd - ly wtd) / ly wtd
	,store_inventory --inventory in store
	,wia.warehouse_inventory -- inventory in warehouse
	,coalesce((store_inventory::numeric(10,2) + warehouse_inventory)/nullif((forecast_n13w +last_4_weeks_units)/17,0),0) as weeks_of_supply_inventory_warehouse
	--(inventory + warehouse) / (next 13 weeks forecast divided by 13)
	,coalesce(warehouse_on_order::numeric(10,2)/nullif((forecast_n13w+last_4_weeks_units)/17,0),0) as weeks_of_supply_on_order
	--(OO) / (last 4 weeks + next 4 weeks for forecast)
    ,sia.traited_store_count_this_year
	,sia.traited_store_count_last_year
	,sia.curr_repl_instock
	,sia.repl_instock_percentage_last_year 
    ,cast(last_week_units::numeric(10,2)/nullif(sia.traited_store_count_this_year,0) as numeric(10,2)) as wtd_units_per_traited_store
    --last weeks units per traited stores 
    ,cast(last_week_sales/nullif(sia.traited_store_count_this_year,0) as numeric(10,2)) as  wtd_sales_per_traited_store
	--last weeks sales sales per traited stores
    ,current_date::date as todays_date
	,division
    ,cat
    ,sub_cat
    ,vendor_nbr_dept
    ,case
        when vendor_nbr_dept = '71'
        and division in('Ameriwood','Dorel Home Products')
        then 'D71 - DHF'
        when vendor_nbr_dept = '71'
        and division = 'Cosco Products'
        then 'D71 - Cosco'
        when vendor_nbr_dept = '12'
        and division = 'Cosco Products'
        then 'D12 - Cosco'
        when vendor_nbr_dept = '79'
        and division = 'Dorel Home Products'
        then 'D79 - DHF'
        when vendor_nbr_dept = '71'
        then 'D71 - DF1'
        else null
        end as department_title
    ,'Daily Report ' ||current_date::date as file_name
    ,store_on_order
	,warehouse_on_order
	,last_13_weeks_units
	,last_52_weeks_units
	,last_4_weeks_sales
	,last_13_weeks_sales
	,last_52_weeks_sales
	,last_4_weeks_units_ly
	,last_13_weeks_units_ly
	,last_52_weeks_units_ly
	,last_4_weeks_sales_ly
	,last_13_weeks_sales_ly
	,last_52_weeks_sales_ly
	,wtd_ly_sales/nullif(wtd_ly_units::numeric(10,2),0) as avg_retail_last_year
	,last_week_sales
	,last_week_units_ly
	,last_week_sales_ly
	,ytd_units_ly
	,ytd_sales_ly
	/*START returns per week 
	counting the number of returns divided by walmart weeks */
	,ytd_store_returns_quantity_defective_and_overstock_ytd/ nullif(ytd_num_of_weeks::numeric(10,4),0) as ytd_store_returns_quantity_defective_and_overstock_perc
	,ytd_store_returns_quantity_recall_ytd/ nullif(ytd_num_of_weeks::numeric(10,4),0) as ytd_store_returns_quantity_recall_perc
	,ytd_store_returns_quantity_to_dc_ytd/ nullif(ytd_num_of_weeks::numeric(10,4),0) as ytd_store_returns_quantity_to_dc_perc
	,ytd_store_returns_quantity_to_return_center_ytd/ nullif(ytd_num_of_weeks::numeric(10,4),0) as ytd_store_returns_quantity_to_return_center_perc
	,ytd_store_returns_quantity_to_vendor_ytd/ nullif(ytd_num_of_weeks::numeric(10,4),0) as ytd_store_returns_quantity_to_vendor_perc
	/*END returns per week */
	--wtd sales last year / wtd units
	,cast(last_week_units_ly::numeric(10,2)/nullif(sia.traited_store_count_last_year,0) as numeric(10,2)) as wtd_units_per_traited_store_ly
    --last weeks units per traited stores 
    ,cast(last_week_sales_ly/nullif(sia.traited_store_count_last_year,0) as numeric(10,2)) as  wtd_sales_per_traited_store_ly
from sa
left join sia
on sa.current_item_num::bigint = sia.all_links_item_number
left join wia
on sa.current_item_num::bigint = wia.walmart_item_number
left join sfc
on sa.current_item_num::bigint = sfc.prime_item_number
)
;