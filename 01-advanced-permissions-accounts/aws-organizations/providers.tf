# =============================================================================
# AWS Organizations - Terraform Lab
# Maps to: Cantrill SAP - Module 1: Advanced Permissions & Accounts
# =============================================================================
#
# PREREQUISITE: Run this from an AWS account that is NOT already in an Organization.
# Creating a new org can only be done from a standalone account (root).
# For existing orgs: comment out aws_organizations_organization and use data source.
#
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-the-hardway"
      Module      = "01-advanced-permissions-accounts"
      ManagedBy   = "terraform"
    }
  }
}
