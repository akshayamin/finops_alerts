# Deployment Guide

This guide explains how to deploy the FinOps alerts solution to your Databricks workspace.

## Prerequisites

1. **Databricks Workspace Access**: You need access to a Databricks workspace with SQL permissions
2. **SQL Warehouse**: A SQL warehouse must be available for running queries
3. **HTTP Connection**: The `aa_databricks_api` connection must be configured in your workspace
4. **Permissions**: You need permissions to create functions and alerts

## Quick Deployment

### Step 1: Deploy the Base Function

Run the simple deployment script:

```bash
./deploy_simple.sh
```

This will show you the SQL function that needs to be executed in your Databricks workspace.

### Step 2: Execute the Function in Databricks

1. Open your Databricks workspace
2. Navigate to **SQL Editor**
3. Copy and paste the SQL function from the deployment script output
4. Execute the function

The function will be created as `aa_catalog.dw_ops.create_alert`.

### Step 3: Create Your First Alert

After the function is deployed, you can create alerts using the examples provided in the `src/finops/` directory.

## Manual Deployment

If you prefer to deploy manually:

1. **Copy the Function**: Copy the content from `src/functions/create_alert.sql`
2. **Execute in SQL Editor**: Paste and execute in your Databricks SQL Editor
3. **Verify Deployment**: The function should be available as `aa_catalog.dw_ops.create_alert`

## Alert Examples

### Cost Monitoring

```sql
-- Monitor daily AWS spending
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'daily_budget_threshold_alert',
  query_text => 'SELECT SUM(cost_usd) as daily_cost FROM your_cost_table WHERE date = CURRENT_DATE()',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 1000.0,
  user_email => 'your-email@company.com',
  cron_schedule => '0 0 */1 * * ?'
);
```

### Usage Monitoring

```sql
-- Monitor underutilized clusters
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'underutilized_clusters_alert',
  query_text => 'SELECT COUNT(*) as underutilized_cluster_count FROM cluster_metrics WHERE avg_cpu_utilization < 20.0',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'your-email@company.com',
  cron_schedule => '0 0 */2 * * ?'
);
```

### Performance Monitoring

```sql
-- Monitor slow queries
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'slow_queries_alert',
  query_text => 'SELECT COUNT(*) as slow_query_count FROM query_history WHERE execution_time_seconds > 300',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 0,
  user_email => 'your-email@company.com',
  cron_schedule => '0 */10 * * * ?'
);
```

## Configuration

### Required Parameters

- `display_name`: Unique name for the alert
- `query_text`: SQL query that returns the value to monitor
- `warehouse_id`: SQL warehouse ID to run the query on

### Optional Parameters

- `comparison_operator`: GREATER_THAN, LESS_THAN, EQUAL, etc. (default: GREATER_THAN)
- `threshold_value`: Numeric threshold to compare against (default: 0.0)
- `user_email`: Email for notifications (default: null)
- `cron_schedule`: Cron expression for evaluation schedule (default: '0 */15 * * * ?')
- `source_display/name`: Column alias from query_text (default: 'value')
- `parent_path`: Workspace path for alert location (default: '/Workspace/Users/')

## Troubleshooting

### Common Issues

1. **Function Not Found**: Ensure the function was created successfully in the correct catalog/schema
2. **HTTP Connection Error**: Verify that `aa_databricks_api` connection is configured
3. **Permission Denied**: Check that you have the necessary permissions to create alerts
4. **Invalid Query**: Ensure your query returns a single value that can be compared against the threshold

### Verification

To verify the deployment:

```sql
-- Check if function exists
SHOW FUNCTIONS IN aa_catalog.dw_ops;

-- Test the function
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'test_alert',
  query_text => 'SELECT 1 as test_value',
  warehouse_id => 'YOUR_WAREHOUSE_ID',
  threshold_value => 0
);
```

## Advanced Deployment with DABs

For automated deployment using Databricks Asset Bundles (DABs):

1. Install DABs CLI: `brew install databricks/tap/databricks`
2. Configure bundle.yaml with your workspace details
3. Run: `databricks bundle deploy --target dev`

Note: DABs deployment requires additional configuration and may need workspace-specific setup.

## Support

For issues and questions:
- Check the [Databricks documentation](https://docs.databricks.com/)
- Review the [examples](examples.md)
- Open an issue in this repository 