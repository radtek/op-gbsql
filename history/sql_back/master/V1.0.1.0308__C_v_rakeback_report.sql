-- auto gen by cherry 2016-01-06 14:15:39
DROP VIEW IF EXISTS v_backwater_report;
DROP VIEW IF EXISTS v_rakeback_report;
CREATE OR REPLACE VIEW v_rakeback_report AS
  SELECT rb."id",
		 rp.player_id,
		 up.special_focus,
		 rp.username		player_name,
		 ua.username		agent_name,
		 uta.username		topagent_name,
		 rb.start_time,
		 rb.end_time,
		 rp.rakeback_total,
		 rp.rakeback_actual,
		 rp.settlement_state
	FROM rakeback_bill rb
   INNER JOIN (
			SELECT player_id,
				   agent_id,
				   top_agent_id,
				   username,
				   settlement_state,
				   rakeback_bill_id,
				   SUM (rakeback_total)		rakeback_total,
				   SUM (rakeback_actual)	rakeback_actual
			  FROM
				rakeback_player
			 GROUP BY player_id, agent_id, top_agent_id, username, settlement_state, rakeback_bill_id
			) rp ON rb.id = rp.rakeback_bill_id
   	LEFT JOIN user_player up ON rp.player_id = up.id
	LEFT JOIN sys_user ua ON rp.agent_id = ua."id"
	LEFT JOIN sys_user uta ON rp.top_agent_id = uta."id"
 WHERE rb.end_time >= now() - INTERVAL '90 day';

ALTER TABLE v_rakeback_report OWNER TO postgres;
COMMENT ON VIEW v_rakeback_report IS '返水统计详细视图 - Fly';

UPDATE sys_resource SET url = 'report/rakeback/rakebackIndex.html' WHERE "id" = (SELECT "id" FROM sys_resource WHERE name = '返水统计' AND parent_id = 5 AND subsys_code = 'mcenter');

DROP VIEW IF EXISTS v_rebate_report;
CREATE OR REPLACE VIEW v_rebate_report AS
SELECT
		rg."id",
		rg.agent_name,
		su.username	topagent_name,
		rg.effective_player,
		rg.effective_transaction,
		rg.profit_loss,
		rg.deposit_amount,
		rg.withdrawal_amount,
		rg.rakeback,
		rg.preferential_value,
		rg.apportion,
		rg.refund_fee,
		rg.rebate_total,
		rg.rebate_actual,
		rg.settlement_state,
		rb.start_time,
		rb.end_time,
		rb.period
	FROM rebate_bill rb
	LEFT JOIN rebate_agent rg ON rb."id" = rg.rebate_bill_id
	LEFT JOIN user_agent ua ON rg.agent_id = ua."id"
	LEFT JOIN sys_user su ON ua.parent_id = su."id"
 WHERE rg."id" IS NOT NULL
	 AND rb.end_time >= now()-interval '90 day';

ALTER TABLE v_rebate_report OWNER TO postgres;
COMMENT ON VIEW v_rebate_report IS '返佣统计详细视图 - FLy';

-- 推荐奖励计划任务
DROP FUNCTION IF EXISTS f_player_recommend_award(VARCHAR, VARCHAR);
/**
 * 玩家推荐奖励存储函数
 * @author: Fly
 * @date: 2015-12-18
 */
CREATE OR REPLACE FUNCTION f_player_recommend_award (
	IN siteCode VARCHAR,		-- 站点代码
	IN orderType VARCHAR		-- 订单类型: 01-充值, 02-优惠, 03-游戏API, 04-返水, 05-返佣, 06-玩家取款, 07-代理提现, 08-转账
)
	RETURNS INTEGER AS $BODY$
DECLARE
	rec record;
	-- 单次奖励
	singleReward BOOLEAN:= (SELECT active FROM sys_param WHERE param_type = 'recommended' AND param_code = 'reward');
	-- 奖励方式: 1-奖励双方,2-奖励推荐人,3-奖励被推荐人
	rewardWay INTEGER:= (SELECT param_value FROM sys_param WHERE param_type = 'recommended' AND param_code = 'reward');
	-- 单次奖励存款金额
	deposit NUMERIC:= (SELECT param_value FROM sys_param WHERE param_type = 'recommended' AND param_code = 'reward.theWay');
	-- 奖励金额
	rewardAmount NUMERIC:= (SELECT param_value FROM sys_param WHERE param_type = 'recommended' AND param_code = 'reward.money');
	-- 单次奖励优惠稽核倍数
	rewardMultiple NUMERIC:= (SELECT param_value FROM sys_param WHERE param_type = 'recommended' AND param_code = 'audit');
	-- 优惠稽核点
	rewardPoint NUMERIC:= rewardAmount * rewardMultiple;

	br record;
	-- 推荐红利
	bonusReward BOOLEAN:= (SELECT active FROM sys_param WHERE param_type = 'recommended' AND param_code = 'bonus');
	-- 推荐红利有效玩家交易量
	effeTrade NUMERIC:= (SELECT param_value FROM sys_param WHERE param_type = 'recommended' AND param_code = 'bonus.trading');
	-- 红利上限
	toplimit NUMERIC:= (SELECT param_value FROM sys_param WHERE param_type = 'recommended' AND param_code = 'bonus.bonusMax');
	-- 奖励金额
	bonusAmount NUMERIC:=0.0;
	-- 优惠稽核点
	bonusPoint NUMERIC:=0.0;

	orderNo VARCHAR:='';
	transType VARCHAR:='recommend';		-- 交易类型:推荐
	transStatus VARCHAR:='success';		-- 交易状态:待处理
	fundType VARCHAR:='recommend';		-- 资金类型:推荐
	single VARCHAR:='single_reward'; 	-- 单次奖励
	bonus VARCHAR:='bonus_awards';		-- 推荐红利
BEGIN
	IF singleReward THEN	-- 单次奖励
		FOR rec IN
			SELECT * FROM (
				/* 去除已奖励的玩家 */
				SELECT up."id", up.recommend_user_id recommend_id, su.username recommend_name
				  FROM user_player up
				 INNER JOIN sys_user su ON up."recommend_user_id" = su."id"
				 WHERE su.user_type = '24'
				   AND up.recommend_user_id IS NOT NULL
				   AND up."id" NOT IN (
					 	SELECT recommend_user_id FROM player_recommend_award
					 	 WHERE reward_mode = 'single_reward'
						   AND user_id IN (SELECT DISTINCT(recommend_user_id) FROM user_player WHERE recommend_user_id IS NOT NULL)
				   )
			) tr INNER JOIN (
				/* 被推荐人满足交易量 */
				SELECT su."id" berecommend_id, su.username berecommend_name, ep.trade_amount
				  FROM (SELECT player_id, SUM(effective_trade_amount) trade_amount FROM player_game_order GROUP BY player_id) ep
				  LEFT JOIN sys_user su ON ep.player_id = su."id"
				 WHERE su.user_type = '24' AND ep.trade_amount >= deposit
			) ta ON tr."id" = ta.berecommend_id

			LOOP

				IF rewardWay = '1' THEN	-- 奖励双方
					orderNo := (SELECT f_order_no(siteCode, orderType));
					/** 奖励推荐人 */
					WITH award1 AS (
						-- 新增推荐记录数据
						INSERT INTO player_recommend_award (transaction_no, user_id, user_name, recommend_user_id, recommend_user_name, reward_mode, reward_amount, reward_time, reward_reason)
						VALUES (orderNo,
							rec.recommend_id, rec.recommend_name, rec.berecommend_id, rec.berecommend_name, single, rewardAmount, now(), '推荐')
						RETURNING id
					)
					-- 新增交易订单数据
					INSERT INTO player_transaction (transaction_no, create_time, transaction_type, remark, transaction_money, balance, status, player_id, source_id,
						effective_transaction, favorable_audit_points, is_satisfy_audit, is_clear_audit, fund_type, transaction_way, transaction_data)
					VALUES (orderNo, now(), transType, '推荐奖励-单次', rewardAmount, rewardAmount + (SELECT wallet_balance FROM user_player WHERE id = rec.recommend_id), transStatus,
						rec.recommend_id, (SELECT id FROM award1), rec.trade_amount, rewardPoint, false, false, fundType, single, '{"username":"'||rec.berecommend_name||'"}');
					-- 修改玩家余额
					UPDATE user_player SET wallet_balance = wallet_balance + rewardAmount WHERE id = rec.recommend_id;

					/** 奖励被推荐人 */
					orderNo := (SELECT f_order_no(siteCode, orderType));
					WITH award2 AS (
						-- 新增推荐记录数据
						INSERT INTO player_recommend_award (transaction_no, user_id, user_name, recommend_user_id, recommend_user_name, reward_mode, reward_amount, reward_time, reward_reason)
						VALUES (orderNo,
							rec.recommend_id, rec.recommend_name, rec.berecommend_id, rec.berecommend_name, single, rewardAmount, now(), '被推荐')
						RETURNING id
					)
					-- 新增交易订单数据
					INSERT INTO player_transaction (transaction_no, create_time, transaction_type, remark, transaction_money, balance, status, player_id, source_id,
						effective_transaction, favorable_audit_points, is_satisfy_audit, is_clear_audit, fund_type, transaction_way, transaction_data)
					VALUES (orderNo,
						now(), transType, '推荐奖励-单次', rewardAmount, rewardAmount + (SELECT wallet_balance FROM user_player WHERE id = rec.berecommend_id), transStatus,
						rec.berecommend_id, (SELECT id FROM award2), rec.trade_amount, rewardPoint, false, false, fundType, single, '{"username":"'||rec.berecommend_name||'"}');
					-- 修改玩家余额
					UPDATE user_player SET wallet_balance = wallet_balance + rewardAmount WHERE id = rec.berecommend_id;

				ELSEIF rewardWay = '2' THEN 	-- 奖励推荐人
					orderNo := (SELECT f_order_no(siteCode, orderType));
					WITH award AS (
						-- 新增推荐记录数据
						INSERT INTO player_recommend_award (transaction_no, user_id, user_name, recommend_user_id, recommend_user_name, reward_mode, reward_amount, reward_time, reward_reason)
						VALUES (orderNo,
							rec.recommend_id, rec.recommend_name, rec.berecommend_id, rec.berecommend_name, single, rewardAmount, now(), '推荐')
						RETURNING id
					)
					-- 新增交易订单数据
					INSERT INTO player_transaction (transaction_no, create_time, transaction_type, remark, transaction_money, balance, status, player_id, source_id,
						effective_transaction, favorable_audit_points, is_satisfy_audit, is_clear_audit, fund_type, transaction_way, transaction_data)
					VALUES (orderNo, now(), transType, '推荐奖励-单次', rewardAmount, rewardAmount + (SELECT wallet_balance FROM user_player WHERE id = rec.recommend_id), transStatus,
						rec.recommend_id, (SELECT id FROM award), rec.trade_amount, rewardPoint, false, false, fundType, single, '{"username":"'||rec.berecommend_name||'"}');
					-- 修改玩家余额
					UPDATE user_player SET wallet_balance = wallet_balance + rewardAmount WHERE id = rec.recommend_id;

				ELSEIF rewardWay = '3' THEN	-- 奖励被推荐人
					orderNo := (SELECT f_order_no(siteCode, orderType));
					WITH award AS (
						-- 新增推荐记录数据
						INSERT INTO player_recommend_award (transaction_no, user_id, user_name, recommend_user_id, recommend_user_name, reward_mode, reward_amount, reward_time, reward_reason)
						VALUES (orderNo,
							rec.recommend_id, rec.recommend_name, rec.berecommend_id, rec.berecommend_name, single, rewardAmount, now(), '被推荐')
						RETURNING id
					)
					-- 新增交易订单数据
					INSERT INTO player_transaction (transaction_no, create_time, transaction_type, remark, transaction_money, balance, status, player_id, source_id,
						effective_transaction, favorable_audit_points, is_satisfy_audit, is_clear_audit, fund_type, transaction_way, transaction_data)
					VALUES (orderNo,
						now(), transType, '推荐奖励-单次', rewardAmount, rewardAmount + (SELECT wallet_balance FROM user_player WHERE id = rec.berecommend_id), transStatus,
						rec.berecommend_id, (SELECT id FROM award), rec.trade_amount, rewardPoint, false, false, fundType, single, '{"username":"'||rec.berecommend_name||'"}');
					-- 修改玩家余额
					UPDATE user_player SET wallet_balance = wallet_balance + rewardAmount WHERE id = rec.berecommend_id;

				END IF;

			END LOOP;

	END IF;

	IF bonusReward THEN 	--推荐红利

		FOR rec IN
			SELECT up.recommend_user_id recommend_id,
				   su.username 			recommend_name,
				   COUNT(up.recommend_user_id) 		recommend_total,
				   SUM(pgo.effective_trade_amount) 	trade_amount
			  FROM user_player up
		 	 INNER JOIN sys_user su ON up.recommend_user_id = su."id"
			  LEFT JOIN player_game_order pgo ON up."id" = pgo.player_id
		 	 WHERE recommend_user_id IS NOT NULL
			   AND su.user_type = '24'
		 	 GROUP BY up.recommend_user_id, su.username

		LOOP

			-- 达到有效交易量
			IF rec.trade_amount >= effeTrade THEN

				FOR br IN
					SELECT playernum, proportion
					  FROM json_to_recordset((SELECT lower(param_value) FROM sys_param WHERE param_type = 'recommended' AND param_code = 'bonus.json')::json)
						AS x(id INTEGER,playernum INTEGER,proportion FLOAT)
					 ORDER BY playernum DESC

				LOOP

					-- 达到推荐人数
					IF rec.recommend_total >= br.playernum THEN

						bonusAmount := br.proportion / 100 * effeTrade; -- 奖励金额
						IF bonusAmount > toplimit THEN -- 奖励金额高于红利上限取上限值
							bonusAmount := toplimit;
						END IF;

						-- 优惠稽核点	(奖励稽核 x 优惠稽核倍数)
						bonusPoint := bonusAmount * rewardPoint;

						orderNo := (SELECT f_order_no(siteCode, orderType));
						WITH award AS (
							-- 新增推荐记录数据
							INSERT INTO player_recommend_award (transaction_no, user_id, user_name, reward_mode, reward_amount, reward_time, reward_reason)
							VALUES (orderNo,
								rec.recommend_id, rec.recommend_name, bonus, bonusAmount, now(), '推荐')
							RETURNING id
						)
						-- 新增交易订单数据
						INSERT INTO player_transaction (transaction_no, create_time, transaction_type, remark, transaction_money, balance, status, player_id, source_id,
							effective_transaction, favorable_audit_points, is_satisfy_audit, is_clear_audit, fund_type, transaction_way, transaction_data)
						VALUES (orderNo, now(), transType, '推荐奖励-红利', bonusAmount, bonusAmount + (SELECT wallet_balance FROM user_player WHERE id = rec.recommend_id), transStatus,
							rec.recommend_id, (SELECT id FROM award), rec.trade_amount, bonusPoint, false, false, fundType, bonus, '{"username":"'||rec.recommend_name||'"}');
						-- 修改玩家余额
						UPDATE user_player SET wallet_balance = wallet_balance + bonusAmount WHERE id = rec.recommend_id;

						EXIT; -- 跳出循环

					END IF; -- end 达到推荐人数

				END LOOP;

			END IF; -- end 达到有效交易量

		END LOOP;

	END IF;

	RETURN 1;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;

ALTER FUNCTION f_player_recommend_award(IN siteCode VARCHAR, IN orderType VARCHAR) OWNER TO "postgres";
COMMENT ON FUNCTION f_player_recommend_award(IN siteCode VARCHAR, IN orderType VARCHAR) IS 'Fly - 玩家推荐奖励存储函数';