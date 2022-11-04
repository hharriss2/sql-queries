--view is used to apply a ratio to the totaled up projection
create or replace view forecast.unit_ratio as (

with mf as 
(
select model, month_num, total_units
from forecast.model_final
)
,mft as
(
select model, sum(total_units) as sum_total_units
from forecast.model_final
group by model
)
select mf.model, month_num, (mf.total_units/ mft.sum_total_units)::numeric(10,2) as unit_ratio
from mf
join mft
on mf.model = mft.model
)