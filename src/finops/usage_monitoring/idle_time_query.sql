CREATE OR REPLACE VIEW {{CATALOG_NAME}}.{{SCHEMA_NAME}}.vw_idle_clusters_summary AS
WITH queries_per_min AS (
  WITH raw_scaling AS (
    SELECT 
      query_min AS event_minute,
      count(*) AS query_count
    FROM (
      WITH base_query AS (
        SELECT 
          w.statement_id,
          date_trunc('MINUTE', w.start_time) AS start_min, 
          date_trunc('MINUTE', w.end_time) AS end_min
        FROM system.query.history w
        WHERE w.compute.warehouse_id = '{{WAREHOUSE_ID}}'
          AND w.start_time >= current_timestamp() - interval '{{TIME_INTERVAL}} hours'
      )
      SELECT 
        statement_id, 
        explode(sequence(start_min, end_min, INTERVAL 1 MINUTE)) AS query_min
      FROM base_query
    )
    GROUP BY query_min
  ),
  full_series AS (
    SELECT explode(sequence(
      (SELECT MIN(event_minute) FROM raw_scaling),
      (SELECT MAX(event_minute) FROM raw_scaling),
      INTERVAL 1 MINUTE
    )) AS minuteChunk
  ),
  filled_in_series AS (
    SELECT 
      spine.minuteChunk AS event_minute,
      COALESCE(SUM(s2.query_count), 0) AS NumberOfQueries
    FROM full_series AS spine
    LEFT JOIN raw_scaling AS s2 
      ON date_trunc('minute', s2.event_minute) = spine.minuteChunk
    GROUP BY spine.minuteChunk
  )
  SELECT 
    event_minute,
    LAST_VALUE(NumberOfQueries, true) OVER (ORDER BY event_minute) AS NumberOfQueries
  FROM filled_in_series
),
clusters_per_min AS (
  WITH raw_scaling AS (
    SELECT 
      date_trunc('MINUTE', event_time) AS event_minute,
      MAX(w.cluster_count) AS clusters
    FROM system.compute.warehouse_events w
    WHERE warehouse_id = '{{WAREHOUSE_ID}}'
      AND event_type IN ('RUNNING', 'SCALED_UP', 'SCALED_DOWN', 'STOPPED')
    GROUP BY date_trunc('MINUTE', event_time)
  ),
  full_series AS (
    SELECT explode(sequence(
      (SELECT MIN(event_minute) FROM raw_scaling),
      (SELECT MAX(event_minute) FROM raw_scaling),
      INTERVAL 1 MINUTE
    )) AS minuteChunk
  ),
  filled_in_series AS (
    SELECT 
      spine.minuteChunk AS event_minute,
      MAX(s2.clusters) AS NumberOfClustersOn
    FROM full_series AS spine
    LEFT JOIN raw_scaling AS s2 
      ON date_trunc('minute', s2.event_minute) = spine.minuteChunk
    GROUP BY spine.minuteChunk
  )
  SELECT 
    event_minute,
    LAST_VALUE(NumberOfClustersOn, true) OVER (ORDER BY event_minute) AS NumberOfClustersOn
  FROM filled_in_series
)
SELECT 
  SUM(CASE 
        WHEN c.NumberOfClustersOn > 0 AND q.NumberOfQueries = 0 
        THEN NumberOfClustersOn 
        ELSE 0 
      END) AS idle_cluster_count
FROM clusters_per_min c
INNER JOIN queries_per_min q
  ON c.event_minute = q.event_minute;