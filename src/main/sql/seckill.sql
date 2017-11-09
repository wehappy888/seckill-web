-- 秒杀存储过程
--定义分隔符
DELIMITER $$ -- console ; 转换为 $$

-- 定义存储过程
-- 参数: in　输入参数; out 输出参数
-- row_count():返回上一条修改类型的sql(delete,update,insert)的影响行数
-- row_count(): 0:未修改数据;>0 :表示修改的行数;<0:sql错误/未执行修改的sql
DROP PROCEDURE IF EXISTS `seckill`.`execute_seckill`;
CREATE PROCEDURE `seckill`.`execute_seckill`
  (in v_seckill_id bigint, in v_user_phone bigint, in v_kill_time TIMESTAMP ,out r_result int)

  BEGIN
    DECLARE insert_count int DEFAULT 0;
      START TRANSACTION;
      INSERT ignore INTO success_killed(seckill_id,user_phone,create_time,state) VALUES (v_seckill_id,v_user_phone,v_kill_time,0);

      SELECT ROW_COUNT() INTO insert_count;
      IF(insert_count = 0) THEN
        ROLLBACK ;
        SET r_result=-1;
      ELSEIF(insert_count < 0) THEN
        ROLLBACK ;
        SET r_result=-2;
      ELSE
        UPDATE seckill
        SET number = number-1
        WHERE seckill_id=v_seckill_id
        AND start_time <= v_kill_time
        AND end_time >= v_kill_time
        AND number > 0;

        SELECT ROW_COUNT() INTO insert_count;
        IF(insert_count <= 0) THEN
          ROLLBACK ;
          SET r_result = -2;
        ELSE
          COMMIT;
          SET r_result=1;
        END IF;
      END IF;
  END;
$$


DELIMITER ;
--初始化返回结果值为-3
SET @r_result=-3;

--执行存储过程
call execute_seckill(1003,13008888172,now(),@r_result);

--获取存储过程的返回结果
SELECT @r_result;

--查看存储过程的详细信息
show create PROCEDURE execute_seckill\G;

-- 存储过程
-- 存储过程优化的是事务行级锁持有的时间
-- 不要过度依赖存储过程, 简单的逻辑可以应用存储过程
-- QPS:一个秒杀单6000/qps

--删除存储过程
DROP PROCEDURE if EXISTS `seckill`.`execute_seckill`;