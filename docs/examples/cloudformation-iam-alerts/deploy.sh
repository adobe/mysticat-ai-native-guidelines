#!/bin/bash

# IAM Activity Alerts - CloudFormation Deployment Script
# This script helps deploy the IAM alerts stack to your AWS account

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
STACK_NAME="iam-activity-alerts"
TEMPLATE_FILE="iam-alerts-cloudformation.yaml"
REGION=""

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    print_info "AWS CLI found: $(aws --version)"
}

# Function to check if CloudTrail is enabled
check_cloudtrail() {
    print_info "Checking if CloudTrail is enabled..."
    local trails=$(aws cloudtrail describe-trails --query 'trailList[?IsMultiRegionTrail==`true`]' --output json 2>/dev/null)

    if [ "$trails" == "[]" ]; then
        print_warning "No multi-region CloudTrail found. The alerts require CloudTrail to be enabled."
        print_warning "Please ensure CloudTrail is configured to log management events."
    else
        print_info "CloudTrail is enabled."
    fi
}

# Function to validate email
validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get user input
get_parameters() {
    echo ""
    echo "=========================================="
    echo "IAM Activity Alerts - Configuration"
    echo "=========================================="
    echo ""

    # Stack name
    read -p "Stack name [${STACK_NAME}]: " input
    STACK_NAME=${input:-$STACK_NAME}

    # AWS Region
    if [ -z "$REGION" ]; then
        REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
    fi
    read -p "AWS Region [${REGION}]: " input
    REGION=${input:-$REGION}

    # Notification method
    echo ""
    echo "Choose notification method:"
    echo "1) Email only"
    echo "2) Slack only"
    echo "3) Both email and Slack"
    read -p "Selection [1-3]: " notification_choice

    EMAIL=""
    WEBHOOK=""

    case $notification_choice in
        1)
            while true; do
                read -p "Email address: " EMAIL
                if validate_email "$EMAIL"; then
                    break
                else
                    print_error "Invalid email format. Please try again."
                fi
            done
            ;;
        2)
            read -p "Slack Webhook URL: " WEBHOOK
            ;;
        3)
            while true; do
                read -p "Email address: " EMAIL
                if validate_email "$EMAIL"; then
                    break
                else
                    print_error "Invalid email format. Please try again."
                fi
            done
            read -p "Slack Webhook URL: " WEBHOOK
            ;;
        *)
            print_error "Invalid selection"
            exit 1
            ;;
    esac

    # Excluded usernames
    echo ""
    read -p "Excluded usernames (comma-separated) [portalsvc1,klam-sts-user]: " input
    EXCLUDED_USERS=${input:-portalsvc1,klam-sts-user}

    # Alert rule name
    read -p "Alert rule name [iam-user-creation-alert]: " input
    ALERT_RULE_NAME=${input:-iam-user-creation-alert}
}

# Function to build parameters
build_parameters() {
    PARAMS="ParameterKey=ExcludedUserNames,ParameterValue=\"${EXCLUDED_USERS}\" "
    PARAMS+="ParameterKey=AlertRuleName,ParameterValue=${ALERT_RULE_NAME} "

    if [ -n "$EMAIL" ]; then
        PARAMS+="ParameterKey=NotificationEmail,ParameterValue=${EMAIL} "
    else
        PARAMS+="ParameterKey=NotificationEmail,ParameterValue=\"\" "
    fi

    if [ -n "$WEBHOOK" ]; then
        PARAMS+="ParameterKey=SlackWebhookUrl,ParameterValue=${WEBHOOK} "
    else
        PARAMS+="ParameterKey=SlackWebhookUrl,ParameterValue=\"\" "
    fi
}

# Function to deploy stack
deploy_stack() {
    print_info "Deploying CloudFormation stack: ${STACK_NAME}"
    print_info "Region: ${REGION}"

    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &>/dev/null; then
        print_warning "Stack already exists. Updating..."
        OPERATION="update-stack"
    else
        print_info "Creating new stack..."
        OPERATION="create-stack"
    fi

    # Deploy
    eval aws cloudformation $OPERATION \
        --stack-name "$STACK_NAME" \
        --template-body file://"$TEMPLATE_FILE" \
        --parameters $PARAMS \
        --capabilities CAPABILITY_IAM \
        --region "$REGION"

    if [ $? -eq 0 ]; then
        print_info "Stack deployment initiated successfully!"
        print_info "Waiting for stack to complete..."

        if [ "$OPERATION" == "create-stack" ]; then
            aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"
        else
            aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$REGION" 2>/dev/null || true
        fi

        print_info "Stack deployment completed!"

        if [ -n "$EMAIL" ]; then
            echo ""
            print_warning "IMPORTANT: Check your email and confirm the SNS subscription!"
        fi

        echo ""
        print_info "Stack outputs:"
        aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$REGION" \
            --query 'Stacks[0].Outputs' \
            --output table
    else
        print_error "Stack deployment failed!"
        exit 1
    fi
}

# Function to show summary
show_summary() {
    echo ""
    echo "=========================================="
    echo "Deployment Summary"
    echo "=========================================="
    echo "Stack Name: ${STACK_NAME}"
    echo "Region: ${REGION}"
    echo "Email: ${EMAIL:-Not configured}"
    echo "Slack: ${WEBHOOK:+Configured}"
    echo "Excluded Users: ${EXCLUDED_USERS}"
    echo "Alert Rule: ${ALERT_RULE_NAME}"
    echo "=========================================="
    echo ""
    read -p "Proceed with deployment? (yes/no): " confirm

    if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
        print_warning "Deployment cancelled."
        exit 0
    fi
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  IAM Activity Alerts Deployment       ║"
    echo "║  CloudFormation Stack Setup            ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    check_aws_cli
    check_cloudtrail
    get_parameters
    build_parameters
    show_summary
    deploy_stack

    echo ""
    print_info "✓ Deployment complete!"
    echo ""
    echo "Next steps:"
    echo "1. If using email, confirm the SNS subscription"
    echo "2. Test the alert by creating a test IAM user"
    echo "3. Monitor CloudWatch Logs for any issues"
    echo ""
    echo "To test:"
    echo "  aws iam create-user --user-name test-alert-user"
    echo ""
    echo "To delete the stack:"
    echo "  aws cloudformation delete-stack --stack-name ${STACK_NAME} --region ${REGION}"
    echo ""
}

# Run main function
main
