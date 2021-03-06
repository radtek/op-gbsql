-- auto gen by cherry 2016-01-12 14:53:27
    select redo_sqls($$
      ALTER TABLE "activity_rule" ADD COLUMN "is_all_rank" bool;
      $$);

COMMENT ON COLUMN "activity_rule"."is_all_rank" IS '是否选择全部层级';

Drop view IF EXISTS v_activity_message;

CREATE OR REPLACE VIEW "v_activity_message" AS
  SELECT a.id,
    b.name,
    a.activity_state,
    a.start_time,
    a.end_time,
    a.activity_classify_key,
    c.activity_name,
    c.activity_version,
    a.is_display,
    c.activity_cover,
    ( SELECT count(1) AS count
      FROM activity_player_apply d
      WHERE ((d.activity_message_id = a.id) AND ((d.check_state)::text = '1'::text))) AS acount,
    b.code,
    c.activity_description,
    e.is_audit,
    b.logo,
    b.introduce,
    CASE
    WHEN (((a.start_time < now()) AND (a.end_time > now())) AND ((a.activity_state)::text <> 'draft'::text)) THEN 'processing'::text
    WHEN ((a.start_time > now()) AND ((a.activity_state)::text <> 'draft'::text)) THEN 'notStarted'::text
    WHEN ((a.end_time < now()) AND ((a.activity_state)::text <> 'draft'::text)) THEN 'finished'::text
    WHEN ((a.activity_state)::text = 'draft'::text) THEN 'notStarted'::text
    ELSE NULL::text
    END AS states,
    a.is_deleted,
    a.check_status,
    ((e.rank)::text || ','::text) AS rankid,
    a.create_time,
    e.preferential_amount_limit,
    e.is_all_rank
  FROM activity_message a
  LEFT JOIN activity_type b ON a.activity_type_code::text = (b.code)::text
          LEFT JOIN activity_message_i18n c ON c.activity_message_id = a.id
         LEFT JOIN activity_rule e ON e.activity_message_id = a.id;

ALTER TABLE "v_activity_message" OWNER TO "postgres";

COMMENT ON VIEW "v_activity_message" IS '优惠视图--eagle';