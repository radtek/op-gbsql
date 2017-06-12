-- auto gen by cherry 2017-06-10 14:31:57
INSERT INTO "task_schedule" ("job_name", "alias_name", "job_group", "job_class", "job_method", "is_local", "status", "cronexpression", "is_sync", "description", "create_time", "update_time", "job_code", "is_system", "is_dynamic", "job_method_arg", "job_method_arg_class", "belong_to_idc")
SELECT 'B-apiId-24-OPUSCASINO-新增下单记录', NULL, NULL, 'so.wwb.gamebox.service.company.PlayerGameOrderFetchJob', 'execute', 't', '2', '0 2/4 * * * ?', 't', 'api任务', '2017-06-03 03:02:10.344033', NULL, 'b-api-24-I', 'f', 'f', '24', 'java.lang.Integer', 'B'
where not EXISTS (SELECT id FROM task_schedule where job_code='b-api-24-I');

INSERT INTO "task_schedule" ("job_name", "alias_name", "job_group", "job_class", "job_method", "is_local", "status", "cronexpression", "is_sync", "description", "create_time", "update_time", "job_code", "is_system", "is_dynamic", "job_method_arg", "job_method_arg_class", "belong_to_idc")
SELECT 'B-apiId-23-OPUSSPORT-新增下单记录', NULL, NULL, 'so.wwb.gamebox.service.company.PlayerGameOrderFetchJob', 'execute', 't', '2', '0 2/4 * * * ?', 't', 'api任务', '2017-06-03 03:02:10.344033', NULL, 'b-api-23-I', 'f', 'f', '23', 'java.lang.Integer', 'B'
where not EXISTS (SELECT id FROM task_schedule where job_code='b-api-23-I');

INSERT INTO "task_schedule" ("job_name", "alias_name", "job_group", "job_class", "job_method", "is_local", "status", "cronexpression", "is_sync", "description", "create_time", "update_time", "job_code", "is_system", "is_dynamic", "job_method_arg", "job_method_arg_class", "belong_to_idc")
SELECT 'A-apiId-24-OPUSCASINO-新增下单记录', NULL, NULL, 'so.wwb.gamebox.service.company.PlayerGameOrderFetchJob', 'execute', 't', '2', '0 1/4 * * * ?', 't', 'api任务', '2017-06-03 03:02:10.344033', NULL, 'a-api-24-I', 'f', 'f', '24', 'java.lang.Integer', 'A'
where not EXISTS (SELECT id FROM task_schedule where job_code='a-api-24-I');

INSERT INTO "task_schedule" ("job_name", "alias_name", "job_group", "job_class", "job_method", "is_local", "status", "cronexpression", "is_sync", "description", "create_time", "update_time", "job_code", "is_system", "is_dynamic", "job_method_arg", "job_method_arg_class", "belong_to_idc")
SELECT 'A-apiId-23-OPUSSPORT-新增下单记录', NULL, NULL, 'so.wwb.gamebox.service.company.PlayerGameOrderFetchJob', 'execute', 't', '2', '0 1/4 * * * ?', 't', 'api任务', '2017-06-03 03:02:10.344033', NULL, 'a-api-23-I', 'f', 'f', '23', 'java.lang.Integer', 'A'
where not EXISTS (SELECT id FROM task_schedule where job_code='a-api-23-I');