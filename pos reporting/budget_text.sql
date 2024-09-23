--powers the text message in parabola
create or replace view pos_reporting.budget_text as 
(
with s as --ships
( -- ships data. will keep 
select * 
,case -- ecommerce retailer
	when retailer in( 'Walmart.com','SamsClub.com')
	then 1
	else 0 
	end as is_dot_com
,case --stores retailer
	when retailer in('Walmart Stores','Sam''s Club')
	then 1
	else 0
	end as is_stores
,case -- omni retailer
	when retailer in ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club')
	then 1
	else 0
	end as is_omni
,case -- yesterdays date
	when date_shipped = date(timezone('CST', now())) -1
	then 1
	else 0
	end as is_yesterday
,case -- year to date
	when date_shipped >= date_trunc('year', current_date)::date
	then 1
	else 0
	end as is_ytd
,case --month to date
	when date_shipped >= date_trunc('month', current_date)::date
	then 1
	else 0
	end as is_mtd
,case  -- quarter to date
	when date_shipped >= date_trunc('quarter', current_date)::date
	then 1
	else 0
	end as is_qtd
,case --last year YTD. used to calculate YOY 
	when date_shipped >= date_trunc('year',current_date - interval '1 year')::date
	and date_shipped <= (current_date - interval '1 year')::date
	then 1
	else 0
	end as is_ytd_ly
from ships_schema.ships
where 1=1
and  date_shipped >=current_date - interval '800 days' -- only want around year to date info from this

)
,a as -- naming convention from old query
( -- row sum up of sales for retailer and ship type by mtd, qtd, YTD, and YOY
select
	date(timezone('CST', now())) -1 as date
	,COALESCE(sum(case when is_yesterday =1 and is_dot_com =1 then sales end),0) as dot_com_yesterday
	,COALESCE(sum(case when is_yesterday =1 and is_stores =1 then sales end),0) as stores_yesterday
	,COALESCE(sum(case when is_yesterday =1 and is_omni =1 then sales end),0) as omni_yesterday
	,COALESCE(sum(case when is_yesterday =1  then sales end),0) as all_yesterday
	,COALESCE(sum(case when is_yesterday =1 and is_dot_com =1 and sale_type = 'Drop Ship' then sales end),0) as dot_com_dsv
	,COALESCE(sum(case when is_yesterday =1 and is_dot_com =1 and sale_type = 'Bulk' then sales end),0) as dot_com_bulk
	,COALESCE(sum(case when is_yesterday =1 and is_dot_com =1 and sale_type = 'Direct Import' then sales end),0) as dot_com_di
	,COALESCE(sum(case when is_yesterday =1 and is_stores =1 and sale_type = 'Brick & Mortar' then sales end),0) as stores_bm
	,COALESCE(sum(case when is_yesterday =1 and is_stores =1 and sale_type = 'Bulk' then sales end),0) as stores_bulk
	,COALESCE(sum(case when is_yesterday =1 and is_stores =1 and sale_type = 'Direct Import' then sales end),0) as stores_di
	,COALESCE(sum(case when is_ytd =1 and is_dot_com =1 then sales end),0) as dot_com_ytd
	,COALESCE(sum(case when is_ytd =1 and is_stores =1 then sales end),0) as stores_ytd
	,COALESCE(sum(case when is_ytd =1 and is_omni =1 then sales end),0) as omni_ytd
	,COALESCE(sum(case when is_mtd =1 and is_dot_com =1 then sales end),0) as dot_com_mtd
	,COALESCE(sum(case when is_mtd =1 and is_stores =1 then sales end),0) as stores_mtd
	,COALESCE(sum(case when is_mtd =1 and is_omni =1 then sales end),0) as omni_mtd
	,COALESCE(sum(case when is_qtd =1 and is_dot_com =1 then sales end),0) as dot_com_qtd
	,COALESCE(sum(case when is_qtd =1 and is_stores =1 then sales end),0) as stores_qtd
	,COALESCE(sum(case when is_qtd =1 and is_omni =1 then sales end),0) as omni_qtd
	,COALESCE(sum(case when is_ytd_ly =1 and is_dot_com =1 then sales end),0) as dot_com_ytd_ly
	,COALESCE(sum(case when is_ytd_ly =1 and is_stores =1 then sales end),0) as stores_ytd_ly
	,COALESCE(sum(case when is_ytd_ly =1 and is_omni =1 then sales end),0) as omni_ytd_ly
	,COALESCE(sum(case when is_ytd =1 then sales end),0) as all_ytd
	,COALESCE(sum(case when is_mtd =1then sales end),0) as all_mtd
	,COALESCE(sum(case when is_qtd =1 then sales end),0) as all_qtd
    ,COALESCE(sum(case when is_ytd_ly =1 then sales end),0) as all_ytd_ly
	from s
	where 1=1
	--and is_omni =1
	and s.model NOT IN ('')
)


,bud as --budget
( -- creating conditionals before summing up numbers. easier to read
select * 
,case 
	when month = date_trunc('month', current_date)
	then 1
	else 0
	end as is_mtd
,case 
	when date_part('quarter',current_date) = date_part('quarter',month)
	then 1
	else 0
	end as is_qtd
,case 
	when month >= date_trunc('year', current_date)
	then 1
	else 0
	end as is_ytd
,case
	when channel in( 'Walmart.com','SamsClub.com')
	then 1
	else 0 
	end as is_dot_com
,case
	when channel in('Walmart Stores','Sam''s Club')
	then 1
	else 0
	end as is_stores
,case
	when channel in ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club')
	then 1
	else 0
	end as is_omni
from budget_2024
)
,c as  -- old naming convention
(-- 1 row line of the summed up budget for this year
select
	date(timezone('CST', now())) - 1 as budget_date
	,COALESCE(sum(case when is_mtd =1 and  is_dot_com =1 then budget end),0) as dot_com_mo_bud
	,COALESCE(sum(case when is_mtd =1 and is_stores =1 then budget end),0) as stores_mo_bud
	,COALESCE(sum(case when is_mtd =1 and is_omni =1 then budget end),0) as omni_mo_bud
	,COALESCE(sum(case when is_qtd =1 and  is_dot_com =1 then budget end),0) as dot_com_qrt_bud
	,COALESCE(sum(case when is_qtd =1 and is_stores =1 then budget end),0) as stores_qrt_bud
	,COALESCE(sum(case when is_qtd =1 and is_omni =1 then budget end),0) as omni_qrt_bud
	,COALESCE(sum(case when  is_ytd =1 and  is_dot_com =1 then budget end),0) as dot_com_ytd_bud
	,COALESCE(sum(case when  is_ytd =1 and is_stores =1 then budget end),0) as stores_ytd_bud
	,COALESCE(sum(case when  is_ytd =1 and is_omni =1 then budget end),0) as omni_ytd_bud
	,COALESCE(sum(case when is_qtd =1 then budget end),0) as all_qrt_bud
	,COALESCE(sum(case when is_mtd =1 then budget end),0) as all_mo_bud
	,COALESCE(sum(case when  is_ytd =1 then budget end),0) as all_ytd_bud
from bud
)
,d as --contacts
( -- list of ppl the text message will send out to 
select
	date(timezone('CST', now())) - 1 as contact_date -- date the text will send out 
	,name
	,phone
	,email
from contacts
)
,e as --walmart calendar
( -- to show which walmart week we're in on the final front facing text
select
	date as wm_date,
	wm_week
	from wm_calendar
)
,format_var as --format variables
(
select
    d.phone
    ,d.email
    ,e.wm_week as wm_week
    ,to_char(date, 'mm.dd') as format_date
    ,'$' || to_char(dot_com_yesterday::numeric(10,0) , 'FM999,999,999') as dot_com_yesterday
    ,'$' || to_char(dot_com_dsv::numeric(10,0) , 'FM999,999,999') as dot_com_dsv
    ,'$' || to_char(dot_com_bulk::numeric(10,0) , 'FM999,999,999') as dot_com_bulk
    ,'$' || to_char(dot_com_di::numeric(10,0) , 'FM999,999,999') as dot_com_di
    ,'$' || to_char(dot_com_mtd::numeric(10,0) , 'FM999,999,999') as dot_com_mtd
    ,'$' || to_char(dot_com_mo_bud::numeric(10,0) , 'FM999,999,999') as dot_com_mo_bud
    ,'$' || to_char(dot_com_qtd::numeric(10,0) , 'FM999,999,999') as dot_com_qtd
    ,'$' || to_char(dot_com_qrt_bud::numeric(10,0) , 'FM999,999,999') as dot_com_qrt_bud
    ,'$' || to_char(dot_com_ytd::numeric(10,0) , 'FM999,999,999') as dot_com_ytd
    ,'$' || to_char(dot_com_ytd_ly::numeric(10,0) , 'FM999,999,999') as dot_com_ytd_ly
    ,'$' || to_char(dot_com_ytd_bud::numeric(10,0) , 'FM999,999,999') as dot_com_ytd_bud
    ,'$' || to_char(stores_yesterday::numeric(10,0) , 'FM999,999,999') as stores_yesterday
    ,'$' || to_char(stores_bm::numeric(10,0) , 'FM999,999,999') as stores_bm
    ,'$' || to_char(stores_bulk::numeric(10,0) , 'FM999,999,999') as stores_bulk
    ,'$' || to_char(stores_di::numeric(10,0) , 'FM999,999,999') as stores_di
    ,'$' || to_char(stores_mtd::numeric(10,0) , 'FM999,999,999') as stores_mtd
    ,'$' || to_char(stores_mo_bud::numeric(10,0) , 'FM999,999,999') as stores_mo_bud
    ,'$' || to_char(stores_qtd::numeric(10,0) , 'FM999,999,999') as stores_qtd
    ,'$' || to_char(stores_qrt_bud::numeric(10,0) , 'FM999,999,999') as stores_qrt_bud
    ,'$' || to_char(stores_ytd::numeric(10,0) , 'FM999,999,999') as stores_ytd
    ,'$' || to_char(stores_ytd_bud::numeric(10,0) , 'FM999,999,999') as stores_ytd_bud
    ,'$' || to_char(omni_yesterday::numeric(10,0) , 'FM999,999,999') as omni_yesterday
    ,'$' || to_char(omni_mtd::numeric(10,0) , 'FM999,999,999') as omni_mtd
    ,'$' || to_char(omni_mo_bud::numeric(10,0) , 'FM999,999,999') as omni_mo_bud
    ,'$' || to_char(omni_qtd::numeric(10,0) , 'FM999,999,999') as omni_qtd
    ,'$' || to_char(omni_qrt_bud::numeric(10,0) , 'FM999,999,999') as omni_qrt_bud
    ,'$' || to_char(omni_ytd::numeric(10,0) , 'FM999,999,999') as omni_ytd
    ,'$' || to_char(omni_ytd_ly::numeric(10,0) , 'FM999,999,999') as omni_ytd_ly
    ,'$' || to_char(omni_ytd_bud::numeric(10,0) , 'FM999,999,999') as omni_ytd_bud
    ,'$' || to_char(all_yesterday::numeric(10,0) , 'FM999,999,999') as all_yesterday
    ,'$' || to_char(all_mtd::numeric(10,0) , 'FM999,999,999') as all_mtd
    ,'$' || to_char(all_qtd::numeric(10,0) , 'FM999,999,999') as all_qtd
    ,'$' || to_char(all_ytd::numeric(10,0) , 'FM999,999,999') as all_ytd
    ,case
        when stores_ytd - stores_ytd_ly <0
        then '($' || to_char((stores_ytd::numeric(10,0)-stores_ytd_ly::numeric(10,0)) * -1 , 'FM999,999,999') ||')'
        else  '$' || to_char(stores_ytd::numeric(10,0)-stores_ytd_ly::numeric(10,0) , 'FM999,999,999')
        end as stores_yoy_dollars
    ,case
        when dot_com_ytd - dot_com_ytd_ly <0
        then '($' || to_char((dot_com_ytd::numeric(10,0)-dot_com_ytd_ly::numeric(10,0)) * -1 , 'FM999,999,999') ||')'
        else  '$' || to_char(dot_com_ytd::numeric(10,0)-dot_com_ytd_ly::numeric(10,0) , 'FM999,999,999')
        end as dot_com_yoy_dollars
    ,case
        when omni_ytd - omni_ytd_ly <0
        then '($' || to_char((omni_ytd::numeric(10,0)-omni_ytd_ly::numeric(10,0)) * -1 , 'FM999,999,999') ||')'
        else  '$' || to_char(omni_ytd::numeric(10,0)-omni_ytd_ly::numeric(10,0) , 'FM999,999,999')
        end as omni_yoy_dollars
    ,case
        when all_ytd - all_ytd_ly <0
        then '($' || to_char((all_ytd::numeric(10,0)-all_ytd_ly::numeric(10,0)) * -1 , 'FM999,999,999') ||')'
        else  '$' || to_char(all_ytd::numeric(10,0)-all_ytd_ly::numeric(10,0) , 'FM999,999,999')
        end as all_yoy_dollars
    ,coalesce(cast(((stores_ytd - stores_ytd_ly)/nullif(stores_ytd_ly,0)) * 100 as numeric(10,2)),0) as stores_yoy_perc
    ,coalesce(cast(((dot_com_ytd - dot_com_ytd_ly)/nullif(dot_com_ytd_ly,0)) * 100 as numeric(10,2)),0) as dot_com_yoy_perc
    ,coalesce(cast(((omni_ytd - omni_ytd_ly)/nullif(omni_ytd_ly,0)) * 100 as numeric(10,2)),0) as omni_yoy_perc
    ,coalesce(cast(((all_ytd - all_ytd_ly)/nullif(all_ytd_ly,0)) * 100 as numeric(10,2)),0) as all_yoy_perc
from a
left join c
on a.date = c.budget_date
join d
on a.date = d.contact_date
left join e 
on a.date = e.wm_date
)
select
    phone
    ,email
    ,wm_week
    ,format_date
    ,dot_com_yesterday
    ,dot_com_dsv
    ,dot_com_bulk
    ,dot_com_di
    ,dot_com_mtd
    ,dot_com_mo_bud
    ,dot_com_qtd
    ,dot_com_qrt_bud
    ,dot_com_ytd
    ,dot_com_yoy_dollars
    ,dot_com_yoy_perc
    ,dot_com_ytd_bud
    ,stores_yesterday
    ,stores_bm
    ,stores_bulk
    ,stores_di
    ,stores_mtd
    ,stores_mo_bud
    ,stores_qtd
    ,stores_qrt_bud
    ,stores_ytd
    ,stores_yoy_dollars
    ,stores_yoy_perc
    ,stores_ytd_bud
    ,omni_yesterday
    ,omni_mtd
    ,omni_mo_bud
    ,omni_qtd
    ,omni_qrt_bud
    ,omni_ytd
    ,omni_yoy_dollars
    ,omni_yoy_perc
    ,omni_ytd_bud
    ,all_yesterday
    ,all_mtd
    ,all_qtd
    ,all_ytd
    ,all_yoy_dollars
    ,all_yoy_perc
    ,'WM Week = '||wm_week
    ||E'\n'||E'\n'||
    '---------------------'
    ||E'\n'||E'\n'||
    'E-Commerce'||E'\n'||format_date||': '||dot_com_yesterday||E'\n'||'DSV: '||dot_com_dsv||E'\n'||'Bulk: '||dot_com_bulk||E'\n'||'DI: '||dot_com_di||E'\n'||E'\n'||'MTD: '||dot_com_mtd||E'\n'||'Bud: '||dot_com_mo_bud||E'\n'||E'\n'||'QTD: '||dot_com_qtd||E'\n'||'Bud: '||dot_com_qrt_bud||E'\n'||E'\n'||'YTD: '||dot_com_ytd||E'\n'||'Bud: '||dot_com_ytd_bud
    ||E'\n'||E'\n'||'YOY($): '||dot_com_yoy_dollars||E'\n'||'YOY(%): '||dot_com_yoy_perc||'%'
    ||E'\n'||E'\n'||
    '---------------------'
    ||E'\n'||E'\n'||
    'Stores'||E'\n'||format_date||': '||stores_yesterday||E'\n'||'B&M: '||stores_bm||E'\n'||'DI: '||stores_di||E'\n'||E'\n'||'MTD: '||stores_mtd||E'\n'||'Bud: '||stores_mo_bud||E'\n'||E'\n'||'QTD: '||stores_qtd||E'\n'||'Bud: '||stores_qrt_bud||E'\n'||E'\n'||'YTD: '||stores_ytd||E'\n'||'Bud: '||stores_ytd_bud
    ||E'\n'||E'\n'||'YOY($): '||stores_yoy_dollars||E'\n'||'YOY(%): '||stores_yoy_perc||'%'
    ||E'\n'||E'\n'||
    '---------------------'
    ||E'\n'||E'\n'||
    'Omni Channel'||E'\n'||format_date||': '||omni_yesterday||E'\n'||E'\n'||'MTD: '||omni_mtd||E'\n'||'Bud: '||omni_mo_bud||E'\n'||E'\n'||'QTD: '||omni_qtd||E'\n'||'Bud: '||omni_qrt_bud||E'\n'||E'\n'||'YTD: '||omni_ytd||E'\n'||'Bud: '||omni_ytd_bud
    ||E'\n'||E'\n'||'YOY($): '||omni_yoy_dollars||E'\n'||'YOY(%): '||omni_yoy_perc||'%'
	as final
from format_var
)
;
