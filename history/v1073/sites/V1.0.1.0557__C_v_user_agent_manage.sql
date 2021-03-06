-- auto gen by george 2017-10-14 18:05:56
CREATE OR REPLACE VIEW v_user_agent_manage AS
WITH ncw AS
(
 SELECT notice_contact_way.user_id,
    max( CASE notice_contact_way.contact_type
         WHEN '110'::text THEN notice_contact_way.contact_value
         ELSE NULL::character varying
         END::text) AS mobile_phone,
    max( CASE notice_contact_way.contact_type
         WHEN '201'::text THEN notice_contact_way.contact_value
         ELSE NULL::character varying
         END::text) AS mail,
    max( CASE notice_contact_way.contact_type
         WHEN '301'::text THEN notice_contact_way.contact_value
         ELSE NULL::character varying
         END::text) AS qq,
    max( CASE notice_contact_way.contact_type
         WHEN '302'::text THEN notice_contact_way.contact_value
         ELSE NULL::character varying
         END::text) AS msn,
    max( CASE notice_contact_way.contact_type
         WHEN '303'::text THEN notice_contact_way.contact_value
         ELSE NULL::character varying
         END::text) AS skype,
    max( CASE notice_contact_way.contact_type
         WHEN '304'::text THEN notice_contact_way.contact_value
         ELSE NULL::character varying
         END::text) AS weixin
   FROM notice_contact_way
  GROUP BY notice_contact_way.user_id )
SELECT
    ua.id,
    sua.username,
    sua.nation,
    sua.owner_id AS topagent_id,
    tau.username AS topagent_username,
    ua.parent_id,
    psu.username AS parent_username,
    sua.real_name,
    uaup.player_num,
    ( SELECT count(1) AS count
           FROM user_agent uag
             LEFT JOIN sys_user sus ON uag.id = sus.id
          WHERE (sus.status::text = ANY (ARRAY['1'::character varying::text, '3'::character varying::text])) AND uag.parent_id = ua.id) AS agent_num,
    pr.rank_name,
    rs.name AS rebate_name,
    rsb.name AS rakeback_name,
    ''::text AS quota_name,
    ua.account_balance,
    ua.total_rebate,
    sua.default_locale,
    sua.default_currency,
    sua.country,
    sua.default_timezone,
    sua.sex,
    sua.birthday,
    ua.regist_code,
    ua.create_channel,
    sua.create_time,
    sua.register_ip,
    sua.last_login_time,
    CASE
        WHEN sua.freeze_end_time >= now() AND sua.freeze_start_time <= now() THEN '3'::character varying
        ELSE sua.status
    END AS status,
    sua.freeze_end_time,
    sua.freeze_start_time,
    ua.player_rank_id,
    sua.region,
    uarb.rakeback_id,
    uar.rebate_id,
    ubc.bankcard_number,
    ( SELECT array_to_string(ARRAY( SELECT t.remark_content
                   FROM remark t
                  WHERE t.entity_user_id = sua.id), '-'::text) AS array_to_string) AS remark_content,
    sua.city,
    sua.built_in,
    uaup.recharge_player_count,
    uaup.recharge_player_total,
    uaup.withdraw_player_total,
    ncw.mobile_phone,
    ncw.mail,
    ncw.qq,
    ncw.msn,
    ncw.skype,
    ncw.weixin,
    ua.agent_rank,
    ua.parent_array,
    ua.add_sub_agent,
    ua.add_new_player
  FROM
    ( SELECT ua.id,
             COUNT(up.id) player_num,
             COALESCE( SUM( (up.recharge_count > 0)::int), 0) recharge_player_count,
             COALESCE( sum(up.recharge_total), 0) recharge_player_total,
             COALESCE( sum(up.withdraw_total), 0) withdraw_player_total
        FROM user_agent ua
          JOIN sys_user sua ON sua.user_type::text = '23'::text AND sua.status::text < '5'::text AND ua.id = sua.id
          LEFT JOIN user_player up ON up.user_agent_id = ua.id
       GROUP BY ua.id
    ) uaup
    LEFT JOIN user_agent ua ON uaup.id = ua.id
    LEFT JOIN sys_user sua ON sua.id = ua.id
    LEFT JOIN ncw ON ua.id = ncw.user_id
    LEFT JOIN player_rank pr ON ua.player_rank_id = pr.id
    LEFT JOIN user_agent_rebate uar ON uar.user_id = ua.id
    LEFT JOIN rebate_set rs ON uar.rebate_id = rs.id
    LEFT JOIN user_agent_rakeback uarb ON uarb.user_id = ua.id
    LEFT JOIN rakeback_set rsb ON uarb.rakeback_id = rsb.id
    LEFT JOIN user_bankcard ubc ON ubc.is_default = true AND ubc.user_id = ua.id
    LEFT JOIN sys_user psu ON ua.parent_id = psu.id
    LEFT JOIN sys_user tau ON tau.id = sua.owner_id;