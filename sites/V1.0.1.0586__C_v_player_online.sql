-- auto gen by george 2017-11-03 15:41:11

CREATE OR REPLACE VIEW "v_player_online" AS
 SELECT s.id,
    s.username,
    s.real_name,
    s.login_time,
    s.login_ip,
    s.login_ip_dict_code,
    s.last_active_time,
    s.use_line,
    s.last_login_time,
    s.last_login_ip,
    s.last_login_ip_dict_code,
    s.total_online_time,
    string_agg(((pgl.game_id)::character varying)::text, ','::text) AS gameids,
    s.session_key,
    u.wallet_balance,
    u.freezing_funds_balance,
    u.rank_id,
    u.channel_terminal,
    s.terminal
   FROM ((user_player u
     JOIN sys_user s ON ((s.id = u.id)))
     LEFT JOIN player_game_log pgl ON (((pgl.user_id = s.id) AND ((pgl.session_key)::text = (s.session_key)::text))))
  WHERE s.session_key IS NOT NULL AND (s.login_time > s.last_logout_time OR s.last_logout_time IS NULL) AND s.last_active_time > (now() - '00:30:00'::interval)
  GROUP BY s.id, s.username, s.real_name, s.login_time, s.login_ip, s.login_ip_dict_code, s.last_active_time, s.use_line, s.last_login_time, s.last_login_ip, s.last_login_ip_dict_code, s.total_online_time, s.session_key, u.wallet_balance, u.freezing_funds_balance, u.rank_id, u.channel_terminal, s.terminal;