# Advanced Permissions & Accounts – Hướng dẫn học theo Cantrill

Tài liệu này map **1:1** với cấu trúc khóa Cantrill. Mỗi bài có: tóm tắt, khái niệm chính, practice và links.

**Cách dùng:** Đánh dấu `[x]` khi hoàn thành mỗi bài.

---

## Phần 1: AWS Organizations & SCP

### 1. [ ] AWS Organizations (12:56) `[ASSOCIATESHARED]`

**Khái niệm chính:**
- Organization = tập hợp nhiều AWS accounts
- Management account vs Member accounts
- Root, OUs (Organizational Units)
- Consolidated billing
- Feature set: CONSOLIDATED_BILLING vs ALL

**Cần nhớ:**
- Chỉ account **standalone** mới tạo được org mới
- Management account không thể chuyển vai trò

**Practice:** Đọc [docs/AWS_ORGANIZATIONS.md](./AWS_ORGANIZATIONS.md) phần 1–3

**Links:** [What is AWS Organizations?](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)

---

### 2. [ ] [DEMO] AWS Organizations (19:48) `[SHAREDALL]`

**Nội dung demo:**
- Tạo Organization trên Console
- Tạo OUs
- Mời/tạo member accounts
- Xem consolidated billing

**Practice Terraform:**
```bash
cd ../aws-organizations
terraform init
terraform plan
terraform apply
```

**Checklist:**
- [ ] Chạy `terraform apply` thành công
- [ ] Xem org trên Console → Organizations
- [ ] So sánh: Console vs Terraform – resource nào tương ứng?

---

### 3. [ ] Service Control Policies (SCP) (12:43) `[ASSOCIATESHARED]`

**Khái niệm chính:**
- SCP = **guardrail**, không grant permission
- Chỉ **Deny**
- Management account **không** bị SCP
- Effective permission = IAM Policy ∩ SCP
- SCP kế thừa theo cây OU

**Cần nhớ:**
- Một Deny ở bất kỳ level nào → chặn toàn bộ cây con
- Cần feature set **ALL** để dùng SCP

**Practice:** Đọc [docs/AWS_ORGANIZATIONS.md](./AWS_ORGANIZATIONS.md) phần 4 (SCP examples)

**Links:** [SCPs Overview](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)

---

### 4. [ ] [DEMO] Using Service Control Policies (16:45) `[SHAREDALL]`

**Nội dung demo:**
- Tạo SCP trên Console
- Attach SCP vào Root/OU
- Test SCP trên member account

**Practice Terraform:**
- Mở `service-control-policies.tf` trong lab
- Thử thêm 1 SCP mới (ví dụ: Deny root user)
- `terraform plan` → `terraform apply`

**Checklist:**
- [ ] Hiểu DenyLeaveOrg, RestrictRegions
- [ ] Biết attach SCP vào Root vs OU khác nhau thế nào

---

## Phần 2: STS & Temporary Credentials

### 5. [ ] Security Token Service (STS) (6:53)

**Khái niệm chính:**
- STS = cấp **temporary credentials** (access key + secret + session token)
- Có thời hạn (expiration)
- Các API: `AssumeRole`, `GetSessionToken`, `AssumeRoleWithWebIdentity`, `AssumeRoleWithSAML`

**Cần nhớ:**
- Temporary credentials an toàn hơn long-term (ít bị lộ)
- Cross-account access thường dùng `AssumeRole`

**Links:** [Request temporary credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html)

---

### 6. [ ] Revoking IAM Role Temporary Security Credentials (9:23)

**Khái niệm chính:**
- Cách thu hồi temporary credentials trước khi hết hạn
- **Revoke sessions**: `sts:GetSessionToken` sessions có thể revoke qua IAM
- **AssumeRole**: revoke bằng cách xóa/disable role hoặc thay đổi trust policy

**Cần nhớ:**
- Credentials đã cấp không thể "thu hồi trực tiếp" – phải thay đổi policy/role
- Session token hết hạn = tự động invalid

---

### 7. [ ] [DEMO] Revoking Temporary Credentials - PART1 (12:12)

**Nội dung demo:**
- Setup role, assume role
- Lấy temporary credentials
- Cách credentials bị ảnh hưởng khi thay đổi

---

### 8. [ ] [DEMO] Revoking Temporary Credentials - PART2 (10:20)

**Nội dung demo:**
- Tiếp tục scenario revoke
- Thực hành trên Console/CLI

**Practice CLI:**
```bash
# Assume role (cần role ARN)
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT:role/ROLE_NAME --role-session-name test
```

---

## Phần 3: Policy Interpretation

### 9. [ ] Policy Interpretation Deep Dive - Example 1 (10:23)

**Khái niệm:**
- Thứ tự đánh giá: Explicit Deny → Explicit Allow → Implicit Deny
- Deny luôn thắng

---

### 10. [ ] Policy Interpretation Deep Dive - Example 2 (9:11)

**Khái niệm:**
- Kết hợp nhiều policy
- Resource-based vs Identity-based

---

### 11. [ ] Policy Interpretation Deep Dive - Example 3 (10:59)

**Khái niệm:**
- Scenario phức tạp
- Cách trace effective permission

**Practice:** Làm lại 3 ví dụ trên giấy – vẽ sơ đồ Allow/Deny

---

## Phần 4: Permissions Boundaries & Cross-Account

### 12. [ ] Permissions Boundaries & Use-cases (17:28)

**Khái niệm chính:**
- Permissions Boundary = **giới hạn tối đa** cho IAM entity
- Áp dụng cho User hoặc Role
- Effective = Identity policy ∩ Permissions Boundary
- Use case: Developer tự tạo role nhưng bị giới hạn bởi boundary

**Cần nhớ:**
- Boundary không grant – chỉ restrict ceiling
- Dùng để delegate IAM cho dev mà vẫn có guardrail

**Links:** [Permissions boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)

---

### 13. [ ] AWS Permissions Evaluation (10:25)

**Khái niệm:**
- Thứ tự đánh giá quyền trong AWS
- Policy types: SCP, Permission Boundary, Session Policy, Identity policy, Resource policy

---

## Phần 5: Cross-Account S3

### 14. [ ] [DEMO] Cross Account Access to S3 - SETUP - STAGE1 (4:29)

**Nội dung:** Setup 2 accounts, bucket ở account A

---

### 15. [ ] [DEMO] Cross Account Access to S3 - ACL - STAGE2 (9:39)

**Khái niệm:** S3 ACL (Access Control List) – legacy, ít dùng

---

### 16. [ ] [DEMO] Cross Account Access to S3 - BUCKET POLICY - STAGE3 (9:38)

**Khái niệm chính:**
- Bucket policy = resource-based policy trên S3
- Cho phép principal từ account khác
- `Principal: { "AWS": "arn:aws:iam::ACCOUNT-B:root" }` hoặc role ARN

**Practice Terraform:** (sẽ thêm lab Cross-Account S3)
```hcl
# Bucket policy cho phép account B
resource "aws_s3_bucket_policy" "cross_account" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::ACCOUNT_B:root" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.main.arn}/*"
    }]
  })
}
```

---

### 17. [ ] [DEMO] Cross Account Access to S3 - ROLE - STAGE4 (8:17)

**Khái niệm:**
- Account B: User assume role có quyền S3
- Role trust policy: cho phép account B assume
- Account A: Bucket policy cho phép role ARN của account B

**Luồng:** User (B) → AssumeRole → Role (B) → Access S3 (A) với bucket policy

---

## Phần 6: AWS RAM & Shared VPC

### 18. [ ] AWS Resource Access Manager (RAM) (14:43)

**Khái niệm chính:**
- RAM = share resources **giữa các accounts** mà không copy
- Share được: VPC subnets, Transit Gateway, License Manager, Route 53, …
- Share với: account cụ thể, OU, cả Organization
- Trong Org: không cần invite, auto access

**Cần nhớ:**
- RAM là regional
- Chỉ owner mới share được (không share cái đã được share)

**Links:** [Getting started with RAM](https://docs.aws.amazon.com/ram/latest/userguide/getting-started-sharing.html)

---

### 19. [ ] [DEMO] Shared ORG VPC - PART1 (10:06)

**Nội dung:** Share VPC subnet qua RAM trong Organization

---

### 20. [ ] [DEMO] Shared ORG VPC - PART2 (16:17)

**Nội dung:** Hoàn thiện setup, test connectivity

**Practice Terraform:** (sẽ thêm lab RAM)
```hcl
resource "aws_ram_resource_share" "vpc" {
  name                      = "shared-vpc"
  allow_external_principals = false
}
resource "aws_ram_principal_association" "org" {
  principal          = aws_organizations_organization.main.arn
  resource_share_arn = aws_ram_resource_share.vpc.arn
}
```

---

## Phần 7: Service Quotas & Quiz

### 21. [ ] Service Quotas (13:27)

**Khái niệm chính:**
- Service Quotas = giới hạn tài nguyên/action của mỗi service
- Soft limit: có thể request tăng
- Hard limit: không đổi
- Mỗi region, mỗi account có quota riêng

**Cần nhớ:**
- Service Quotas console: xem và request tăng
- Account mới có thể có quota thấp hơn

**Links:** [Service Quotas](https://docs.aws.amazon.com/servicequotas/latest/userguide/intro.html)

---

### 22. [ ] SECTION QUIZ - ADVANCED PERMISSIONS & ACCOUNTS

**Ôn tập:**
- [ ] AWS Organizations: Management vs Member, OUs, Root
- [ ] SCP: Deny only, inheritance, Management account exempt
- [ ] STS: Temporary credentials, AssumeRole
- [ ] Permissions Boundary vs SCP
- [ ] Cross-account: Bucket policy, AssumeRole
- [ ] RAM: Share resources trong Org
- [ ] Service Quotas: Soft vs Hard limit

---

## Tổng hợp Terraform Practice

| Bài | Terraform / Practice |
|-----|----------------------|
| 2 | `aws-organizations/` – org, OUs |
| 4 | `service-control-policies.tf` – SCP |
| 8 | `aws sts assume-role` |
| 16–17 | Cross-account S3 (bucket policy + role) |
| 19–20 | RAM resource share |

---

## Tài liệu tham khảo

- [AWS_ORGANIZATIONS.md](./AWS_ORGANIZATIONS.md) – Organizations, SCP, links chính thức
- [AWS IAM Policy Evaluation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- [AWS RAM Shareable Resources](https://docs.aws.amazon.com/ram/latest/userguide/shareable.html)
