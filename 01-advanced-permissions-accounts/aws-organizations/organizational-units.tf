# =============================================================================
# Organizational Units (OUs)
# =============================================================================
#
# Cantrill: OUs = logical grouping of accounts, hierarchy for SCP inheritance
#
# Common patterns:
#   - Security: security tooling, logging, audit
#   - Infrastructure: shared services, networking
#   - Workloads: dev, staging, prod (or by team/product)
#   - Sandbox: experimentation, learning
#
# =============================================================================

resource "aws_organizations_organizational_unit" "top_level" {
  for_each = toset(var.ou_structure)

  name      = each.value
  parent_id = aws_organizations_organization.main.roots[0].id
}

# -----------------------------------------------------------------------------
# Nested OU example: Workloads -> Dev, Staging, Prod
# -----------------------------------------------------------------------------
resource "aws_organizations_organizational_unit" "workloads_env" {
  for_each = toset(["Dev", "Staging", "Prod"])

  name      = each.value
  parent_id = aws_organizations_organizational_unit.top_level["Workloads"].id
}
