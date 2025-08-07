# FinOps Alerts

A comprehensive collection of SQL functions and alert configurations for Databricks FinOps monitoring and alerting.

## Overview

This repository contains SQL functions and configurations for creating Databricks alerts using the [Databricks SQL Alerts API](https://docs.databricks.com/aws/en/sql/user/alerts/). The solution provides a flexible, parameterized approach to creating monitoring alerts for FinOps use cases.

## Repository Structure

```
finops_alerts/
├── README.md                    # This file
├── deploy.py                    # Python deployment tool
├── requirements.txt             # Python dependencies
├── config/                      # Configuration files
│   └── deployment.yaml          # Main deployment configuration
├── src/                         # Source code
│   ├── functions/               # SQL functions
│   │   └── create_alert.sql     # Base alert creation function
│   └── finops/                  # FinOps specific alerts
│       ├── cost_monitoring/     # Cost-related alerts
│       ├── usage_monitoring/    # Usage-related alerts
│       └── performance/         # Performance-related alerts
└── docs/                        # Documentation
    └── examples.md              # Usage examples
```

## Features

- **Parameterized Alert Creation**: Create alerts with flexible configuration options
- **FinOps Focused**: Pre-built alert templates for cost, usage, and performance monitoring
- **Modern Python Tool**: Clean, cross-platform deployment tool with beautiful UI
- **Comprehensive Documentation**: Detailed examples and usage guides

## Quick Start

### 1. Python Deployment Tool (Recommended)

```bash
# Install dependencies
pip3 install -r requirements.txt

# List available alerts
python3 deploy.py list-alerts config/deployment.yaml

# Validate configuration
python3 deploy.py validate config/deployment.yaml

# Deploy alerts (alerts defined in config)
python3 deploy.py deploy dev config/deployment.yaml

# Deploy to different environment
python3 deploy.py deploy prod config/deployment-prod.yaml

# For different environments, create environment-specific config files:
# config/deployment-dev.yaml, config/deployment-prod.yaml, etc.
```

### 2. Manual Deployment

```bash
# Deploy just the base function manually
# Copy and paste the SQL from deploy.py output into Databricks SQL Editor
```

### 4. Create Custom Alerts

```sql
-- Example: Monitor high error rates
SELECT aa_catalog.dw_ops.create_alert(
  display_name => 'high_error_rate_alert',
  query_text => 'SELECT COUNT(*) as error_count FROM error_logs WHERE error_date >= CURRENT_DATE()',
  warehouse_id => 'your-warehouse-id',
  comparison_operator => 'GREATER_THAN',
  threshold_value => 10,
  user_email => 'your-email@company.com',
  cron_schedule => '0 */5 * * * ?'
);
```

## Documentation

- [Databricks SQL Alerts Documentation](https://docs.databricks.com/aws/en/sql/user/alerts/)
- [Databricks SQL Functions](https://docs.databricks.com/sql/language-manual/sql-ref-functions-builtin.html)
- [Examples](docs/examples.md) - Detailed usage examples

## Configuration

### Configuration Files

The deployment system uses YAML configuration files to manage environment-specific settings:

#### `config/deployment.yaml` (Main Configuration)
```yaml
# Deployment configuration
deployment:
  alerts_to_deploy:
    - idle_time
    - queue_time_percentage
    # - daily_spend  # Uncomment to include

environments:
  dev:
    warehouse_id: "4b9b953939869799"
    user_email: "akshay.amin@databricks.com"
    parent_path_root: "/Workspace/Users/akshay.amin@databricks.com/"
    
alerts:
  idle_time:
    enabled: true                    # Enable/disable this alert
    threshold_value: 10
    cron_schedule: "0 0 */1 * * ?"  # Every hour
    description: "Monitors idle cluster count"
```

#### `config/deployment-prod.yaml` (Production Example)
```yaml
# Deployment configuration
deployment:
  alerts_to_deploy:
    - idle_time
    - queue_time_percentage

environments:
  prod:
    warehouse_id: "prod-warehouse-id-67890"
    user_email: "finops-prod@company.com"
    parent_path_root: "/Workspace/Users/finops-prod@company.com/"
    
alerts:
  idle_time:
    enabled: true                    # Enable/disable this alert
    threshold_value: 5              # More sensitive
    cron_schedule: "0 */15 * * * ?" # Every 15 minutes
    description: "Monitors idle cluster count"
```

### Configuration Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `catalog_name` | Databricks catalog name | `"aa_catalog"` |
| `schema_name` | Databricks schema name | `"dw_ops"` |
| `warehouse_id` | SQL warehouse ID | `"4b9b953939869799"` |
| `user_email` | Notification email | `"finops@company.com"` |
| `parent_path_root` | Workspace path root | `"/Workspace/Users/finops/"` |
| `threshold_value` | Alert threshold | `10` |
| `cron_schedule` | Evaluation schedule | `"0 */15 * * * ?"` |
| `enabled` | Enable/disable alert | `true` or `false` |
| `source_display` | Column alias for display | `"error_count"` |
| `source_name` | Column alias for API | `"error_count"` |
| `description` | Human-readable description | `"Monitors idle cluster count"` |

## Alert Structure

Each FinOps alert consists of two files:
- `_query.sql`: Creates a view with the monitoring query
- `_alert.sql`: Creates the alert using the view

### Available Alerts

#### Performance Monitoring
- **queue_time_percentage**: Monitors query queue time percentage
  - Files: `src/finops/performance/queue_time_percentage_query.sql`, `queue_time_percentage_alert.sql`

#### Usage Monitoring
- **idle_time**: Monitors idle cluster time
  - Files: `src/finops/usage_monitoring/idle_time_query.sql`, `idle_time_alert.sql`

#### Cost Monitoring
- **daily_spend**: Monitors daily spending
  - Files: `src/finops/cost_monitoring/daily_spend_query.sql`, `daily_spend_alert.sql`

### Adding New Alerts

To add a new alert:

1. Create the query file: `src/finops/[category]/[alert_name]_query.sql`
2. Create the alert file: `src/finops/[category]/[alert_name]_alert.sql`
3. Add configuration to your config file:
   ```yaml
   alerts:
     your_alert_name:
       enabled: true
       category: "your_category"
       threshold_value: 10
       cron_schedule: "0 */15 * * * ?"
       source_display: "your_column_name"
       source_name: "your_column_name"
       parent_path_suffix: "finops_alerts/your_category"
       description: "A brief description of your alert"
   ```
4. Add to deployment list:
   ```yaml
   deployment:
     alerts_to_deploy:
       - your_alert_name
   ```

## Alert Types

### Cost Monitoring
- **Budget Threshold Alerts**: Monitor spending against budget limits
- **Cost Spike Detection**: Alert on unusual cost increases
- **Resource Cost Optimization**: Identify expensive resources

### Usage Monitoring
- **Cluster Utilization**: Monitor cluster usage patterns
- **Storage Growth**: Track storage consumption trends
- **User Activity**: Monitor user engagement and activity

### Performance Monitoring
- **Query Performance**: Monitor slow-running queries
- **Resource Contention**: Alert on resource bottlenecks
- **System Health**: Monitor overall system performance

## Configuration

### Required Parameters
- `display_name`: Unique name for the alert
- `query_text`: SQL query that returns the value to monitor
- `warehouse_id`: SQL warehouse ID to run the query on

### Optional Parameters
- `comparison_operator`: GREATER_THAN, LESS_THAN, EQUAL, etc.
- `threshold_value`: Numeric threshold to compare against
- `user_email`: Email for notifications
- `cron_schedule`: Cron expression for evaluation schedule
- `source_display/name`: Column alias from query_text
- `parent_path`: Workspace path for alert location

## Deployment

The Python deployment tool (`deploy.py`) provides a modern, cross-platform solution for deploying FinOps alerts:

### Features
- **Beautiful UI**: Rich, colorful output with tables and syntax highlighting
- **Configuration Validation**: Comprehensive validation of YAML configuration
- **Error Handling**: Robust error handling with clear error messages
- **Cross-Platform**: Works on Windows, Mac, and Linux
- **Interactive**: Confirms deployment before proceeding

### Commands
- `list-alerts`: Display all available alerts with their status
- `validate`: Validate configuration file for errors
- `deploy`: Deploy alerts to specified environment

For detailed examples, see [examples.md](docs/examples.md).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your alert configurations to the appropriate folder
4. Update configuration files as needed
5. Test with `python3 deploy.py validate config/deployment.yaml`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [Databricks documentation](https://docs.databricks.com/)
- Review the [examples](docs/examples.md)
- Open an issue in this repository
