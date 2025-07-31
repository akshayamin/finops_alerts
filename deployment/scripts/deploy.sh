#!/bin/bash

# =============================================================================
# FINOPS ALERTS DEPLOYMENT SCRIPT
# =============================================================================
# 
# Purpose: Automated deployment script for FinOps alerts using DABs
# 
# Usage:
#   ./deploy.sh [target] [config] [options]
# 
# Examples:
#   ./deploy.sh dev functions.yaml
#   ./deploy.sh prod alerts.yaml --enable-cost-alerts
#   ./deploy.sh staging config.yaml --enable-all-alerts
# 
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DABS_CONFIG_DIR="$PROJECT_ROOT/dabs"

# Default values
TARGET=""
CONFIG=""
ENABLE_COST_ALERTS=false
ENABLE_USAGE_ALERTS=false
ENABLE_PERFORMANCE_ALERTS=false
DRY_RUN=false

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [target] [config] [options]"
    echo ""
    echo "Arguments:"
    echo "  target    Deployment target (dev|staging|prod) [default: dev]"
    echo "  config    DABs configuration file [default: config.yaml]"
    echo ""
    echo "Options:"
    echo "  --enable-cost-alerts       Enable cost monitoring alerts"
    echo "  --enable-usage-alerts      Enable usage monitoring alerts"
    echo "  --enable-performance-alerts Enable performance monitoring alerts"
    echo "  --enable-all-alerts        Enable all alert categories"
    echo "  --dry-run                  Show what would be deployed without executing"
    echo "  --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 dev functions.yaml"
    echo "  $0 prod alerts.yaml --enable-cost-alerts"
    echo "  $0 staging config.yaml --enable-all-alerts"
}

# Function to validate target
validate_target() {
    local target=$1
    case $target in
        dev|staging|prod)
            return 0
            ;;
        *)
            print_error "Invalid target: $target. Must be dev, staging, or prod."
            return 1
            ;;
    esac
}

# Function to validate config file
validate_config() {
    local config=$1
    local config_path="$DABS_CONFIG_DIR/$config"
    
    if [[ ! -f "$config_path" ]]; then
        print_error "Configuration file not found: $config_path"
        return 1
    fi
    
    return 0
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if databricks CLI is installed
    if ! command -v databricks &> /dev/null; then
        # Try to find it in common locations
        if [[ -f "/opt/homebrew/Cellar/databricks/0.262.0/bin/databricks" ]]; then
            export PATH="/opt/homebrew/Cellar/databricks/0.262.0/bin:$PATH"
        else
            print_error "Databricks CLI is not installed. Please install it first."
            print_info "Installation guide: https://docs.databricks.com/dev-tools/bundles/index.html"
            exit 1
        fi
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/README.md" ]]; then
        print_warning "README.md not found in project root, but continuing..."
    fi
    
    print_success "Prerequisites check passed"
}

# Function to set environment variables
set_environment_variables() {
    print_info "Setting environment variables for target: $TARGET"
    
    # Load environment-specific variables
    local env_file="$PROJECT_ROOT/.env.$TARGET"
    if [[ -f "$env_file" ]]; then
        print_info "Loading environment variables from $env_file"
        export $(cat "$env_file" | grep -v '^#' | xargs)
    else
        print_warning "Environment file not found: $env_file"
        print_info "Please ensure required environment variables are set:"
        echo "  - DATABRICKS_HOST"
        echo "  - ${TARGET}_WAREHOUSE_ID"
        echo "  - ${TARGET}_ALERT_OWNER"
        echo "  - ${TARGET}_NOTIFICATION_EMAIL"
    fi
}

# Function to build deployment command
build_deploy_command() {
    local cmd="cd $PROJECT_ROOT && databricks bundle deploy --target $TARGET"
    
    # Add alert enablement flags
    if [[ "$ENABLE_COST_ALERTS" == true ]]; then
        cmd="$cmd --var enable_cost_alerts=true"
    fi
    
    if [[ "$ENABLE_USAGE_ALERTS" == true ]]; then
        cmd="$cmd --var enable_usage_alerts=true"
    fi
    
    if [[ "$ENABLE_PERFORMANCE_ALERTS" == true ]]; then
        cmd="$cmd --var enable_performance_alerts=true"
    fi
    
    # Add dry run flag
    if [[ "$DRY_RUN" == true ]]; then
        cmd="$cmd --dry-run"
    fi
    
    echo "$cmd"
}

# Function to deploy
deploy() {
    print_info "Starting deployment..."
    print_info "Target: $TARGET"
    print_info "Config: $CONFIG"
    
    # Build deployment command
    local deploy_cmd=$(build_deploy_command)
    print_info "Deployment command: $deploy_cmd"
    
    # Execute deployment
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN - No actual deployment will be performed"
        print_info "Would run: $deploy_cmd"
    else
        print_info "Executing deployment..."
        if eval "$deploy_cmd"; then
            print_success "Deployment completed successfully!"
        else
            print_error "Deployment failed!"
            exit 1
        fi
    fi
}

# Function to show deployment summary
show_summary() {
    echo ""
    print_info "Deployment Summary:"
    echo "  Target: $TARGET"
    echo "  Config: $CONFIG"
    echo "  Cost Alerts: $ENABLE_COST_ALERTS"
    echo "  Usage Alerts: $ENABLE_USAGE_ALERTS"
    echo "  Performance Alerts: $ENABLE_PERFORMANCE_ALERTS"
    echo "  Dry Run: $DRY_RUN"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --enable-cost-alerts)
            ENABLE_COST_ALERTS=true
            shift
            ;;
        --enable-usage-alerts)
            ENABLE_USAGE_ALERTS=true
            shift
            ;;
        --enable-performance-alerts)
            ENABLE_PERFORMANCE_ALERTS=true
            shift
            ;;
        --enable-all-alerts)
            ENABLE_COST_ALERTS=true
            ENABLE_USAGE_ALERTS=true
            ENABLE_PERFORMANCE_ALERTS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
            elif [[ -z "$CONFIG" ]]; then
                CONFIG="$1"
            else
                print_error "Too many arguments: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Set default values if not provided
if [[ -z "$TARGET" ]]; then
    TARGET="dev"
fi
if [[ -z "$CONFIG" ]]; then
    CONFIG="config.yaml"
fi

# Main execution
main() {
    print_info "FinOps Alerts Deployment Script"
    echo "=================================="
    
    # Validate inputs
    if ! validate_target "$TARGET"; then
        exit 1
    fi
    
    if ! validate_config "$CONFIG"; then
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Set environment variables
    set_environment_variables
    
    # Show summary
    show_summary
    
    # Confirm deployment (unless dry run)
    if [[ "$DRY_RUN" == false ]]; then
        read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    # Deploy
    deploy
    
    print_success "Deployment script completed!"
}

# Run main function
main "$@" 