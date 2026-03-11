# =============================================================================
# AWS Organization
# =============================================================================
#
# Feature sets:
#   - ALL: Consolidated billing + SCPs + Tag policies + Backup policies
#   - CONSOLIDATED_BILLING: Billing only (legacy)
#
# Cantrill: Organizations = multi-account strategy, centralized management
#
# =============================================================================

resource "aws_organizations_organization" "main" {
  feature_set = "ALL"

  # Enable specific policy types (ALL feature set enables these by default)
  # enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY", "BACKUP_POLICY"]

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    # "sso.amazonaws.com",  # Uncomment for AWS IAM Identity Center (SSO)
  ]

  # Optional: Enable all features for new accounts
  # enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

# Root ID: aws_organizations_organization.main.roots[0].id
# Use as parent_id for top-level OUs
