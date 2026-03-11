# Tài liệu học AWS Organizations

Tài liệu tham khảo cho Module 1 – Advanced Permissions & Accounts.

---

## 1. Tài liệu chính thức AWS

### Tổng quan & Khái niệm

| Tài liệu | URL | Nội dung |
|----------|-----|----------|
| **What is AWS Organizations?** | [docs.aws.amazon.com/organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html) | Giới thiệu, tính năng, use cases |
| **Getting Started** | [orgs_getting-started](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started.html) | Tạo org, OUs, mời accounts |
| **Managing an organization** | [orgs_manage_org](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org.html) | Quản lý org, account, OUs |

### Service Control Policies (SCPs)

| Tài liệu | URL | Nội dung |
|----------|-----|----------|
| **SCPs Overview** | [orgs_manage_policies_scps](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) | SCP là gì, cách hoạt động |
| **SCP Syntax** | [orgs_manage_policies_scps_syntax](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_syntax.html) | Cú pháp JSON, Action, Condition |
| **SCP Examples** | [orgs_manage_policies_scps_examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html) | Ví dụ SCP thường dùng |
| **SCP Evaluation** | [orgs_manage_policies_scps_evaluation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_evaluation.html) | Cách AWS đánh giá SCP |

### Khác

| Tài liệu | URL | Nội dung |
|----------|-----|----------|
| **FAQs** | [aws.amazon.com/organizations/faqs](https://aws.amazon.com/organizations/faqs/) | Câu hỏi thường gặp |
| **User Guide PDF** | [organizations-userguide.pdf](https://docs.aws.amazon.com/pdfs/organizations/latest/userguide/organizations-userguide.pdf) | Tải toàn bộ User Guide |

---

## 2. Terraform AWS Organizations

### Provider & Resources

| Resource | Registry | Mô tả |
|----------|----------|-------|
| `aws_organizations_organization` | [registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | Tạo/quản lý Organization |
| `aws_organizations_organizational_unit` | [registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | Tạo OU |
| `aws_organizations_account` | [registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | Tạo account mới trong org |
| `aws_organizations_policy` | [registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | Tạo policy (SCP, Tag policy, etc.) |
| `aws_organizations_policy_attachment` | [registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | Gắn policy vào Root/OU/Account |

### Data Sources

| Data Source | Mô tả |
|-------------|-------|
| `aws_organizations_organization` | Lấy thông tin org hiện tại (khi đã có org) |
| `aws_organizations_organizational_units` | Lấy danh sách OUs con của parent |

---

## 3. Khái niệm cần nhớ

### Management Account vs Member Account

| | Management Account | Member Account |
|---|-------------------|----------------|
| **Vai trò** | Tạo org, quản trị cao nhất | Account được mời vào org |
| **SCP** | Không bị ảnh hưởng | Bị SCP áp dụng |
| **Rời org** | Không thể | Có thể (trừ khi SCP chặn) |
| **Chuyển vai trò** | Không thể | Có thể promote (nâng cấp) |

### Feature Set

| Feature Set | Gồm |
|-------------|-----|
| **CONSOLIDATED_BILLING** | Chỉ gộp hóa đơn |
| **ALL** | Consolidated Billing + SCPs + Tag policies + Backup policies |

Dùng SCP → cần feature set **ALL**.

### SCP Inheritance

```
Root
 ├── SCP-A (Deny X)
 └── OU: Workloads
      ├── SCP-B (Deny Y)
      └── OU: Prod
           └── Account-123
```

- Account-123 chịu **cả** SCP-A và SCP-B
- **Một Deny** ở bất kỳ level nào → chặn toàn bộ cây con

**Effective permissions** = IAM Policy ∩ SCP (phần giao – cái hạn chế hơn thắng)

---

## 4. SCP Examples (AWS chính thức)

### Deny leave organization

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyLeaveOrg",
    "Effect": "Deny",
    "Action": "organizations:LeaveOrganization",
    "Resource": "*"
  }]
}
```

### Restrict regions

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyAllExceptAllowedRegions",
    "Effect": "Deny",
    "NotAction": [
      "iam:*", "organizations:*", "account:*", "sts:*",
      "support:*", "cloudfront:*", "route53:*", "route53domains:*",
      "globalaccelerator:*", "wafv2:*", "waf:*", "shield:*"
    ],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestedRegion": ["ap-southeast-1", "ap-southeast-2", "us-east-1"]
      }
    }
  }]
}
```

### Require MFA for root

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyAllExceptListedIfNoMFA",
    "Effect": "Deny",
    "NotAction": [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ],
    "Resource": "*",
    "Condition": {
      "BoolIfExists": {"aws:MultiFactorAuthPresent": "false"}
    }
  }]
}
```

### Deny root user

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyRootAccess",
    "Effect": "Deny",
    "Action": "*",
    "Resource": "*",
    "Condition": {
      "StringLike": {
        "aws:PrincipalArn": "arn:aws:iam::*:root"
      }
    }
  }]
}
```

---

## 5. Lộ trình học đề xuất

1. **Đọc**: [What is AWS Organizations?](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
2. **Đọc**: [SCPs Overview](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
3. **Xem**: Cantrill – Advanced Permissions & Accounts
4. **Practice**: Chạy lab Terraform trong `aws-organizations/`
5. **Đọc**: [SCP Examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html) – thử thêm SCP mới

---

## 6. Liên quan đến NAB

- NAB dùng **Terraform Enterprise** để quản lý infrastructure
- Multi-account: AWS + Azure
- SCP: ví dụ **restrict regions** (Sydney – data sovereignty)
- Compliance: [Sentinel](https://www.hashicorp.com/sentinel) policy as code
