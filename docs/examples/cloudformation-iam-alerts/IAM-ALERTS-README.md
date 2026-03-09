# IAM Activity Alert CloudFormation Template

This CloudFormation template sets up automated alerts for IAM user creation activities in your AWS account. It monitors `CreateUser`, `CreateAccessKey`, and `CreateLoginProfile` events and sends notifications via email (SNS) and/or Slack.

## Features

- **EventBridge Rule** monitoring IAM events via CloudTrail
- **Flexible Notifications**: Choose email, Slack, or both
- **Customizable User Exclusions**: Exclude service accounts from alerts
- **Rich Slack Messages**: Color-coded messages with detailed event information
- **Email Notifications**: Formatted email alerts via SNS
- **Easy to Share**: Parameterized for easy deployment across multiple AWS accounts

## Prerequisites

1. **CloudTrail must be enabled** in your AWS account (management events logging)
2. **AWS CLI** installed and configured with appropriate credentials
3. For Slack notifications: Slack Incoming Webhook URL (see setup instructions below)
4. For email notifications: Valid email address with access to confirm subscription

## Setting Up Notifications

### Slack Webhook Setup

To receive alerts in Slack, you need to create an Incoming Webhook:

1. **Go to Slack API Apps page**
   - Visit https://api.slack.com/apps
   - Click "Create New App"

2. **Create the App**
   - Choose "From scratch"
   - Enter App Name (e.g., "IAM Activity Alerts")
   - Select your workspace
   - Click "Create App"

3. **Enable Incoming Webhooks**
   - In the left sidebar, click "Incoming Webhooks"
   - Toggle "Activate Incoming Webhooks" to ON

4. **Create a Webhook for Your Channel**
   - Scroll down and click "Add New Webhook to Workspace"
   - Select the channel where you want alerts posted (e.g., #security-alerts)
   - Click "Allow"

5. **Copy the Webhook URL**
   - You'll see a webhook URL like: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`
   - Copy this URL - you'll use it as the `SlackWebhookUrl` parameter

6. **Test the Webhook (Optional)**
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"IAM Alerts test message"}' \
     https://hooks.slack.com/services/YOUR/WEBHOOK/URL
   ```

### Email Subscription Confirmation

When using email notifications, you must confirm your subscription after deployment:

1. **Deploy the CloudFormation Stack**
   - Use one of the deployment methods below with your email address

2. **Check Your Email**
   - Within a few minutes, you'll receive an email from `AWS Notifications <no-reply@sns.amazonaws.com>`
   - Subject: "AWS Notification - Subscription Confirmation"

3. **Confirm the Subscription**
   - Open the email
   - Click the "Confirm subscription" link
   - You'll see a confirmation page in your browser

4. **Verify Subscription Status**
   ```bash
   aws sns list-subscriptions-by-topic \
     --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:iam-user-creation-alert-topic
   ```
   - Look for your email with `SubscriptionArn` (not "PendingConfirmation")

**Important Notes:**
- The confirmation link expires after 3 days
- No alerts will be sent until you confirm the subscription
- If you miss the email, you can resend it by updating the stack with the same email parameter

### Using Both Slack and Email

You can enable both notification methods simultaneously. Both require their respective setup:
- Slack: No confirmation needed (works immediately after deployment)
- Email: Requires subscription confirmation via email link

## Deployment Options

### Option 1: AWS Console

1. Open AWS CloudFormation console
2. Click "Create stack" > "With new resources"
3. Upload the `iam-alerts-cloudformation.yaml` template
4. Fill in the parameters:
   - **NotificationEmail**: Your email address (leave empty if using Slack only)
   - **SlackWebhookUrl**: Your Slack webhook URL (leave empty if using email only)
   - **ExcludedUserNames**: Comma-separated list of usernames to exclude (default: portalsvc1,klam-sts-user)
   - **AlertRuleName**: Custom name for the alert rule (default: iam-user-creation-alert)
5. Review and create the stack
6. If using email, check your inbox and confirm the SNS subscription

### Option 2: AWS CLI

```bash
# Deploy with email notifications
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your-email@example.com \
    ParameterKey=ExcludedUserNames,ParameterValue="portalsvc1,klam-sts-user" \
  --capabilities CAPABILITY_IAM

# Deploy with Slack notifications
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters \
    ParameterKey=SlackWebhookUrl,ParameterValue=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
    ParameterKey=ExcludedUserNames,ParameterValue="portalsvc1,klam-sts-user" \
  --capabilities CAPABILITY_IAM

# Deploy with both email and Slack
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your-email@example.com \
    ParameterKey=SlackWebhookUrl,ParameterValue=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
    ParameterKey=ExcludedUserNames,ParameterValue="portalsvc1,klam-sts-user" \
  --capabilities CAPABILITY_IAM
```

### Option 3: Using a Parameters File

Create a `parameters.json` file:

```json
[
  {
    "ParameterKey": "NotificationEmail",
    "ParameterValue": "security-team@example.com"
  },
  {
    "ParameterKey": "SlackWebhookUrl",
    "ParameterValue": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  },
  {
    "ParameterKey": "ExcludedUserNames",
    "ParameterValue": "portalsvc1,klam-sts-user,automation-user"
  },
  {
    "ParameterKey": "AlertRuleName",
    "ParameterValue": "iam-user-creation-alert"
  }
]
```

Then deploy:

```bash
aws cloudformation create-stack \
  --stack-name iam-activity-alerts \
  --template-body file://iam-alerts-cloudformation.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_IAM
```

## Post-Deployment Steps

### For Email Notifications

1. **Confirm your subscription** (required)
   - Check your email inbox for the confirmation message
   - Click the confirmation link within 3 days
   - You should see "Subscription confirmed!" in your browser

2. **Verify subscription status**
   ```bash
   aws sns list-subscriptions-by-topic \
     --topic-arn $(aws cloudformation describe-stacks \
       --stack-name iam-activity-alerts \
       --query 'Stacks[0].Outputs[?OutputKey==`SNSTopicArn`].OutputValue' \
       --output text)
   ```

3. **If you didn't receive the email**
   - Check your spam/junk folder
   - Verify the email address in the CloudFormation parameters
   - Redeploy the stack or update it to resend the confirmation

### For Slack Notifications

1. **Verify Lambda function was created**
   ```bash
   aws lambda get-function \
     --function-name iam-user-creation-alert-slack-notifier
   ```

2. **Check the Slack channel**
   - No confirmation needed - alerts will appear immediately when triggered
   - Ensure the Slack app has permission to post to the channel

3. **Test the webhook** (optional)
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test: IAM Alerts are configured"}' \
     YOUR_WEBHOOK_URL
   ```

### Verify EventBridge Rule

Check that the EventBridge rule is active:
```bash
aws events describe-rule --name iam-user-creation-alert
```

Look for `"State": "ENABLED"` in the output.

## Monitored Events

The template monitors these IAM events:
- **CreateUser**: When a new IAM user is created
- **CreateAccessKey**: When an access key is created for any user
- **CreateLoginProfile**: When console access is enabled for a user

## Alert Information

Both email and Slack notifications include:
- Event type (CreateUser, CreateAccessKey, or CreateLoginProfile)
- Target username
- Event timestamp
- AWS Account ID
- Region
- Principal ID (who performed the action)
- Principal ARN
- Source IP address

## Customization

### Adding More Excluded Users

Update the `ExcludedUserNames` parameter with a comma-separated list:

```bash
aws cloudformation update-stack \
  --stack-name iam-activity-alerts \
  --use-previous-template \
  --parameters \
    ParameterKey=ExcludedUserNames,ParameterValue="user1,user2,user3"
```

### Monitoring Additional IAM Events

Edit the template's EventPattern section to add more events:

```yaml
eventName:
  - CreateUser
  - CreateAccessKey
  - CreateLoginProfile
  - DeleteUser  # Add this
  - DeleteAccessKey  # Add this
```

### Changing Notification Target

Update the stack parameters to change email or Slack webhook:

```bash
aws cloudformation update-stack \
  --stack-name iam-activity-alerts \
  --use-previous-template \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=new-email@example.com \
    ParameterKey=SlackWebhookUrl,UsePreviousValue=true
```

## Testing

To test the alert:

1. Create a test IAM user (not in the excluded list):
   ```bash
   aws iam create-user --user-name test-alert-user
   ```

2. Check your email/Slack for the alert

3. Clean up:
   ```bash
   aws iam delete-user --user-name test-alert-user
   ```

## Sharing with Other Accounts

To share this template with other teams or AWS accounts:

1. **Upload to S3** (for easy access):
   ```bash
   aws s3 cp iam-alerts-cloudformation.yaml s3://your-templates-bucket/
   aws s3api put-object-acl --bucket your-templates-bucket \
     --key iam-alerts-cloudformation.yaml --acl public-read
   ```

2. **Share the S3 URL** or the template file directly

3. **Provide deployment instructions** (this README)

## Cost Considerations

- **EventBridge**: No charge for rules; charged per event matched (minimal cost)
- **Lambda** (Slack only): Charged per invocation and execution time (minimal cost, free tier eligible)
- **SNS** (email only): First 1,000 email notifications per month are free
- **CloudWatch Logs** (Slack only): Lambda logs incur minimal charges

Expected cost: **< $1/month** for typical usage

## Troubleshooting

### No Email Alerts Received

1. **Check subscription status**
   ```bash
   aws sns list-subscriptions-by-topic \
     --topic-arn $(aws cloudformation describe-stacks \
       --stack-name iam-activity-alerts \
       --query 'Stacks[0].Outputs[?OutputKey==`SNSTopicArn`].OutputValue' \
       --output text)
   ```
   - If status shows "PendingConfirmation", check your email and confirm
   - If the confirmation email expired, update the stack to resend

2. **Check spam/junk folder**
   - Confirmation emails from AWS SNS may be filtered
   - Add `no-reply@sns.amazonaws.com` to your contacts

3. **Verify email address**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name iam-activity-alerts \
     --query 'Stacks[0].Parameters[?ParameterKey==`NotificationEmail`].ParameterValue' \
     --output text
   ```

4. **Resend confirmation email**
   ```bash
   aws cloudformation update-stack \
     --stack-name iam-activity-alerts \
     --use-previous-template \
     --parameters ParameterKey=NotificationEmail,ParameterValue=your-email@example.com \
       ParameterKey=SlackWebhookUrl,UsePreviousValue=true \
       ParameterKey=ExcludedUserNames,UsePreviousValue=true \
       ParameterKey=AlertRuleName,UsePreviousValue=true \
     --capabilities CAPABILITY_IAM
   ```

### No Slack Alerts Received

1. **Test the webhook directly**
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test message"}' \
     https://hooks.slack.com/services/YOUR/WEBHOOK/URL
   ```
   - If this fails, the webhook URL is invalid or the Slack app was removed

2. **Check Lambda function logs**
   ```bash
   aws logs tail /aws/lambda/iam-user-creation-alert-slack-notifier --follow
   ```
   - Look for error messages indicating webhook failures

3. **Verify Lambda has correct webhook URL**
   ```bash
   aws lambda get-function-configuration \
     --function-name iam-user-creation-alert-slack-notifier \
     --query 'Environment.Variables.SLACK_WEBHOOK_URL'
   ```

4. **Check Lambda execution errors**
   ```bash
   aws lambda get-function \
     --function-name iam-user-creation-alert-slack-notifier \
     --query 'Configuration.LastUpdateStatus'
   ```

### No Alerts at All (Both Email and Slack)

1. **Verify CloudTrail is enabled and logging management events**
   ```bash
   aws cloudtrail get-trail-status --name YOUR_TRAIL_NAME
   ```

2. **Check EventBridge rule status**
   ```bash
   aws events describe-rule --name iam-user-creation-alert
   ```
   - Ensure `"State": "ENABLED"`

3. **Review EventBridge rule targets**
   ```bash
   aws events list-targets-by-rule --rule iam-user-creation-alert
   ```
   - Verify your SNS topic and/or Lambda function are listed

4. **Trigger a test event**
   ```bash
   aws iam create-user --user-name test-alert-user
   aws iam delete-user --user-name test-alert-user
   ```
   - Wait 1-2 minutes for the alert
   - Ensure "test-alert-user" is not in your excluded users list

### Excluded Users Still Triggering Alerts

1. **Verify the parameter value** (case-sensitive)
   ```bash
   aws cloudformation describe-stacks \
     --stack-name iam-activity-alerts \
     --query 'Stacks[0].Parameters[?ParameterKey==`ExcludedUserNames`].ParameterValue' \
     --output text
   ```

2. **Check the EventBridge rule pattern**
   ```bash
   aws events describe-rule --name iam-user-creation-alert \
     --query 'EventPattern' --output text | jq .
   ```

### Lambda Function Errors (Slack)

1. **View recent logs**
   ```bash
   aws logs tail /aws/lambda/iam-user-creation-alert-slack-notifier --follow
   ```

2. **Check for permission errors**
   - Verify the Lambda execution role has CloudWatch Logs permissions

3. **Verify urllib3 is available**
   - The Lambda uses Python 3.12 with built-in urllib3
   - If you see import errors, check the runtime version

## Cleanup

To remove all resources:

```bash
aws cloudformation delete-stack --stack-name iam-activity-alerts
```

## Security Considerations

- The Slack webhook URL is marked as `NoEcho` to prevent exposure in console/CLI
- Lambda function has minimal IAM permissions (only CloudWatch Logs)
- SNS topic policy restricts publishing to EventBridge service only
- No sensitive IAM credentials are stored or transmitted

## Support

For issues or questions:
- Check AWS CloudFormation stack events for deployment errors
- Review CloudWatch Logs for Lambda execution errors
- Verify CloudTrail is properly configured and logging events
