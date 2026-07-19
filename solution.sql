WITH template_events AS (
    SELECT
        user_id,
        event_time,
        value,
        LAG(event_time) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS prev_time
    FROM logs
    WHERE event = 'template_selected'
),

sessions AS (
    SELECT *,
           SUM(
               CASE
                   WHEN prev_time IS NULL
                        OR event_time - prev_time > INTERVAL '5 minutes'
                   THEN 1
                   ELSE 0
               END
           ) OVER (
               PARTITION BY user_id
               ORDER BY event_time
           ) AS session_id
    FROM template_events
),

repeated_templates AS (
    SELECT *,
           LAG(value) OVER (
               PARTITION BY user_id, session_id
               ORDER BY event_time
           ) AS previous_template
    FROM sessions
)

SELECT
    value AS template_name,
    COUNT(*) AS repeat_count
FROM repeated_templates
WHERE value = previous_template
GROUP BY value
ORDER BY repeat_count DESC
LIMIT 5;
