-- auto gen by cherry 2017-06-08 19:53:02
INSERT INTO "lottery_gather_conf" ("id", "abbr_name", "name", "code", "type", "url", "method", "request_content_type", "response_content_type", "json_param")
SELECT '9', 'kai', '168开彩网', 'ahk3', 'k3', 'http://api.1680210.com/lotteryJSFastThree/getBaseJSFastThree.do?issue=20170608013&lotCode=10030', 'GET', 'JSON', 'JSON', NULL
WHERE not EXISTS(SELECT id FROM lottery_gather_conf where id=9);

INSERT INTO "lottery_gather_conf" ("id", "abbr_name", "name", "code", "type", "url", "method", "request_content_type", "response_content_type", "json_param")
SELECT '10', 'kai', '168开彩网', 'hbk3', 'k3', 'http://api.1680210.com/lotteryJSFastThree/getBaseJSFastThree.do?issue=20170608011&lotCode=10032', 'GET', 'JSON', 'JSON', NULL
WHERE not EXISTS(SELECT id FROM lottery_gather_conf where id=10);

INSERT INTO "lottery_gather_conf" ("id", "abbr_name", "name", "code", "type", "url", "method", "request_content_type", "response_content_type", "json_param")
SELECT '11', 'kai', '168开彩网', 'gxk3', 'k3', 'http://api.1680210.com/lotteryJSFastThree/getBaseJSFastThree.do?issue=170608008&lotCode=10026', 'GET', 'JSON', 'JSON', NULL
WHERE not EXISTS(SELECT id FROM lottery_gather_conf where id=11);
