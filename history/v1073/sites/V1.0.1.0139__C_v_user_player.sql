-- auto gen by admin 2016-05-07 22:06:59
-- auto gen by admin 2016-05-07 17:40:54
DROP VIEW v_user_top_agent_manage;
DROP VIEW v_user_player;

CREATE OR REPLACE VIEW "v_user_player" AS
 SELECT a.id,
    a.rank_id,
    a.total_assets,
    a.phone_code,
    a.wallet_balance,
    a.synchronization_time,
    a.special_focus,
    a.balance_type,
    a.balance_freeze_start_time,
    a.balance_freeze_end_time,
    a.freeze_code,
    a.balance_freeze_remark,
    b.account_freeze_remark,
    a.rakeback_id,
    a.level,
    a.ohter_contact_information,
    a.rakeback,
    a.backwash_total_amount,
    a.backwash_balance_amount,
    a.backwash_recharge_warn,
    a.transaction_syn_time,
    a.recharge_count,
    a.recharge_total,
    a.recharge_max_amount,
    a.withdraw_count AS tx_count,
    a.withdraw_total AS tx_total,
    a.level_lock,
    a.total_profit_loss,
    a.total_trade_volume,
    a.total_effective_volume,
    a.create_channel,
    a.mail_status,
    a.mobile_phone_status,
    a.is_first_recharge,
    a.manual_backwash_total_amount,
    a.manual_backwash_balance_amount,
    b.nickname,
    b.sex,
    b.constellation,
    b.birthday,
    b.country,
    b.region,
    b.city,
    b.nation,
    b.create_time,
    b.owner_id AS user_agent_id,
    b.default_currency,
    b.username,
    b.password,
    b.dept_id,
    b.status,
    b.freeze_type,
    b.freeze_start_time,
    b.freeze_end_time,
    b.freeze_code AS user_freeze_code,
    b.register_ip,
    b.owner_id AS agent_id,
    d.username AS agent_name,
    d.real_name AS agent_realname,
    f.username AS general_agent_name,
    f.id AS general_agent_id,
    f.real_name AS general_agent_realname,
    g.id AS on_line_id,
    b.real_name,
    b.default_locale,
    ( SELECT h.username
           FROM sys_user h
          WHERE (h.id = b.create_user)) AS create_user,
    ( SELECT count(1) AS remarkcount
           FROM remark player_remark
          WHERE (player_remark.entity_user_id = a.id)) AS remarkcount,
    ( SELECT count(1) AS tagcount
           FROM player_tag
          WHERE (player_tag.player_id = a.id)) AS tagcount,
    b.default_timezone,
    r.rank_name,
    r.risk_marker,
    ( SELECT way.contact_value
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '110'::text))
         LIMIT 1) AS mobile_phone,
    ( SELECT way.contact_value
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '201'::text))
         LIMIT 1) AS mail,
    ( SELECT way.contact_value
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '301'::text))
         LIMIT 1) AS qq,
    ( SELECT way.contact_value
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '302'::text))
         LIMIT 1) AS msn,
    ( SELECT way.contact_value
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '303'::text))
         LIMIT 1) AS skype,
    ( SELECT way.status
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '110'::text))
         LIMIT 1) AS mobile_phone_way_status,
    ( SELECT way.status
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '201'::text))
         LIMIT 1) AS mail_way_status,
    ( SELECT way.status
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '301'::text))
         LIMIT 1) AS qq_way_status,
    ( SELECT way.status
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '302'::text))
         LIMIT 1) AS msn_way_status,
    ( SELECT way.status
           FROM notice_contact_way way
          WHERE ((way.user_id = a.id) AND ((way.contact_type)::text = '303'::text))
         LIMIT 1) AS skype_way_status,
    ( SELECT array_to_string(ARRAY( SELECT t.remark_content
                   FROM remark t
                  WHERE ((t.entity_user_id = a.id) OR (t.operator_id = a.id))), '-'::text) AS array_to_string) AS remarks,
    rs.name AS rakeback_name
   FROM ((((((user_player a
     JOIN sys_user b ON ((a.id = b.id)))
     LEFT JOIN sys_user d ON ((b.owner_id = d.id)))
     LEFT JOIN sys_user f ON ((d.owner_id = f.id)))
     LEFT JOIN player_rank r ON ((a.rank_id = r.id)))
     LEFT JOIN sys_on_line_session g ON ((a.id = g.sys_user_id)))
     LEFT JOIN rakeback_set rs ON ((a.rakeback_id = rs.id)));


CREATE OR REPLACE VIEW v_user_top_agent_manage AS
 SELECT ua.id,
    su.username,
    su.nation,
    su.real_name,
    ( SELECT count(1) AS count
           FROM sys_user child
          WHERE child.owner_id = ua.id AND child.user_type::text = '23'::text) AS child_agent_num,
    ( SELECT count(1) AS count
           FROM v_user_player players
          WHERE (players.user_agent_id IN ( SELECT child.id
                   FROM sys_user child
                  WHERE child.owner_id = ua.id))) AS player_num,
    ( SELECT count(1) AS count
           FROM rebate_set rs
             JOIN user_agent_rebate uar ON uar.rebate_id = rs.id
          WHERE uar.user_id = su.id) AS rebatenum,
    ( SELECT count(1) AS count
           FROM rakeback_set rs
             JOIN user_agent_rakeback uarb ON uarb.rakeback_id = rs.id
          WHERE uarb.user_id = su.id) AS rakebacknum,
    su.default_locale,
    su.country,
    su.default_timezone,
    ctct.mobile_phone,
    ctct.mail,
    su.sex,
    su.birthday,
    ua.regist_code,
    ua.create_channel,
    su.create_time,
    su.register_ip,
    su.last_login_time,
    ctct.qq,
    ctct.msn,
    ctct.skype,
        CASE
            WHEN su.freeze_end_time >= now() AND su.freeze_start_time <= now() THEN '3'::character varying(5)
            ELSE su.status
        END AS status,
    su.freeze_end_time,
    su.freeze_start_time,
    su.region,
    su.constellation,
    ( SELECT array_to_string(ARRAY( SELECT t.remark_content
                   FROM remark t
                  WHERE t.entity_user_id = su.id), '-'::text) AS array_to_string) AS remark_content
   FROM user_agent ua
     JOIN ( SELECT sys_user.id,
            sys_user.username,
            sys_user.password,
            sys_user.dept_id,
            sys_user.status,
            sys_user.create_user,
            sys_user.create_time,
            sys_user.update_user,
            sys_user.update_time,
            sys_user.default_locale,
            sys_user.default_timezone,
            sys_user.subsys_code,
            sys_user.user_type,
            sys_user.built_in,
            sys_user.site_id,
            sys_user.owner_id,
            sys_user.freeze_type,
            sys_user.freeze_start_time,
            sys_user.freeze_end_time,
            sys_user.freeze_code,
            sys_user.login_time,
            sys_user.login_ip,
            sys_user.last_active_time,
            sys_user.use_line,
            sys_user.last_login_time,
            sys_user.last_login_ip,
            sys_user.total_online_time,
            sys_user.nickname,
            sys_user.real_name,
            sys_user.birthday,
            sys_user.sex,
            sys_user.constellation,
            sys_user.country,
            sys_user.nation,
            sys_user.register_ip,
            sys_user.avatar_url,
            sys_user.permission_pwd,
            sys_user.idcard,
            sys_user.default_currency,
            sys_user.register_site,
            sys_user.region,
            sys_user.city,
            sys_user.memo
           FROM sys_user
          WHERE sys_user.user_type::text = '22'::text AND sys_user.status::text < '5'::text) su ON ua.id = su.id
     LEFT JOIN ( SELECT ct.user_id,
            ct.mobile_phone,
            ct.mail,
            ct.qq,
            ct.msn,
            ct.skype
           FROM crosstab('SELECT user_id, contact_type,contact_value

	       FROM   notice_contact_way

	       ORDER  BY user_id,contact_type'::text, 'VALUES (''110''::text),  (''201''::text),  (''301''::text), (''302''::text), (''303''::text)'::text) ct(user_id integer, mobile_phone character varying, mail character varying, qq character varying, msn character varying, skype character varying)) ctct ON ua.id = ctct.user_id;



--修改存款时申请活动的函数
CREATE OR REPLACE FUNCTION "f_preferential_deposit"(activitymessageid int4, money numeric,playerid int4)
  RETURNS SETOF "pg_catalog"."record" AS $BODY$

declare

		rec	RECORD;--返回结果集
		order_num int;--满足的优惠档次
		startTime TIMESTAMP;--活动开始时间
		endTime TIMESTAMP;--活动结束时间
		status  VARCHAR;--活动审核状态
		activityType VARCHAR;--活动类型
		type_deposit_send VARCHAR := 'deposit_send';--存就送的activity_type
		type_first_deposit VARCHAR := 'first_deposit';--首存送送的activity_type
		activity_status_success VARCHAR := '1';--活动审核通过状态值
		playerRank int;--玩家层级
		activityRank VARCHAR;--活动参与层级
		isAllRank BOOLEAN;--是否全部层级
		tempActivityRank VARCHAR;--临时活动参与层级字符串
		tempPlayerRank VARCHAR;--临时玩家层级字符串

BEGIN

SELECT start_time,end_time,check_status,activity_type_code FROM activity_message WHERE id = activitymessageid INTO startTime,endTime,status,activityType;
raise info '活动开始时间为:%,结束时间为:%,当前审核状态为:%,活动类型为：%',startTime,endTime,status,activityType;

IF status != activity_status_success THEN
raise info '活动:%,未审核通过,立即结束计算.',activitymessageid;
RETURN;
END IF;

IF activityType != type_deposit_send AND activityType != type_first_deposit THEN
raise info '活动:%,不是存款类活动,立即结束计算.',activitymessageid;
RETURN;
END IF;

IF startTime > CURRENT_TIMESTAMP THEN
raise info '活动:%未开始,立即结束计算.',activitymessageid;
RETURN;
END IF;

IF endTime < CURRENT_TIMESTAMP THEN
raise info '活动:%已结束,立即结束计算.',activitymessageid;
RETURN;
END IF;

SELECT rank,is_all_rank FROM activity_rule WHERE activity_message_id=activitymessageid INTO activityRank,isAllRank;
SELECT rank_id FROM user_player WHERE id=playerid INTO playerRank;
IF  isAllRank=FALSE THEN
tempActivityRank = ',' || activityRank || ',';
tempPlayerRank =  ',' || playerRank || ',';
raise info '申请玩家层级:%,活动参与层级:%',tempPlayerRank,tempActivityRank;
IF position(tempPlayerRank in tempActivityRank) <=0 THEN
raise info '该玩家不能参与该活动';
RETURN;
END IF;
END IF;

select order_column from activity_preferential_relation where activity_message_id = activitymessageid and preferential_value <= money ORDER BY order_column DESC LIMIT 1 into order_num;
raise info '当前存款金额:%,满足的优惠档次为:%',money,COALESCE(order_num, 0);

FOR rec IN select T.preferential_form,T.preferential_value,T.preferential_audit from activity_way_relation  t where activity_message_id = activitymessageid  and order_column = COALESCE(order_num, 0)
loop
RETURN NEXT rec;
END loop;
RETURN;
END

$BODY$
  LANGUAGE 'plpgsql' VOLATILE COST 100
 ROWS 1000
;
COMMENT ON FUNCTION "f_preferential_deposit"(activitymessageid int4, money numeric) IS '存款优惠计算入口';
