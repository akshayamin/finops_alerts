-- =============================================================================
-- CLUSTER UTILIZATION ALERT
-- =============================================================================
-- 
-- Purpose: Monitor cluster usage patterns and resource utilization
-- Category: Usage Monitoring
-- 
-- This alert monitors cluster performance and triggers when:
-- - Clusters are underutilized (wasting resources)
-- - Clusters are overutilized (performance issues)
-- - Idle clusters are running unnecessarily
-- - Resource allocation is inefficient
-- 
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

-- Example: Monitor underutilized clusters (CPU < 20% for extended periods)
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'underutilized_clusters_alert',
  query_text => '
    SELECT 
      COUNT(*) as underutilized_cluster_count
    FROM cluster_metrics 
    WHERE date = CURRENT_DATE()
      AND avg_cpu_utilization < 20.0
      AND uptime_hours > 4
      AND cluster_state = ''RUNNING''
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0, -- Alert if any clusters are underutilized
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 0 */2 * * ?', -- Every 2 hours
  source_display => 'underutilized_cluster_count',
  source_name => 'underutilized_cluster_count',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/usage_monitoring'
);

-- Example: Monitor overutilized clusters (CPU > 90%)
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'overutilized_clusters_alert',
  query_text => '
    SELECT 
      COUNT(*) as overutilized_cluster_count
    FROM cluster_metrics 
    WHERE date = CURRENT_DATE()
      AND avg_cpu_utilization > 90.0
      AND cluster_state = ''RUNNING''
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0, -- Alert if any clusters are overutilized
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 */15 * * * ?', -- Every 15 minutes
  source_display => 'overutilized_cluster_count',
  source_name => 'overutilized_cluster_count',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/usage_monitoring'
);

-- Example: Monitor idle clusters (no activity for > 2 hours)
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'idle_clusters_alert',
  query_text => '
    SELECT 
      COUNT(*) as idle_cluster_count
    FROM cluster_metrics 
    WHERE date = CURRENT_DATE()
      AND last_activity_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)
      AND cluster_state = ''RUNNING''
      AND avg_cpu_utilization < 5.0
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0, -- Alert if any clusters are idle
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'idle_cluster_count',
  source_name => 'idle_cluster_count',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/usage_monitoring'
);

-- Example: Monitor storage growth trends
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'storage_growth_alert',
  query_text => '
    WITH storage_trend AS (
      SELECT 
        date,
        SUM(storage_gb) as total_storage_gb
      FROM cluster_metrics 
      WHERE date >= DATE_SUB(CURRENT_DATE(), 7)
      GROUP BY date
    ),
    growth_rate AS (
      SELECT 
        (MAX(total_storage_gb) - MIN(total_storage_gb)) / MIN(total_storage_gb) * 100 as growth_percent
      FROM storage_trend
    )
    SELECT growth_percent
    FROM growth_rate
  ',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 20.0, -- 20% growth in 7 days
  user_email => 'YOUR_EMAIL@company.com',
  cron_schedule => '0 0 9 */1 * ?', -- Daily at 9 AM
  source_display => 'growth_percent',
  source_name => 'growth_percent',
  parent_path => '/Workspace/Users/YOUR_USERNAME/finops_alerts/usage_monitoring'
); 