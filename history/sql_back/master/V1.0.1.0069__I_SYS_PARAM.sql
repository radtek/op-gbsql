-- auto gen by tom 2015-09-15 11:51:53
-- 偏好设置系统提示音系统参数值
INSERT INTO sys_param(module,param_type,param_code,param_value,default_value,order_num,remark,parent_code, active,site_id ) select 'setting', 'remind_project', 'deposit', '1#2', '1#2', 1, '存款', NULL, 't', NULL  where (select count(1) from sys_param where  module='setting' and param_type='remind_project' and param_code='deposit')<1;
INSERT INTO sys_param(module,param_type,param_code,param_value,default_value,order_num,remark,parent_code, active,site_id ) select 'setting', 'remind_project', 'draw', '1#2', '1#2', 1, '取款', NULL, 't', NULL  where (select count(1) from sys_param where  module='setting' and param_type='remind_project' and param_code='draw')<1;
INSERT INTO sys_param(module,param_type,param_code,param_value,default_value,order_num,remark,parent_code, active,site_id ) select 'setting', 'remind_project', 'audit', '1#2', '1#2', 1, '审批', NULL, 't', NULL  where (select count(1) from sys_param where  module='setting' and param_type='remind_project' and param_code='audit')<1;
INSERT INTO sys_param(module,param_type,param_code,param_value,default_value,order_num,remark,parent_code, active,site_id ) select 'setting', 'remind_project', 'warm', '1#2', '1#2', 1, '警告', NULL, 't', NULL  where (select count(1) from sys_param where  module='setting' and param_type='remind_project' and param_code='warm')<1;
INSERT INTO sys_param(module,param_type,param_code,param_value,default_value,order_num,remark,parent_code, active,site_id ) select 'setting', 'remind_project', 'notice', '1#2', '1#2', 1, '公告', NULL, 't', NULL  where (select count(1) from sys_param where  module='setting' and param_type='remind_project' and param_code='notice')<1;