-- auto gen by Water 2017-07-04 11:48:57

--补leo脚本
DROP VIEW v_site_task_information;

CREATE VIEW v_site_task_information AS SELECT a.site_id,
                                         a.task_type,
                                         a.task_name,
                                         a.task_period,
                                         a.task_status,
                                         a.start_time,
                                         a.end_time,
                                         a.remark,
                                         a.is_effective,
                                         t.name,
                                         t.timezone,
                                         t.id
                                       FROM (sys_site t
                                         LEFT JOIN task_infomation a ON ((t.id = a.site_id)))
                                       WHERE ((a.is_effective = true) OR (a.is_effective IS NULL));

