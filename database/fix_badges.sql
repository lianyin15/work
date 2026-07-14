SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE badges;
SET FOREIGN_KEY_CHECKS=1;

INSERT INTO badges (name, description, icon, condition_type, condition_value) VALUES
    ('首次打卡', '完成第一次打卡', 'star', 'first_checkin', 1),
    ('持之以恒', '连续打卡 7 天', 'fire', 'streak_7', 7),
    ('坚如磐石', '连续打卡 30 天', 'diamond', 'streak_30', 30),
    ('打卡达人', '累计打卡 50 次', 'medal', 'total_50', 50),
    ('打卡王者', '累计打卡 100 次', 'crown', 'total_100', 100);
