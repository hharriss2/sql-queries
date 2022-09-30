--powers the mattress report on Power BI
create or replace view pos_reporting.mattress_report as(
with ty_lw_sales as 
(
select item_id,sum(sales) as ty_lw_sales, sum(units) as ty_lw_units, wm_week
from retail_link_pos 
where 1=1
and wm_week = (select max(wm_week) from retail_link_pos where wm_week !=(select max(wm_week) from retail_link_pos))
group by wm_week, item_id
order by wm_week desc
)
,
 ly_lw_sales as 
(
select item_id,sum(sales) as ly_lw_sales,sum(units) as ly_lw_units ,wm_week
from retail_link_pos 
where 1=1
and wm_week = (select max(wm_week) -100 from retail_link_pos where wm_week !=(select max(wm_week) from retail_link_pos))
group by wm_week, item_id
order by wm_week desc
)
,
 ty_l13_sales as 
(
select item_id,sum(sales) as ty_l13_sales,sum(units) as ty_l13_units
from retail_link_pos 
where 1=1
and wm_week in (select distinct wm_week 
				from retail_link_pos 
				where wm_week !=(select max(wm_week) 
									from retail_link_pos
								)
								
				order by wm_week desc
				limit 13
				)
group by item_id
)
,ly_l13_sales as 
(
select item_id,sum(sales) as ly_l13_sales,sum(units) as ly_l13_units
from retail_link_pos 
where 1=1
and wm_week in (select distinct wm_week -100
				from retail_link_pos 
				where wm_week !=(select max(wm_week) 
									from retail_link_pos
								)
								
				order by wm_week -100 desc
				limit 13
				)
group by item_id
)
,ty_ytd_sales as 
(
select item_id,sum(sales) as ty_ytd_sales,sum(units) as ty_ytd_units
from retail_link_pos 
where wm_week in (
				select distinct wm_week
				from retail_link_pos 
				where 1=1
				and wm_week !=(select max(wm_week) 
									from retail_link_pos
								)
				and wm_week::text like concat(date_part('year',now())::text,'%')
				order by wm_week desc
				limit 52
				)
group by item_id
)
,ly_ytd_sales as 
(
select item_id,sum(sales) as ly_ytd_sales,sum(units) as ly_ytd_units
from retail_link_pos 
where wm_week in (
				select distinct wm_week -100
				from retail_link_pos 
				where 1=1
				and wm_week !=(select max(wm_week) 
									from retail_link_pos
								)
				and wm_week::text like concat(date_part('year',now())::text,'%')
				order by wm_week - 100 desc
				limit 52
				)
group by item_id
)
,tool_model as 
(
select * 
from clean_data.master_com_list
where model in (select model from cat_by_model where cat ='Mattresses')
)
,product_status as 
(
select distinct p.model, production_status , cat
from products_raw p
left join cat_by_model cbm 
on p.model = cbm.model
where cat ='Mattresses'
)
select tm.item_id
	,ty_lw_sales
	,ty_lw_units
	,ty_ytd_units
	,ty_ytd_sales
	,ly_ytd_units
	,ly_ytd_sales
	,ty_l13_units
	,ty_l13_sales
	,ly_l13_units
	,ly_l13_sales
	,ps.production_status
from product_status ps 
join tool_model tm
	on ps.model = tm.model
left join ty_ytd_sales t1
	on t1.item_id = tm.item_id
left join ly_ytd_sales t2
	on tm.item_id = t2.item_id
left join ty_l13_sales t3
	on tm.item_id = t3.item_id
left join ly_l13_sales t4
	on tm.item_id = t4.item_id
left join ty_lw_sales t5
	on tm.item_id = t5.item_id
left join ly_lw_sales t6
	on tm.item_id = t6.item_id
);
