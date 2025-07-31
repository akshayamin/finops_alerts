-- =============================================================================
-- QUERY PERFORMANCE ALERT
-- =============================================================================
-- 
-- Purpose: Monitor query performance and execution patterns
-- Category: Performance Monitoring
-- 
-- This alert monitors query performance and triggers when:
-- - Queries take longer than expected to execute
-- - High resource consumption queries are detected
-- - Query failures exceed thresholds
-- - Performance degradation is detected
-- 
-- =============================================================================
-- USAGE
-- =============================================================================
-- 
-- Replace the following parameters:
-- - YOUR_WAREHOUSE_ID: Your SQL warehouse ID
-- - YOUR_EMAIL: Your email for notifications
-- - QUERY_HISTORY_TABLE: Your query history/metrics table
-- 
-- =============================================================================

-- Example: Monitor slow queries (> 5 minutes execution time)
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'slow_queries_alert',
  query_text => '
    SELECT 
      COUNT(*) as slow_query_count
    FROM query_history 
    WHERE date = CURRENT_DATE()
      AND execution_time_seconds > 300  -- 5 minutes
      AND status = ''SUCCESS''
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0, -- Alert if any slow queries detected
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 */10 * * * ?', -- Every 10 minutes
  source_display => 'slow_query_count',
  source_name => 'slow_query_count',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/performance'
);

-- Example: Monitor query failure rate
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'query_failure_rate_alert',
  query_text => '
    WITH query_stats AS (
      SELECT 
        COUNT(*) as total_queries,
        COUNT(CASE WHEN status = ''FAILED'' THEN 1 END) as failed_queries
      FROM query_history 
      WHERE date = CURRENT_DATE()
        AND execution_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
    )
    SELECT 
      (failed_queries / total_queries) * 100 as failure_rate_percent
    FROM query_stats
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 5.0, -- 5% failure rate
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 */15 * * * ?', -- Every 15 minutes
  source_display => 'failure_rate_percent',
  source_name => 'failure_rate_percent',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/performance'
);

-- Example: Monitor high resource consumption queries
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'high_resource_queries_alert',
  query_text => '
    SELECT 
      COUNT(*) as high_resource_query_count
    FROM query_history 
    WHERE date = CURRENT_DATE()
      AND (cpu_time_seconds > 60 OR memory_gb > 10)
      AND status = ''SUCCESS''
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0, -- Alert if any high resource queries detected
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 */30 * * * ?', -- Every 30 minutes
  source_display => 'high_resource_query_count',
  source_name => 'high_resource_query_count',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/performance'
);

-- Example: Monitor average query execution time trend
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'query_performance_degradation_alert',
  query_text => '
    WITH current_avg AS (
      SELECT AVG(execution_time_seconds) as avg_execution_time
      FROM query_history 
      WHERE date = CURRENT_DATE()
        AND execution_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
        AND status = ''SUCCESS''
    ),
    historical_avg AS (
      SELECT AVG(execution_time_seconds) as avg_execution_time
      FROM query_history 
      WHERE date = DATE_SUB(CURRENT_DATE(), 1)
        AND execution_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 25 HOUR)
        AND execution_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
        AND status = ''SUCCESS''
    )
    SELECT 
      ((SELECT avg_execution_time FROM current_avg) / 
       (SELECT avg_execution_time FROM historical_avg)) * 100 as performance_ratio
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 150.0, -- 50% worse than historical average
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'performance_ratio',
  source_name => 'performance_ratio',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/performance'
);

-- Example: Monitor concurrent query load
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'high_concurrent_queries_alert',
  query_text => '
    SELECT 
      COUNT(*) as concurrent_queries
    FROM query_history 
    WHERE execution_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
      AND status IN (''RUNNING'', ''QUEUED'')
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 50, -- More than 50 concurrent queries
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 */5 * * * ?', -- Every 5 minutes
  source_display => 'concurrent_queries',
  source_name => 'concurrent_queries',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/performance'
); 