,coalesce(cast(((stores_ytd - stores_ytd_ly)/nullif(stores_ytd_ly,0)) * 100 as numeric(10,2)),0) as stores_yoy_perc
,coalesce(cast(((dot_com_ytd - dot_com_ytd_ly)/nullif(dot_com_ytd_ly,0)) * 100 as numeric(10,2)),0) as dot_com_yoy_perc
,coalesce(cast(((omni_ytd - omni_ytd_ly)/nullif(omni_ytd_ly,0)) * 100 as numeric(10,2)),0) as omni_yoy_perc
,coalesce(cast(((all_ytd - all_ytd_ly)/nullif(all_ytd_ly,0)) * 100 as numeric(10,2)),0) as all_yoy_perc
