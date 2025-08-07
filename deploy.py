#!/usr/bin/env python3
"""
FinOps Alerts Deployment Tool
=============================

A modern Python-based deployment tool for Databricks FinOps alerts.

Usage:
    python3 deploy.py dev config/deployment.yaml
    python3 deploy.py --list-alerts config/deployment.yaml
    python3 deploy.py --validate config/deployment.yaml
"""

import yaml
import sys
import json
import os
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import click
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Confirm
from rich.syntax import Syntax

# Initialize Rich console for beautiful output
console = Console()

@dataclass
class AlertConfig:
    """Data class for alert configuration."""
    name: str
    enabled: bool
    category: str
    threshold_value: float
    cron_schedule: str
    source_display: str
    source_name: str
    parent_path_suffix: str
    description: str
    query_settings: Optional[Dict[str, Any]] = None

@dataclass
class EnvironmentConfig:
    """Data class for environment configuration."""
    catalog_name: str
    schema_name: str
    warehouse_id: str
    user_email: str
    parent_path_root: str

class ConfigError(Exception):
    """Custom exception for configuration errors."""
    pass

class DeploymentError(Exception):
    """Custom exception for deployment errors."""
    pass

class FinOpsDeployer:
    """Main deployment class for FinOps alerts."""
    
    def __init__(self, config_file: str):
        self.config_file = Path(config_file)
        self.config = self._load_config()
        self.console = Console()
    
    def _load_config(self) -> Dict[str, Any]:
        """Load and validate configuration file."""
        try:
            with open(self.config_file, 'r') as file:
                config = yaml.safe_load(file)
            
            if not config:
                raise ConfigError("Configuration file is empty")
            
            return config
        except FileNotFoundError:
            raise ConfigError(f"Configuration file not found: {self.config_file}")
        except yaml.YAMLError as e:
            raise ConfigError(f"Invalid YAML in configuration file: {e}")
    
    def _get_environment_config(self, target: str) -> EnvironmentConfig:
        """Get environment-specific configuration."""
        environments = self.config.get('environments', {})
        
        if target not in environments:
            available = list(environments.keys())
            raise ConfigError(f"Environment '{target}' not found. Available: {available}")
        
        env_config = environments[target]
        
        return EnvironmentConfig(
            catalog_name=env_config.get('catalog_name', 'aa_catalog'),
            schema_name=env_config.get('schema_name', 'dw_ops'),
            warehouse_id=env_config.get('warehouse_id'),
            user_email=env_config.get('user_email'),
            parent_path_root=env_config.get('parent_path_root')
        )
    
    def _get_alert_config(self, alert_name: str) -> AlertConfig:
        """Get alert-specific configuration."""
        alerts = self.config.get('alerts', {})
        
        if alert_name not in alerts:
            available = list(alerts.keys())
            raise ConfigError(f"Alert '{alert_name}' not found. Available: {available}")
        
        alert_config = alerts[alert_name]
        
        return AlertConfig(
            name=alert_name,
            enabled=alert_config.get('enabled', True),
            category=alert_config.get('category'),
            threshold_value=alert_config.get('threshold_value'),
            cron_schedule=alert_config.get('cron_schedule'),
            source_display=alert_config.get('source_display'),
            source_name=alert_config.get('source_name'),
            parent_path_suffix=alert_config.get('parent_path_suffix'),
            description=alert_config.get('description', 'No description'),
            query_settings=alert_config.get('query_settings')
        )
    
    def _get_deployment_alerts(self) -> List[str]:
        """Get list of alerts to deploy from configuration."""
        deployment = self.config.get('deployment', {})
        alerts_to_deploy = deployment.get('alerts_to_deploy', [])
        
        if not alerts_to_deploy:
            raise ConfigError("No alerts configured for deployment")
        
        return alerts_to_deploy
    
    def list_alerts(self):
        """Display all available alerts with their status."""
        alerts = self.config.get('alerts', {})
        
        if not alerts:
            self.console.print("❌ No alerts found in configuration", style="red")
            return
        
        # Create table
        table = Table(title="Available Alerts")
        table.add_column("Status", style="cyan", width=10)
        table.add_column("Alert Name", style="magenta", width=25)
        table.add_column("Category", style="blue", width=20)
        table.add_column("Description", style="green")
        
        for alert_name, config in alerts.items():
            status = "✅ ENABLED" if config.get('enabled', False) else "❌ DISABLED"
            category = config.get('category', 'unknown')
            description = config.get('description', 'No description')
            
            table.add_row(status, alert_name, category, description)
        
        self.console.print(table)
        
        # Show deployment info
        deployment_alerts = self._get_deployment_alerts()
        self.console.print(f"\n🎯 Alerts configured for deployment: {', '.join(deployment_alerts)}")
        self.console.print("\n💡 To deploy alerts, use:")
        self.console.print(f"   python3 deploy.py <target> {self.config_file}")
    
    def validate_config(self):
        """Validate configuration file for errors."""
        self.console.print("🔍 Validating configuration...")
        
        errors = []
        warnings = []
        
        # Check required sections
        required_sections = ['environments', 'alerts', 'deployment']
        for section in required_sections:
            if section not in self.config:
                errors.append(f"Missing required section: {section}")
        
        # Validate environments
        environments = self.config.get('environments', {})
        for env_name, env_config in environments.items():
            required_env_fields = ['warehouse_id', 'user_email', 'parent_path_root']
            for field in required_env_fields:
                if field not in env_config:
                    errors.append(f"Environment '{env_name}' missing required field: {field}")
        
        # Validate alerts
        alerts = self.config.get('alerts', {})
        for alert_name, alert_config in alerts.items():
            required_alert_fields = ['category', 'threshold_value', 'cron_schedule', 
                                   'source_display', 'source_name', 'parent_path_suffix']
            for field in required_alert_fields:
                if field not in alert_config:
                    errors.append(f"Alert '{alert_name}' missing required field: {field}")
        
        # Validate deployment
        deployment = self.config.get('deployment', {})
        if 'alerts_to_deploy' not in deployment:
            errors.append("Missing 'alerts_to_deploy' in deployment section")
        else:
            alerts_to_deploy = deployment['alerts_to_deploy']
            for alert_name in alerts_to_deploy:
                if alert_name not in alerts:
                    errors.append(f"Deployment references unknown alert: {alert_name}")
                elif not alerts[alert_name].get('enabled', False):
                    warnings.append(f"Deployment includes disabled alert: {alert_name}")
        
        # Report results
        if errors:
            self.console.print("❌ Configuration validation failed:", style="red")
            for error in errors:
                self.console.print(f"   • {error}", style="red")
            raise ConfigError("Configuration validation failed")
        
        if warnings:
            self.console.print("⚠️  Configuration warnings:", style="yellow")
            for warning in warnings:
                self.console.print(f"   • {warning}", style="yellow")
        
        self.console.print("✅ Configuration validation passed!", style="green")
    
    def _generate_function_sql(self, env_config: EnvironmentConfig) -> str:
        """Generate SQL for the create_alert function."""
        return f"""-- =============================================================================
-- CREATE ALERT FUNCTION
-- =============================================================================
-- 
-- Purpose: Creates Databricks alerts using SQL queries with flexible configuration
-- API Reference: https://docs.databricks.com/api/workspace/alerts/create
-- 
-- =============================================================================

create or replace function {env_config.catalog_name}.{env_config.schema_name}.create_alert(
  -- Required parameters
  display_name string,
  query_text string,
  warehouse_id string,
  
  -- Alert configuration
  comparison_operator string default 'GREATER_THAN',
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
  source_display string default null,
  source_name string default null
)
comment 'Creates a Databricks alert with parameterized configuration.'
return
select
  http_request(
    conn => 'aa_databricks_api',
    method => 'POST',
    path => '2.0/alerts',
    json => concat(
      '{{"display_name":"', display_name, '",',
      '"query_text":"', query_text, '",',
      '"parent_path":"', parent_path, '",',
      '"warehouse_id":"', warehouse_id, '",',
      '"evaluation":{{"comparison_operator":"', comparison_operator, '",',
      '"empty_result_state":"', empty_result_state, '",',
      '"notification":{{"notify_on_ok":', case when notify_on_ok then 'true' else 'false' end, ',"retrigger_seconds":', cast(retrigger_seconds as string), ',',
      '"subscriptions":[',
      case when user_email is not null then concat('{{"user_email":"', user_email, '"}}') else '' end,
      ']}}',
      ',"source":{{"aggregation":"', source_aggregation, '","display":"', coalesce(source_display, 'value'), '","name":"', coalesce(source_name, 'value'), '"}}',
      ',"threshold":{{"value":{{"double_value":', cast(threshold_value as string), '}}}}',
      ',"schedule":{{"pause_status":"', pause_status, '","quartz_cron_schedule":"', cron_schedule, '","timezone_id":"', timezone_id, '"}}'
    )
  ).text as resp;"""
    
    def _read_sql_file(self, file_path: str) -> str:
        """Read SQL file and replace placeholders."""
        sql_file = Path(file_path)
        
        if not sql_file.exists():
            raise DeploymentError(f"SQL file not found: {sql_file}")
        
        with open(sql_file, 'r') as file:
            content = file.read()
        
        return content
    
    def _replace_template_variables(self, sql_content: str, env_config: EnvironmentConfig, alert_config: AlertConfig, alert_name: str, environment: str) -> str:
        """Replace template variables in SQL content."""
        # Get query settings (global or alert-specific)
        global_query_settings = self.config.get('environments', {}).get(environment, {}).get('query_settings', {})
        alert_query_settings = alert_config.query_settings if alert_config.query_settings else {}
        
        # Merge settings (alert-specific overrides global)
        query_settings = {**global_query_settings, **alert_query_settings}
        
        # Build replacements dictionary
        replacements = {
            '{{CATALOG_NAME}}': env_config.catalog_name,
            '{{SCHEMA_NAME}}': env_config.schema_name,
            '{{WAREHOUSE_ID}}': env_config.warehouse_id,
            '{{USER_EMAIL}}': env_config.user_email,
            '{{PARENT_PATH_ROOT}}': env_config.parent_path_root,
            '{{ALERT_NAME}}': alert_name,
            '{{THRESHOLD_VALUE}}': str(alert_config.threshold_value),
            '{{CRON_SCHEDULE}}': alert_config.cron_schedule,
            '{{SOURCE_DISPLAY}}': alert_config.source_display,
            '{{SOURCE_NAME}}': alert_config.source_name,
            '{{PARENT_PATH_SUFFIX}}': alert_config.parent_path_suffix,
            '{{TIME_INTERVAL}}': str(query_settings.get('time_interval_hours', 26)),
            '{{STATEMENT_TYPE}}': query_settings.get('default_statement_type', 'SELECT')
        }
        
        # Replace all template variables
        for template_var, value in replacements.items():
            sql_content = sql_content.replace(template_var, value)
        
        return sql_content
    
    def _generate_alert_sql(self, env_config: EnvironmentConfig, alert_config: AlertConfig, alert_name: str, environment: str) -> str:
        """Generate SQL for creating an alert."""
        # Read the alert template file
        alert_file = f"src/finops/{alert_config.category}/{alert_name}_alert.sql"
        try:
            alert_sql = self._read_sql_file(alert_file)
            alert_sql = self._replace_template_variables(alert_sql, env_config, alert_config, alert_name, environment)
            return alert_sql
        except DeploymentError as e:
            # Fallback to generating SQL directly if template file not found
            parent_path = f"{env_config.parent_path_root}{alert_config.parent_path_suffix}"
            
            return f"""SELECT {env_config.catalog_name}.{env_config.schema_name}.create_alert(
  display_name => '{alert_name}_alert',
  query_text => 'select * from {env_config.catalog_name}.{env_config.schema_name}.{alert_name}_summary_vw',
  warehouse_id => '{env_config.warehouse_id}',
  comparison_operator => 'GREATER_THAN',
  threshold_value => {alert_config.threshold_value},
  user_email => '{env_config.user_email}',
  cron_schedule => '{alert_config.cron_schedule}',
  source_display => '{alert_config.source_display}',
  source_name => '{alert_config.source_name}',
  parent_path => '{parent_path}'
);"""
    
    def deploy_alerts(self, target: str):
        """Main deployment method."""
        self.console.print(Panel.fit("🚀 FinOps Alerts Deployment", style="bold blue"))
        
        # Validate configuration first
        self.validate_config()
        
        # Get configurations
        env_config = self._get_environment_config(target)
        deployment_alerts = self._get_deployment_alerts()
        
        self.console.print(f"🎯 Target: {target}")
        self.console.print(f"📁 Config: {self.config_file}")
        self.console.print(f"📊 Alerts: {', '.join(deployment_alerts)}")
        self.console.print()
        
        # Check for disabled alerts
        disabled_alerts = []
        for alert_name in deployment_alerts:
            alert_config = self._get_alert_config(alert_name)
            if not alert_config.enabled:
                disabled_alerts.append(alert_name)
        
        if disabled_alerts:
            self.console.print("⚠️  Warning: Some alerts are disabled:", style="yellow")
            for alert in disabled_alerts:
                self.console.print(f"   • {alert}", style="yellow")
            self.console.print()
        
        # Confirm deployment
        if not Confirm.ask("Do you want to proceed with the deployment?"):
            self.console.print("❌ Deployment cancelled", style="red")
            return
        
        try:
            # Step 1: Deploy function
            self.console.print("📦 Step 1: Deploying create_alert function...")
            function_sql = self._generate_function_sql(env_config)
            
            self.console.print("SQL to execute:")
            syntax = Syntax(function_sql, "sql", theme="monokai")
            self.console.print(syntax)
            self.console.print(f"💡 This will create: {env_config.catalog_name}.{env_config.schema_name}.create_alert")
            self.console.print()
            
            # Step 2: Deploy query views
            self.console.print("📊 Step 2: Deploying query views...")
            for alert_name in deployment_alerts:
                alert_config = self._get_alert_config(alert_name)
                
                if not alert_config.enabled:
                    self.console.print(f"⏭️  Skipping disabled alert: {alert_name}", style="yellow")
                    continue
                
                self.console.print(f"📋 Deploying query for: {alert_name}")
                
                query_file = f"src/finops/{alert_config.category}/{alert_name}_query.sql"
                try:
                    query_sql = self._read_sql_file(query_file)
                    query_sql = self._replace_template_variables(query_sql, env_config, alert_config, alert_name, target)
                    
                    syntax = Syntax(query_sql, "sql", theme="monokai")
                    self.console.print(syntax)
                except DeploymentError as e:
                    self.console.print(f"⚠️  {e}", style="yellow")
                
                self.console.print()
            
            # Step 3: Deploy alerts
            self.console.print("🔔 Step 3: Deploying alerts...")
            for alert_name in deployment_alerts:
                alert_config = self._get_alert_config(alert_name)
                
                if not alert_config.enabled:
                    self.console.print(f"⏭️  Skipping disabled alert: {alert_name}", style="yellow")
                    continue
                
                self.console.print(f"🔔 Deploying alert for: {alert_name}")
                
                alert_sql = self._generate_alert_sql(env_config, alert_config, alert_name, target)
                syntax = Syntax(alert_sql, "sql", theme="monokai")
                self.console.print(syntax)
                self.console.print()
            
            # Success message
            self.console.print("✅ Deployment instructions provided!", style="green")
            self.console.print("📝 Please execute the SQL statements in the order shown above:")
            self.console.print("   1. First deploy the create_alert function")
            self.console.print("   2. Then deploy the query views")
            self.console.print("   3. Finally deploy the alerts")
            
        except Exception as e:
            self.console.print(f"❌ Deployment failed: {e}", style="red")
            raise

@click.group()
def cli():
    """FinOps Alerts Deployment Tool"""
    pass

@cli.command()
@click.argument('config_file')
def list_alerts(config_file):
    """List available alerts in configuration file."""
    try:
        deployer = FinOpsDeployer(config_file)
        deployer.list_alerts()
    except Exception as e:
        console.print(f"❌ {e}", style="red")
        sys.exit(1)

@cli.command()
@click.argument('config_file')
def validate(config_file):
    """Validate configuration file."""
    try:
        deployer = FinOpsDeployer(config_file)
        deployer.validate_config()
    except Exception as e:
        console.print(f"❌ {e}", style="red")
        sys.exit(1)

@cli.command()
@click.argument('target')
@click.argument('config_file')
def deploy(target, config_file):
    """Deploy FinOps alerts using configuration file."""
    try:
        deployer = FinOpsDeployer(config_file)
        deployer.deploy_alerts(target)
    except Exception as e:
        console.print(f"❌ {e}", style="red")
        sys.exit(1)

if __name__ == "__main__":
    cli() 