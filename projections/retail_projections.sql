
--retail projection piece for projection view
create or replace view projections.retail_projection as (
with r as 
(
	select * 
	from forecast.aur_projection
	
)
,aur_compare as 
(
	select distinct 
	item_id
	,aur
	,units
	,((units/weeks_sold_at_retail) *4)::numeric(10,2) as aur_ams
	--aur_ams - average monthly sale of the item when it sales at that retail
	--multiplied by 4 because 4 weeks in a month
	,weeks_sold_at_retail
	,dense_rank() over (partition by item_id order by (units/weeks_sold_at_retail)*4 desc) as aur_ranking
	,row_id
	,case 
			when row_id =1 then .9
			when row_id = 2 then .5
			when row_id = 3 then .3
			else .1
			end as cred_weight
	from
		(--SQ2. Rounds AUR to 10, sums weeks sold at retail, gives it a ranking from highest weeks sold to lowest
		select item_id
			, ((aur * .1 )::numeric(10,0)) * 10 as aur
			, sum(sum_units) units
			,sum(wm_week_count) as weeks_sold_at_retail
			,dense_rank() over(partition by item_id order by sum(wm_week_count) desc ) as row_id
		from
			(--SQ1.  finds aur& sum units by item id and week.
				select item_id
					,wm_week
					,(sum(sales)/sum(units))::numeric(10,0) as aur
					,sum(units) as sum_units
					,count(distinct wm_week) as wm_week_count
				from retail_link_pos
				where units >0
	--			and item_id = '38797912'
				group by item_id,wm_week
			--END SQ1
			)aur_sum
		--group aur's together to find sum of units for that Item's aur
		group by 
			item_id
			,((aur * .1 )::numeric(10,0))
		--END SQ2
		) t2
	where 1=1
)
,retail_ams as
(
	select sum(units)/count(distinct wm_week) as avg_ams, item_id
	from retail_link_pos
	where units >0
	group by item_id
)
select distinct 
r.item_id
,r.projected_aur
,r.sale_month
,aur_compare.aur
, aur_compare.aur_ams
,cred_weight
,case when avg_ams >0--cannot divide by 0
then ((aur_ams- avg_ams) / avg_ams) * cred_weight
--the ams * how credible it is
else 1-- first 2 criteria should make it 0
end as ams_over_ams
from forecast.aur_projection r
join  aur_compare
on r.item_id = aur_compare.item_id
left join retail_ams
on r.item_id = retail_ams.item_id
where 1=1
and ((projected_aur *.1)::numeric(10,0)) * 10 = aur	
);


--INSERT RESULTS INTO THE TABLE
truncate projections.retail_projectoin_tbl;
insert into projections.retail_projection_tbl(
item_id
,projected_aur
,sale_month 
,aur 
,aur_ams 
,cred_weight 
,ams_over_ams 
)
select item_id
,projected_aur
,sale_month 
,aur 
,aur_ams 
,cred_weight 
,ams_over_ams 
from projections.retail_projection
;
