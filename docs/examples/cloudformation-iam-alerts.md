# CloudFormation IAM Activity Alerts

A production-ready CloudFormation template for monitoring IAM user creation activities across AWS accounts. This example demonstrates infrastructure-as-code automation with real-time alerting.

## Overview

This template sets up automated alerts for critical IAM events:
- **CreateUser** - New IAM user creation
- **CreateAccessKey** - Access key generation
- **CreateLoginProfile** - Console access enablement

Notifications are delivered via email (SNS) and/or Slack, enabling security teams to monitor unauthorized or unexpected IAM activity.

## Use Cases

- **Security Monitoring** - Detect unauthorized IAM user creation in real-time
- **Compliance** - Maintain audit trail for IAM changes
- **Team Awareness** - Keep security teams informed of IAM activities
- **Multi-Account Deployment** - Standardize alerting across AWS Organization

## Files Included

All files are available in the [cloudformation-iam-alerts](cloudformation-iam-alerts/) folder:

| File | Description |
|------|-------------|
| `iam-alerts-cloudformation.yaml` | Main CloudFormation template with EventBridge, SNS, and Lambda |
| `deploy.sh` | Interactive deployment script with validation |
| `parameters-example.json` | Sample parameters file for easy deployment |
| `IAM-ALERTS-README.md` | Comprehensive documentation with setup and troubleshooting |
| `README.md` | Quick start guide |

## Quick Start

### Prerequisites

- AWS account with CloudTrail enabled (management events)
- AWS CLI installed and configured
- (Optional) Slack Incoming Webhook URL

### Deploy with Interactive Script

```bash
cd cloudformation-iam-alerts
./deploy.sh
```

The script will prompt for:
- Notification method (email, Slack, or both)
- Email address or Slack webhook URL
- Excluded usernames (service accounts)
- Alert rule name

### Deploy with AWS CLI

Email notifications:
```bash
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=security@example.com \
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

## Architecture

The template creates:

1. **EventBridge Rule** - Monitors CloudTrail for IAM events
2. **SNS Topic** (optional) - Email notifications with formatted messages
3. **Lambda Function** (optional) - Slack integration with color-coded alerts
4. **IAM Roles** - Minimal permissions for Lambda execution

## Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `NotificationEmail` | Email for SNS alerts | (empty) |
| `SlackWebhookUrl` | Slack webhook URL | (empty) |
| `ExcludedUserNames` | Comma-separated list of users to exclude | `portalsvc1,klam-sts-user` |
| `AlertRuleName` | EventBridge rule name | `iam-user-creation-alert` |

## Alert Information

Each alert includes:
- Event type and timestamp
- Target username
- AWS Account ID and region
- Principal who performed the action (ARN)
- Source IP address

## Post-Deployment

### Email Subscription

If using email notifications, you must confirm the SNS subscription:

1. Check your email for "AWS Notification - Subscription Confirmation"
2. Click the confirmation link within 3 days
3. Verify subscription status:
   ```bash
   aws sns list-subscriptions-by-topic --topic-arn YOUR_TOPIC_ARN
   ```

### Slack Verification

Slack notifications work immediately after deployment. To verify:

```bash
# Check Lambda function
aws lambda get-function --function-name iam-user-creation-alert-slack-notifier

# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test: IAM Alerts configured"}' \
  YOUR_WEBHOOK_URL
```

## Testing

Trigger a test alert:

```bash
# Create a test user (will trigger alert)
aws iam create-user --user-name test-alert-user

# Clean up
aws iam delete-user --user-name test-alert-user
```

Check your email or Slack channel for the alert within 1-2 minutes.

## Sharing Across Teams

This template is designed for easy distribution:

1. **Share the repository** - All files are self-contained
2. **Customize parameters** - Each team can adjust excluded users, notification targets
3. **Multi-account deployment** - Use AWS CloudFormation StackSets for organization-wide deployment

## Cost

Expected cost: **< $1/month** for typical usage

- EventBridge: No charge for rules; minimal per-event cost
- Lambda (Slack): Minimal invocations, free tier eligible
- SNS (email): First 1,000 emails/month free
- CloudWatch Logs: Minimal charges

## Security

- Slack webhook URL protected with `NoEcho` (not visible in console/logs)
- Lambda has minimal IAM permissions (only CloudWatch Logs)
- SNS topic policy restricts publishing to EventBridge only
- No credentials stored or transmitted

## Documentation

For detailed documentation including:
- Step-by-step Slack webhook setup
- Email subscription confirmation process
- Comprehensive troubleshooting guide
- Customization options

See the complete [IAM-ALERTS-README.md](cloudformation-iam-alerts/IAM-ALERTS-README.md).

## Related Resources

- [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [CloudTrail Event Reference](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference.html)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)

## AI-First Context

This template was created using AI-assisted development practices:

- **Spec-driven design** - Requirements defined before implementation
- **Template reusability** - Parameterized for easy sharing
- **Documentation-first** - Comprehensive guides included
- **Automated deployment** - Interactive script reduces errors

The template demonstrates how AI tools can accelerate infrastructure automation while maintaining production quality and security standards.
