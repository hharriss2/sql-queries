--calculates the shipping cost using lookups.base_zone_calculator & additional logic provided by david leitner
create or replace view components.item_shipping_cost as 
(
with d as --dims
( -- bring in the dimension table for products
select
	distinct model
	,length
	,width
	,height
	,case -- based on oversize criteria. if lenght is >96 or girth above 130, then weight is charged 90 lbs minimum
		when length + (width *2) + (height *2) >130 or length >96
		then
			case
			when weight >=90
			then weight
			else 90
			end
		else weight
		end as weight
	,zone_number
	,shipping_cost
	,case -- if girth over 130 or lengh is greater than 96, oversize charge is added
		when length + (width *2) + (height *2) >130
		then 1
		when length >96
		then 1
		else 0 
		end as is_oversize
	,case -- criteria for additional weight charge
		when weight >50
		then 1
		else 0
		end as is_additional_weight
	,case --criteria for additional handling
		when length >=48
		then 1
		when width >=30
		then 1
		when length + (width *2) + (height *2) >105
		then 1 
		else 0
		end as is_additional_handle
from components.dsv_item_cost_3p
)
,dc as --dims calculated
( -- finding extra costs for the shipping based of dimensions
select *
	,case-- static charges provided by david
		when is_oversize =1
		then
			case 
			when zone_number ='2'
			then 43.61
			when zone_number in ('3','4')
			then 46.46
			when zone_number in ('5','6')
			then 51.21
			when zone_number in ('7','8')
			then 53.11
			else 0 end
		else 0
		end as oversize_surcharge
	,case --static charges provided for additional weight charge
		when is_additional_weight =1
		then
			case
			when zone_number ='2'
			then 7.22
			when zone_number in ('3','4')
			then 7.79
			when zone_number in ('5','6')
			then 8.26
			when zone_number in ('7','8')
			then 8.93
			else 0 end
		else 0
		end as additional_weight_surcharge
	,case -- static charges provided for handling surcharge
		when is_additional_handle =1
		then
			case
			when zone_number ='2'
			then 4.84
			when zone_number in ('3','4')
			then 5.32
			when zone_number in ('5','6')
			then 5.79
			when zone_number in ('7','8')
			then 6.36
			else 0 end
		else 0
		end as additional_handle_surcharge
from d
)
,bc as --base calculator
( -- finds the base + residential cost based on the zone and weight
select * 
from lookups.base_zone_calculator
)
,details as 
(
select dc.*
	,case -- bringing in base lookup table. map columns to rows 
		when zone_number = '2'
		then zone_2
		when zone_number = '3'
		then zone_3
		when zone_number = '4'
		then zone_4
		when zone_number = '5'
		then zone_5
		when zone_number = '6'
		then zone_6
		when zone_number = '7'
		then zone_7
		when zone_number = '8'
		then zone_8
		else null
		end as base_residential_rate
from dc
left join bc
on dc.weight::numeric(10,0) = bc.weight
)
select
	model
	,length
	,width
	,height
	,weight
	,zone_number
	,shipping_cost
	,base_residential_rate
	,oversize_surcharge
	,additional_weight_surcharge
	,additional_handle_surcharge
	,case --if oversize, fed ex only uses oversize charge for some reason in their api
		when is_oversize =1
		then (base_residential_rate + oversize_surcharge) *.16
		else
		(base_residential_rate + oversize_surcharge + additional_weight_surcharge +additional_handle_surcharge) * .16
        end as fuel_surcharge
	,case -- calculating the total shipping cost. if oversize, use the other shipping cost 
		when is_oversize =1
		then base_residential_rate + oversize_surcharge + ((base_residential_rate + oversize_surcharge) *.16)
        --^calculation for oversized fuel surcharge
		else
		base_residential_rate
	+oversize_surcharge
	+additional_weight_surcharge
	+additional_handle_surcharge
	+(base_residential_rate + oversize_surcharge + additional_weight_surcharge +additional_handle_surcharge) * .16
	end as total_shipping_cost
from details
)
;