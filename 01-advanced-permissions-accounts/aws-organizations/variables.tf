# =============================================================================
# Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for API calls (Organizations is global, but provider needs a region)"
  type        = string
  default     = "ap-southeast-1"
}

variable "organization_name" {
  description = "Name for the AWS Organization (optional, used in tags)"
  type        = string
  default     = "terraform-lab-org"
}

# -----------------------------------------------------------------------------
# OU Structure - typical enterprise layout
# -----------------------------------------------------------------------------
variable "ou_structure" {
  description = "Organizational Unit structure (top-level OUs)"
  type        = list(string)
  default     = ["Security", "Infrastructure", "Workloads", "Sandbox"]
}
