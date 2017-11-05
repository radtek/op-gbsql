-- auto gen by marz 2017-11-02 15:51:03
INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT   '710', '系统工具', 'lotterySysTool/index.html', '系统工具', '7', NULL, '9', 'boss', 'lottery:systool', '1', NULL, 'f', 't', 't'  WHERE 710 NOT IN(SELECT id FROM sys_resource WHERE id=710);
INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT   '71001', '撤单（未结算）', 'lotterySysTool/cancelNoPayoutOrder.html', '撤单（未结算）', '710', '', '1', 'boss', 'lottery:cancleorder_nopayout', '2', '', 'f', 't', 't'  WHERE 71001 NOT IN(SELECT id FROM sys_resource WHERE id=71001);
INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT   '71002', '撤单（已结算）', 'lotterySysTool/cancelPayoutOrder.html', '撤单（已结算）', '710', '', '2', 'boss', 'lottery:cancleorder_payout', '2', '', 'f', 't', 't'  WHERE 71002 NOT IN(SELECT id FROM sys_resource WHERE id=71002);
INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT   '71003', '采集开奖号码', 'lotterySysTool/gatherOpenCode.html', '采集开奖号码', '710', '', '3', 'boss', 'lottery:gather_opencode', '2', '', 'f', 't', 't'  WHERE 71003 NOT IN(SELECT id FROM sys_resource WHERE id=71003);
INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT   '71004', '手动派彩', 'lotterySysTool/openLotteryResult.html', '手动派彩', '710', '', '4', 'boss', 'lottery:open_lotteryresult', '2', '', 'f', 't', 't'  WHERE 71004 NOT IN(SELECT id FROM sys_resource WHERE id=71004);
INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT   '71005', '手动重结', 'lotterySysTool/rePayout.html', '手动重结', '710', '', '5', 'boss', 'lottery:repayout_betorder', '2', '', 'f', 't', 't'  WHERE 71005 NOT IN(SELECT id FROM sys_resource WHERE id=71005);

INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT  '71006', '彩票维护', 'lotterySysTool/lotteryMaintain.html', '彩票维护', '710', '', '6', 'boss', 'lottery:lotterymaintain', '2', '', 'f', 't', 't' WHERE 71006 NOT IN(SELECT id FROM sys_resource WHERE id=71006);


INSERT INTO sys_resource ("id", "name", "url", "remark", "parent_id", "structure", "sort_num", "subsys_code", "permission", "resource_type", "icon", "privilege", "built_in", "status") SELECT  '70103', '彩票玩法管理', 'lottery/manage/changeLotteryGenre.html', '彩票玩法管理', '701', '', '3', 'boss', 'lottery:change_lotterygenre', '2', '', 'f', 't', 't'  WHERE 70103 NOT IN(SELECT id FROM sys_resource WHERE id=70103);





