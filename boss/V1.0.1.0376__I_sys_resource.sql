-- auto gen by cherry 2017-07-08 09:23:49
INSERT INTO "sys_resource" ( "id","name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT '30614','免转钱包', '', '启用禁用免转钱包', '306', '', '12', 'boss', 'platform:site_auto_pay', '2', '', 'f', 't', 't' WHERE NOT EXISTS (SELECT id FROM sys_resource WHERE id='30614' AND name='免转钱包' AND parent_id='306' AND permission='platform:site_auto_pay');
INSERT INTO "sys_resource" ( "id","name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT '30615','现金取款', '', '启用禁用现金取款', '306', '', '13', 'boss', 'platform:site_is_cash', '2', '', 'f', 't', 't' WHERE NOT EXISTS (SELECT id FROM sys_resource WHERE id='30615' AND name='现金取款' AND parent_id='306' AND permission='platform:site_is_cash');
INSERT INTO "sys_resource" ( "id","name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT '30616','BTC取款', '', '启用禁用BTC取款', '306', '', '14', 'boss', 'platform:site_is_bitcoin', '2', '', 'f', 't', 't' WHERE NOT EXISTS (SELECT id FROM sys_resource WHERE id='30616' AND name='BTC取款' AND parent_id='306' AND permission='platform:site_is_bitcoin');