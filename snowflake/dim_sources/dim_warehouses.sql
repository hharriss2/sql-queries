
--combining dhp and juv warehouses
create table walmart.dim_sources.dim_warehouses
(
warehouse_id integer default walmart.dim_sources.dim_warehouse_seq.nextval
,warehouse_name varchar(300)
,warehouse_number varchar(300) unique
,warehouse_group_name varchar(300)
,warehouse_country  varchar(300)
)
;
insert into walmart.dim_sources.dim_warehouses
(warehouse_name
,warehouse_number
,warehouse_group_name
,warehouse_country)
select businessunitname
,mcu_costcenter
,addressline1 ||', '||country
,country
from djus_jde_shared.public.ods_f0006_business_unit_master
;