# MCP Workflows

End-to-end examples showing how MCP tools work together in real development scenarios.

These workflows demonstrate the power of combining multiple MCP servers with AI-assisted development. Each workflow includes the MCP tools used and the sequence of operations.

---

## Workflow 1: Development (Jira → Code → PR → Merge)

### Scenario

Implement a feature from Jira ticket to merged PR, with proper tracking and team notification.

### MCP Tools Used

| Server | Tools |
|--------|-------|
| mcp-atlassian | `jira_get_issue`, `jira_add_comment`, `jira_transition_issue`, `jira_create_remote_issue_link` |
| github | `create_branch`, `create_pull_request`, `update_pull_request` |
| slack | `conversations_add_message` |

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. READ TICKET                                                   │
│    jira_get_issue(issue_key="PROJ-123")                         │
│    → Get requirements, acceptance criteria                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. CREATE BRANCH                                                 │
│    create_branch(owner="org", repo="app", branch="PROJ-123-...")│
│    → Isolate work                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. IMPLEMENT (with superpowers skills)                          │
│    - brainstorming → clarify approach                           │
│    - test-driven-development → RED-GREEN-REFACTOR               │
│    - verification-before-completion → confirm working           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. CREATE PR                                                     │
│    create_pull_request(                                          │
│      owner="org", repo="app",                                   │
│      title="[PROJ-123] Add password reset",                     │
│      head="PROJ-123-password-reset", base="main"                │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. LINK PR TO JIRA                                               │
│    jira_create_remote_issue_link(                               │
│      issue_key="PROJ-123",                                      │
│      url="https://github.com/org/app/pull/456",                 │
│      title="PR #456: Add password reset"                        │
│    )                                                             │
│    jira_add_comment(issue_key="PROJ-123",                       │
│      comment="PR ready for review: [PR #456|https://...]")      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. REQUEST REVIEW                                                │
│    update_pull_request(pullNumber=456, reviewers=["teammate"])  │
│    conversations_add_message(channel="#team",                   │
│      payload="PR ready for review: PROJ-123 password reset")    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. ON MERGE: UPDATE JIRA                                         │
│    jira_transition_issue(issue_key="PROJ-123",                  │
│      transition_id="done")                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Key Points

- **Jira linking**: Use `jira_create_remote_issue_link` to create a trackable link (appears in issue's Links section), plus add a clickable link in the comment text
- **Notifications**: Slack message ensures team visibility
- **Traceability**: Full audit trail from ticket to deployment

---

## Workflow 2: Deployment (PR → Validation → Monitoring)

### Scenario

Deploy code changes with pre-flight validation and post-deployment monitoring.

### MCP Tools Used

| Server | Tools |
|--------|-------|
| github-enterprise | `pull_request_read`, `merge_pull_request` |
| flex | `PreDeploymentCheck`, `ValidateDeployment`, `GetFlexLinks` |
| splunk | `search_splunk` |
| mcp-atlassian | `jira_add_comment` |

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. CHECK PR STATUS                                               │
│    pull_request_read(method="get_status", pullNumber=202)       │
│    → Verify CI passed, reviews approved                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. PRE-DEPLOYMENT VALIDATION                                     │
│    PreDeploymentCheck(                                          │
│      orgName="my-org",                                          │
│      repoName="my-app-deploy",                                  │
│      gitRef="feature-branch"                                    │
│    )                                                             │
│    → Validates Helm charts, environment config                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. MERGE PR                                                      │
│    merge_pull_request(                                          │
│      owner="my-org",                                             │
│      repo="my-app-deploy",                                    │
│      pullNumber=202,                                            │
│      merge_method="squash"                                      │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. VALIDATE DEPLOYMENT                                           │
│    ValidateDeployment(                                          │
│      orgName="my-org",                                          │
│      repoName="my-app-deploy"                                   │
│    )                                                             │
│    → Check Argo CD sync status, app health                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. MONITOR LOGS                                                  │
│    search_splunk(                                               │
│      query="search index=app_logs                               │
│        sourcetype=my_app_backend_dev                            │
│        level=ERROR earliest=-15m | head 50"                     │
│    )                                                             │
│    → Check for errors post-deployment                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. UPDATE TRACKING                                               │
│    jira_add_comment(issue_key="PROJ-123",                       │
│      comment="Deployed to dev. Monitoring: no errors in 15m")  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Points

- **Pre-flight checks**: Catch configuration errors before deployment
- **Post-deployment monitoring**: Actively look for errors, don't assume success
- **Documentation**: Update Jira with deployment status for audit trail

---

## Workflow 3: Incident Response (Alert → Investigate → Fix → Close)

### Scenario

Based on a real incident: AWS Backup was generating 1.6-2.1 million S3 requests/second, causing ~$111K/year in unnecessary costs. Investigation, mitigation, and resolution using MCP tools.

### MCP Tools Used

| Server | Tools |
|--------|-------|
| slack | `conversations_history`, `conversations_add_message` |
| splunk | `search_splunk` |
| postgres | `query` |
| github | `create_branch`, `create_pull_request` |
| mcp-atlassian | `confluence_create_page`, `jira_create_issue`, `jira_create_remote_issue_link` |

### The Incident

> **S3 Backup Incident (2026-01-28)**: The `myapp-*-assets` S3 buckets experienced 1.6-2.1 million requests/second. Root cause: AWS Backup daily jobs scanning all object versions in buckets with 100K+ frequently-updated task files. **Impact**: ~$56K in 6 months, projected $111K/year.

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. ALERT RECEIVED                                                │
│    conversations_history(channel_id="#alerts")                  │
│    → "High S3 request volume detected in CloudWatch"            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. GATHER INITIAL DATA                                           │
│    search_splunk(                                               │
│      query="search index=aws_cloudwatch                         │
│        metric_name=AllRequests                                  │
│        bucket=myapp-*-assets                                    │
│        | timechart span=5m sum(value)"                          │
│    )                                                             │
│    → Confirmed: 1.6-2.1M req/sec, 99.87% GET requests           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. INVESTIGATE ROOT CAUSE                                        │
│    query(sql="SELECT key, last_modified, size                   │
│               FROM s3_inventory                                  │
│               WHERE bucket = 'myapp-dev-assets'     │
│               ORDER BY last_modified DESC LIMIT 100")           │
│    → Found: 103K objects in tasks/ prefix, frequent updates      │
│                                                                  │
│    # Check S3 access logs (enabled during investigation)        │
│    → Found: arn:aws:sts::...:assumed-role/myapp-backup-role  │
│    → Request types: REST.GET.ACL, REST.GET.OBJECT_TAGGING       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. ROOT CAUSE IDENTIFIED                                         │
│    AWS Backup scanning all object versions:                     │
│    - S3 versioning enabled                                      │
│    - 103K task files × ~50 versions each × 4+ API calls         │
│    - = 20+ million requests per backup job                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. IMMEDIATE MITIGATION                                          │
│    # Via AWS CLI (not MCP - direct action needed)               │
│    aws backup stop-backup-job --backup-job-id "DB94D908-..."    │
│                                                                  │
│    conversations_add_message(channel="#incidents",              │
│      payload="DEV/PROD backup jobs stopped. Investigating...")  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. VERIFY MITIGATION                                             │
│    search_splunk(                                               │
│      query="search index=aws_cloudwatch                         │
│        metric_name=AllRequests                                  │
│        bucket=myapp-dev-assets                                  │
│        earliest=-30m | timechart span=1m sum(value)"            │
│    )                                                             │
│    → Confirmed: 1.6M → 977 req/sec (>99% reduction)             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. CREATE PERMANENT FIX                                          │
│    create_branch(branch="fix/exclude-assets-from-backup")       │
│                                                                  │
│    # Edit: modules/s3/buckets.tf                                │
│    # Change: "App.IncludeInBackup" = "true" → "false"      │
│                                                                  │
│    create_pull_request(                                         │
│      title="fix: exclude asset buckets from AWS Backup",      │
│      body="## Summary\n- Root cause: backup scanning versions..." │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. DOCUMENT INCIDENT                                             │
│    confluence_create_page(                                      │
│      space_key="OPS",                                           │
│      title="S3 Backup Incident - 2026-01-28",                   │
│      content="# Executive Summary\n\nAWS Backup jobs..."        │
│    )                                                             │
│                                                                  │
│    jira_create_issue(                                           │
│      project_key="OPS",                                         │
│      summary="Post-incident: Add CloudWatch alarms for S3",     │
│      issue_type="Task"                                          │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. LINK PR TO DOCUMENTATION                                      │
│    jira_create_remote_issue_link(                               │
│      issue_key="OPS-456",                                       │
│      url="https://github.com/.../pull/266",                     │
│      title="PR #266: Exclude from backup"                       │
│    )                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 10. CLOSE INCIDENT                                               │
│    conversations_add_message(channel="#incidents",              │
│      payload="Incident resolved. PR merged. Projected savings:  │
│               ~$111K/year. Post-mortem: [link to Confluence]")  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Points

- **Evidence gathering**: Use Splunk and database queries to understand the problem
- **Quick mitigation**: Stop the bleeding first, then investigate
- **Verification**: Confirm mitigation worked before declaring success
- **Documentation**: Create lasting record for future reference
- **Follow-up**: Track remediation tasks in Jira

### Related Investigation: CDN Log Cost Spike

The backup incident investigation also uncovered a separate issue: a 37x increase in S3 PUT costs from CDN log streaming.

**Tools used for cost analysis**:
```
# Query cost data
query(sql="
  SELECT month, tier1_cost, tier2_cost, bucket_name
  FROM aws_cost_explorer
  WHERE service = 'S3'
    AND bucket_name LIKE 'cdn-logs-%'
  ORDER BY month DESC
")
```

**Findings**: 171 per-site CDN log buckets generating ~3B PUT requests/month (~$15K/month) from real-time log streaming.

This demonstrates how MCP tools enable deep investigation that might otherwise require multiple browser tabs and manual data correlation.

---

## Workflow Patterns

### Pattern: Evidence-First Investigation

```
1. Gather metrics (Splunk, CloudWatch, database)
2. Form hypothesis
3. Gather more targeted evidence
4. Confirm or refute hypothesis
5. Only then take action
```

### Pattern: Mitigation Before Root Cause

```
1. Stop the immediate problem (stop job, rollback, etc.)
2. Verify mitigation worked
3. Then investigate root cause
4. Implement permanent fix
```

### Pattern: Full Traceability

```
1. Link PRs to Jira tickets
2. Link Confluence docs to Jira
3. Add comments with URLs at each stage
4. Team can reconstruct the timeline from any entry point
```

## See Also

- [MCP Overview](overview.md) - Protocol fundamentals
- [MCP Servers](servers.md) - Server catalog
- [Superpowers Plugin](../plugins/superpowers.md) - Skills that complement workflows
- [Environment & Secrets](../env-secrets.md) - Managing credentials
