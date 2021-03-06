-- auto gen by george 2018-01-28 10:13:02
DROP FUNCTION IF EXISTS gb_rebate_agent(INT, TIMESTAMP, TIMESTAMP, TEXT);
DROP FUNCTION IF EXISTS gb_rebate_agent(INT, TEXT, TIMESTAMP, TIMESTAMP, TEXT);
CREATE OR REPLACE FUNCTION gb_rebate_agent(
  p_bill_id   INT,
  p_period    TEXT,
  p_start_time   TIMESTAMP,
  p_end_time   TIMESTAMP,
  p_settle_flag   TEXT
) RETURNS VOID AS $$
/*版本更新说明
  版本   时间        作者    内容
--v1.00  2016/10/08  Laser  创建此函数: 返佣结算账单.代理返佣
--v1.10  2017/07/31  Laser  增加多级代理返佣支持
--v1.11  2017/09/03  Laser  取费用比率时，增加空值判断
--v1.12  2017/11/17  Laser  增加按梯度计算费用比率功能
--v1.13  2017/11/20  Laser  改由period来确定上期
--v1.14  2018/01/19  Laser  增加返佣上限处理

*/
DECLARE

  --v1.13  2017/11/20  Laser
  --d_last_start_time TIMESTAMP;
  v_last_period     TEXT;

  n_deposit_ratio   FLOAT := 0;
  n_withdraw_ratio  FLOAT := 0;
  n_rakeback_ratio  FLOAT := 0;
  n_favorable_ratio FLOAT := 0;
  n_other_ratio     FLOAT := 0;

  h_param_array  hstore;

BEGIN

  --v1.11  2017/09/03  Laser
  SELECT string_agg(hstore(param_code, param_value)::TEXT, ',')::hstore
    FROM ( SELECT param_code, CASE param_value WHEN NULL THEN '0' WHEN '' THEN '0' ELSE param_value END
           FROM sys_param WHERE ( param_type = 'apportionSetting' OR param_type = 'rebateSetting') AND active = TRUE ORDER BY 1
         ) sp
    INTO h_param_array;

  n_deposit_ratio := COALESCE(h_param_array ->'settlement.deposit.fee', '0')::FLOAT;
  n_withdraw_ratio := COALESCE(h_param_array ->'settlement.withdraw.fee', '0')::FLOAT;
  n_rakeback_ratio := COALESCE(h_param_array ->'agent.rakeback.percent', '0')::FLOAT;
  n_favorable_ratio := COALESCE(h_param_array ->'agent.preferential.percent', '0')::FLOAT;
  n_other_ratio := COALESCE(h_param_array ->'agent.other.percent', '0')::FLOAT;

  --v1.13  2017/11/20  Laser
  --d_last_start_time := p_start_time + '1 day' + '-1 month' + '-1 day'; -- 加一天防止是月末日期，再取上个月。
  v_last_period := to_char( to_timestamp (p_period, 'YYYY-MM') - interval '1mon', 'YYYY-MM');

  raise notice 'gb_rebate_agent.BEGIN: %', clock_timestamp();

  IF p_settle_flag = 'Y' THEN

    WITH
    ua AS --代理信息
    (
      SELECT ua.agent_rank, ua.id agent_id, su.username agent_name, ua.parent_id, ua.parent_array, uar.rebate_id rebate_set_id
        FROM user_agent ua
               INNER JOIN
             sys_user su ON su.user_type = '23' AND ua.id = su.id
               LEFT JOIN user_agent_rebate uar ON ua.id = uar.user_id
       WHERE su.status IN ('1', '2', '3')
    ),

    raa AS --本期返佣信息
    (
      SELECT agent_id,
             COALESCE( MIN(rebate_grads_id), 0) rebate_grads_id,
             COALESCE( MIN(max_rebate), 0) max_rebate,
             COALESCE( MIN(effective_player), 0) effective_player,
             COALESCE( SUM(effective_transaction), 0) effective_transaction,
             COALESCE( SUM(profit_loss), 0) profit_loss,
             COALESCE( SUM(rebate_parent), 0) rebate_parent,
             COALESCE( SUM(effective_self), 0) effective_self,
             COALESCE( SUM(profit_self), 0) profit_self,
             COALESCE( SUM(rebate_self), 0)::numeric(20,2) rebate_self,
             COALESCE( SUM(rebate_sun), 0)::numeric(20,2) rebate_sun
        FROM rebate_agent_api
       WHERE rebate_bill_id = p_bill_id
       GROUP BY agent_id
    ),

    rpf AS --分摊费用
    (
      SELECT agent_id,
             COALESCE( SUM(deposit_amount), 0) AS deposit_amount,
             n_deposit_ratio AS deposit_ratio,
             (SUM(deposit_amount) * n_deposit_ratio/100)::numeric(20,2) AS deposit_fee,

             COALESCE( SUM(withdraw_amount), 0) AS withdraw_amount,
             n_withdraw_ratio AS withdraw_ratio,
             (SUM(withdraw_amount)*n_withdraw_ratio/100)::numeric(20,2) AS withdraw_fee,

             COALESCE( SUM(rakeback_amount), 0) AS rakeback_amount,
             n_rakeback_ratio AS rakeback_ratio,
             --v1.12  2017/11/17  Laser
             --(SUM(rakeback_amount) * n_rakeback_ratio/100)::numeric(20,2) AS rakeback_fee,

             COALESCE( SUM(favorable_amount), 0) AS favorable_amount,
             n_favorable_ratio AS favorable_ratio,
             --(SUM(favorable_amount) * n_favorable_ratio/100)::numeric(20,2) AS favorable_fee,

             COALESCE( SUM(other_amount), 0) AS other_amount,
             n_other_ratio AS other_ratio
             --(SUM(other_amount) * n_other_ratio/100)::numeric(20,2) AS other_fee

        FROM rebate_player_fee
       WHERE rebate_bill_id = p_bill_id
       GROUP BY agent_id
    ),

    rah AS --上期返佣信息
    (
      SELECT agent_id,
             COALESCE( rebate_self + rebate_self_history, 0) AS rebate_self_history,
             COALESCE( rebate_sun + rebate_sun_history, 0) AS rebate_sun_history,
             COALESCE( fee_amount + fee_history, 0) AS fee_history
        FROM rebate_agent
       --v1.13  2017/11/20  Laser
       --WHERE rebate_bill_id = (SELECT id FROM rebate_bill WHERE start_time = d_last_start_time)
       WHERE rebate_bill_id = (SELECT id FROM rebate_bill WHERE period = v_last_period)
         AND settlement_state = 'next_lssuing'
    ),

    rai AS
    (
      SELECT ua.agent_id, ua.agent_name, ua.agent_rank, ua.parent_id, ua.parent_array, ua.rebate_set_id,
             raa.rebate_grads_id, raa.max_rebate, raa.effective_player, raa.effective_transaction, raa.profit_loss, raa.rebate_parent,
             raa.effective_self, raa.profit_self,
             raa.rebate_self, rah.rebate_self_history, raa.rebate_sun, rah.rebate_sun_history,
             --v1.14  2018/01/19  Laser
             CASE WHEN COALESCE(raa.rebate_self, 0) + COALESCE(raa.rebate_sun, 0) > raa.max_rebate THEN raa.max_rebate ELSE COALESCE(raa.rebate_self, 0) + COALESCE(raa.rebate_sun, 0) END rebate_amount,
             rpf.deposit_amount, rpf.deposit_ratio, rpf.deposit_fee,
             rpf.withdraw_amount, rpf.withdraw_ratio, rpf.withdraw_fee,
             --v1.12  2017/11/17  Laser
             --rpf.rakeback_amount, rpf.rakeback_ratio, rpf.rakeback_fee,
             --rpf.favorable_amount, rpf.favorable_ratio, rpf.favorable_fee,
             --rpf.other_amount, rpf.other_ratio, rpf.other_fee,
             rpf.rakeback_amount, COALESCE(rg.rakeback_ratio, rpf.rakeback_ratio) rakeback_ratio, (rpf.rakeback_amount * COALESCE(rg.rakeback_ratio, rpf.rakeback_ratio)/100 )::numeric(20,2) rakeback_fee,
             rpf.favorable_amount, COALESCE(rg.favorable_ratio, rpf.favorable_ratio) favorable_ratio, (rpf.favorable_amount * COALESCE(rg.favorable_ratio, rpf.favorable_ratio)/100 )::numeric(20,2) favorable_fee,
             rpf.other_amount, COALESCE(rg.other_ratio, rpf.other_ratio) other_ratio, (rpf.other_amount * COALESCE(rg.other_ratio, rpf.other_ratio)/100 )::numeric(20,2) other_fee,
             --v1.12  2017/11/17  Laser
             --rpf.deposit_fee + rpf.withdraw_fee + rpf.rakeback_fee + rpf.favorable_fee + rpf.other_fee AS fee_amount,
             rpf.deposit_fee + rpf.withdraw_fee + (rpf.rakeback_amount * COALESCE(rg.rakeback_ratio, rpf.rakeback_ratio)/100)::numeric(20,2)
             + (rpf.favorable_amount * COALESCE(rg.favorable_ratio, rpf.favorable_ratio)/100)::numeric(20,2)
             + (rpf.other_amount * COALESCE(rg.other_ratio, rpf.other_ratio)/100)::numeric(20,2) AS fee_amount,
             rah.fee_history
        FROM ua
            LEFT JOIN
          raa ON ua.agent_id = raa.agent_id
            LEFT JOIN
          rebate_grads rg ON raa.rebate_grads_id = rg.id
            LEFT JOIN
          rpf ON ua.agent_id = rpf.agent_id
            LEFT JOIN
          rah ON ua.agent_id = rah.agent_id
    )

    INSERT INTO rebate_agent ( rebate_bill_id, agent_id, agent_name, agent_rank, parent_id, parent_array, rebate_set_id,
        rebate_grads_id, max_rebate, effective_player, effective_transaction, profit_loss, rebate_parent, effective_self, profit_self,
        rebate_self, rebate_self_history, rebate_sun, rebate_sun_history, rebate_amount,
        deposit_amount, deposit_ratio, deposit_fee,
        withdraw_amount, withdraw_ratio, withdraw_fee, rakeback_amount, rakeback_ratio, rakeback_fee,
        favorable_amount, favorable_ratio, favorable_fee, other_amount, other_ratio, other_fee, fee_amount, fee_history,
        rebate_total, rebate_actual, settlement_state
    )
    SELECT p_bill_id, agent_id, agent_name, agent_rank, parent_id, parent_array, rebate_set_id,
           rebate_grads_id, max_rebate, COALESCE(effective_player, 0), COALESCE(effective_transaction, 0), COALESCE(profit_loss, 0), COALESCE(rebate_parent, 0), COALESCE(effective_self, 0), COALESCE(profit_self, 0),
           COALESCE(rebate_self, 0), COALESCE(rebate_self_history, 0), COALESCE(rebate_sun, 0), COALESCE(rebate_sun_history, 0), COALESCE(rebate_amount, 0),
           COALESCE(deposit_amount, 0), COALESCE(deposit_ratio, 0), COALESCE(deposit_fee, 0),
           COALESCE(withdraw_amount, 0), COALESCE(withdraw_ratio, 0), COALESCE(withdraw_fee, 0), COALESCE(rakeback_amount, 0), COALESCE(rakeback_ratio, 0), COALESCE(rakeback_fee, 0),
           COALESCE(favorable_amount, 0), COALESCE(favorable_ratio, 0), COALESCE(favorable_fee, 0), COALESCE(other_amount, 0), COALESCE(other_ratio, 0), COALESCE(other_fee, 0), COALESCE(fee_amount, 0), COALESCE(fee_history, 0),
           --v1.14  2018/01/19  Laser
           COALESCE(rebate_amount, 0) + --COALESCE(rebate_self, 0) + COALESCE(rebate_sun , 0)
           + COALESCE(rebate_self_history , 0) + COALESCE(rebate_sun_history , 0) - COALESCE(fee_amount , 0) - COALESCE(fee_history, 0) AS rebate_total,
           0 AS rebate_actual,
           'pending_lssuing'
      FROM rai
     WHERE ( COALESCE(effective_transaction, 0) <> 0 OR COALESCE(profit_loss, 0) <> 0 OR
             COALESCE(rebate_self, 0) <> 0 OR COALESCE(rebate_self_history , 0) <> 0 OR COALESCE(rebate_sun , 0) <> 0 OR
             COALESCE(rebate_sun_history , 0) <> 0 OR COALESCE(fee_amount , 0) <> 0 OR COALESCE(fee_history, 0) <> 0
           );


  ELSEIF p_settle_flag = 'N' THEN

    WITH
    ua AS --代理信息
    (
      SELECT ua.agent_rank, ua.id agent_id, su.username agent_name, ua.parent_id, ua.parent_array, uar.rebate_id rebate_set_id
        FROM user_agent ua
               INNER JOIN
             sys_user su ON su.user_type = '23' AND ua.id = su.id
               LEFT JOIN user_agent_rebate uar ON ua.id = uar.user_id
       WHERE su.status IN ('1', '2', '3')
    ),

    raa AS --本期返佣信息
    (
      SELECT agent_id,
             COALESCE( MIN(rebate_grads_id), 0) rebate_grads_id,
             COALESCE( MIN(max_rebate), 0) max_rebate,
             COALESCE( MIN(effective_player), 0) effective_player,
             COALESCE( SUM(effective_transaction), 0) effective_transaction,
             COALESCE( SUM(profit_loss), 0) profit_loss,
             COALESCE( SUM(rebate_parent), 0) rebate_parent,
             COALESCE( SUM(effective_self), 0) effective_self,
             COALESCE( SUM(profit_self), 0) profit_self,
             COALESCE( SUM(rebate_self), 0)::numeric(20,2) rebate_self,
             COALESCE( SUM(rebate_sun), 0)::numeric(20,2) rebate_sun
        FROM rebate_agent_api_nosettled
       WHERE rebate_bill_id = p_bill_id
       GROUP BY agent_id
    ),

    rpf AS --分摊费用
    (
      SELECT agent_id,
             COALESCE( SUM(deposit_amount), 0) AS deposit_amount,
             n_deposit_ratio AS deposit_ratio,
             (SUM(deposit_amount) * n_deposit_ratio/100)::numeric(20,2) AS deposit_fee,

             COALESCE( SUM(withdraw_amount), 0) AS withdraw_amount,
             n_withdraw_ratio AS withdraw_ratio,
             (SUM(withdraw_amount)*n_withdraw_ratio/100)::numeric(20,2) AS withdraw_fee,

             COALESCE( SUM(rakeback_amount), 0) AS rakeback_amount,
             n_rakeback_ratio AS rakeback_ratio,
             --v1.12  2017/11/17  Laser
             --(SUM(rakeback_amount) * n_rakeback_ratio/100)::numeric(20,2) AS rakeback_fee,

             COALESCE( SUM(favorable_amount), 0) AS favorable_amount,
             n_favorable_ratio AS favorable_ratio,
             --(SUM(favorable_amount) * n_favorable_ratio/100)::numeric(20,2) AS favorable_fee,

             COALESCE( SUM(other_amount), 0) AS other_amount,
             n_other_ratio AS other_ratio
             --(SUM(other_amount) * n_other_ratio/100)::numeric(20,2) AS other_fee

        FROM rebate_player_fee_nosettled
       WHERE rebate_bill_id = p_bill_id
       GROUP BY agent_id
    ),

    rah AS --上期返佣信息
    (
      SELECT agent_id,
             COALESCE(rebate_self + rebate_self_history, 0) AS rebate_self_history,
             COALESCE(rebate_sun + rebate_sun_history, 0) AS rebate_sun_history,
             COALESCE(fee_amount + fee_history, 0) AS fee_history
        FROM rebate_agent --上期费用不要用nosettled表
        --v1.13  2017/11/20  Laser
        --WHERE rebate_bill_id = (SELECT id FROM rebate_bill WHERE start_time = d_last_start_time)
        WHERE rebate_bill_id = (SELECT id FROM rebate_bill WHERE period = v_last_period)
         AND settlement_state = 'next_lssuing'
    ),

    rai AS
    (
      SELECT ua.agent_id, ua.agent_name, ua.agent_rank, ua.parent_id, ua.parent_array, ua.rebate_set_id,
             raa.rebate_grads_id, raa.max_rebate, raa.effective_player, raa.effective_transaction, raa.profit_loss, raa.rebate_parent,
             raa.effective_self, raa.profit_self,
             raa.rebate_self, rah.rebate_self_history, raa.rebate_sun, rah.rebate_sun_history,
             --v1.14  2018/01/19  Laser
             CASE WHEN COALESCE(raa.rebate_self, 0) + COALESCE(raa.rebate_sun, 0) > raa.max_rebate THEN raa.max_rebate ELSE COALESCE(raa.rebate_self, 0) + COALESCE(raa.rebate_sun, 0) END rebate_amount,
             rpf.deposit_amount, rpf.deposit_ratio, rpf.deposit_fee,
             rpf.withdraw_amount, rpf.withdraw_ratio, rpf.withdraw_fee,
             --v1.12  2017/11/17  Laser
             --rpf.rakeback_amount, rpf.rakeback_ratio, rpf.rakeback_fee,
             --rpf.favorable_amount, rpf.favorable_ratio, rpf.favorable_fee,
             --rpf.other_amount, rpf.other_ratio, rpf.other_fee,
             rpf.rakeback_amount, COALESCE(rg.rakeback_ratio, rpf.rakeback_ratio) rakeback_ratio, (rpf.rakeback_amount * COALESCE(rg.rakeback_ratio, rpf.rakeback_ratio)/100 )::numeric(20,2) rakeback_fee,
             rpf.favorable_amount, COALESCE(rg.favorable_ratio, rpf.favorable_ratio) favorable_ratio, (rpf.favorable_amount * COALESCE(rg.favorable_ratio, rpf.favorable_ratio)/100 )::numeric(20,2) favorable_fee,
             rpf.other_amount, COALESCE(rg.other_ratio, rpf.other_ratio) other_ratio, (rpf.other_amount * COALESCE(rg.other_ratio, rpf.other_ratio)/100 )::numeric(20,2) other_fee,
             --v1.12  2017/11/17  Laser
             --rpf.deposit_fee + rpf.withdraw_fee + rpf.rakeback_fee + rpf.favorable_fee + rpf.other_fee AS fee_amount,
             rpf.deposit_fee + rpf.withdraw_fee + (rpf.rakeback_amount * COALESCE(rg.rakeback_ratio, rpf.rakeback_ratio)/100)::numeric(20,2)
             + (rpf.favorable_amount * COALESCE(rg.favorable_ratio, rpf.favorable_ratio)/100)::numeric(20,2)
             + (rpf.other_amount * COALESCE(rg.other_ratio, rpf.other_ratio)/100)::numeric(20,2) AS fee_amount,
             rah.fee_history
        FROM ua
            LEFT JOIN
          raa ON ua.agent_id = raa.agent_id
            LEFT JOIN
          rebate_grads rg ON raa.rebate_grads_id = rg.id
            LEFT JOIN
          rpf ON ua.agent_id = rpf.agent_id
            LEFT JOIN
          rah ON ua.agent_id = rah.agent_id
    )

    INSERT INTO rebate_agent_nosettled ( rebate_bill_id, agent_id, agent_name, agent_rank, parent_id, parent_array, rebate_set_id,
        rebate_grads_id, max_rebate, effective_player, effective_transaction, profit_loss, rebate_parent, effective_self, profit_self,
        rebate_self, rebate_self_history, rebate_sun, rebate_sun_history, rebate_amount,
        deposit_amount, deposit_ratio, deposit_fee,
        withdraw_amount, withdraw_ratio, withdraw_fee, rakeback_amount, rakeback_ratio, rakeback_fee,
        favorable_amount, favorable_ratio, favorable_fee, other_amount, other_ratio, other_fee, fee_amount, fee_history,
        rebate_total
    )
    SELECT p_bill_id, agent_id, agent_name, agent_rank, parent_id, parent_array, rebate_set_id,
           rebate_grads_id, max_rebate, COALESCE(effective_player, 0), COALESCE(effective_transaction, 0), COALESCE(profit_loss, 0), COALESCE(rebate_parent, 0), COALESCE(effective_self, 0), COALESCE(profit_self, 0),
           COALESCE(rebate_self, 0), COALESCE(rebate_self_history, 0), COALESCE(rebate_sun, 0), COALESCE(rebate_sun_history, 0), COALESCE(rebate_amount, 0),
           COALESCE(deposit_amount, 0), COALESCE(deposit_ratio, 0), COALESCE(deposit_fee, 0),
           COALESCE(withdraw_amount, 0), COALESCE(withdraw_ratio, 0), COALESCE(withdraw_fee, 0), COALESCE(rakeback_amount, 0), COALESCE(rakeback_ratio, 0), COALESCE(rakeback_fee, 0),
           COALESCE(favorable_amount, 0), COALESCE(favorable_ratio, 0), COALESCE(favorable_fee, 0), COALESCE(other_amount, 0), COALESCE(other_ratio, 0), COALESCE(other_fee, 0), COALESCE(fee_amount, 0), COALESCE(fee_history, 0),
           --v1.14  2018/01/19  Laser
           COALESCE(rebate_amount, 0) + --COALESCE(rebate_self, 0) + COALESCE(rebate_sun , 0)
           + COALESCE(rebate_self_history , 0) + COALESCE(rebate_sun_history , 0) - COALESCE(fee_amount , 0) - COALESCE(fee_history, 0) AS rebate_total
      FROM rai
     WHERE ( COALESCE(effective_transaction, 0) <> 0 OR COALESCE(profit_loss, 0) <> 0 OR
             COALESCE(rebate_self, 0) <> 0 OR COALESCE(rebate_self_history , 0) <> 0 OR COALESCE(rebate_sun , 0) <> 0 OR
             COALESCE(rebate_sun_history , 0) <> 0 OR COALESCE(fee_amount , 0) <> 0 OR COALESCE(fee_history, 0) <> 0
           );

  END IF;

  raise notice 'gb_rebate_agent.END: %', clock_timestamp();

END;

$$ language plpgsql;
COMMENT ON FUNCTION gb_rebate_agent(p_bill_id INT, p_period TEXT, p_start_time TIMESTAMP, p_end_time TIMESTAMP, p_settle_flag TEXT)
IS 'Laser-返佣结算账单.代理返佣';

DROP FUNCTION IF EXISTS gb_topagent_occupy_gather( TEXT, INT, INT);
CREATE OR REPLACE FUNCTION gb_topagent_occupy_gather(
  p_occupy_bill_no TEXT,
  p_occupy_year   INT,
  p_occupy_month   INT
) RETURNS INT AS $$
/*版本更新说明
  版本   时间        作者   内容
--v1.00  2017/07/12  Laser  创建此函数: 总代占成账单-总代汇总
--v1.01  2017/08/21  Laser  适应多级代理返佣调整
--v1.02  2018/01/21  Laser  返佣费用取本期返佣（针对返佣上限）

*/
--费用类型(以player_transaction为准): backwater, favorable, recommend, refund_fee, rebate 佣金, poundage 存取款手续费
DECLARE

  --v1.01  2017/08/21  Laser
  h_apportion_setting hstore;
  --n_refund_fee_ratio FLOAT := 0.00;
  n_favorable_ratio FLOAT := 0.00;
  n_rakeback_ratio   FLOAT := 0.00;
  n_rebate_ratio     FLOAT := 0.00;
  v_period VARCHAR(7);

BEGIN

  --v1.01  2017/08/21  Laser
  SELECT gamebox_sys_param('apportionSetting') INTO h_apportion_setting;

  --n_refund_fee_ratio = h_apportion_setting->'topagent.poundage.percent';
  n_favorable_ratio = h_apportion_setting->'topagent.preferential.percent';
  n_rakeback_ratio   = h_apportion_setting->'topagent.rakeback.percent';
  n_rebate_ratio     = h_apportion_setting->'topagent.rebate.percent';

  v_period = to_char( to_date( p_occupy_year::TEXT||'-'||p_occupy_month::TEXT, 'YYYY-MM'), 'YYYY-MM');

  --插入总代API占成表
  --v1.01  2017/08/21  Laser
  INSERT INTO topagent_occupy ( occupy_bill_no, occupy_year, occupy_month, topagent_id, topagent_name, profit_amount, operation_occupy, topagent_occupy,
      favorable, favorable_ratio, rakeback, rakeback_ratio, rebate, rebate_ratio, apportion_value)
  SELECT p_occupy_bill_no, p_occupy_year, p_occupy_month, ut.topagent_id, ut.topagent_name,
      COALESCE(profit_amount, 0),
      COALESCE(operation_occupy, 0),
      COALESCE(topagent_occupy, 0),
      --COALESCE(poundage, 0),
      COALESCE(favorable, 0),
      n_favorable_ratio,
      --COALESCE(recommend, 0),
      --COALESCE(refund_fee, 0),
      COALESCE(rakeback, 0),
      n_rakeback_ratio,
      COALESCE(rebate, 0),
      n_rebate_ratio,
      --COALESCE(apportion_ratio, 0),
      --( COALESCE(poundage, 0) + COALESCE(favorable, 0) + COALESCE(recommend, 0) + COALESCE(refund_fee, 0) +
      --  COALESCE(rakeback, 0) + COALESCE(rebate, 0) ) * COALESCE(apportion_ratio, 0)/100
      COALESCE(favorable, 0) * n_favorable_ratio/100 + COALESCE(rakeback, 0) * n_rakeback_ratio/100 +
      COALESCE(rebate, 0) * n_rebate_ratio/100
   FROM
  (
    SELECT id topagent_id, username topagent_name FROM sys_user WHERE user_type='22'
  ) ut
  LEFT JOIN
  (
    SELECT topagent_id,
           SUM(profit_amount)    profit_amount,
           SUM(operation_occupy) operation_occupy,
           SUM(occupy_value)     topagent_occupy,
           MAX(occupy_ratio)     apportion_ratio
      FROM topagent_occupy_api
     WHERE occupy_bill_no = p_occupy_bill_no
     GROUP BY topagent_id
  ) toi
  ON ut.topagent_id = toi.topagent_id
  --v1.01  2017/08/21  Laser
  LEFT JOIN
  (
    SELECT su.owner_id                           AS topagent_id,
           SUM(favorable_amount)                 AS favorable,
           SUM(rakeback_amount)                  AS rakeback,
           --SUM(rebate_self + rebate_sun)         AS rebate --v1.02  2018/01/21  Laser
           SUM(rebate_amount)         AS rebate
      FROM rebate_agent ra, rebate_bill rb, sys_user su
     WHERE ra.rebate_bill_id = rb.id
       AND rb.period = v_period
       AND ra.agent_id = su.id
       AND su.user_type = '23'
     GROUP BY su.owner_id
  ) ar
  ON ut.topagent_id = ar.topagent_id
   WHERE (toi.topagent_id IS NOT NULL OR ar.topagent_id IS NOT NULL)
  ;
  /*--v1.01  2017/08/21  Laser
  LEFT JOIN
  (
    SELECT topagent_id,
           SUM(fee_amount)       poundage,
           SUM(favorable_amount) favorable,
           SUM(other_amount)     recommend,
           0 refund_fee,
           SUM(rakeback_amount)  rakeback,
           SUM(rebate_amount)    rebate
      FROM agent_rebate
     WHERE rebate_year  = p_occupy_year
       AND rebate_month = p_occupy_month
     GROUP BY topagent_id
  ) ar
  ON ut.topagent_id = ar.topagent_id
  ;
  */

  RETURN 0;
END;

$$ language plpgsql;
COMMENT ON FUNCTION gb_topagent_occupy_gather( p_occupy_bill_no TEXT, p_occupy_year INT, p_occupy_month INT)
IS 'Laser-总代占成账单-总代汇总';

DROP FUNCTION IF EXISTS gb_api_collate_player(TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION gb_api_collate_player(
  p_comp_url   TEXT,
  p_curday     TEXT,
  p_apis       TEXT
) RETURNS text AS $$
/*版本更新说明
  版本   时间        作者    内容
--v1.00  2018/01/12  Laser   创建此函数: API注单核对-玩家报表
*/
DECLARE
  sif     JSON;
  rtn     TEXT:='';
  n_count    INT:=0;
  n_site_id   INT;
  n_master_id   INT;
  n_center_id   INT;
  c_site_name   TEXT:='';
  c_master_name TEXT:='';
  c_center_name TEXT:='';
  d_static_date DATE;
  rec RECORD;
  d_start_time TIMESTAMP;
  d_end_time   TIMESTAMP;

BEGIN

	--收集当前所有运营站点相关信息.
  SELECT gamebox_collect_site_infor(p_comp_url, gamebox_current_site()) into sif;
  IF sif->>'siteid' = '-1' THEN
    rtn = '运营商库中不存在当前站点的相关信息,请确保此站点是否合法.';
    raise info '%', rtn;
    return rtn;
  END IF;

  rtn = rtn||chr(13)||chr(10)||'        ┣1.正在收集玩家下单信息：';

  --开始执行玩家经营报表信息收集
  n_site_id   = COALESCE((sif->>'siteid')::INT, -1);
  c_site_name  = COALESCE(sif->>'sitename', '');
  n_master_id  = COALESCE((sif->>'masterid')::INT, -1);
  c_master_name  = COALESCE(sif->>'mastername', '');
  n_center_id  = COALESCE((sif->>'operationid')::INT, -1);
  c_center_name  = COALESCE(sif->>'operationname', '');

  d_static_date := to_date(p_curday, 'YYYY-MM-DD');

  --清除当天的统计信息，保证每天只作一次统计信息
  rtn = rtn||chr(13)||chr(10)||'          |清除当天的统计数据，保证每天只作一次统计||';
  --delete from api_collate_player WHERE to_char(static_time, 'YYYY-MM-dd') = p_curday;
  DELETE FROM api_collate_player WHERE static_date = d_static_date AND ( COALESCE(p_apis, '') = '' OR api_id = ANY ( regexp_split_to_array(p_apis, ',')::INT[]) );

  GET DIAGNOSTICS n_count = ROW_COUNT;
  raise notice '本次删除记录数 %', n_count;
  rtn = rtn||'|执行完毕，删除记录数: '||n_count||' 条||';

  /*
  FOR rec IN
    SELECT timezone, array_agg(api_id) apis
      FROM ( VALUES ('GMT-04:00',5),  ('GMT-04:00',7),  ('GMT-04:00',9),  ('GMT-04:00',10), ('GMT-04:00',12), ('GMT-04:00',17), ('GMT-04:00',19), ('GMT-04:00',23), ('GMT-04:00',24),
                    ('GMT+08:00',1),  ('GMT+08:00',2),  ('GMT+08:00',4),  ('GMT+08:00',6),  ('GMT+08:00',15), ('GMT+08:00',16), ('GMT+08:00',20), ('GMT+08:00',25), ('GMT+08:00',28),
                    ('GMT+08:00',31), ('GMT+08:00',32), ('GMT+08:00',33),
                    ('GMT+00:00',3),  ('GMT+00:00',21), ('GMT+00:00',22), ('GMT+00:00',26), ('GMT+00:00',27)
           ) AS t (timezone, api_id )
     WHERE ( COALESCE(p_apis, '') = '' OR api_id = ANY ( regexp_split_to_array(p_apis, ',')::INT[]) )
     GROUP BY timezone ORDER BY timezone
  LOOP
  */
  perform dblink_connect_u('mainsite', p_comp_url);

  FOR rec IN
    SELECT *
    	FROM dblink('mainsite',
    							'SELECT timezone, array_agg(id) apis
    								 FROM api
                    WHERE ( COALESCE('''|| p_apis || ''', '''') = '''' OR id = ANY ( regexp_split_to_array(''' || p_apis ||''', '','')::INT[]) )
    								GROUP BY timezone ORDER BY timezone')
    		AS a ( timezone VARCHAR(16), apis INT[])
  LOOP

    d_start_time := d_static_date - replace(rec.timezone, 'GMT', '')::interval;
    d_end_time   := d_start_time + interval '1d';

    raise notice '正在收集api:%, 开始时间:%, 结束时间:%', rec.apis, d_start_time, d_end_time;

    INSERT INTO api_collate_player(
      center_id, center_name, master_id, master_name,
      site_id, site_name, topagent_id, topagent_name,
      agent_id, agent_name, player_id, player_name,
      api_id, api_type_id, game_type,
      static_date, static_time, static_time_end, create_time,
      transaction_order, transaction_volume, effective_transaction,
      profit_loss, winning_amount, contribution_amount
    ) SELECT
          n_center_id, c_center_name, n_master_id, c_master_name,
          n_site_id, c_site_name, u.topagent_id, u.topagent_name,
          u.agent_id, u.agent_name, u.id, u.username,
          p.api_id, p.api_type_id, p.game_type,
          d_static_date, d_start_time::TIMESTAMP, d_end_time::TIMESTAMP, now(),
          p.transaction_order, p.transaction_volume, p.effective_transaction,
          p.profit_loss, p.winning_amount, p.contribution_amount
        FROM (SELECT
                  player_id, api_id, api_type_id, game_type,
                  COUNT(order_no)                as transaction_order,
                  COALESCE(SUM(single_amount), 0.00)      as transaction_volume,
                  COALESCE(SUM(profit_amount), 0.00)      as profit_loss,
                  COALESCE(SUM(effective_trade_amount), 0.00) as effective_transaction,
                  COALESCE(SUM(winning_amount), 0.00) as winning_amount,
                  COALESCE(SUM(contribution_amount), 0.00) as contribution_amount
               FROM player_game_order
              WHERE payout_time >= d_start_time::TIMESTAMP
                AND payout_time < d_end_time::TIMESTAMP
                AND api_id = ANY ( rec.apis::INT[] )
                AND order_state = 'settle'
              GROUP BY player_id, api_id, api_type_id, game_type
              ) p, v_sys_user_tier u
        WHERE p.player_id = u.id;

	  GET DIAGNOSTICS n_count = ROW_COUNT;
	  raise notice '本次插入数据量 %', n_count;
	  rtn = rtn||chr(13)||chr(10)||'          |api:'||rec.apis::TEXT||'执行完毕,新增记录数: '||n_count||' 条||';

  END LOOP;

  perform dblink_disconnect('mainsite');
  return rtn;
END;

$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION gb_api_collate_player(p_comp_url TEXT, p_curday TEXT, p_apis TEXT)
IS 'Laser-API注单核对-玩家报表';