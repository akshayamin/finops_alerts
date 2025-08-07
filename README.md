# FinOps Alerts

A comprehensive collection of SQL functions and alert configurations for Databricks FinOps monitoring and alerting.

## Overview

This repository contains SQL functions and configurations for creating Databricks alerts using the [Databricks SQL Alerts API](https://docs.databricks.com/aws/en/sql/user/alerts/). The solution provides a **template-based, configuration-driven approach** to creating monitoring alerts for FinOps use cases.

### 🎯 Key Benefits
- **🔧 Template Variables**: SQL files use `{{VARIABLE}}` placeholders that get replaced during deployment
- **⚙️ Configuration-Driven**: All parameters (warehouse IDs, emails, thresholds) come from YAML config
- **🌍 Environment-Agnostic**: Same SQL templates work for dev, staging, and production
- **🚀 Modern Python Tool**: Beautiful CLI with validation and error handling

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

- **🔧 Template-Based SQL**: SQL files use `{{VARIABLE}}` placeholders for complete parameterization
- **⚙️ Configuration-Driven**: All settings (warehouse IDs, emails, thresholds) managed via YAML
- **🌍 Environment-Agnostic**: Same templates work across dev, staging, and production
- **🚀 Modern Python Tool**: Beautiful CLI with validation, error handling, and colorful output
- **📊 FinOps Focused**: Pre-built alert templates for cost, usage, and performance monitoring
- **📚 Comprehensive Documentation**: Detailed examples and usage guides

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

### 3. Create Custom Alerts

The system uses **template variables** for complete flexibility:

```sql
-- Query file: src/finops/your_category/your_alert_query.sql
CREATE OR REPLACE VIEW {{CATALOG_NAME}}.{{SCHEMA_NAME}}.your_alert_summary_vw AS
SELECT COUNT(*) as error_count 
FROM error_logs 
WHERE error_date >= CURRENT_DATE() - interval '{{TIME_INTERVAL}} hours'
  AND warehouse_id = '{{WAREHOUSE_ID}}';

-- Alert file: src/finops/your_category/your_alert_alert.sql
SELECT {{CATALOG_NAME}}.{{SCHEMA_NAME}}.create_alert(
  display_name => '{{ALERT_NAME}}_alert',
  query_text => 'select * from {{CATALOG_NAME}}.{{SCHEMA_NAME}}.{{ALERT_NAME}}_summary_vw',
  warehouse_id => '{{WAREHOUSE_ID}}',
  threshold_value => {{THRESHOLD_VALUE}},
  user_email => '{{USER_EMAIL}}',
  cron_schedule => '{{CRON_SCHEDULE}}'
);
```

**All `{{VARIABLE}}` placeholders get automatically replaced with values from your YAML configuration!**

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
    # Database settings
    catalog_name: "aa_catalog"
    schema_name: "dw_ops"
    
    # Infrastructure settings
    warehouse_id: "4b9b953939869799"
    
    # Notification settings
    user_email: "akshay.amin@databricks.com"
    
    # Workspace settings
    parent_path_root: "/Workspace/Users/akshay.amin@databricks.com/"
    
    # Global query settings (can be overridden per alert)
    query_settings:
      time_interval_hours: 26
      default_statement_type: "SELECT"
    
alerts:
  idle_time:
    enabled: true                    # Enable/disable this alert
    category: "usage_monitoring"
    threshold_value: 10
    cron_schedule: "0 0 */1 * * ?"  # Every hour
    source_display: "idle_cluster_count"
    source_name: "idle_cluster_count"
    parent_path_suffix: "finops_alerts/usage_monitoring"
    description: "Monitors idle cluster count"
    # Optional: Override global query settings
    # query_settings:
    #   time_interval_hours: 48  # Override default 26 hours
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
- `_query.sql`: Creates a view with the monitoring query (uses template variables)
- `_alert.sql`: Creates the alert using the view (uses template variables)

### Template Variables

The SQL files use template variables that get replaced during deployment:

| **Template Variable** | **Purpose** | **Config Source** |
|----------------------|-------------|-------------------|
| `{{CATALOG_NAME}}` | Database catalog | `environments.[env].catalog_name` |
| `{{SCHEMA_NAME}}` | Database schema | `environments.[env].schema_name` |
| `{{WAREHOUSE_ID}}` | SQL warehouse ID | `environments.[env].warehouse_id` |
| `{{USER_EMAIL}}` | Notification email | `environments.[env].user_email` |
| `{{PARENT_PATH_ROOT}}` | Workspace path root | `environments.[env].parent_path_root` |
| `{{ALERT_NAME}}` | Alert name | From alert configuration |
| `{{THRESHOLD_VALUE}}` | Alert threshold | `alerts.[alert].threshold_value` |
| `{{CRON_SCHEDULE}}` | Evaluation schedule | `alerts.[alert].cron_schedule` |
| `{{TIME_INTERVAL}}` | Query time window | `environments.[env].query_settings.time_interval_hours` |
| `{{STATEMENT_TYPE}}` | SQL statement type | `environments.[env].query_settings.default_statement_type` |
| `{{SOURCE_DISPLAY}}` | Column display name | `alerts.[alert].source_display` |
| `{{SOURCE_NAME}}` | Column API name | `alerts.[alert].source_name` |
| `{{PARENT_PATH_SUFFIX}}` | Subfolder path | `alerts.[alert].parent_path_suffix` |

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

1. **Create the query file**: `src/finops/[category]/[alert_name]_query.sql`
   ```sql
   CREATE OR REPLACE VIEW {{CATALOG_NAME}}.{{SCHEMA_NAME}}.[alert_name]_summary_vw AS
   SELECT 
     your_metric_column
   FROM your_table
   WHERE compute.warehouse_id = '{{WAREHOUSE_ID}}'
     AND start_time >= current_timestamp() - interval '{{TIME_INTERVAL}} hours'
     AND statement_type = '{{STATEMENT_TYPE}}';
   ```

2. **Create the alert file**: `src/finops/[category]/[alert_name]_alert.sql`
   ```sql
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
   ```

3. **Add configuration to your config file**:
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
       # Optional: Override global query settings
       query_settings:
         time_interval_hours: 48  # Override default 26 hours
   ```

4. **Add to deployment list**:
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
- **🔧 Template Variable Replacement**: Automatically replaces `{{VARIABLE}}` placeholders with config values
- **🎨 Beautiful UI**: Rich, colorful output with tables and syntax highlighting
- **✅ Configuration Validation**: Comprehensive validation of YAML configuration
- **🛡️ Error Handling**: Robust error handling with clear error messages
- **🌍 Cross-Platform**: Works on Windows, Mac, and Linux
- **🤝 Interactive**: Confirms deployment before proceeding

### Commands
- `list-alerts`: Display all available alerts with their status
- `validate`: Validate configuration file for errors
- `deploy`: Deploy alerts to specified environment (with template variable replacement)

### Template Variable Replacement
During deployment, the tool automatically replaces template variables:
- `{{WAREHOUSE_ID}}` → Your warehouse ID from config
- `{{USER_EMAIL}}` → Your email from config
- `{{THRESHOLD_VALUE}}` → Alert threshold from config
- And many more...

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
