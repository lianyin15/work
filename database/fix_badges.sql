SET NAMES utf8mb4;
USE checkin_app;

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
