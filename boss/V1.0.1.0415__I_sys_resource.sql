-- auto gen by cherry 2017-09-27 14:57:23
INSERT INTO "sys_resource" ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status")
SELECT '30618', '修改', '', '额度上限修改', '306', '', '16', 'boss', 'siteManage:quota', '2', '', 'f', 't', 't' WHERE NOT EXISTS(SELECT ID FROM sys_resource WHERE permission='siteManage:quota');