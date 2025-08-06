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
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'idle_clusters_alert',
  query_text => 'select * from aa_catalog.dw_ops.vw_idle_clusters_summary',
  warehouse_id => '4b9b953939869799',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 10, -- Alert if any warehouses are idle for more than 10 minutes
  user_email => 'akshay.amin@databricks.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'idle_cluster_count',
  source_name => 'idle_cluster_count',
  parent_path => '/Workspace/Users/akshay.amin@databricks.com/finops_alerts/usage_monitoring'
);
