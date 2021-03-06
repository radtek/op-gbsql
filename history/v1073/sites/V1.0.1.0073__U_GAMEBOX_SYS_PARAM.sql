-- auto gen by tom 2016-03-18 13:55:04
CREATE OR REPLACE FUNCTION "gamebox_sys_param"(paramtype text)
  RETURNS "hstore" AS $BODY$

DECLARE
	param 	text:='';
	hash 	hstore;
	rec 	record;
	sid 	INT;

BEGIN
	FOR rec IN SELECT param_code,case when param_value ='' then '0' when param_value is null then '0' else param_value end FROM sys_param WHERE param_type=$1
	LOOP
		param = param||rec.param_code||'=>'||rec.param_value||',';
	END LOOP;
	raise notice '结果:%',param;

	IF length(param) > 0 THEN
		param=substring(param, 1, length(param) - 1);
	END IF;

	SELECT param::hstore into hash;
  	--raise info '取得优惠值比例:%', hash->'topagent.rakeback.percent';
	SELECT gamebox_current_site() INTO sid;
	hash = hash||(SELECT ('site_id=>'||sid)::hstore);

	return hash;
END;

$BODY$
  LANGUAGE 'plpgsql' VOLATILE COST 100
;

ALTER FUNCTION "gamebox_sys_param"(paramtype text) OWNER TO "postgres";

COMMENT ON FUNCTION "gamebox_sys_param"(paramtype text) IS 'Lins-返佣-系统各种参数萃取';