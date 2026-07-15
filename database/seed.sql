SET NAMES utf8mb4;
USE checkin_app;

INSERT INTO badges (name, description, icon, condition_type, condition_value) VALUES
    ('首次打卡', '完成第一次打卡', '🌱', 'first_checkin', 1),
    ('持之以恒', '连续打卡 7 天', '🔥', 'streak_7', 7),
    ('坚如磐石', '连续打卡 30 天', '💎', 'streak_30', 30),
    ('打卡达人', '累计打卡 50 次', '⭐', 'total_50', 50),
    ('打卡王者', '累计打卡 100 次', '👑', 'total_100', 100);

-- ====================================
-- 迁移：将已存在徽章的图标从文本更新为 Emoji
-- 新库已有正确图标，此语句仅对旧库生效
-- ====================================
UPDATE badges
SET icon = CASE condition_type
    WHEN 'first_checkin' THEN '🌱'
    WHEN 'streak_7' THEN '🔥'
    WHEN 'streak_30' THEN '💎'
    WHEN 'total_50' THEN '⭐'
    WHEN 'total_100' THEN '👑'
    ELSE icon
END
WHERE condition_type IN ('first_checkin', 'streak_7', 'streak_30', 'total_50', 'total_100');
