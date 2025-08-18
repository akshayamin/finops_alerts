# FinOps Alerts Examples

This guide provides comprehensive examples of how to use the FinOps alerts system for different monitoring scenarios.

## Quick Start Example

```sql
-- Simple test alert
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'test_alert',
  query_text => 'SELECT 25 as test_value',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 10,
  user_email => 'your-email@company.com'
);
```

## Cost Monitoring Examples

### 1. Daily Budget Threshold

```sql
-- Monitor daily spending against budget
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'daily_budget_alert',
  query_text => '
    SELECT 
      SUM(cost_usd) as daily_cost
    FROM cloud_costs 
    WHERE date = CURRENT_DATE()
      AND cloud_provider = ''AWS''
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 1000.0,
  user_email => 'finops@company.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'daily_cost',
  source_name => 'daily_cost'
);
```

### 2. Monthly Budget Utilization

```sql
-- Monitor monthly budget utilization percentage
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'monthly_budget_utilization',
  query_text => '
    SELECT 
      (SUM(cost_usd) / 5000.0) * 100 as budget_utilization_percent
    FROM cloud_costs 
    WHERE date >= DATE_TRUNC(''month'', CURRENT_DATE())
      AND date <= CURRENT_DATE()
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 80.0, -- 80% of monthly budget
  user_email => 'finops@company.com',
  cron_schedule => '0 0 12 */1 * ?', -- Daily at noon
  source_display => 'budget_utilization_percent',
  source_name => 'budget_utilization_percent'
);
```

### 3. Cost Spike Detection

```sql
-- Detect unusual cost increases
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'cost_spike_detection',
  query_text => '
    WITH daily_costs AS (
      SELECT 
        date,
        SUM(cost_usd) as daily_cost
      FROM cloud_costs 
      WHERE date >= DATE_SUB(CURRENT_DATE(), 7)
      GROUP BY date
    ),
    avg_cost AS (
      SELECT AVG(daily_cost) as avg_daily_cost
      FROM daily_costs
      WHERE date < CURRENT_DATE()
    )
    SELECT 
      (SELECT daily_cost FROM daily_costs WHERE date = CURRENT_DATE()) / 
      (SELECT avg_daily_cost FROM avg_cost) as cost_spike_ratio
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 2.0, -- 2x the average daily cost
  user_email => 'finops@company.com',
  cron_schedule => '0 0 18 */1 * ?', -- Daily at 6 PM
  source_display => 'cost_spike_ratio',
  source_name => 'cost_spike_ratio'
);
```

## Usage Monitoring Examples

### 1. Underutilized Clusters

```sql
-- Monitor clusters with low CPU utilization
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'underutilized_clusters',
  query_text => '
    SELECT 
      COUNT(*) as underutilized_cluster_count
    FROM cluster_metrics 
    WHERE date = CURRENT_DATE()
      AND avg_cpu_utilization < 20.0
      AND uptime_hours > 4
      AND cluster_state = ''RUNNING''
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'ops@company.com',
  cron_schedule => '0 0 */2 * * ?', -- Every 2 hours
  source_display => 'underutilized_cluster_count',
  source_name => 'underutilized_cluster_count'
);
```

### 2. Overutilized Clusters

```sql
-- Monitor clusters with high CPU utilization
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'overutilized_clusters',
  query_text => '
    SELECT 
      COUNT(*) as overutilized_cluster_count
    FROM cluster_metrics 
    WHERE date = CURRENT_DATE()
      AND avg_cpu_utilization > 90.0
      AND cluster_state = ''RUNNING''
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'ops@company.com',
  cron_schedule => '0 */15 * * * ?', -- Every 15 minutes
  source_display => 'overutilized_cluster_count',
  source_name => 'overutilized_cluster_count'
);
```

### 3. Idle Clusters

```sql
-- Monitor clusters that are idle
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'idle_clusters',
  query_text => '
    SELECT 
      COUNT(*) as idle_cluster_count
    FROM cluster_metrics 
    WHERE date = CURRENT_DATE()
      AND last_activity_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)
      AND cluster_state = ''RUNNING''
      AND avg_cpu_utilization < 5.0
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'ops@company.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'idle_cluster_count',
  source_name => 'idle_cluster_count'
);
```

## Performance Monitoring Examples

### 1. Slow Queries

```sql
-- Monitor queries taking longer than expected
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'slow_queries',
  query_text => '
    SELECT 
      COUNT(*) as slow_query_count
    FROM query_history 
    WHERE date = CURRENT_DATE()
      AND execution_time_seconds > 300  -- 5 minutes
      AND status = ''SUCCESS''
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'performance@company.com',
  cron_schedule => '0 */10 * * * ?', -- Every 10 minutes
  source_display => 'slow_query_count',
  source_name => 'slow_query_count'
);
```

### 2. Query Failure Rate

```sql
-- Monitor query failure rates
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'query_failure_rate',
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
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 5.0, -- 5% failure rate
  user_email => 'performance@company.com',
  cron_schedule => '0 */15 * * * ?', -- Every 15 minutes
  source_display => 'failure_rate_percent',
  source_name => 'failure_rate_percent'
);
```

### 3. High Resource Consumption

```sql
-- Monitor queries consuming excessive resources
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'high_resource_queries',
  query_text => '
    SELECT 
      COUNT(*) as high_resource_query_count
    FROM query_history 
    WHERE date = CURRENT_DATE()
      AND (cpu_time_seconds > 60 OR memory_gb > 10)
      AND status = ''SUCCESS''
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'performance@company.com',
  cron_schedule => '0 */30 * * * ?', -- Every 30 minutes
  source_display => 'high_resource_query_count',
  source_name => 'high_resource_query_count'
);
```

## Advanced Examples

### 1. Multi-Column Alert

```sql
-- Alert based on multiple conditions
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'complex_monitoring_alert',
  query_text => '
    SELECT 
      CASE 
        WHEN error_count > 100 AND response_time_avg > 5000 THEN 1 
        ELSE 0 
      END as alert_condition
    FROM system_metrics 
    WHERE date = CURRENT_DATE()
  ',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'EQUAL',
  threshold_value => 1,
  user_email => 'alerts@company.com',
  cron_schedule => '0 */5 * * * ?', -- Every 5 minutes
  source_display => 'alert_condition',
  source_name => 'alert_condition'
);
```

### 2. Trend-Based Alert

```sql
-- Alert based on trend analysis
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'performance_degradation',
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
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 150.0, -- 50% worse than historical average
  user_email => 'performance@company.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'performance_ratio',
  source_name => 'performance_ratio'
);
```

## Customization Tips

### 1. Notification Settings

```sql
-- Custom notification settings
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'custom_notification_alert',
  query_text => 'SELECT 1 as test_value',
  warehouse_id => 'your-warehouse-id',
  user_email => 'team@company.com',
  notify_on_ok => false,  -- Only notify on failures
  retrigger_seconds => 3600  -- Retrigger after 1 hour
);
```

### 2. Schedule Customization

```sql
-- Different schedules for different scenarios
-- Business hours only (9 AM - 5 PM, Monday-Friday)
cron_schedule => '0 0 9-17 ? * MON-FRI *'

-- Weekends only
cron_schedule => '0 0 */2 ? * SAT,SUN *'

-- Every 30 minutes during business hours
cron_schedule => '0 */30 9-17 ? * MON-FRI *'
```

### 3. Threshold Customization

```sql
-- Dynamic thresholds based on time of day
query_text => '
  SELECT 
    CASE 
      WHEN HOUR(CURRENT_TIMESTAMP()) BETWEEN 9 AND 17 THEN 100  -- Business hours
      ELSE 50  -- Off hours
    END as dynamic_threshold
  FROM dual
'
```

## Best Practices

1. **Start Simple**: Begin with basic alerts and gradually add complexity
2. **Test Thoroughly**: Always test alerts with sample data before production
3. **Monitor Alert Volume**: Avoid creating too many alerts that could cause notification fatigue
4. **Use Descriptive Names**: Choose clear, descriptive names for your alerts
5. **Document Queries**: Keep your monitoring queries well-documented
6. **Regular Review**: Periodically review and adjust alert thresholds based on actual usage patterns

## Troubleshooting

### Common Issues

1. **Query Returns No Results**: Ensure your query handles empty result sets
2. **Incorrect Data Types**: Make sure your query returns numeric values for comparison
3. **Timezone Issues**: Be aware of timezone differences in your cron schedules
4. **Permission Errors**: Verify you have the necessary permissions to create alerts

### Testing Your Alerts

```sql
-- Test your query first
SELECT * FROM your_monitoring_table WHERE date = CURRENT_DATE();

-- Test the alert function
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'test_alert',
  query_text => 'SELECT 1 as test_value',
  warehouse_id => 'your-warehouse-id',
  threshold_value => 0
);
``` 