CREATE DATABASE IF NOT EXISTS checkin_app DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE checkin_app;

CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    points INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tasks_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE checkins (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    checkin_date DATE NOT NULL,
    points INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_checkins_task FOREIGN KEY (task_id) REFERENCES tasks(id),
    CONSTRAINT fk_checkins_user FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY uk_task_user_date (task_id, user_id, checkin_date)
);

CREATE TABLE badges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NOT NULL,
    icon VARCHAR(50) NOT NULL DEFAULT '🏅',
    condition_type VARCHAR(30) NOT NULL,
    condition_value INT NOT NULL
);

CREATE TABLE user_badges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    badge_id BIGINT NOT NULL,
    earned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ub_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_ub_badge FOREIGN KEY (badge_id) REFERENCES badges(id),
    UNIQUE KEY uk_user_badge (user_id, badge_id)
);

-- ====================================
-- 迁移：将旧唯一索引 uk_task_date 升级为 uk_task_user_date
-- 新库已包含正确索引，此脚本仅对旧库生效
-- ====================================
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
