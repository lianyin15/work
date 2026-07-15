USE checkin_app;

SET @has_old_index = (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'checkins'
      AND index_name = 'uk_task_date'
);

SET @drop_old_index_sql = IF(
    @has_old_index > 0,
    'ALTER TABLE checkins DROP INDEX uk_task_date',
    'SELECT 1'
);
PREPARE drop_old_index_stmt FROM @drop_old_index_sql;
EXECUTE drop_old_index_stmt;
DEALLOCATE PREPARE drop_old_index_stmt;

SET @has_new_index = (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'checkins'
      AND index_name = 'uk_task_user_date'
);

SET @add_new_index_sql = IF(
    @has_new_index = 0,
    'ALTER TABLE checkins ADD UNIQUE KEY uk_task_user_date (task_id, user_id, checkin_date)',
    'SELECT 1'
);
PREPARE add_new_index_stmt FROM @add_new_index_sql;
EXECUTE add_new_index_stmt;
DEALLOCATE PREPARE add_new_index_stmt;
