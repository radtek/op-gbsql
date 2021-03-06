-- auto gen by linsen 2018-07-11 16:44:37
-- 添加自定义图片启用/禁用状态 by linsen
DROP VIEW IF EXISTS v_site_api_type_relation;
CREATE OR REPLACE VIEW "v_site_api_type_relation" AS
 SELECT a1.id,
    a1.site_id,
    a1.api_id,
    a1.api_type_id,
    ( SELECT count(1) AS count
           FROM site_game a
          WHERE ((a.api_id = a1.api_id) AND (a.site_id = a1.site_id) AND (a.api_type_id = a1.api_type_id))) AS game_count,
    0 AS player_count,
    a1.status,
    a1.order_num,
    a1.mobile_order_num,
    a1.api_real_status,
    a1.api_status,
    a1.maintain_start_time,
    a1.maintain_end_time,
		a1.own_icon
   FROM ( SELECT s3.id,
            s3.site_id,
            s3.api_id,
            s3.api_type_id,
            s3.order_num,
            s3.mobile_order_num,
            s3.api_status,
            s3.maintain_end_time,
            s3.maintain_start_time,
            s3.api_real_status,
            s4.status,
						s4.own_icon
           FROM (( SELECT s1.id,
                    s1.site_id,
                    s1.api_id,
                    s1.api_type_id,
                    s1.order_num,
                    s1.mobile_order_num,
                    s2.status AS api_status,
                    s2.maintain_end_time,
                    s2.maintain_start_time,
                        CASE
                            WHEN ((s2.status)::text <> 'maintain'::text) THEN (s2.status)::text
                            ELSE
                            CASE
                                WHEN ((now() < s2.maintain_end_time) AND (now() > s2.maintain_start_time)) THEN 'maintain'::text
                                ELSE 'normal'::text
                            END
                        END AS api_real_status
                   FROM (site_api_type_relation s1
                     LEFT JOIN api s2 ON ((s1.api_id = s2.id)))) s3
             LEFT JOIN site_api s4 ON (((s3.api_id = s4.api_id) AND (s3.site_id = s4.site_id))))) a1;

COMMENT ON VIEW "v_site_api_type_relation" IS '站点API类型和API视图--river';