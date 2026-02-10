Select
    PAGE4a.GLDATE                                                AS "DATE",
    DailyPlan.Column1                                            As "Daily Plan",
    PAGE4a.SHEXTAMOUNT                                           As SHEXTAMOUNT,
    PAGE4a.WH5019                                                As "WH 5019",
    PAGE4a.WH5035                                                As "WH 5035",
    PAGE4a.WH5085                                                As "WH 5085",
    PAGE4a.WH5090                                                As "WH 5090",
    PAGE4a.WH6000                                                As "WH 6000",
    PAGE4a.WH7000                                                As "WH 7000",
    PAGE4a.COGS                                                  As COGS,
    DIV0((PAGE4a.SHEXTAMOUNT - PAGE4a.COGS), PAGE4a.SHEXTAMOUNT) As "Product Margin",
    Page4b.Sum_WJXBFS1                                           As OO_Total,
    Page4b.WH5019                                                As "OO WH 5019",
    Page4b.WH5035                                                As "OO WH 5035",
    Page4b.WH5085                                                As "OO WH 5085",
    Page4b.WH5090                                                As "OO WH 5090",
    Page4b.WH6000                                                As "OO WH 6000",
    Page4b.WH7000                                                As "OO WH 7000"
From (Select
          a11.GL_DATEID                           As Date_ID,
          a12."DATE"                              As GLDATE,
          Sum(a11.AEXP_AMOUNTEXTENDEDPRICE)          SHEXTAMOUNT,
          Sum(Case
                  When a11.MCU_COSTCENTER = '5019'
                      Then a11.AEXP_AMOUNTEXTENDEDPRICE
                  Else 0
              End)                                As WH5019,
          Sum(Case
                  When a11.MCU_COSTCENTER = '5035'
                      Then a11.AEXP_AMOUNTEXTENDEDPRICE
                  Else 0
              End)                                As WH5035,
          Sum(Case
                  When a11.MCU_COSTCENTER = '5085'
                      Then a11.AEXP_AMOUNTEXTENDEDPRICE
                  Else 0
              End)                                As WH5085,
          Sum(Case
                  When a11.MCU_COSTCENTER = '5090'
                      Then a11.AEXP_AMOUNTEXTENDEDPRICE
                  Else 0
              End)                                As WH5090,
          Sum(Case
                  When a11.MCU_COSTCENTER = '6000'
                      Then a11.AEXP_AMOUNTEXTENDEDPRICE
                  Else 0
              End)                                As WH6000,
                    Sum(Case
                  When a11.MCU_COSTCENTER = '7000'
                      Then a11.AEXP_AMOUNTEXTENDEDPRICE
                  Else 0
              End)                                As WH7000,
          Sum(a11.ECST_AMOUNTEXTENDEDCOST)        As COGS,
          Sum(div0((a11.AEXP_AMOUNTEXTENDEDPRICE - a11.ECST_AMOUNTEXTENDEDCOST),
                   a11.AEXP_AMOUNTEXTENDEDPRICE)) As Product_Margin
      From DJUS_JDE.PUBLIC.ODS_F42119_SALES_HISTORY a11
               INNER JOIN DJUS_JDE.PUBLIC.ODS_F4101_ITEM_MASTER IM
                          ON A11.ITM_IDENTIFIERSHORTITEM = IM.ITM_IDENTIFIERSHORTITEM
               Inner Join DJUS_JDE.PUBLIC.ODS_CALENDAR_DAY a12
                          On a11.GL_DATEID = a12.DATE_ID
               Inner Join (Select
                               A.MCU_COSTCENTER,
                               A.DL01_DESCRIPTION001
                           From DJUS_JDE.PUBLIC.ODS_F0006_BUSINESS_UNIT_MASTER A
                           Where A.STYL_COSTCENTERTYPE In ('FC', 'WC')) a13
                          On (a11.MCU_COSTCENTER =
                              a13.MCU_COSTCENTER)
               Inner Join DJUS_JDE.PUBLIC.ODS_CURRENT_DATE ods_current_date_
                          On ods_current_date_.MNTH_ID = a11.GL_MONTHID
      Where a11.DCTO_ORDERTYPE Not In ('C1', 'SV', 'SG', 'KP', 'SH')
        And a11.LNTY_LINETYPE In ('D', 'S', 'S7')
        And a11.KCOO_COMPANYKEYORDERNO = '00100'
        AND IM.SRP1_SALESREPORTINGCODE1 <> 'JUV'
      Group By a11.GL_DATEID,
               a12.DATE) PAGE4a
         Inner Join (Select
                         Page4b.DATE_SRCCD,
                         Sum(Page4b.WJXBFS1) As Sum_WJXBFS1,
                         Sum(Case
                                 When Page4b.REVENUE_BUSINESS_UNIT = '5019'
                                     Then Page4b.WJXBFS1
                                 Else 0
                             End)            As WH5019,
                         Sum(Case
                                 When Page4b.REVENUE_BUSINESS_UNIT = '5035'
                                     Then Page4b.WJXBFS1
                                 Else 0
                             End)            As WH5035,
                         Sum(Case
                                 When Page4b.REVENUE_BUSINESS_UNIT = '5085'
                                     Then Page4b.WJXBFS1
                                 Else 0
                             End)            As WH5085,
                         Sum(Case
                                 When Page4b.REVENUE_BUSINESS_UNIT = '5090'
                                     Then Page4b.WJXBFS1
                                 Else 0
                             End)            As WH5090,
                         Sum(Case
                                 When Page4b.REVENUE_BUSINESS_UNIT = '6000'
                                     Then Page4b.WJXBFS1
                                 Else 0
                             End)            As WH6000,
                         Sum(Case
                                 When Page4b.REVENUE_BUSINESS_UNIT = '7000'
                                     Then Page4b.WJXBFS1
                                 Else 0
                             End)            As WH7000
                     From (Select
                               a11.TRDJ_DATETRANSACTIONJULIAN   DATE_SRCCD,
                               a11.MCU_COSTCENTER               REVENUE_BUSINESS_UNIT,
                               Sum(((a11.SOBK_UNITSQUANBACKORHELD + a11.SOQS_UNITSQUANTITYSHIPPED) *
                                    a11.UPRC_AMTPRICEPERUNIT2)) WJXBFS1,
                               a11.KCOO_COMPANYKEYORDERNO
                           From DJUS_JDE.PUBLIC.ODS_F4211_OPEN_ORDERS a11
                                    INNER JOIN DJUS_JDE.PUBLIC.ODS_F4101_ITEM_MASTER IM
                                               ON A11.ITM_IDENTIFIERSHORTITEM = IM.ITM_IDENTIFIERSHORTITEM
                                    Inner Join DJUS_JDE.PUBLIC.ODS_CALENDAR_DAY a12
                                               On (a11.TRDJ_DATETRANSACTIONJULIAN = a12.DATE_ID)
                           Where a11.KCOO_COMPANYKEYORDERNO = '00100'
                             AND IM.SRP1_SALESREPORTINGCODE1 <> 'JUV'
                             And a11.DCTO_ORDERTYPE Not In ('C1', 'SV', 'SG', 'KP', 'SH')
                             And a11.LNTY_LINETYPE In ('D', 'S', 'S7')
                             And a11.SOURCE In ('H', 'O')
                             And (a12.MNTH_ID) In (Select
                                                       c22.MNTH_ID
                                                   From DJUS_JDE.PUBLIC.ODS_CURRENT_DATE c21,
                                                        DJUS_JDE.PUBLIC.ODS_CALENDAR_MONTH_2 c22
                                                   Where c22.MNTH_ID = c21.MNTH_ID)
                           Group By a11.TRDJ_DATETRANSACTIONJULIAN,
                                    a11.MCU_COSTCENTER,
                                    a11.KCOO_COMPANYKEYORDERNO
                           union All
                           Select
                               a11.TRDJ_DATETRANSACTIONJULIAN   DATE_SRCCD,
                               a11.MCU_COSTCENTER               REVENUE_BUSINESS_UNIT,
                               Sum(((a11.SOBK_UNITSQUANBACKORHELD + a11.SOQS_UNITSQUANTITYSHIPPED) *
                                    a11.UPRC_AMTPRICEPERUNIT2)) WJXBFS1,
                               a11.KCOO_COMPANYKEYORDERNO
                           From DJUS_JDE.PUBLIC.ODS_F42119_SALES_HISTORY a11
                                    INNER JOIN DJUS_JDE.PUBLIC.ODS_F4101_ITEM_MASTER IM
                                               ON A11.ITM_IDENTIFIERSHORTITEM = IM.ITM_IDENTIFIERSHORTITEM
                                    Inner Join DJUS_JDE.PUBLIC.ODS_CALENDAR_DAY a12
                                               On (a11.TRDJ_DATETRANSACTIONJULIAN = a12.DATE_ID)
                           Where a11.DCTO_ORDERTYPE Not In ('C1', 'SV', 'SG', 'KP', 'SH')
                             AND A11.KCOO_COMPANYKEYORDERNO = '00100' -- DMG ADDED THIS, IT WAS MISSING
                             AND IM.SRP1_SALESREPORTINGCODE1 <> 'JUV'
                             And a11.LNTY_LINETYPE In ('D', 'S', 'S7')
                             And a11.SOURCE In ('H', 'O')
                             And (a12.MNTH_ID) In (Select
                                                       c22.MNTH_ID
                                                   From DJUS_JDE.PUBLIC.ODS_CURRENT_DATE c21,
                                                        DJUS_JDE.PUBLIC.ODS_CALENDAR_MONTH_2 c22
                                                   Where c22.MNTH_ID = c21.MNTH_ID)
                           Group By a11.TRDJ_DATETRANSACTIONJULIAN,
                                    a11.MCU_COSTCENTER,
                                    a11.KCOO_COMPANYKEYORDERNO) Page4b
                     Where Page4b.KCOO_COMPANYKEYORDERNO = '00100'
                     Group By Page4b.DATE_SRCCD) Page4b
                    On PAGE4a.Date_ID = Page4b.DATE_SRCCD,
     (Select
          Sum(DIV0(BUD.BUDGETQUANTY * BUD.BUDGETAVGUNITPRICE,
                   Day_Count.TOT_DAYS)) As Column1
      From (Select
                Sum(Case
                        When ods_calendar_month_.MNTH_ID = ods_current_date_.MNTH_ID Then
                            Cal1.DAYCNT
                        Else 0
                    End) As TOT_DAYS,
                Sum(Case
                        When Cal1.DOM < Extract(Day From ods_current_date_."DATE") And
                             ods_calendar_month_.MNTH_ID = ods_current_date_.MNTH_ID Then Cal1.DAYCNT
                        Else 0
                    End) As Days_Worked
            From DJUS_JDE.PUBLIC.ODS_WORKDAY Cal1
                     Inner Join DJUS_JDE.PUBLIC.ODS_CALENDAR_MONTH ods_calendar_month_
                                On Cal1.YEAR_MONTH = ods_calendar_month_.MNTH_SRCCD,
                 DJUS_JDE.PUBLIC.ODS_CURRENT_DATE ods_current_date_
            Where Cal1.DAY_TYPE = 'W') Day_Count,
           DJUS_JDE.PUBLIC.ODS_BUDGET BUD
               INNER JOIN DJUS_JDE.PUBLIC.ODS_F4101_ITEM_MASTER IM
                          ON BUD.ITM_IDENTIFIERSHORTITEM = IM.ITM_IDENTIFIERSHORTITEM
               Inner Join DJUS_JDE.PUBLIC.ODS_CURRENT_DATE ods_current_date_
                          On ods_current_date_.MNTH_ID = BUD.MONTHID
      Where BUD.KCOO_COMPANY = '00100'
        AND IM.SRP1_SALESREPORTINGCODE1 <> 'JUV') DailyPlan
Order By 1