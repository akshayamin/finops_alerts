# FinOps Alerts

A comprehensive collection of SQL functions and alert configurations for Databricks FinOps monitoring and alerting.

## Overview

This repository contains SQL functions and configurations for creating Databricks alerts using the [Databricks SQL Alerts API](https://docs.databricks.com/aws/en/sql/user/alerts/). The solution provides a flexible, parameterized approach to creating monitoring alerts for FinOps use cases.

## Repository Structure

```
finops_alerts/
├── README.md                    # This file
├── src/                         # Source code
│   ├── functions/               # SQL functions
│   │   └── create_alert.sql     # Base alert creation function
│   └── finops/                  # FinOps specific alerts
│       ├── cost_monitoring/     # Cost-related alerts
│       ├── usage_monitoring/    # Usage-related alerts
│       └── performance/         # Performance-related alerts
├── deployment/                  # Deployment artifacts
│   ├── dabs/                    # DABs configuration
│   │   ├── config.yaml          # Main deployment config
│   │   ├── functions.yaml       # Functions deployment config
│   │   └── alerts.yaml          # Alerts deployment config
│   └── scripts/                 # Deployment scripts
└── docs/                        # Documentation
    ├── examples.md              # Usage examples
    └── deployment.md            # Deployment guide
```

## Features

- **Parameterized Alert Creation**: Create alerts with flexible configuration options
- **FinOps Focused**: Pre-built alert templates for cost, usage, and performance monitoring
- **DABs Integration**: Automated deployment using Databricks Asset Bundles
- **Comprehensive Documentation**: Detailed examples and deployment guides

## Quick Start

### 1. Deploy the Base Function

```bash
# Deploy the create_alert function
dabs deploy --target dev --config deployment/dabs/functions.yaml
```

### 2. Create Your First Alert

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
- [Databricks Asset Bundles (DABs)](https://docs.databricks.com/dev-tools/bundles/index.html)
- [Databricks SQL Functions](https://docs.databricks.com/sql/language-manual/sql-ref-functions-builtin.html)

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

See [deployment guide](docs/deployment.md) for detailed instructions on deploying alerts using DABs.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your alert configurations to the appropriate folder
4. Update documentation as needed
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [Databricks documentation](https://docs.databricks.com/)
- Review the [examples](docs/examples.md)
- Open an issue in this repository
