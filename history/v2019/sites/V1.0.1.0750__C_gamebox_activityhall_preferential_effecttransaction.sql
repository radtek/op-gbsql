-- auto gen by linsen 2018-04-15 21:31:37
-- 有效交易量活动计算 by kobe
DROP FUNCTION IF EXISTS gamebox_activityhall_preferential_effecttransaction(activitymessageid int4, sitecode varchar);
CREATE OR REPLACE FUNCTION "gamebox_activityhall_preferential_effecttransaction"(activitymessageid int4, sitecode varchar)
  RETURNS "pg_catalog"."void" AS $BODY$

declare
	rec_apply			RECORD;		-- 优惠申请结果集
	rec_way 			record;		-- 优惠形式结果集
	activityname_json 	VARCHAR:= '';	-- 活动名称，所有语言版本的名称都需要存储
	order_num 			int;		-- 满足的优惠档次
	preferential_value_temp NUMERIC;-- 优惠规则梯次值
	isaudit 			BOOLEAN;	-- 活动是否需要审核
	conditiontype int;    --优惠类型
	orderNo 			VARCHAR;
	favorable_id_temp 	int;		-- 优惠记录主键
	transaction_id_temp int;		-- 订单记录主键
	isAuditFavorable 	BOOLEAN:=TRUE;	-- 是否优惠稽核
	auditPoints 		NUMERIC;	-- 稽核点
	preferential_form_regular 	varchar:='regular_handsel';			-- 优惠形式:固定彩金
	type_effective_transaction 	VARCHAR:='effective_transaction';	-- 有效交易量的activity_type
	rule_total_transaction_ge 	varchar:='total_transaction_ge';	-- 优惠规则：总有效交易量
	preferential_condition VARCHAR;   --优惠条件

BEGIN
	-- 获取活动基本信息：需要站长审核状态，活动国际化名称
	SELECT is_audit, condition_type FROM activity_rule WHERE activity_message_id = activitymessageid INTO isaudit, conditiontype;
	SELECT * from gamebox_activityhall_query_activityname(activitymessageid) INTO activityname_json;
	raise info '活动是否需要审核:%, 活动条件:% 活动名称的JSON:%', isaudit, conditiontype, activityname_json;

	-- 获取该活动当前需要结算的所有申请玩家
	FOR rec_apply IN (SELECT * FROM activity_player_apply WHERE activity_message_id = activitymessageid AND check_state = '0' AND end_time <= CURRENT_TIMESTAMP)
	LOOP
		-- 计算玩家该申领周期内的总有效交易量
		SELECT gamebox_activityhall_calculator_effective_transaction(rec_apply.user_id,rec_apply.start_time,rec_apply.end_time,activitymessageid) INTO preferential_value_temp;
		raise notice '查询玩家的总有效交易量, 结果:%', preferential_value_temp;

		-- 计算玩家能获取的优惠奖励档次
		SELECT order_column
		  FROM activity_preferential_relation
		 WHERE activity_message_id = activitymessageid
		   AND preferential_code = rule_total_transaction_ge
		   AND preferential_value <= preferential_value_temp
		 ORDER BY order_column DESC
		 LIMIT 1 INTO order_num;

		order_num = COALESCE(order_num, 0);

		-- 满足任意档次，则生成相应的优惠信息
		IF 	order_num != 0 THEN
			raise info '开始计算玩家:%能获得的优惠， 获得的优惠档次为:%', rec_apply.user_id, order_num;

			--根据conditiontype生成条件:4-单次模式,5-闯关模式
			IF (conditiontype = 5) THEN
				preferential_condition = 'activity_message_id = ''' || activitymessageid || ''' AND order_column <= ''' || order_num  || '''';
			ELSE
				preferential_condition = 'activity_message_id = ''' || activitymessageid || ''' AND order_column = ''' || order_num || '''';
			END IF;
			-- 获取该优惠档次所有的优惠形式，目前只支持固定彩金，如有其他形式，需要考虑相应的业务逻辑
			raise info '优惠拼接条件:%', preferential_condition;
			FOR rec_way in EXECUTE 'SELECT * FROM activity_way_relation WHERE ' || preferential_condition
			LOOP
				-- 生成玩家活动优惠记录
				IF rec_way.preferential_form = preferential_form_regular THEN
					INSERT INTO activity_player_preferential(
						activity_player_apply_id,
						activity_message_id,
						preferential_form,
						preferential_value,
						preferential_audit
					) VALUES (
						rec_apply.id,
						rec_apply.activity_message_id,
						rec_way.preferential_form,
						rec_way.preferential_value,
						rec_way.preferential_audit
					);
				END IF;

				-- 根据是否提交站长审核进行不同的处理
				IF isaudit THEN
					-- 更新玩家优惠申请信息的状态: １-待处理, ２-成功, ３-失败
					UPDATE activity_player_apply set check_state = '1' WHERE id = rec_apply.id;
				ELSE
					-- 生成订单号
					orderNo := (SELECT f_order_no(siteCode, '02'));
					-- 赠送奖励是否设置了稽核
					IF rec_way.preferential_audit = NULL THEN
						isAuditFavorable = FALSE;
					ELSE
						auditPoints = rec_way.preferential_value * rec_way.preferential_audit;
					END IF;

					-- 更新玩家优惠申请信息为成功
					UPDATE activity_player_apply set check_state = '2' WHERE id = rec_apply.id;

					-- 自动生成优惠记录
					WITH favorable AS (
						INSERT INTO player_favorable(
							favorable,
							favorable_remark,
							is_audit_favorable,
							audit_favorable_multiple,
							activity_message_id,
							transaction_no,
							favorable_source,
							player_id,
							player_apply_id
						) VALUES (
							rec_way.preferential_value,
							'系统自动计算玩家参与优惠活动【有效交易量】',
							isAuditFavorable,
							rec_way.preferential_audit,
							activitymessageid,
							orderNo,
							'activity_favorable',
							rec_apply.user_id,
							rec_apply.id
						)
						RETURNING id
					)
					SELECT id FROM favorable INTO favorable_id_temp;

					-- 自动生成交易订单
					WITH playtransaction AS (
						INSERT INTO player_transaction(
							transaction_no,
							create_time,
							transaction_type,
							remark,
							transaction_money,
							balance,
							status,
							player_id,
							source_id,
							favorable_audit_points,
							is_satisfy_audit,
							is_clear_audit,
							fund_type,
							transaction_way,
							transaction_data,
							origin,
							rank_id,
							completion_time
						) VALUES (
							orderNo,
							now(),
							'favorable',
							'系统自动计算玩家参与优惠活动【有效交易量】',
							rec_way.preferential_value,
							rec_way.preferential_value + (SELECT wallet_balance FROM user_player WHERE id = rec_apply.user_id),
							'success',
							rec_apply.user_id,
							favorable_id_temp,
							auditPoints,
							false,
							false,
							'favourable',
							type_effective_transaction,
							activityname_json,
							'PC',
							(SELECT rank_id FROM user_player WHERE id = rec_apply.user_id),
							now()
						)
						RETURNING id
					)
					SELECT id FROM playtransaction INTO transaction_id_temp;

					-- 更新玩家优惠记录
					UPDATE player_favorable set player_transaction_id = transaction_id_temp WHERE id = favorable_id_temp;

					-- 修改玩家余额
					UPDATE user_player SET wallet_balance = COALESCE(wallet_balance,0) + rec_way.preferential_value WHERE id = rec_apply.user_id;

				END IF;
			END loop;
		ELSE	-- 不满足条件，更新申请状态
			UPDATE activity_player_apply SET check_state = '4' WHERE id = rec_apply.id;
		END IF;
	END loop;
END

$BODY$
  LANGUAGE 'plpgsql' VOLATILE COST 100
;

COMMENT ON FUNCTION "gamebox_activityhall_preferential_effecttransaction"(activitymessageid int4, sitecode varchar) IS '有效交易量活动计算';