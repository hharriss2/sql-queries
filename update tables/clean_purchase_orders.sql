create view ssr_py_clean as (
SELECT ssr_py.item, min(ssr_py.order_date::date) AS min 
FROM ssr_py 
GROUP BY ssr_py.item);
--create view for update later. puts every model with the first day of the SSR
update ssr_py 
set current = 0 
where transaction_type = 'PUR - Purchase Orders'; 
--Purchase Order current is summed up in the dates. Messes with the actual OH current in the AVS current. 
update ssr_py t1 set current = 0 
from ssr_py_clean t2 where t1.item=t2.item 
and t1.order_date::date !=t2.min;
--updating becasue current would repeat values
drop view ssr_py_clean;