-- auto gen by tom 2015-11-19 15:56:35
DROP VIEW IF EXISTS v_site_master_manage;

CREATE OR REPLACE VIEW "v_site_master_manage" AS
 SELECT su.id,
    su.username,
    su.nickname,
    su.sex,
    ( SELECT count(1) AS count
           FROM sys_site
          WHERE (sys_site.sys_user_id = su.id)) AS site_num,
    su.status,
    su.last_login_time,
    su.create_time,
    ctct.user_id,
    ctct.mobile_phone,
    ctct.mail,
    ctct.qq,
    ctct.msn,
    ctct.skype,
    ue.referrals,
    su.memo,
    su.last_login_ip,
    su.birthday,
    su.constellation,
    su.user_type,
    su.site_id,
    su.owner_id,
    su.freeze_type,
    su.freeze_start_time,
    su.freeze_end_time,
    ss.name,
    su.last_login_ip_dict_code,
    su.password
   FROM (((sys_user su
     LEFT JOIN user_extend ue ON ((su.id = ue.id)))
     LEFT JOIN sys_site ss ON ((su.site_id = ss.id)))
     LEFT JOIN ( SELECT ct.user_id,
            ct.mobile_phone,
            ct.mail,
            ct.qq,
            ct.msn,
            ct.skype
           FROM crosstab('SELECT user_id, contact_type,contact_value
	       FROM   notice_contact_way
	       ORDER  BY user_id,contact_type'::text, 'VALUES (''110''::text),  (''201''::text),  (''301''::text), (''302''::text), (''303''::text)'::text) ct(user_id integer, mobile_phone character varying, mail character varying, qq character varying, msn character varying, skype character varying)) ctct ON ((su.id = ctct.user_id)));

ALTER TABLE "v_site_master_manage" OWNER TO "postgres";

COMMENT ON VIEW v_site_master_manage  IS '站长管理 --tom';