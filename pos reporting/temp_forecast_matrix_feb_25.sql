--using temp tables, I made a matrix table for kevin
/*
model type feb 26 march 26 .... feb 27
123     forecast 1 0 0 1 
123     ATS     1 0 0 0 0 
123     po's open   1 1 1 1 1
 */
;
with fc as 
(
select
	tm.model
	,1 as row_id
	,'Forecast' as column_type
	,sum(february_26) as february_26
	,sum(march_26) as march_26
	,sum(april_26) as april_26
	,sum(may_26) as may_26
	,sum(june_26) as june_26
	,sum(july_26) as july_26
	,sum(august_26) as august_26
	,sum(september_26) as september_26
	,sum(october_26) as october_26
	,sum(november_26) as november_26
	,sum(december_26) as december_26
	,sum(january_27) as january_27
	,sum(february_27) as february_27
from temp_model tm
left join temp_forecasting tf
on tm.model = tf.model
where 1=1
and warehouse !='5019'
group by tm.model
)
,inv as 
(
select
	tm.model
	,2 as row_id
	,'Dorel ATS' as column_type
	,available_to_sell as february_26
	,null::integer as march_26
	,null::integer as april_26
	,null::integer as may_26
	,null::integer as june_26
	,null::integer as july_26
	,null::integer as august_26
	,null::integer as september_26
	,null::integer as october_26
	,null::integer as november_26
	,null::integer as december_26
	,null::integer as january_27
	,null::integer as february_27
from temp_model tm
left join  temp_inventory ti
on tm.model = ti.model
)
,pos as 
(
select
	tm.model
	,3 as row_id
	,'Inbound PO''s' as column_type
	,sum(february_26) as february_26
	,sum(march_26) as march_26
	,sum(april_26) as april_26
	,sum(may_26) as may_26
	,sum(june_26) as june_26
	,sum(july_26) as july_26
	,sum(august_26) as august_26
	,sum(september_26) as september_26
	,sum(october_26) as october_26
	,sum(november_26) as november_26
	,sum(december_26) as december_26
	,sum(january_27) as january_27
	,sum(february_27) as february_27
from temp_model tm
left join temp_po tp
on tm.model = tp.model
group by tm.model
)
,details as
(
select *
from fc
union all 
select * 
from inv
union all 
select *
from pos
)
select d.* , division
from details d
left join temp_model tm 
on d.model = tm.model
where 1=1
and d.model in (select model from temp_forecasting)
order by model, row_id

;
