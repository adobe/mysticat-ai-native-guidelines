# CloudFormation IAM Activity Alerts

Automated monitoring and alerting for IAM user creation activities across AWS accounts.

## Overview

This CloudFormation template sets up real-time alerts for critical IAM events:
- **CreateUser** - New IAM user creation
- **CreateAccessKey** - Access key generation
- **CreateLoginProfile** - Console access enablement

Notifications can be delivered via email (SNS) and/or Slack to monitor unauthorized or unexpected IAM activity.

## Prerequisites

- AWS account with CloudTrail enabled (management events)
- AWS CLI installed and configured
- (Optional) Slack Incoming Webhook URL

## Deployment

### Interactive Script
```bash
cd cloudformation-iam-alerts
./deploy.sh
```

### AWS CLI

Email notifications:
```bash
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your-email@example.com \
    ParameterKey=ExcludedUserNames,ParameterValue="service-account1,service-account2" \
  --capabilities CAPABILITY_IAM
```

Slack notifications:
```bash
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters \
    ParameterKey=SlackWebhookUrl,ParameterValue=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
    ParameterKey=ExcludedUserNames,ParameterValue="service-account1,service-account2" \
  --capabilities CAPABILITY_IAM
```

## Repository Contents

- **`iam-alerts-cloudformation.yaml`** - Main CloudFormation template
- **`deploy.sh`** - Interactive deployment script
- **`parameters-example.json`** - Sample parameters file
- **`IAM-ALERTS-README.md`** - Detailed documentation

## Features

- Real-time monitoring via EventBridge
- Flexible notifications (Email, Slack, or both)
- Customizable user exclusions (for service accounts)
- Rich alert details (event type, user, timestamp, source IP, etc.)
- Easy to share across AWS accounts
- Minimal cost (< $1/month)
- Secure (Slack webhook stored with NoEcho)

## Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `NotificationEmail` | Email for SNS alerts | (empty) |
| `SlackWebhookUrl` | Slack webhook URL | (empty) |
| `ExcludedUserNames` | Users to exclude from alerts | `portalsvc1,klam-sts-user` |
| `AlertRuleName` | EventBridge rule name | `iam-user-creation-alert` |

## Alert Information

Each alert includes:
- Event type and timestamp
- Target username
- AWS Account ID and region
- Principal who performed the action
- Source IP address

## Testing

Test your deployment:
```bash
# Create a test user (will trigger alert)
aws iam create-user --user-name test-alert-user

# Clean up
aws iam delete-user --user-name test-alert-user
```

## Cleanup

Remove all resources:
```bash
aws cloudformation delete-stack --stack-name iam-activity-alerts
```

## Use Cases

- Security Monitoring - Detect unauthorized IAM user creation
- Compliance - Audit trail for IAM changes
- Team Awareness - Keep security teams informed of IAM activities
- Multi-Account Deployment - Standardize alerting across AWS Organization

## Security

- Webhook URLs protected with NoEcho (not visible in console/logs)
- Minimal IAM permissions (Lambda only has CloudWatch Logs access)
- SNS topic policy restricts publishing to EventBridge only
- No credentials stored or transmitted

## Documentation

For detailed documentation, troubleshooting, and advanced configuration, see [IAM-ALERTS-README.md](IAM-ALERTS-README.md).
