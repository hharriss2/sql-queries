create or replace view forecast.forecast_agenda_view as (
select 
	tool_id
	,model
	,cat
	,product_name
	,implimentation_code
	,priority_code
	,fcast_month
	,fcast_year
	,end_of_week_oh_unit
	,on_order_unit		
	,fcast_units
	,case 
		when fcast_month <date_part('month',now()) and fcast_year = date_part('year',now()) 
		then 0 
		else lag(available_to_sell) over (order by fcast_id) end as available_to_sell
	,purchase_orders
	,pos_units
	,pos_sales
	,pos_units_ly
	,pos_sales_ly
	,s_sales
	,s_sales_ly
	,s_units
	,s_units_ly
	,l4_units
	,l13_units
	,l52_units
	,ams_units
	,current_cost
	,fcast_id
	,ssr_id
	,l4_units_ships
	,first_purchase_date
	,l12_units_ships
from
	(
		with
		fcast as 
			(
			-- forecast data 2nd view
			--different then the first
			--this one has ty and ny forecasts running down
		
					select 
					dense_rank() over (order by
						f.model, forecast_date
					) as fcast_id
					,coalesce(mcl.item_id,f.item_id) as tool_id
					,f.model
					,implimentation_code
					,priority_code
					,date_part('month', forecast_date)::integer as fcast_month
					,date_part('year', forecast_date)::integer as fcast_year
					--write a case statement to get the following:
					-- we want to get current pos for this month and prior of the year
					--if month is past current, use last years sale to populate.
					--this this all the way up to current month next year
					,case 
						when date_part('month',forecast_date)::integer <= date_part('month',now())::integer
							and date_part('year',forecast_date)::integer = date_part('year',now())::integer
						--when fcast_month is less than or equal to current month, then 1
					then 1
						when date_part('month',forecast_date)::integer > date_part('month',now())::integer
							AND date_part('year', forecast_date)::integer = date_part('year',now())::integer
						--when fcast_month is greater than current month, next step
						--when fcast year = current year, then 2
					then 2
						when date_part('month',forecast_date)::integer <=date_part('month',now())::integer
					then 3
					else 4
						--else 3
					end as is_month
					--repeat and rename to join last years to pos
					,case 
						when date_part('month',forecast_date)::integer <= date_part('month',now())::integer
					then 1
						when date_part('month',forecast_date)::integer > date_part('month',now())::integer
							AND date_part('year', forecast_date)::integer = date_part('year',now())::integer
					then 2
					else 3
					end as is_month_ly
					,units as fcast_units
					 --3. case statement to determine forecast year
				from forecast.forecast_agenda f
				left join clean_data.com_product_list mcl
				on f.model = mcl.model
				where date_inserted::date =(select max(date_inserted::date) from forecast.forecast_agenda)
				and f.model != '2241009W'--because kevin told me to 
				--2. finding the most recent forcast data
				--find current agenda
				--finds the current forecast
		
			)
--		,oh as --dont need since we have SSR on hands
--			(
--			select distinct model
--				,date_part('month', inventory_date)::integer as oh_month
--				,date_part('year', inventory_date)::integer as oh_year
--				,sum(c.qty_on_hand) - sum(c.open_order_qty) as on_hand_qty
--				--calculate actual on hands
--			from forecast.com_on_hand c
--			where warehouse_name !='Montreal Passthrough (ALL)'
--			and warehouse_name !~~'%Direct Import%'
--			and inventory_date = (select max(inventory_date) from forecast.com_on_hand)
--			--only finding current on hands
--			group by 
--				model
--				,date_part('month', inventory_date)::integer
--				,date_part('year', inventory_date)::integer
--			)
		,pos as
			(
			--need pos data to calculate AUR.pulling in item id, date, units, and sales. will calculate AURS in power bi 
		select model
			, pos_month
			, sum(current_units) as current_units
		--	,sum(past_month_ly_units) as past_month_ly_units
		--	,sum(current_units_ly) as current_units_ly
		--	,sum(past_month_last_ly_units) as past_month_last_ly_units
			,sum(current_sales) as current_sales
		--	,sum(past_month_ly_sales) as past_month_ly_sales
		--	,sum(current_sales_ly) as current_sales_ly
		--	,sum(past_month_last_ly_sales) as past_month_last_ly_sales
			,sum(total_units_ly) as total_units_ly
			,sum(total_sales_ly) as total_sales_ly
		from(
				select tool_id::integer
					,coalesce(lc.model, cl.model) as model
					,date_part('month', sale_date)::integer as pos_month
					,date_part('year', sale_date)::integer as pos_year
					--same logic as forecast
					--different way to calculate
					,case --units sold THIS year up to current month
						when date_part('year', sale_date)::integer = date_part('year',now())::integer
					then sum(units)
					else 0 
					end as current_units
		/*			
					,case --units sold LAST year that are past the current month
						when date_part('month',sale_date)::integer > date_part('month',now())::integer
						and date_part('year', sale_date)::integer = date_part('year',now())::integer -1
					then sum(units)
					else 0
					end as past_month_ly_units
					,case --units sold LAST year up to current month
						when date_part('year', sale_date)::integer = date_part('year',now())::integer -1
						and date_part('month',sale_date)::integer <= date_part('month',now())::integer
					then sum(units)
					else 0
					end as current_units_ly
					,case --$ sold LAST year up to current month
						when date_part('year', sale_date)::integer = date_part('year',now())::integer -1
						and date_part('month',sale_date)::integer <= date_part('month',now())::integer
					then sum(sales)
					else 0
					end as current_sales_ly
					,case-- units sold YEAR BEFORE last year that are past the current month
						when date_part('month',sale_date)::integer > date_part('month',now())::integer
						and date_part('year', sale_date)::integer = date_part('year',now())::integer -2
					then sum(units)
					else 0
					end as past_month_last_ly_units
		*/			
					,case--$ sold THIS year up to current month
						when date_part('year', sale_date)::integer = date_part('year',now())::integer
					then sum(sales)
					else 0 
					end as current_sales
		/*			
					,case--$ sold LAST year that are past the current month
						when date_part('month',sale_date)::integer > date_part('month',now())::integer
						and date_part('year', sale_date)::integer = date_part('year',now())::integer -1
					then sum(sales)
					else 0
					end as past_month_ly_sales			
					,case-- $ sold YEAR BEFORE last year that are past the current month
						when date_part('month',sale_date)::integer > date_part('month',now())::integer
						and date_part('year', sale_date)::integer = date_part('year',now())::integer -2
					then sum(sales)
					else 0
					end as past_month_last_ly_sales
		*/			
					,case --total of last years units
						when date_part('year', sale_date)::integer = date_part('year',now())::integer -1
					then sum(units)
					else 0 
					end as total_units_ly
					,case --total of last years $
						when date_part('year', sale_date)::integer = date_part('year',now())::integer -1
					then sum(sales)
					else 0 
					end as total_sales_ly
				from pos_reporting.retail_sales rs
				left join clean_data.com_product_list cl
				on rs.tool_id = cl.item_id::text
				left join pos_reporting.lookup_com lc
				on lc.item_id = rs.tool_id
				group by tool_id::integer
					,coalesce(lc.model, cl.model)
					,date_part('month', sale_date)::integer
					,date_part('year', sale_date)::integer
			) t1
		group by tool_id
			, model
			, pos_month
			)
		,s as 
			(--needs ships to find this year and last year ships
		
			select
				model
				,s_month
				,sum(current_units) as current_units
		--		,sum(past_month_ly_units) as past_month_ly_units
				,sum(current_sales) as current_sales
		--		,sum(past_month_ly_sales) as past_month_ly_sales
				,sum(total_units_ly) as total_units_ly
				,sum(total_sales_ly) as total_sales_ly
			from(
				select model
					,date_part('month', date_shipped)::integer s_month
					,date_part('year', date_shipped)::integer as s_year
					,case --units sold THIS year up to current month
						when date_part('year', date_shipped)::integer = date_part('year',now())::integer
					then sum(units)
					else 0 
					end as current_units
					,case --units sold THIS year up to current month
						when date_part('year', date_shipped)::integer = date_part('year',now())::integer
					then sum(sales)
					else 0 
					end as current_sales
		/* last years next month - end of year 
					,case --units sold LAST year that are past the current month
						when date_part('month',date_shipped)::integer > date_part('month',now())::integer
						and date_part('year', date_shipped)::integer = date_part('year',now())::integer -1
					then sum(sales)
					else 0
					end as past_month_ly_sales
					,case --units sold LAST year that are past the current month
						when date_part('month',date_shipped)::integer > date_part('month',now())::integer
						and date_part('year', date_shipped)::integer = date_part('year',now())::integer -1
					then sum(units)
					else 0
					end as past_month_ly_units
		*/
		/*	last year sales jan-now		
					,case --$ sold LAST year up to current month
						when date_part('year', date_shipped)::integer = date_part('year',now())::integer -1
						and date_part('month',date_shipped)::integer <= date_part('month',now())::integer
					then sum(sales)
					else 0
					end as current_sales_ly
					,case --Units sold LAST year up to current month
						when date_part('year', date_shipped)::integer = date_part('year',now())::integer -1
						and date_part('month',date_shipped)::integer <= date_part('month',now())::integer
					then sum(units)
					else 0
					end as current_units_ly
		*/			
					,case --total of last years units
						when date_part('year', date_shipped)::integer = date_part('year',now())::integer -1
					then sum(units)
					else 0 
					end as total_units_ly
					,case --total of last years $
						when date_part('year', date_shipped)::integer = date_part('year',now())::integer -1
					then sum(sales)
					else 0 
					end as total_sales_ly
				from ships_schema.ships
				where retailer !='Walmart Stores'--throws off our forecast
				group by model
					,date_part('month', date_shipped)::integer
					,date_part('year', date_shipped)::integer
				)t1
				group by model
					,s_month
		
			)
		,pr as 
			(
			select distinct p.model, cbm.cat, p.product_name
			from products_raw p 
			join cat_by_model cbm 
			on p.model = cbm.model
			)
		,pos_lw as
			(
			select tool_id
				,model
				,l4_units
				,l13_units
				,l52_units 
			from pos_reporting.pos_lw
			)
		,cur_cost as
			(--wanting to see what shipments do. might redo heiarchy later
			select distinct --2 dupes from raw upload. gotta add distinct 
				model,
				case
					when current_dsv_cost>0 then current_dsv_cost
					when current_dsv_cost is not null then current_dsv_cost
					when perm_dsv_cost >0 then perm_dsv_cost
					when perm_dsv_cost is not null then perm_dsv_cost
					else null
					end as current_cost
			from lookups.current_cost
			)
		,ssr as 
			(
			 select ssr_id
			 	,model
			 	,ssr_month
			 	,ssr_year
			 	,purchase_orders
			 	, ats_qty + purchase_orders as ats_qty
			 	,min_id
			 	,first_purchase_date 
			 from forecast.purchase_orders_fcast
			)
		,oh as --new on hands
			(
			select ml.model
				,f.item_id
				,f.end_of_week_oh_unit
				,f.on_order_unit
				,date_part('month',f.report_date) as oh_month
				,date_part('year',f.report_date) as oh_year
				,f.vendor_stock_id 
			from forecast.fc_instock f
			left join clean_data.master_com_list ml
			on f.item_id = ml.item_id
			)
		,ams_ships as
			(
			select s.model, ams_units, l4_units_ships, s.l12_units_ships
			from misc_views.ams_ships s
			)
		
		select 
			fcast.tool_id
			,fcast.model
			,pr.cat
			,pr.product_name
			,implimentation_code
			,priority_code
			,fcast_month
			,fcast_year
			,end_of_week_oh_unit
			,on_order_unit
			,fcast_units
			,coalesce(lead(ats_qty,1) over (order by fcast_id),0) +
			coalesce((sum(ats_qty) over (partition by fcast.model order by fcast_id) ) - (sum(fcast_units) over (partition by fcast.model order by fcast_id)),0) as available_to_sell
			,purchase_orders
			--1 is TY Jan-Now
			-- 2 Next month- End of Year
			-- 3 is NY Jan-Now
			-- 4 is Next Month
				--pos_units
			,case when fcast.is_month = 1
				then pos.current_units--when month is 1, current units
				when fcast.is_month = 2--when month is 2, ly units
				then 0--pos.total_units_ly
				else 0
				end as pos_units --POS TY
				--pos sales
			,case when fcast.is_month = 1--when month is 1. current sales
				then pos.current_sales
				when fcast.is_month = 2
				then 0--pos.total_sales_ly--when month is 2, ly sales
				else 0
				end as pos_sales --POS TY
				--ly pos units
			,case when fcast.is_month = 1 --when month is 1 then ly years
				then pos.total_units_ly
				when fcast.is_month = 2 --when month is 2, ly units
				then pos.total_units_ly
				when fcast.is_month = 3
				then pos.current_units --when month is 3, current units
				else 0
				end as pos_units_ly --POS Units LY
				--pos sales ly
			,case when fcast.is_month = 1 --when month is 1, then last years units
				then pos.total_sales_ly
				when fcast.is_month = 2
				then pos.total_sales_ly
				when fcast.is_month = 3
				then pos.current_sales
				else 0
				end as pos_sales_ly
				--ships units
			,case when fcast.is_month = 1 --when month is 1, current units
				then s.current_units
				when fcast.is_month = 2 --when month is 2, ly units
				then 0--s.total_units_ly
				else 0
				end as s_units
			,case when fcast.is_month = 1 --when month is 1, ly units
				then s.total_units_ly
				when fcast.is_month = 2 --when month is 2, ly units
				then s.total_units_ly
				when fcast.is_month = 3 --when month is 3, current units
				then s.current_units
				else 0
				end as s_units_ly
			,case when fcast.is_month = 1 --when month is 1, current units
				then s.current_sales
				when fcast.is_month = 2 --when month is 2, ly units
				then 0--s.total_sales_ly
				else 0
				end as s_sales
			,case when fcast.is_month = 1 --when month is 1, ly units
				then s.total_sales_ly
				when fcast.is_month = 2 --when month is 2, ly units
				then s.total_sales_ly
				when fcast.is_month = 3 --when month is 3, current units
				then s.current_sales
				else 0
				end as s_sales_ly
		--	,pos.total_units_ly
		--	,pos.total_sales_ly
			,l4_units
			,l13_units
			,l52_units
			,ams_units
			,current_cost * fcast_units as current_cost
			,fcast_id
			,ssr_id
			,l4_units_ships
			,first_purchase_date
			,l12_units_ships
		from fcast
		left join s
		on s.model = fcast.model and s_month = fcast_month  
		left join oh
		on oh.model = fcast.model and oh_month = fcast_month and fcast_year = oh_year
		left join pos 
		on pos.model = fcast.model and pos_month = fcast_month 
		left join pr
		on pr.model = fcast.model
		left join pos_lw 
		on pos_lw.model = fcast.model
		left join cur_cost 
		on cur_cost.model = fcast.model
		left join ams_ships 
		on fcast.model = ams_ships.model
		left join ssr 
		on ssr.model = fcast.model and ssr.ssr_month = fcast_month and ssr.ssr_year = fcast_year


)t1
)

;



--FORECAST AGENDA FACT VIEW
create or replace view power_bi.forecast_agenda_pbix as (
select tiv.tool_id_id
	,mv.model_id
	,cbm.cbm_id
	,pn.product_name_id
	,icv.ic_id
	,pc.pc_id
	,mt.fcast_date_id
	,end_of_week_oh_unit
	,on_order_unit
	,fcast_units
	,available_to_sell
	,purchase_orders
	,pos_units
	,pos_units_ly
	,pos_sales
	,pos_sales_ly
	,s_sales
	,s_sales_ly
	,s_units
	,s_units_ly
	,l4_units
	,l13_units
	,l52_units
	,ams_units
	,current_cost
	,fcast_id
	,ssr_id
--	,min_id
	,l4_units_ships
	,first_purchase_date
	,l12_units_ships
from forecast.forecast_agenda_view fav
left join power_bi.tool_id_view tiv
on fav.tool_id::text = tiv.tool_id
left join power_bi.model_view_pbix mv
on mv.model_name = fav.model
left join cat_by_model cbm
on cbm.model = fav.model
left join power_bi.product_name_view_pbix pn
on fav.product_name = pn.product_name
left join power_bi.imp_code_view icv
on icv.implimentation_code = fav.implimentation_code
left join power_bi.priority_code pc
on pc.priority_code = fav.priority_code
left join power_bi.fcast_date_tbl mt
on mt.month_number = fav.fcast_month and mt.year_number = fav.fcast_year
)

;




/*START VIEW TO STAGING*/
truncate forecast.forecast_agenda_tbl;
insert into forecast.forecast_agenda_tbl ( 
    fcast_id,
	tool_id,
    model,
    cat,
    product_name,
    implimentation_code,
    priority_code,
    fcast_month,
    fcast_year,
    end_of_week_oh_unit,
    on_order_unit,
    fcast_units,
    available_to_sell,
    purchase_orders,
    pos_units,
    pos_sales,
    pos_units_ly,
    pos_sales_ly,
    s_sales,
    s_sales_ly,
    s_units,
    s_units_ly,
    l4_units,
    l13_units,
    l52_units,
    ams_units,
    current_cost,
    ssr_id,
    l4_units_ships,
    first_purchase_date
)
select     
	fcast_id,
	tool_id,
    model,
    cat,
    product_name,
    implimentation_code,
    priority_code,
    fcast_month,
    fcast_year,
    end_of_week_oh_unit,
    on_order_unit,
    fcast_units,
    available_to_sell,
    purchase_orders,
    pos_units,
    pos_sales,
    pos_units_ly,
    pos_sales_ly,
    s_sales,
    s_sales_ly,
    s_units,
    s_units_ly,
    l4_units,
    l13_units,
    l52_units,
    ams_units,
    current_cost,
    ssr_id,
    l4_units_ships,
    first_purchase_date
 from forecast.forecast_agenda_view;
 /*END VIEW TO STAGING*/
 
