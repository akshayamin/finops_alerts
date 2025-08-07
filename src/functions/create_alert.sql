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

create or replace function {{CATALOG_NAME}}.{{SCHEMA_NAME}}.create_alert(
  -- Required parameters
  display_name string,
  query_text string, -- Example: 'select count(*) as ct from my_table'
  warehouse_id string,
  
  -- Alert configuration
  comparison_operator string default 'GREATER_THAN', -- Options: GREATER_THAN, GREATER_THAN_OR_EQUAL, LESS_THAN, LESS_THAN_OR_EQUAL, EQUAL, NOT_EQUAL
  threshold_value double default 0.0,
  empty_result_state string default 'UNKNOWN',
  
  -- Notification settings
  user_email string default null,
  notify_on_ok boolean default true,
  retrigger_seconds int default 0,
  
  -- Schedule settings
  cron_schedule string default '0 */15 * * * ?',
  timezone_id string default 'UTC',
  pause_status string default 'UNPAUSED',
  
  -- Optional settings
  parent_path string default '/Workspace/Users/',
  source_aggregation string default 'FIRST',
  source_display string default null, -- Example: 'ct' (should match column alias in query_text)
  source_name string default null -- Example: 'ct' (should match column alias in query_text)
)
comment 'Creates a Databricks alert with parameterized configuration. Allows DBAs to create alerts using SQL queries with flexible notification and scheduling options.'
return
select
  http_request(
    conn => 'aa_databricks_api',
    method => 'POST',
    path => '2.0/alerts',
    json => concat(
      '{"display_name":"', display_name, '",',
      '"query_text":"', query_text, '",',
      '"parent_path":"', parent_path, '",',
      '"warehouse_id":"', warehouse_id, '",',
      '"evaluation":{"comparison_operator":"', comparison_operator, '",',
      '"empty_result_state":"', empty_result_state, '",',
      '"notification":{"notify_on_ok":', case when notify_on_ok then 'true' else 'false' end, ',"retrigger_seconds":', cast(retrigger_seconds as string), ',',
      '"subscriptions":[',
      case when user_email is not null then concat('{"user_email":"', user_email, '"}') else '' end,
      ']}',
      ',"source":{"aggregation":"', source_aggregation, '","display":"', coalesce(source_display, 'value'), '","name":"', coalesce(source_name, 'value'), '"}',
      ',"threshold":{"value":{"double_value":', cast(threshold_value as string), '}}}',
      ',"schedule":{"pause_status":"', pause_status, '","quartz_cron_schedule":"', cron_schedule, '","timezone_id":"', timezone_id, '"}}'
    )
  ).text as resp; 