# Module 1: Advanced Permissions & Accounts

**Cantrill SAP** → Section: Advanced Permissions & Accounts, AWS Organizations

## Tài liệu học

| Tài liệu | Mô tả |
|----------|-------|
| **[docs/LEARNING_GUIDE.md](./docs/LEARNING_GUIDE.md)** | Hướng dẫn học theo từng bài Cantrill (checklist, khái niệm, practice) |
| **[docs/AWS_ORGANIZATIONS.md](./docs/AWS_ORGANIZATIONS.md)** | Tài liệu AWS Organizations (links chính thức, SCP examples, Terraform reference) |

## Nội dung Cantrill

- AWS Organizations: multi-account strategy
- Management account vs Member accounts
- Organizational Units (OUs) – hierarchy
- Service Control Policies (SCPs) – guardrails
- Consolidated billing
- AWS Control Tower (built on top of Organizations)

## Cấu trúc lab

```
01-advanced-permissions-accounts/
└── aws-organizations/     # Terraform implementation
    ├── providers.tf       # AWS provider config
    ├── organization.tf   # Create org, feature set
    ├── organizational-units.tf  # OUs + nested OUs
    ├── service-control-policies.tf  # SCPs
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars.example
```

## Chạy lab

### Điều kiện

- **Tài khoản AWS standalone** (chưa thuộc Organization nào)
- Tạo org mới chỉ được thực hiện từ root của account standalone

### Nếu đã có Organization

- Comment/xóa `aws_organizations_organization` trong `organization.tf`
- Dùng `data "aws_organizations_organization" "current"` để lấy org hiện tại
- Điều chỉnh `parent_id` trong OUs để dùng `data.aws_organizations_organization.current.roots[0].id`

### Lệnh

```bash
cd 01-advanced-permissions-accounts/aws-organizations

# Init
terraform init

# Plan (xem trước thay đổi)
terraform plan

# Apply (cần confirm)
terraform apply
```

## Resources được tạo

| Resource | Mô tả |
|----------|-------|
| `aws_organizations_organization` | Org với feature set ALL (SCPs, Tag policies) |
| `aws_organizations_organizational_unit` | 4 OUs: Security, Infrastructure, Workloads, Sandbox |
| `aws_organizations_organizational_unit.workloads_env` | 3 OUs con: Dev, Staging, Prod |
| `aws_organizations_policy` (DenyLeaveOrg) | SCP: không cho leave org |
| `aws_organizations_policy` (RestrictRegions) | SCP: chỉ ap-southeast-1, ap-southeast-2, us-east-1 |
| `aws_organizations_policy_attachment` | Gắn SCP vào root/OU |

## Ghi chú SCP

- **SCP chỉ Deny**, không grant permission
- Management account **không** bị ảnh hưởng bởi SCP
- Effective permission = IAM policy ∩ SCP (phần giao)
- RestrictRegions không áp dụng cho Sandbox OU (để dễ thực hành)
