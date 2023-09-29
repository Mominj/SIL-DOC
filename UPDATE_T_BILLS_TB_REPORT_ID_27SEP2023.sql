UPDATE TB_REPORT_ID
SET SQL_STRING = 'SELECT t.*, (nvl(t.MARKET_VALUE, 0) - nvl(t.PRESENT_VALUE, 0)) MTMGL
  FROM (WITH data AS (SELECT MAX(reval_date) reval_date
                        FROM (SELECT reval_date FROM tb_amrtz_reval_hist)
                       WHERE reval_date <=
                             to_date(<FROM_DATE>, ''DD - MON - YY''))
         SELECT tp.prod_desc,
                th.reval_date REVAL_DT,
                th.security_code REFERENCENUMBER,
                tp.prod_code,
                tp.prod_desc PRODUCTDESC,
                th.amrtz_holding_days HOLDINGDAYS,
                th.deal_id,
                tl.VALUE_DATE,
                 CASE
                           WHEN td.deal_type = ''REPO'' AND
                                td.deal_flow=''SELL'' THEN
                           TRUNC(tl.value_date)
                           ELSE
                            TRUNC(td.trade_dt)
                         END TRADE_DATE,
                vf.issue_dt ISSUE_DATE,
                vf.maturity_dt MATURITY_DATE,
                Pkg_Fis_Utility.FN_GET_QTY_ASOF(th.deal_id,TO_DATE(th.reval_date, ''DD-MON-YY'')) *td.paid_up_value AS FACE_VALUE,
                Pkg_Fis_Utility.FN_GET_QTY_ASOF(th.deal_id,TO_DATE(th.reval_date, ''DD-MON-YY''))*th.clean_price  AS OFFER_VALUE,
                fn_co_convert_tolcy(vf.BRANCH_CODE, vf.CCY_CODE, vf.YTM) PRIMARY_YIELD,
                th.prev_amrtz as PREVIOUS_VALUE,
                th.present_amrtz as PRESENT_VALUE,
                th.amrtz_holding_int as INCOME,
                ABS(th.present_amrtz+th.reval_profit_loss) MARKET_VALUE
           FROM data                d,
                tb_amrtz_reval_hist th,
                vw_fis_deal_rpt     vf,
                tb_fis_deal         td,
                Tb_Fis_Deal_Leg      tl,
                tb_product          tp
          WHERE th.security_code = vf.security_code
            AND th.deal_id = vf.deal_id
            AND th.deal_id=td.deal_id
            AND td.deal_id=tl.deal_id
            AND tl.deal_flow = CASE
                  WHEN td.deal_type = ''REPO'' AND td.deal_flow = ''SELL'' THEN
                   ''BUY''
                  WHEN td.deal_type = ''REPO'' AND td.deal_flow = ''BUY'' THEN
                   ''SELL''
                  ELSE
                   td.deal_flow
              END
            AND th.reval_date = d.reval_date
            AND th.portfolio_code = ''BILL''
            AND th.strategy_code=''HFT''
            AND tp.prod_code NOT LIKE ''1%''
            AND vf.prod_code NOT in (''201'', ''202'', ''206'')
            AND vf.prod_code = tp.prod_code
            AND vf.prod_name = tp.prod_name
            AND tp.prod_type = ''FI''
          ORDER BY tp.prod_code, vf.issue_dt, th.security_code) t'
WHERE PARENT_ID = 'T_Bills'
AND REP_ID = 'T_Bills';
commit;