-- =============================================================================
-- CREATE ALERT FUNCTION
-- =============================================================================
-- 
-- Purpose: Creates Databricks alerts using SQL queries with flexible configuration
-- API Reference: https://docs.databricks.com/api/workspace/alerts/create
-- 
-- This function allows DBAs to create monitoring alerts for:
-- - Data quality checks (null values, data freshness)
-- - Performance monitoring (slow queries, high resource usage)
-- - Error rate monitoring (application errors, system failures)
-- - Business metrics (record counts, aggregation thresholds)
-- 
-- =============================================================================
-- USAGE EXAMPLES
-- =============================================================================
-- 
-- Basic Alert (Count Monitoring):
-- %sql
-- select aa_catalog.dw_ops.create_alert(
--   display_name => 'high_error_rate_alert',
--   query_text => 'select 25 as error_count',
--   warehouse_id => '4b9b953939869799',
--   comparison_operator => 'GREATER_THAN',
--   threshold_value => 10,
--   user_email => 'akshay.amin@databricks.com',
--   cron_schedule => '0 */5 * * * ?',
--   source_display => 'error_count',
--   source_name => 'error_count',
--   parent_path => '/Workspace/Users/akshay.amin@databricks.com/offerings/dw_ops/dbsql_http/jobs'
-- );
-- 
-- =============================================================================
-- PARAMETER REFERENCE
-- =============================================================================
-- 
-- Required Parameters:
-- - display_name: Unique name for the alert
-- - query_text: SQL query that returns the value to monitor
-- - warehouse_id: SQL warehouse ID to run the query on
-- 
-- Optional Parameters (with defaults):
-- - comparison_operator: GREATER_THAN, LESS_THAN, EQUAL, etc. (default: GREATER_THAN)
-- - threshold_value: Numeric threshold to compare against (default: 0.0)
-- - user_email: Email for notifications (default: null)
-- - cron_schedule: Cron expression for evaluation schedule (default: '0 */15 * * * ?')
-- - source_display/name: Column alias from query_text (default: 'value')
-- - parent_path: Workspace path for alert location (default: '/Workspace/Users/')
-- 
-- =============================================================================

CREATE OR REPLACE FUNCTION create_alert(
  -- Required
  display_name STRING,
  query_text STRING,
  warehouse_id STRING,

  -- Alert config
  comparison_operator STRING DEFAULT 'GREATER_THAN',
  threshold_value DOUBLE DEFAULT 0.0,
  empty_result_state STRING DEFAULT 'UNKNOWN',

  -- Notification
  user_email STRING DEFAULT NULL,
  notify_on_ok BOOLEAN DEFAULT TRUE,
  retrigger_seconds INT DEFAULT 0,

  -- Schedule
  cron_schedule STRING DEFAULT '0 */15 * * * ?',
  timezone_id STRING DEFAULT 'UTC',
  pause_status STRING DEFAULT 'UNPAUSED',

  -- Optional
  parent_path STRING DEFAULT '/Workspace/Users/',
  source_aggregation STRING DEFAULT 'FIRST',
  source_display STRING DEFAULT 'value',
  source_name STRING DEFAULT 'value'
)
COMMENT 'Creates a Databricks alert with parameterized configuration. Uses JSON construction via structs.'
RETURN
WITH payload AS (
  SELECT
    to_json(
      named_struct(
        'display_name',         display_name,
        'query_text',           query_text,          -- safely escaped by to_json
        'parent_path',          parent_path,
        'warehouse_id',         warehouse_id,
        'evaluation', named_struct(
          'comparison_operator', comparison_operator,
          'empty_result_state',  empty_result_state,
          'notification', named_struct(
            'notify_on_ok',      notify_on_ok,
            'retrigger_seconds', retrigger_seconds,
            'subscriptions',
              CASE
                WHEN user_email IS NOT NULL
                  THEN array(named_struct('user_email', user_email))
                ELSE array()   -- empty array if no email
              END
          ),
          'source', named_struct(
            'aggregation', source_aggregation,
            'display',     source_display,
            'name',        source_name
          ),
          'threshold', named_struct(
            'value', named_struct('double_value', threshold_value)
          )
        ),
        'schedule', named_struct(
          'pause_status',         pause_status,
          'quartz_cron_schedule', cron_schedule,
          'timezone_id',          timezone_id
        )
      )
    ) AS json_body
)
SELECT
  http_request(
    conn   => 'databricks_api',
    method => 'POST',
    path   => '2.0/alerts',
    json   => json_body
  ).text AS resp
FROM payload;