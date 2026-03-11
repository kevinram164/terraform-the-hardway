# =============================================================================
# Outputs
# =============================================================================

output "organization_id" {
  description = "The ID of the organization"
  value       = aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "ARN of the organization"
  value       = aws_organizations_organization.main.arn
}

output "organization_master_account_id" {
  description = "The account ID of the management account"
  value       = aws_organizations_organization.main.master_account_id
}

output "root_id" {
  description = "The ID of the root (use as parent for top-level OUs)"
  value       = aws_organizations_organization.main.roots[0].id
}

output "organizational_units" {
  description = "Map of OU names to their IDs"
  value = {
    for k, v in aws_organizations_organizational_unit.top_level : k => v.id
  }
}

output "workloads_child_ous" {
  description = "Child OUs under Workloads (Dev, Staging, Prod)"
  value = {
    for k, v in aws_organizations_organizational_unit.workloads_env : k => v.id
  }
}
