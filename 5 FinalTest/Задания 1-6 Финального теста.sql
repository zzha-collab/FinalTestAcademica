use new_schema;
SELECT *
FROM test
LIMIT 1000;

# 1 MAU
SELECT COUNT(DISTINCT user_id) AS MAU
FROM test WHERE date BETWEEN '2023-11-01' AND '2023-11-30';
# Ответ: 7639

# 2 DAU
SELECT ROUND(AVG(DAU), 2) AS average_DAU
FROM (SELECT date, COUNT(DISTINCT user_id) AS DAU
    FROM test GROUP BY date) AS daily_users;
# Ответ: 560

# 3 Retention
SELECT COUNT(DISTINCT day1.user_id) AS users_nov_1,
    COUNT(DISTINCT day2.user_id) AS returned_nov_2,
    ROUND(COUNT(DISTINCT day2.user_id) * 100.0 / COUNT(DISTINCT day1.user_id),
        2) AS retention_day_1
FROM (SELECT DISTINCT user_id
    FROM test WHERE date = '2023-11-01') AS day1
LEFT JOIN (SELECT DISTINCT user_id FROM test
    WHERE date = '2023-11-02') AS day2
    ON day1.user_id = day2.user_id;
# Ответ: 26,65%

# 5 Пользовательская конверсия
SELECT COUNT(DISTINCT user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN view_adverts > 0 THEN user_id 
    END) AS users_viewed_adverts,
    ROUND(COUNT(DISTINCT CASE WHEN view_adverts > 0 THEN user_id 
        END) * 100.0 / COUNT(DISTINCT user_id), 2
    ) AS conversion_percent
FROM test WHERE date >= '2023-11-01' AND date < '2023-12-01';

#Ответ: 46,31%

# 6 Среднее количесвто просмотренных объявлений в ноябре на пользователя
SELECT SUM(view_adverts) AS total_adverts_views,
    COUNT(DISTINCT user_id) AS total_users,
    ROUND(SUM(view_adverts) / COUNT(DISTINCT user_id), 2) AS avg_adverts_per_user
FROM test WHERE date >= '2023-11-01' AND date < '2023-12-01';

#Ответ: 2,87

