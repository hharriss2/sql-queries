--powers the text message in parabola
create or replace view pos_reporting.budget_text as 
(
with s as --ships
( -- ships data. will keep 
select * 
,case
	when retailer in( 'Walmart.com','SamsClub.com')
	then 1
	else 0 
	end as is_dot_com
,case
	when retailer in('Walmart Stores','Sam''s Club')
	then 1
	else 0
	end as is_stores
,case
	when retailer in ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club')
	then 1
	else 0
	end as is_omni
,case
	when date_shipped = date(timezone('CST', now())) -1
	then 1
	else 0
	end as is_yesterday
,case 
	when date_shipped >= date_trunc('year', current_date)
	then 1
	else 0
	end as is_ytd
,case 
	when date_shipped >= date_trunc('month', current_date)
	then 1
	else 0
	end as is_mtd
,case 
	when date_shipped >= date_trunc('quarter', current_date)
	then 1
	else 0
	end as is_qtd
from ships_schema.ships
where 1=1
and  date_shipped >=current_date - interval '400 days' -- only want around year to date info from this

)

,a as -- naming convention from old query
( -- 1 row sum up of sales for retailer and ship type by mtd, qtd, and ytd
select
	date(timezone('CST', now())) -1 as date,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in( 'Walmart.com','SamsClub.com') then sales end),0) as dot_com_yesterday,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in('Walmart Stores','Sam''s Club') then sales end),0) as stores_yesterday,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then sales end),0) as omni_yesterday,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1  then sales end),0)
as all_yesterday,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in( 'Walmart.com','SamsClub.com') and sale_type = 'Drop Ship' then sales end),0) as dot_com_dsv,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in( 'Walmart.com','SamsClub.com') and sale_type = 'Bulk' then sales end),0) as dot_com_bulk,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in( 'Walmart.com','SamsClub.com') and sale_type = 'Direct Import' then sales end),0) as dot_com_di,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in('Walmart Stores','Sam''s Club') and sale_type = 'Brick & Mortar' then sales end),0) as stores_bm,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in('Walmart Stores','Sam''s Club') and sale_type = 'Bulk' then sales end),0) as stores_bulk,
	COALESCE(sum(case when date_shipped = date(timezone('CST', now())) -1 and retailer in('Walmart Stores','Sam''s Club') and sale_type = 'Direct Import' then sales end),0) as stores_di,
	COALESCE(sum(case when date_shipped >= date_trunc('year', current_date) and retailer in( 'Walmart.com','SamsClub.com') then sales end),0) as dot_com_ytd,
	COALESCE(sum(case when date_shipped >= date_trunc('year', current_date) and retailer in('Walmart Stores','Sam''s Club') then sales end),0) as stores_ytd,
	COALESCE(sum(case when date_shipped >= date_trunc('year', current_date) and retailer IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then sales end),0) as omni_ytd,
	COALESCE(sum(case when date_shipped >= date_trunc('month', current_date) and retailer in( 'Walmart.com','SamsClub.com') then sales end),0) as dot_com_mtd,
	COALESCE(sum(case when date_shipped >= date_trunc('month', current_date) and retailer in('Walmart Stores','Sam''s Club') then sales end),0) as stores_mtd,
	COALESCE(sum(case when date_shipped >= date_trunc('month', current_date) and retailer IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then sales end),0) as omni_mtd,
	COALESCE(sum(case when date_shipped >= date_trunc('quarter', current_date) and retailer in( 'Walmart.com','SamsClub.com') then sales end),0) as dot_com_qtd,
	COALESCE(sum(case when date_shipped >= date_trunc('quarter', current_date) and retailer in('Walmart Stores','Sam''s Club') then sales end),0) as stores_qtd,
	COALESCE(sum(case when date_shipped >= date_trunc('quarter', current_date) and retailer IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then sales end),0) as omni_qtd,
	COALESCE(sum(case when date_shipped >= date_trunc('year', current_date) then sales end),0) 
as all_ytd,
	COALESCE(sum(case when date_shipped >= date_trunc('month', current_date)then sales end),0) 
as all_mtd,
	COALESCE(sum(case when date_shipped >= date_trunc('quarter', current_date) then sales end),0) 
as all_qtd
	from s
	where 1=1
	--and retailer IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club')
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
	date(timezone('CST', now())) - 1 as budget_date,
	COALESCE(sum(case when is_mtd =1 and  is_dot_com =1 then budget end),0) as dot_com_mo_bud,
	COALESCE(sum(case when is_mtd =1 and is_stores =1 then budget end),0) as stores_mo_bud,
	COALESCE(sum(case when is_mtd =1 and is_omni =1 then budget end),0) as omni_mo_bud,
	COALESCE(sum(case when is_qtd =1 and  is_dot_com =1 then budget end),0) as dot_com_qrt_bud,
	COALESCE(sum(case when is_qtd =1 and is_stores =1 then budget end),0) as stores_qrt_bud,
	COALESCE(sum(case when is_qtd =1 and is_omni =1 then budget end),0) as omni_qrt_bud,
	COALESCE(sum(case when  is_ytd =1 and  is_dot_com =1 then budget end),0) as dot_com_ytd_bud,
	COALESCE(sum(case when  is_ytd =1 and is_stores =1 then budget end),0) as stores_ytd_bud,
	COALESCE(sum(case when  is_ytd =1 and is_omni =1 then budget end),0) 
as omni_ytd_bud,
	COALESCE(sum(case when is_qtd =1 then budget end),0) as all_qrt_bud,
	COALESCE(sum(case when is_mtd =1 then budget end),0) 
as all_mo_bud,
	COALESCE(sum(case when  is_ytd =1 then budget end),0) 
as all_ytd_bud
from bud
)
,d as --contacts
( -- list of ppl the text message will send out to 
select
	date(timezone('CST', now())) - 1 as contact_date, -- date the text will send out 
	name,
	phone,
	email
from contacts
)
,e as --walmart calendar
( -- to show which walmart week we're in on the final front facing text
select
	date as wm_date,
	wm_week
	from wm_calendar
)
select
d.phone,
d.email,
e.wm_week as wm_week,
to_char(date, 'mm.dd') as date,
'$' || to_char(dot_com_yesterday::numeric(10,0) , 'FM999,999,999') as dot_com_yesterday,
'$' || to_char(dot_com_dsv::numeric(10,0) , 'FM999,999,999') as dot_com_dsv,
'$' || to_char(dot_com_bulk::numeric(10,0) , 'FM999,999,999') as dot_com_bulk,
'$' || to_char(dot_com_di::numeric(10,0) , 'FM999,999,999') as dot_com_di,
'$' || to_char(dot_com_mtd::numeric(10,0) , 'FM999,999,999') as dot_com_mtd,
'$' || to_char(dot_com_mo_bud::numeric(10,0) , 'FM999,999,999') as dot_com_mo_bud,
'$' || to_char(dot_com_qtd::numeric(10,0) , 'FM999,999,999') as dot_com_qtd,
'$' || to_char(dot_com_qrt_bud::numeric(10,0) , 'FM999,999,999') as dot_com_qrt_bud,
'$' || to_char(dot_com_ytd::numeric(10,0) , 'FM999,999,999') as dot_com_ytd,
'$' || to_char(dot_com_ytd_bud::numeric(10,0) , 'FM999,999,999') as dot_com_ytd_bud,
'$' || to_char(stores_yesterday::numeric(10,0) , 'FM999,999,999') as stores_yesterday,
'$' || to_char(stores_bm::numeric(10,0) , 'FM999,999,999') as stores_bm,
'$' || to_char(stores_bulk::numeric(10,0) , 'FM999,999,999') as stores_bulk,
'$' || to_char(stores_di::numeric(10,0) , 'FM999,999,999') as stores_di,
'$' || to_char(stores_mtd::numeric(10,0) , 'FM999,999,999') as stores_mtd,
'$' || to_char(stores_mo_bud::numeric(10,0) , 'FM999,999,999') as stores_mo_bud,
'$' || to_char(stores_qtd::numeric(10,0) , 'FM999,999,999') as stores_qtd,
'$' || to_char(stores_qrt_bud::numeric(10,0) , 'FM999,999,999') as stores_qrt_bud,
'$' || to_char(stores_ytd::numeric(10,0) , 'FM999,999,999') as stores_ytd,
'$' || to_char(stores_ytd_bud::numeric(10,0) , 'FM999,999,999') as stores_ytd_bud,
'$' || to_char(omni_yesterday::numeric(10,0) , 'FM999,999,999') as omni_yesterday,
'$' || to_char(omni_mtd::numeric(10,0) , 'FM999,999,999') as omni_mtd,
'$' || to_char(omni_mo_bud::numeric(10,0) , 'FM999,999,999') as omni_mo_bud,
'$' || to_char(omni_qtd::numeric(10,0) , 'FM999,999,999') as omni_qtd,
'$' || to_char(omni_qrt_bud::numeric(10,0) , 'FM999,999,999') as omni_qrt_bud,
'$' || to_char(omni_ytd::numeric(10,0) , 'FM999,999,999') as omni_ytd,
'$' || to_char(omni_ytd_bud::numeric(10,0) , 'FM999,999,999') as omni_ytd_bud,
'$' || to_char(all_yesterday::numeric(10,0) , 'FM999,999,999') as all_yesterday,
'$' || to_char(all_mtd::numeric(10,0) , 'FM999,999,999') as all_mtd,
'$' || to_char(all_qtd::numeric(10,0) , 'FM999,999,999') as all_qtd,
'$' || to_char(all_ytd::numeric(10,0) , 'FM999,999,999') as all_ytd,


'WM Week = '||e.wm_week
||E'\n'||E'\n'||
'---------------------'
||E'\n'||E'\n'||
'E-Commerce'||E'\n'||to_char(date, 'mm.dd')||': $'||to_char(dot_com_yesterday,'FM999,999,999')||E'\n'||'DSV: $'||to_char(dot_com_dsv,'FM999,999,999')||E'\n'||'Bulk: $'||to_char(dot_com_bulk,'FM999,999,999')||E'\n'||'DI: $'||to_char(dot_com_di,'FM999,999,999')||E'\n'||E'\n'||'MTD: $'||to_char(dot_com_mtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(dot_com_mo_bud,'FM999,999,999')||E'\n'||E'\n'||'QTD: $'||to_char(dot_com_qtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(dot_com_qrt_bud,'FM999,999,999')||E'\n'||E'\n'||'YTD: $'||to_char(dot_com_ytd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(dot_com_ytd_bud,'FM999,999,999')
||E'\n'||E'\n'||
'---------------------'
||E'\n'||E'\n'||
'Stores'||E'\n'||to_char(date, 'mm.dd')||': $'||to_char(stores_yesterday,'FM999,999,999')||E'\n'||'B&M: $'||to_char(stores_bm,'FM999,999,999')||E'\n'||'DI: $'||to_char(stores_di,'FM999,999,999')||E'\n'||E'\n'||'MTD: $'||to_char(stores_mtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(stores_mo_bud,'FM999,999,999')||E'\n'||E'\n'||'QTD: $'||to_char(stores_qtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(stores_qrt_bud,'FM999,999,999')||E'\n'||E'\n'||'YTD: $'||to_char(stores_ytd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(stores_ytd_bud,'FM999,999,999')
||E'\n'||E'\n'||
'---------------------'
||E'\n'||E'\n'||
'Omni Channel'||E'\n'||to_char(date, 'mm.dd')||': $'||to_char(omni_yesterday,'FM999,999,999')||E'\n'||E'\n'||'MTD: $'||to_char(omni_mtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(omni_mo_bud,'FM999,999,999')||E'\n'||E'\n'||'QTD: $'||to_char(omni_qtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(omni_qrt_bud,'FM999,999,999')||E'\n'||E'\n'||'YTD: $'||to_char(omni_ytd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(omni_ytd_bud,'FM999,999,999')

	
as final
from a
left join c
on a.date = c.budget_date
join d
on a.date = d.contact_date
left join e 
on a.date = e.wm_date
)
;
