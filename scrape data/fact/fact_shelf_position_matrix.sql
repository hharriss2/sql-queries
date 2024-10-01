--used for the shelf position pricing page on the power bi Buy Box
create or replace view power_bi.fact_shelf_position_matrix as 
(
with spp as --shelf position pricing
(--find all the items on the first page of each request term. determine the price
select sp.request_type
	,sp.request_term
	,sp.shelf_position
	,sp.product_name
	,sp.item_id
	,sp.review_rating
	,sp.review_count
	,sp.price_retail
	,sp.price_was
	,cbm.cat
	,cbm.sub_cat
	,case
		when mcl.item_id is not null
		then 1
		else 0
		end as is_owned
	,date_trunc('week',date_inserted)::date as week_inserted
	,case
		when date_inserted = current_date 
		then 1
		else 0
		end as is_current_scrape
from scrape_data.shelf_position sp
left join clean_data.master_com_list mcl
on sp.item_id= mcl.item_id
left join cat_by_model cbm 
on mcl.model = cbm.model
where 1=1
and page_number = 1
--and request_term = 'Futons'
)
,bucket_assign as 
(--adding the bucket categorization in this clause
select
	request_type
	,request_term
	,item_id
	,product_name
	,price_retail
	,price_was
	,is_owned
	,case
		when price_retail >10 and price_retail <=20
		then 1
		when price_retail >20 and price_retail <=30
		then 2
		when price_retail >30 and price_retail <=40
		then 3
		when price_retail >40 and price_retail <=50
		then 4
		when price_retail >50 and price_retail <=60
		then 5
		when price_retail >60 and price_retail <=70
		then 6
		when price_retail >70 and price_retail <=80
		then 7
		when price_retail >80 and price_retail <=90
		then 8
		when price_retail >90 and price_retail <=100
		then 9
		when price_retail >100 and price_retail <=115
		then 10
		when price_retail >115 and price_retail <=135
		then 11
		when price_retail >135 and price_retail <=155
		then 12
		when price_retail >155 and price_retail <=175
		then 13
		when price_retail >175 and price_retail <=195
		then 14
		when price_retail >195 and price_retail <=215
		then 15
		when price_retail >215 and price_retail <=245
		then 16
		when price_retail >245 and price_retail <=275
		then 17
		when price_retail >275 and price_retail <=305
		then 18
		when price_retail >305 and price_retail <=345
		then 19
		when price_retail >345 and price_retail <=385
		then 20
		when price_retail >385 and price_retail <=415
		then 21
		when price_retail >415 and price_retail <=450
		then 22
		when price_retail >450 and price_retail <=500
		then 23
		when price_retail >500 and price_retail <=550
		then 24
		when price_retail >550 and price_retail <=600
		then 25
		when price_retail >600 and price_retail <=700
		then 26
		when price_retail >700 and price_retail <=800
		then 27
		when price_retail >800 and price_retail <=900
		then 28
		when price_retail >900 and price_retail <=1000
		then 29
		when price_retail >1000
		then 30
		end as price_bucket

		,is_current_scrape
		,week_inserted
from spp
where price_retail >10
order by price_retail
)

select distinct * 
	,case
	    when price_bucket = 1
	    then '$10-$20'
	    when price_bucket = 2
	    then '$20-$30'
	    when price_bucket = 3
	    then '$30-$40'
	    when price_bucket = 4
	    then '$40-$50'
	    when price_bucket = 5
	    then '$50-$60'
	    when price_bucket = 6
	    then '$60-$70'
	    when price_bucket = 7
	    then '$70-$80'
	    when price_bucket = 8
	    then '$80-$90'
	    when price_bucket = 9
	    then '$90-$100'
	    when price_bucket = 10
	    then '$100-$115'
	    when price_bucket = 11
	    then '$115-$135'
	    when price_bucket = 12
	    then '$135-$155'
	    when price_bucket = 13
	    then '$155-$175'
	    when price_bucket = 14
	    then '$175-$195'
	    when price_bucket = 15
	    then '$195-$215'
	    when price_bucket = 16
	    then '$215-$245'
	    when price_bucket = 17
	    then '$245-$275'
	    when price_bucket = 18
	    then '$275-$305'
	    when price_bucket = 19
	    then '$305-$345'
	    when price_bucket = 20
	    then '$345-$385'
	    when price_bucket = 21
	    then '$385-$415'
	    when price_bucket = 22
	    then '$415-$450'
	    when price_bucket = 23
	    then '$450-$500'
	    when price_bucket = 24
	    then '$500-$550'
	    when price_bucket = 25
	    then '$550-$600'
	    when price_bucket = 26
	    then '$600-$700'
	    when price_bucket = 27
	    then '$700-$800'
	    when price_bucket = 28
	    then '$800-$900'
	    when price_bucket = 29
	    then '$900-$1000'
	    when price_bucket = 30
	    then '$1000+'
	    end as price_bucket_text
from bucket_assign
)
;