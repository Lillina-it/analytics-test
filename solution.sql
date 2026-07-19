WITH all_events AS (
    SELECT
        user_id,
        event,
        event_time,
        value,
        LAG(event_time) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS prev_time
    FROM logs
),

sessions AS (
    SELECT
        *,
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
    FROM all_events
),

template_events AS (
    SELECT
        user_id,
        session_id,
        event_time,
        value,
        LAG(value) OVER (
            PARTITION BY user_id, session_id
            ORDER BY event_time
        ) AS prev_template
    FROM sessions
    WHERE event = 'template_selected'
)

SELECT
    value AS template_name,
    COUNT(*) AS repeat_count
FROM template_events
WHERE value = prev_template
GROUP BY value
ORDER BY repeat_count DESC
LIMIT 5;
