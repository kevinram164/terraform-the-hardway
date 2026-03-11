# =============================================================================
# Service Control Policies (SCPs)
# =============================================================================
#
# Cantrill: SCPs = guardrails, NOT permissions. They DENY by default.
# - Apply to OUs or accounts (inherited down)
# - Management account is NOT affected by SCPs
# - Effective permissions = IAM policy INTERSECT SCP (most restrictive wins)
#
# =============================================================================

# -----------------------------------------------------------------------------
# SCP: Deny leaving the organization (common baseline)
# -----------------------------------------------------------------------------
resource "aws_organizations_policy" "deny_leave_org" {
  name        = "DenyLeaveOrganization"
  description = "Prevent member accounts from leaving the organization"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyLeaveOrg"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_leave_org_root" {
  policy_id = aws_organizations_policy.deny_leave_org.id
  target_id = aws_organizations_organization.main.roots[0].id
}

# -----------------------------------------------------------------------------
# SCP: Restrict regions (e.g. NAB uses Sydney - data sovereignty)
# -----------------------------------------------------------------------------
resource "aws_organizations_policy" "restrict_regions" {
  name        = "RestrictRegions"
  description = "Allow only specific regions (ap-southeast-1, ap-southeast-2)"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptAllowedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "account:*",
          "sts:*",
          "support:*",
          "cloudfront:*",
          "route53:*",
          "route53domains:*",
          "globalaccelerator:*",
          "wafv2:*",
          "waf:*",
          "shield:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "ap-southeast-1",
              "ap-southeast-2",
              "us-east-1"  # Required for some global services
            ]
          }
        }
      }
    ]
  })
}

# Attach to specific OUs only - NOT Sandbox (so Sandbox has full region access for learning)
resource "aws_organizations_policy_attachment" "restrict_regions" {
  for_each = {
    for k, v in aws_organizations_organizational_unit.top_level : k => v
    if k != "Sandbox"
  }

  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = each.value.id
}
