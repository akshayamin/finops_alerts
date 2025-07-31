#!/bin/bash

# =============================================================================
# SIMPLE FINOPS ALERTS DEPLOYMENT
# =============================================================================
# 
# Purpose: Simple deployment script that directly executes SQL functions
# 
# This script bypasses DABs and directly executes the SQL functions
# to create the alert creation function in Databricks.
# 
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
CATALOG_NAME="aa_catalog"
SCHEMA_NAME="dw_ops"
FUNCTION_NAME="create_alert"

print_info "FinOps Alerts Simple Deployment"
echo "=================================="

# Check if we're in the right directory
if [[ ! -f "src/functions/create_alert.sql" ]]; then
    print_error "create_alert.sql not found. Please run this script from the project root."
    exit 1
fi

print_info "Deploying create_alert function to ${CATALOG_NAME}.${SCHEMA_NAME}"

# Read the SQL function
SQL_CONTENT=$(cat src/functions/create_alert.sql)

print_info "Function content loaded successfully"
print_info "Function name: ${FUNCTION_NAME}"
print_info "Target location: ${CATALOG_NAME}.${SCHEMA_NAME}.${FUNCTION_NAME}"

print_warning "This script will create/replace the function in your Databricks workspace."
print_warning "Make sure you have the necessary permissions."

read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

print_info "To deploy this function, you need to:"
echo ""
echo "1. Open your Databricks workspace"
echo "2. Navigate to SQL Editor"
echo "3. Execute the following SQL:"
echo ""
echo "=========================================="
echo "$SQL_CONTENT"
echo "=========================================="
echo ""
print_success "Function deployment instructions provided!"
print_info "After deploying the function, you can create alerts using the examples in:"
echo "  - src/finops/cost_monitoring/budget_threshold_alert.sql"
echo "  - src/finops/usage_monitoring/cluster_utilization_alert.sql"
echo "  - src/finops/performance/query_performance_alert.sql" 