USE test77;

#Задание 1
#клиенты, активные все 12 месяцев
USE test77;
SELECT
    ID_client,
    COUNT(DISTINCT DATE_FORMAT(data_new, '%Y-%m')) AS active_months
FROM transactions_excel1
WHERE data_new >= '2015-06-01'
  AND data_new < '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(data_new, '%Y-%m')) = 12;

USE test77;
# объединяем 
SELECT t.ID_client, c.Gender, c.Age, c.Count_city,
    COUNT(DISTINCT DATE_FORMAT(t.data_new, '%Y-%m')) AS active_months,
    COUNT(DISTINCT t.Id_check) AS operations_count,
    ROUND(SUM(t.Sum_payment), 2) AS total_sum_for_period,
    ROUND(SUM(t.Sum_payment) / COUNT(DISTINCT t.Id_check), 2) AS avg_check,
    ROUND(SUM(t.Sum_payment) / 12, 2) AS avg_monthly_sum
FROM transactions_excel1 AS t
JOIN customer_info AS c
    ON t.ID_client = c.Id_client
WHERE t.data_new >= '2015-06-01'
  AND t.data_new < '2016-06-01'
GROUP BY t.ID_client,   c.Gender,   c.Age,    c.Count_city
HAVING COUNT(DISTINCT DATE_FORMAT(t.data_new, '%Y-%m')) = 12
ORDER BY t.ID_client;

# Ответ: 1 клиент с ID 16052.

# Задание 2
USE test77;
# последний измененный запрос
WITH monthly AS (
    SELECT
        DATE_FORMAT(data_new, '%Y-%m') AS month_number,
        COUNT(DISTINCT Id_check) AS operations_count_month,
        COUNT(DISTINCT ID_client) AS clients_count_month,
        SUM(Sum_payment) AS sum_month
    FROM transactions_excel1
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY DATE_FORMAT(data_new, '%Y-%m')
),

year_total AS (
    SELECT
        COUNT(DISTINCT Id_check) AS operations_count_year,
        SUM(Sum_payment) AS sum_year
    FROM transactions_excel1
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
)

SELECT
    m.month_number,
    ROUND(m.sum_month / m.operations_count_month, 2) AS avg_check_month,
    ROUND(m.operations_count_month / m.clients_count_month, 2) AS avg_operations_per_client_month,
    ROUND(m.sum_month / m.clients_count_month, 2) AS avg_sum_per_client_month,
    m.operations_count_month,
    m.clients_count_month,
    ROUND(
        m.operations_count_month * 100.0 / y.operations_count_year,
        2
    ) AS operations_share_percent,

    ROUND(
        m.sum_month * 100.0 / y.sum_year,
        2
    ) AS sum_share_percent
FROM monthly AS m
CROSS JOIN year_total AS y
ORDER BY m.month_number;
#Запрос для 2e
USE test77;
WITH gender_month AS (SELECT        DATE_FORMAT(t.data_new, '%Y-%m') AS month_number,
        COALESCE(NULLIF(c.Gender, ''), 'NA') AS gender_group,
        COUNT(DISTINCT t.ID_client) AS clients_count,
        SUM(t.Sum_payment) AS gender_sum
    FROM transactions_excel1 AS t
    LEFT JOIN customer_info AS c
        ON t.ID_client = c.Id_client
    WHERE t.data_new >= '2015-06-01'
      AND t.data_new < '2016-06-01'
    GROUP BY DATE_FORMAT(t.data_new, '%Y-%m'), COALESCE(NULLIF(c.Gender, ''), 'NA')),
month_total AS (    SELECT        DATE_FORMAT(data_new, '%Y-%m') AS month_number, COUNT(DISTINCT ID_client) AS total_clients,
        SUM(Sum_payment) AS total_sum
    FROM transactions_excel1
    WHERE data_new >= '2015-06-01'  AND data_new < '2016-06-01' GROUP BY DATE_FORMAT(data_new, '%Y-%m'))
SELECT   gm.month_number,    gm.gender_group,    gm.clients_count,    ROUND(gm.clients_count * 100.0 / mt.total_clients, 2) AS clients_share_percent,
    ROUND(gm.gender_sum, 2) AS gender_sum,  ROUND(gm.gender_sum * 100.0 / mt.total_sum, 2) AS spending_share_percent
FROM gender_month AS gm JOIN month_total AS mt
    ON gm.month_number = mt.month_number
ORDER BY    gm.month_number,    gm.gender_group;
    
    #Задание 3
    #общий запрос за весь период: сумма покупок и количество операций по возрастным группам
    WITH base AS (
    SELECT        t.ID_client,        t.Id_check,        t.Sum_payment,
        CASE     WHEN c.Age IS NULL OR c.Age = 0 THEN 'NA'
            ELSE CONCAT(
                FLOOR(c.Age / 10) * 10,
                '-',
                FLOOR(c.Age / 10) * 10 + 9
            )
        END AS age_group
    FROM transactions_excel1 AS t
    LEFT JOIN customer_info AS c
        ON t.ID_client = c.Id_client
    WHERE t.data_new >= '2015-06-01'
      AND t.data_new < '2016-06-01'
)
SELECT    age_group,
    COUNT(DISTINCT ID_client) AS clients_count,
    COUNT(DISTINCT Id_check) AS operations_count,
    ROUND(SUM(Sum_payment), 2) AS total_sum,
    ROUND(SUM(Sum_payment) / COUNT(DISTINCT Id_check), 2) AS avg_check,
    ROUND(
        COUNT(DISTINCT Id_check) * 100.0 /
        (SELECT COUNT(DISTINCT Id_check) FROM base),
        2
    ) AS operations_share_percent,
    ROUND(
        SUM(Sum_payment) * 100.0 /
        (SELECT SUM(Sum_payment) FROM base),
        2
    ) AS sum_share_percent
FROM base
GROUP BY age_group
ORDER BY
    CASE
        WHEN age_group = 'NA' THEN 999
        ELSE CAST(SUBSTRING_INDEX(age_group, '-', 1) AS UNSIGNED)
    END;
    
    # запрос по кварталам
    WITH base AS (
    SELECT
        t.ID_client,
        t.Id_check,
        t.Sum_payment,
        CONCAT(YEAR(t.data_new), '-Q', QUARTER(t.data_new)) AS quarter_number,
        CASE
            WHEN c.Age IS NULL OR c.Age = 0 THEN 'NA'
            ELSE CONCAT(
                FLOOR(c.Age / 10) * 10,
                '-',
                FLOOR(c.Age / 10) * 10 + 9
            )
        END AS age_group
    FROM transactions_excel1 AS t
    LEFT JOIN customer_info AS c
        ON t.ID_client = c.Id_client
    WHERE t.data_new >= '2015-06-01'
      AND t.data_new < '2016-06-01'
),

quarter_total AS (
    SELECT
        quarter_number,
        COUNT(DISTINCT Id_check) AS total_operations,
        SUM(Sum_payment) AS total_sum
    FROM base
    GROUP BY quarter_number
)

SELECT
    b.quarter_number,
    b.age_group,
    COUNT(DISTINCT b.ID_client) AS clients_count,
    COUNT(DISTINCT b.Id_check) AS operations_count,
    ROUND(SUM(b.Sum_payment), 2) AS total_sum,
    ROUND(SUM(b.Sum_payment) / COUNT(DISTINCT b.Id_check), 2) AS avg_check,

    ROUND(
        COUNT(DISTINCT b.Id_check) * 100.0 / q.total_operations,
        2
    ) AS operations_share_percent,

    ROUND(
        SUM(b.Sum_payment) * 100.0 / q.total_sum,
        2
    ) AS sum_share_percent

FROM base AS b
JOIN quarter_total AS q
    ON b.quarter_number = q.quarter_number
GROUP BY
    b.quarter_number,
    b.age_group,
    q.total_operations,
    q.total_sum
ORDER BY
    b.quarter_number,
    CASE
        WHEN b.age_group = 'NA' THEN 999
        ELSE CAST(SUBSTRING_INDEX(b.age_group, '-', 1) AS UNSIGNED)
    END;