--workflow that inserts views into tables for timley views

--START item id's
--insert the scrape data item ids
insert into power_bi.dim_item_id
(
item_id
,inserted_at
)
select distinct item_id ,now()
from scrape_data.scrape_tbl
on conflict(item_id)
do update set
inserted_at = excluded.inserted_at
;
--insert the pos item ids
insert into power_bi.dim_item_id
(
item_id
,inserted_at
)
select distinct item_id, now()
from power_bi.dim_item_id_view_pos
on conflict(item_id)
do update set 
inserted_at = excluded.inserted_at
;
--insert the ships item id's
--END item id's