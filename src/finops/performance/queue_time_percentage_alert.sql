SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'queue_time_percentage_alert',
  query_text => 'select * from aa_catalog.dw_ops.queue_time_summary_vw',
  warehouse_id => '4b9b953939869799',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 15, -- Alert if any warehouses are idle for more than 10 minutes
  user_email => 'akshay.amin@databricks.com',
  cron_schedule => '0 0 */1 * * ?', -- Every hour
  source_display => 'queue_time_percentage',
  source_name => 'queue_time_percentage',
  parent_path => '/Workspace/Users/akshay.amin@databricks.com/finops_alerts/usage_monitoring'
);
