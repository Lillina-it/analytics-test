WITH all_events AS (
    SELECT
        user_id,
        event,
        event_time,
        value,
        LAG(event_time) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS prev_event_time
    FROM logs
),

session_marks AS (
    SELECT
        *,
        CASE
            WHEN prev_event_time IS NULL
              OR event_time - prev_event_time > INTERVAL '5 minutes'
            THEN 1
            ELSE 0
        END AS new_session
    FROM all_events
),

sessions AS (
    SELECT
        *,
        SUM(new_session) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS session_id
    FROM session_marks
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
        ) AS prev_value
    FROM sessions
    WHERE event = 'template_selected'
)

SELECT
    value AS template_name,
    COUNT(*) AS repeat_count
FROM template_events
WHERE value = prev_value
GROUP BY value
ORDER BY repeat_count DESC
LIMIT 5;
