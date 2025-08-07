-- =============================================================================
-- CLUSTER UTILIZATION ALERT
-- =============================================================================
-- 
-- Purpose: Monitor cluster usage patterns and resource utilization
-- Category: Usage Monitoring
-- 
-- This alert monitors cluster performance and triggers when:
-- - Clusters are underutilized (wasting resources)
-- =============================================================================
-- USAGE
-- =============================================================================
-- 
-- Replace the following parameters:
-- - YOUR_WAREHOUSE_ID: Your SQL warehouse ID
-- - YOUR_EMAIL: Your email for notifications
-- - CLUSTER_UTILIZATION_TABLE: Your cluster metrics table
-- 
-- =============================================================================
-- Example: Monitor idle time on warehouses
SELECT {{CATALOG_NAME}}.{{SCHEMA_NAME}}.create_alert(
  display_name => '{{ALERT_NAME}}_alert',
  query_text => 'select * from {{CATALOG_NAME}}.{{SCHEMA_NAME}}.{{ALERT_NAME}}_summary_vw',
  warehouse_id => '{{WAREHOUSE_ID}}',
  comparison_operator => 'GREATER_THAN',
  threshold_value => {{THRESHOLD_VALUE}},
  user_email => '{{USER_EMAIL}}',
  cron_schedule => '{{CRON_SCHEDULE}}',
  source_display => '{{SOURCE_DISPLAY}}',
  source_name => '{{SOURCE_NAME}}',
  parent_path => '{{PARENT_PATH_ROOT}}{{PARENT_PATH_SUFFIX}}'
);
