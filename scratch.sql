create or replace view pos_reporting.budget_text as 
(
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
'Walmart.com'||E'\n'||to_char(date, 'mm.dd')||': $'||to_char(dot_com_yesterday,'FM999,999,999')||E'\n'||'DSV: $'||to_char(dot_com_dsv,'FM999,999,999')||E'\n'||'Bulk: $'||to_char(dot_com_bulk,'FM999,999,999')||E'\n'||'DI: $'||to_char(dot_com_di,'FM999,999,999')||E'\n'||E'\n'||'MTD: $'||to_char(dot_com_mtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(dot_com_mo_bud,'FM999,999,999')||E'\n'||E'\n'||'QTD: $'||to_char(dot_com_qtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(dot_com_qrt_bud,'FM999,999,999')||E'\n'||E'\n'||'YTD: $'||to_char(dot_com_ytd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(dot_com_ytd_bud,'FM999,999,999')
||E'\n'||E'\n'||
'---------------------'
||E'\n'||E'\n'||
'Walmart Stores'||E'\n'||to_char(date, 'mm.dd')||': $'||to_char(stores_yesterday,'FM999,999,999')||E'\n'||'B&M: $'||to_char(stores_bm,'FM999,999,999')||E'\n'||'DI: $'||to_char(stores_di,'FM999,999,999')||E'\n'||E'\n'||'MTD: $'||to_char(stores_mtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(stores_mo_bud,'FM999,999,999')||E'\n'||E'\n'||'QTD: $'||to_char(stores_qtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(stores_qrt_bud,'FM999,999,999')||E'\n'||E'\n'||'YTD: $'||to_char(stores_ytd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(stores_ytd_bud,'FM999,999,999')
||E'\n'||E'\n'||
'---------------------'
||E'\n'||E'\n'||
'Omni Channel'||E'\n'||to_char(date, 'mm.dd')||': $'||to_char(omni_yesterday,'FM999,999,999')||E'\n'||E'\n'||'MTD: $'||to_char(omni_mtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(omni_mo_bud,'FM999,999,999')||E'\n'||E'\n'||'QTD: $'||to_char(omni_qtd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(omni_qrt_bud,'FM999,999,999')||E'\n'||E'\n'||'YTD: $'||to_char(omni_ytd,'FM999,999,999')||E'\n'||'Bud: $'||to_char(omni_ytd_bud,'FM999,999,999')

	
as final

from 
	(select
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
	from ships_schema.ships s
	where 1=1
	--and retailer IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club')
	and s.model NOT IN ('')) a
	left join (
	select
	date(timezone('CST', now())) - 1 as budget_date,
	COALESCE(sum(case when month = date_trunc('month', current_date) and channel in( 'Walmart.com','SamsClub.com') then budget end),0) as dot_com_mo_bud,
	COALESCE(sum(case when month = date_trunc('month', current_date) and channel in('Walmart Stores','Sam''s Club') then budget end),0) as stores_mo_bud,
	COALESCE(sum(case when month = date_trunc('month', current_date) and channel IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then budget end),0) as omni_mo_bud,
	COALESCE(sum(case when date_part('quarter',current_date) = date_part('quarter',month) and channel in( 'Walmart.com','SamsClub.com') then budget end),0) as dot_com_qrt_bud,
	COALESCE(sum(case when date_part('quarter',current_date) = date_part('quarter',month) and channel in('Walmart Stores','Sam''s Club') then budget end),0) as stores_qrt_bud,
	COALESCE(sum(case when date_part('quarter',current_date) = date_part('quarter',month) and channel IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then budget end),0) as omni_qrt_bud,
	COALESCE(sum(case when month >= date_trunc('year', current_date) and channel in( 'Walmart.com','SamsClub.com') then budget end),0) as dot_com_ytd_bud,
	COALESCE(sum(case when month >= date_trunc('year', current_date) and channel in('Walmart Stores','Sam''s Club') then budget end),0) as stores_ytd_bud,
	COALESCE(sum(case when month >= date_trunc('year', current_date) and channel IN ('Walmart.com','Walmart Stores','SamsClub.com','Sam''s Club') then budget end),0) 
as omni_ytd_bud,
	COALESCE(sum(case when date_part('quarter',current_date) = date_part('quarter',month) then budget end),0) as all_qrt_bud,
	COALESCE(sum(case when month = date_trunc('month', current_date) then budget end),0) 
as all_mo_bud,
	COALESCE(sum(case when month >= date_trunc('year', current_date) then budget end),0) 
as all_ytd_bud
	from budget_2024) c
	on a.date = c.budget_date
	join (
	select
	date(timezone('CST', now())) - 1 as contact_date,
	name,
	phone,
	email
	from contacts
	 ) d
	on a.date = d.contact_date
	left join (
	select
	date as wm_date,
	wm_week
	from wm_calendar ) e
	on a.date = e.wm_date
)
;