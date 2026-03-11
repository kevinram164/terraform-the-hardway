# Tài liệu học AWS Organizations

Tài liệu chi tiết cho Module 1 – Advanced Permissions & Accounts. Đọc trực tiếp, không cần mở link ngoài.

---

## 1. Tổng quan & Khái niệm

### 1.1 AWS Organizations là gì?

**AWS Organizations** là dịch vụ giúp bạn quản lý nhiều tài khoản AWS trong một tổ chức (organization). Thay vì đăng nhập từng account riêng lẻ, bạn có một điểm trung tâm để:

- **Gộp hóa đơn** (Consolidated Billing): Một thẻ thanh toán cho tất cả accounts
- **Tổ chức accounts** theo cây phân cấp (Organizational Units – OUs)
- **Áp dụng chính sách** (Service Control Policies – SCPs) cho cả nhóm accounts
- **Tạo accounts mới** từ management account mà không cần email riêng cho mỗi account (khi dùng AWS Control Tower hoặc script)

**Use cases thường gặp:**

| Use case | Mô tả |
|----------|-------|
| Tách môi trường | Dev, Staging, Prod mỗi môi trường một account – giảm rủi ro khi lỗi |
| Giới hạn tài nguyên | Mỗi account có quota riêng (VPC, EC2, …) – tránh một team dùng hết |
| Phân quyền rõ ràng | Team A chỉ truy cập account Dev, không đụng Prod |
| Hóa đơn theo team | Xem chi phí từng account, chargeback nội bộ |
| Compliance | SCP chặn region, service – đảm bảo data sovereignty, security |

---

### 1.2 Cấu trúc Organization

Một Organization gồm:

```
                    ROOT (gốc)
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   OU: Security    OU: Workloads    OU: Sandbox
        │               │
        ▼               ├── OU: Dev
   Account A            ├── OU: Staging
                        └── OU: Prod
                             │
                             ├── Account B
                             └── Account C
```

- **Root**: Nút gốc, mọi thứ nằm dưới Root
- **Management Account**: Account tạo Organization – có quyền cao nhất, **không** bị SCP áp dụng
- **Member Account**: Các account được mời vào hoặc tạo trong org
- **OU (Organizational Unit)**: Nhóm logic để gom accounts, có thể lồng nhau (OU trong OU)

---

### 1.3 Management Account vs Member Account

| | Management Account | Member Account |
|---|-------------------|----------------|
| **Vai trò** | Tạo org, quản trị toàn bộ | Account thành viên, dùng để chạy workload |
| **SCP** | **Không** bị SCP áp dụng | Bị SCP áp dụng |
| **Rời org** | Không thể (org gắn với account này) | Có thể (trừ khi SCP chặn) |
| **Chuyển vai trò** | Không thể chuyển Management sang account khác | Có thể promote member lên Management (trường hợp đặc biệt) |

**Lưu ý:** Management account thường dùng để quản trị, không chạy ứng dụng. Workload nên đặt ở member accounts.

---

### 1.4 Feature Set

Khi tạo Organization, bạn chọn feature set:

| Feature Set | Gồm những gì |
|-------------|---------------|
| **CONSOLIDATED_BILLING** | Chỉ gộp hóa đơn. Không có SCP, Tag policy, Backup policy |
| **ALL** | Consolidated Billing + SCPs + Tag policies + Backup policies |

**Dùng SCP thì bắt buộc chọn ALL.** Không thể nâng cấp từ CONSOLIDATED_BILLING lên ALL sau khi tạo – phải tạo org mới.

---

### 1.5 Tạo Organization, OUs, mời accounts

**Tạo Organization:**

- Chỉ account **standalone** (chưa thuộc org nào) mới tạo được
- Vào AWS Console → Organizations → Create organization
- Chọn feature set (ALL nếu cần SCP)
- Account hiện tại trở thành Management account

**Tạo OU:**

- Trong Organizations, chọn Root hoặc OU cha
- Create organizational unit → đặt tên (ví dụ: Security, Workloads)
- Có thể tạo OU con (ví dụ: Workloads → Dev, Staging, Prod)

**Mời account:**

- Add account → Invite account
- Nhập email của account cần mời
- Owner account đó nhận email, vào Organizations → Accept invite
- Sau khi accept, account trở thành member

**Tạo account mới (trong org):**

- Add account → Create account
- Nhập tên account và email (phải chưa dùng cho AWS)
- Account mới được tạo và tự động là member, không cần invite

---

### 1.6 Quản lý Organization

**Di chuyển account giữa các OU:**

- Chọn account → Move → chọn OU đích
- Account kế thừa SCP của OU mới

**Xóa OU:**

- OU phải trống (không có account, không có OU con)
- Di chuyển accounts ra trước khi xóa

**Rời Organization (member account):**

- Vào Organizations trong member account → Leave organization
- Chỉ làm được nếu không có SCP chặn `organizations:LeaveOrganization`

---

## 2. Service Control Policies (SCPs)

### 2.1 SCP là gì, cách hoạt động

**Service Control Policy (SCP)** là policy ở cấp Organization dùng để đặt **giới hạn tối đa** (guardrail) cho quyền trong các member accounts.

**Điểm quan trọng:**

1. **SCP không grant quyền** – Chỉ có thể **Deny** hoặc giới hạn. Quyền thực tế vẫn do IAM policy cấp.
2. **SCP không áp dụng cho Management account** – Chỉ member accounts bị ảnh hưởng.
3. **Effective permission = IAM Policy ∩ SCP** – Phần giao. IAM cho phép X, SCP chặn X → kết quả là Deny.

**Ví dụ:**

- IAM user có policy: `ec2:*` (mọi thao tác EC2, mọi region)
- SCP: Deny mọi thao tác nếu region khác `ap-southeast-1`
- Kết quả: User chỉ dùng được EC2 ở `ap-southeast-1`

---

### 2.2 Cú pháp SCP (JSON)

SCP dùng cú pháp giống IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MoTaNgan",
      "Effect": "Deny",
      "Action": ["service:Action1", "service:Action2"],
      "Resource": "*",
      "Condition": {
        "Điều kiện": "Giá trị"
      }
    }
  ]
}
```

**Các thành phần:**

| Thành phần | Mô tả |
|------------|-------|
| **Version** | Luôn `"2012-10-17"` |
| **Statement** | Mảng các statement – mỗi statement là một quy tắc |
| **Sid** | Tên ngắn cho statement (tùy chọn) |
| **Effect** | `Allow` hoặc `Deny`. SCP thường dùng `Deny` |
| **Action** | API action bị ảnh hưởng (ví dụ: `ec2:RunInstances`) |
| **NotAction** | Mọi action **trừ** các action liệt kê – dùng khi muốn Deny "tất cả trừ X" |
| **Resource** | Thường `"*"` trong SCP |
| **Condition** | Điều kiện (region, MFA, tag, …) |

**Condition thường dùng:**

| Condition key | Ý nghĩa |
|---------------|---------|
| `aws:RequestedRegion` | Region mà request gửi tới |
| `aws:MultiFactorAuthPresent` | Có MFA hay không |
| `aws:PrincipalArn` | ARN của principal (user, role) |
| `aws:PrincipalAccount` | Account ID của principal |

---

### 2.3 Cách AWS đánh giá SCP

**Thứ tự đánh giá quyền trong AWS (tóm tắt):**

1. **Explicit Deny** – Nếu có Deny (từ SCP, IAM, resource policy) → **Denied**
2. **Explicit Allow** – Nếu có Allow và không bị Deny → **Allowed**
3. **Implicit Deny** – Mặc định → **Denied**

**SCP kế thừa theo cây:**

- SCP gắn vào Root → áp dụng cho **tất cả** accounts trong org
- SCP gắn vào OU → áp dụng cho accounts trong OU đó và các OU con
- Một account chịu **tất cả** SCP từ Root xuống đến OU chứa nó

**Ví dụ:**

```
Root
 ├── SCP-1: Deny LeaveOrg (gắn Root)
 └── OU: Workloads
      ├── SCP-2: Restrict regions (gắn Workloads)
      └── Account-123
```

Account-123 chịu **cả** SCP-1 và SCP-2. Chỉ cần **một** Deny trùng với request → Denied.

---

### 2.4 Ví dụ SCP thường dùng

#### Deny leave organization

Không cho member account rời org:

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

#### Restrict regions

Chỉ cho phép dùng một số region (ví dụ: data sovereignty):

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

`NotAction` = Deny mọi thứ **trừ** các service global (IAM, Route53, …) khi request **không** ở region cho phép. Các service global thường không gắn region nên cần exclude.

#### Require MFA for root

Chặn root user nếu không có MFA (trừ các API cần thiết để bật MFA):

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

#### Deny root user

Không cho dùng root user (chỉ dùng IAM user/role):

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

## 3. Terraform AWS Organizations

### 3.1 Resources chính

| Resource | Mô tả |
|----------|-------|
| `aws_organizations_organization` | Tạo/quản lý Organization |
| `aws_organizations_organizational_unit` | Tạo OU |
| `aws_organizations_account` | Tạo account mới trong org |
| `aws_organizations_policy` | Tạo policy (SCP, Tag policy, …) |
| `aws_organizations_policy_attachment` | Gắn policy vào Root/OU/Account |

### 3.2 Data Sources

| Data Source | Mô tả |
|-------------|-------|
| `aws_organizations_organization` | Lấy thông tin org hiện tại (khi đã có org, không tạo mới) |
| `aws_organizations_organizational_units` | Lấy danh sách OUs con của parent |

### 3.3 Ví dụ Terraform

**Tạo org:**

```hcl
resource "aws_organizations_organization" "main" {
  feature_set = "ALL"
}
```

**Lấy Root ID** (dùng làm parent cho OU top-level):

```hcl
aws_organizations_organization.main.roots[0].id
```

**Tạo OU:**

```hcl
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.main.roots[0].id
}
```

**Tạo SCP và gắn vào Root:**

```hcl
resource "aws_organizations_policy" "deny_leave" {
  name        = "DenyLeaveOrg"
  description = "Prevent leaving organization"
  content     = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "organizations:LeaveOrganization"
      Resource = "*"
    }]
  })
}

resource "aws_organizations_policy_attachment" "deny_leave_root" {
  policy_id = aws_organizations_policy.deny_leave.id
  target_id = aws_organizations_organization.main.roots[0].id
}
```

---

## 4. Câu hỏi thường gặp

**Q: Account đã trong org có tạo org mới được không?**  
A: Không. Chỉ account standalone mới tạo được.

**Q: Có thể chuyển Management account sang account khác không?**  
A: Không. Management account cố định.

**Q: SCP có grant quyền không?**  
A: Không. SCP chỉ Deny hoặc giới hạn. Quyền vẫn do IAM policy cấp.

**Q: Management account có bị SCP không?**  
A: Không. SCP chỉ áp dụng cho member accounts.

**Q: Có thể dùng SCP với feature set CONSOLIDATED_BILLING không?**  
A: Không. Cần feature set ALL.

---

## 5. Liên quan đến NAB

- NAB dùng **Terraform Enterprise** để quản lý infrastructure
- Multi-account: AWS + Azure
- SCP: ví dụ **restrict regions** (Sydney – data sovereignty)
- Compliance: Sentinel policy as code
