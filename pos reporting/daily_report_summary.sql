--metrics used in the parabola email report to send out in the HTML Body of the email.
--mimics The body portion Rob used to send out daily
create or replace view pos_reporting.daily_report_summary as 
(
with dc as --daily conditional
( -- creating a conditional to get everything in 1 row
select
	--for black steel chair
	sum(
		case
		when current_item_num = '585106868'
		then wtd_units
		else 0
		end
		) as ms_steel_chair_black_wtd_units
	,sum(
		case
		when current_item_num = '585106868'
		then wtd_ly_units
		else 0
		end
		) as ms_steel_chair_black_wtd_ly_units
	--for white resin char
	,sum(
		case
		when current_item_num = '578557216'
		then wtd_units
		else 0
		end
		) as ms_resin_chair_white_wtd_units
	,sum(
		case
		when current_item_num = '578557216'
		then wtd_ly_units
		else 0
		end
		) as ms_resin_chair_white_wtd_ly_units
	--for black resin chair
	,sum(
		case
		when current_item_num = '582833521'
		then wtd_units
		else 0
		end
		) as ms_resin_chair_black_wtd_units
	,sum(
		case
		when current_item_num = '582833521'
		then wtd_ly_units
		else 0
		end
		) as ms_resin_chair_black_wtd_ly_units
	--mainstays adjustable height table
	,sum(
		case
		when current_item_num = '550955318'
		then wtd_units
		else 0
		end
		) as ms_adj_height_table_wtd_units
	,sum(
		case
		when current_item_num = '550955318'
		then wtd_ly_units
		else 0
		end
		) as ms_adj_height_table_wtd_ly_units
	--cosco 3 step premium stool 
	,sum(
		case
		when current_item_num = '595884037'
		then wtd_units
		else 0
		end
		) as cosco_3_step_prem_stool_wtd_units
	,sum(
		case
		when current_item_num = '595884037'
		then wtd_ly_units
		else 0
		end
		) as cosco_3_step_prem_stool_wtd_ly_units
	--cosco 1 step plastic stool
	,sum(
		case
		when current_item_num = '664903430'
		then wtd_units
		else 0
		end
		) as cosco_1_step_plastic_stool_wtd_units
	,sum(
		case
		when current_item_num = '664903430'
		then wtd_ly_units
		else 0
		end
		) as cosco_1_step_plastic_stool_wtd_ly_units
--Starting DHP
	--Parsons End Table Black
	,sum(
		case
		when current_item_num = '595743759'
		then wtd_units
		else 0
		end
		) as parsons_end_tbl_black_wtd_units
	,sum(
		case
		when current_item_num = '595743759'
		then wtd_ly_units
		else 0
		end
		) as parsons_end_tbl_black_wtd_ly_units
	--Parsons TV Stand Black
	,sum(
		case
		when current_item_num = '669836851'
		then wtd_units
		else 0
		end
		) as parsons_tv_stand_black_wtd_units
	,sum(
		case
		when current_item_num = '669836851'
		then wtd_ly_units
		else 0
		end
		) as parsons_tv_stand_black_wtd_ly_units
	--Mainstays Futon with USB Black
	,sum(
		case
		when current_item_num = '657459665'
		then wtd_units
		else 0
		end
		) as ms_futon_with_usb_wtd_units
	,sum(
		case
		when current_item_num = '657459665'
		then wtd_ly_units
		else 0
		end
		) as ms_futon_with_usb_wtd_ly_units
	--Mainstays 5 piece dining set
	,sum(
		case
		when current_item_num = '578306263'
		then wtd_units
		else 0
		end
		) as ms_5_pc_dining_set_wtd_units
	,sum(
		case
		when current_item_num = '578306263'
		then wtd_ly_units
		else 0
		end
		) as ms_5_pc_dining_set_wtd_ly_units
	--Mainstays Expandable TV Stand
	,sum(
		case
		when current_item_num = '667102384'
		then wtd_units
		else 0
		end
		) as ms_expandable_tv_stand_wtd_units
	,sum(
		case
		when current_item_num = '667102384'
		then wtd_ly_units
		else 0
		end
		) as ms_expandable_tv_stand_wtd_ly_units
	--Mainstays Parsons Coffee Table Black 595743716
	,sum(
		case
		when current_item_num = '595743716'
		then wtd_units
		else 0
		end
		) as ms_parsons_coffee_table_black_wtd_units
	,sum(
		case
		when current_item_num = '595743716'
		then wtd_ly_units
		else 0
		end
		) as ms_parsons_coffee_table_black_wtd_ly_units
	--Mainstays Parsons TV Stand Canyon Walnut 669836850
	,sum(
		case
		when current_item_num = '669836850'
		then wtd_units
		else 0
		end
		) as ms_parsons_tv_stand_cw_wtd_units
	,sum(
		case
		when current_item_num = '669836850'
		then wtd_ly_units
		else 0
		end
		) as ms_parsons_tv_stand_cw_wtd_ly_units
	--Mainstays 4 Door Cabinet White 670695099
	,sum(
		case
		when current_item_num = '670695099'
		then wtd_units
		else 0
		end
		) as ms_4_door_cabinet_white_wtd_units
	,sum(
		case
		when current_item_num = '670695099'
		then wtd_ly_units
		else 0
		end
		) as ms_4_door_cabinet_white_wtd_ly_units
	--Fireplace TV Stand Mahogany Oak 668281987
	,sum(
		case
		when current_item_num = '668281987'
		then wtd_units
		else 0
		end
		) as fireplace_tv_magoak_wtd_units
	,sum(
		case
		when current_item_num = '668281987'
		then wtd_ly_units
		else 0
		end
		) as fireplace_tv_magoak_wtd_ly_units
from pos_reporting.daily_report
)
select
	--for black steel chair
to_char(ms_steel_chair_black_wtd_units,'FM999,999,999') as ms_steel_chair_black_wtd_units
,to_char(ms_steel_chair_black_wtd_ly_units,'FM999,999,999') as ms_steel_chair_black_wtd_ly_units
	--for white resin char
,to_char(ms_resin_chair_white_wtd_units,'FM999,999,999') as ms_resin_chair_white_wtd_units
,to_char(ms_resin_chair_white_wtd_ly_units,'FM999,999,999') as ms_resin_chair_white_wtd_ly_units
	--for black resin chair
,to_char(ms_resin_chair_black_wtd_units,'FM999,999,999') as ms_resin_chair_black_wtd_units
,to_char(ms_resin_chair_black_wtd_ly_units,'FM999,999,999') as ms_resin_chair_black_wtd_ly_units
	--mainstays adjustable height table
,to_char(ms_adj_height_table_wtd_units,'FM999,999,999') as ms_adj_height_table_wtd_units
,to_char(ms_adj_height_table_wtd_ly_units,'FM999,999,999') as ms_adj_height_table_wtd_ly_units
	--cosco 3 step premium stool 
,to_char(cosco_3_step_prem_stool_wtd_units,'FM999,999,999') as cosco_3_step_prem_stool_wtd_units
,to_char(cosco_3_step_prem_stool_wtd_ly_units,'FM999,999,999') as cosco_3_step_prem_stool_wtd_ly_units
	--cosco 1 step plastic stool
,to_char(cosco_1_step_plastic_stool_wtd_units,'FM999,999,999') as cosco_1_step_plastic_stool_wtd_units
,to_char(cosco_1_step_plastic_stool_wtd_ly_units,'FM999,999,999') as cosco_1_step_plastic_stool_wtd_ly_units
--Starting DHP
	--Parsons End Table Black
,to_char(parsons_end_tbl_black_wtd_units,'FM999,999,999') as parsons_end_tbl_black_wtd_units
,to_char(parsons_end_tbl_black_wtd_ly_units,'FM999,999,999') as parsons_end_tbl_black_wtd_ly_units
	--Parsons TV Stand Black
,to_char(parsons_tv_stand_black_wtd_units,'FM999,999,999') as parsons_tv_stand_black_wtd_units
,to_char(parsons_tv_stand_black_wtd_ly_units,'FM999,999,999') as parsons_tv_stand_black_wtd_ly_units
	--Mainstays Futon with USB Black
,to_char(ms_futon_with_usb_wtd_units,'FM999,999,999') as ms_futon_with_usb_wtd_units
,to_char(ms_futon_with_usb_wtd_ly_units,'FM999,999,999') as ms_futon_with_usb_wtd_ly_units
	--Mainstays 5 piece dining set
,to_char(ms_5_pc_dining_set_wtd_units,'FM999,999,999') as ms_5_pc_dining_set_wtd_units
,to_char(ms_5_pc_dining_set_wtd_ly_units,'FM999,999,999') as ms_5_pc_dining_set_wtd_ly_units
	--Mainstays Expandable TV Stand
,to_char(ms_expandable_tv_stand_wtd_units,'FM999,999,999') as ms_expandable_tv_stand_wtd_units
,to_char(ms_expandable_tv_stand_wtd_ly_units,'FM999,999,999') as ms_expandable_tv_stand_wtd_ly_units
	--Mainstays Parsons Coffee Table Black 595743716
,to_char(ms_parsons_coffee_table_black_wtd_units,'FM999,999,999') as ms_parsons_coffee_table_black_wtd_units
,to_char(ms_parsons_coffee_table_black_wtd_ly_units,'FM999,999,999') as ms_parsons_coffee_table_black_wtd_ly_units
	--Mainstays Parsons TV Stand Canyon Walnut 669836850
,to_char(ms_parsons_tv_stand_cw_wtd_units,'FM999,999,999') as ms_parsons_tv_stand_cw_wtd_units
,to_char(ms_parsons_tv_stand_cw_wtd_ly_units,'FM999,999,999') as ms_parsons_tv_stand_cw_wtd_ly_units
	--Mainstays 4 Door Cabinet White 670695099
,to_char(ms_4_door_cabinet_white_wtd_units,'FM999,999,999') as ms_4_door_cabinet_white_wtd_units
,to_char(ms_4_door_cabinet_white_wtd_ly_units,'FM999,999,999') as ms_4_door_cabinet_white_wtd_ly_units
	--Fireplace TV Stand Mahogany Oak 668281987
,to_char(fireplace_tv_magoak_wtd_units,'FM999,999,999') as fireplace_tv_magoak_wtd_units
,to_char(fireplace_tv_magoak_wtd_ly_units,'FM999,999,999') as fireplace_tv_magoak_wtd_ly_units
,'harris.jones@dorelusa.com' as email
,to_char(current_date,'MM-DD-YYYY') as report_date
from dc
)
;