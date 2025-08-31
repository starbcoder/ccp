# TikTokDemoVPC - S3 VPC Endpoints Lab (Console-Only)
**AWS Certified Cloud Practitioner / Associate Friendly**  
Build and compare S3 Gateway Endpoint vs S3 Interface Endpoint using a private subnet in the Default VPC.

---

## Prerequisites
- Region: choose your preferred region (examples assume `us-west-2`)
- AWS account with Administrator access
- All steps use the AWS Management Console only

---

## Goal & Architecture (Default VPC)
- Use the Default VPC: typically `172.31.0.0/16` with an Internet Gateway already attached
- Create a new private subnet (no public IPs, no route to IGW)
- Add an EC2 Instance Connect Endpoint (EICE) so you can connect to the private instance without a public IP
- Attach an IAM role to the EC2 instance granting full S3 access
- First, create an S3 Gateway VPC Endpoint and verify S3 access from the private instance
- Then delete the Gateway endpoint, create an S3 Interface Endpoint, enable Private DNS, and verify S3 access again

Notes:
- The EC2 Instance Connect Endpoint (EICE) creation has a special console flow and does not support endpoint policies.
- The private subnet CIDR must be inside the Default VPC CIDR; we will use `172.31.64.0/20` in one AZ as an example.

---

## Task 1: Create a Private Subnet (in the Default VPC)
1. VPC → Your VPCs → find the VPC with the name tag `default` (or the one marked as Default) and CIDR like `172.31.0.0/16`.
2. VPC → Subnets → Create subnet
   - VPC: select the Default VPC
   - Subnet name: `PrivateSubnet-NoIGW`
   - Availability Zone: e.g., `us-west-2a`
   - IPv4 CIDR block: `172.31.64.0/20` (inside `172.31.0.0/16`)
   - Create subnet
3. Select the new subnet → Actions → Edit subnet settings
   - Turn OFF Auto-assign public IPv4 address
   - Save

Why a custom route table? The Default VPC's main route table typically has `0.0.0.0/0 → igw-...`. We'll isolate this subnet by associating a private-only route table.

---

## Task 2: Create a Private-Only Route Table and Associate It
1. VPC → Route tables → Create route table
   - Name: `PrivateOnly-RT`
   - VPC: Default VPC
   - Create route table
2. Select `PrivateOnly-RT` → Routes tab
   - Ensure the only route is the implicit local route `172.31.0.0/16 → local`
   - Do NOT add any `0.0.0.0/0` route
3. Subnet associations → Edit subnet associations → select `PrivateSubnet-NoIGW` → Save

Result: Instances in this subnet will have no internet egress.

---

## Task 3: Security Groups
Create two security groups in the Default VPC.

### 3.1 `eice-sg`
1. EC2 → Security Groups → Create security group
2. Name: `eice-sg` | VPC: Default VPC
3. Inbound rules:
   - HTTPS (443) → Source: `0.0.0.0/0`
4. Outbound rules: leave default (All traffic)

### 3.2 `private-ec2-sg`
1. Create another SG: Name `private-ec2-sg` | VPC: Default VPC
2. Inbound rules:
   - SSH (22) → Source: `eice-sg` (select the SG as the source)
3. Outbound rules: default (All traffic)

This allows the EC2 Instance Connect Endpoint to initiate SSH to the instance.

---

## Task 4: Create EC2 Instance Connect Endpoint (EICE)
1. VPC → Endpoints → Choose EC2 Instance Connect Endpoint
2. VPC: Default VPC
3. Subnets: select `PrivateSubnet-NoIGW`
4. Security group: `eice-sg`
5. Policy: Note that EICE does not support endpoint policies (option not shown)
6. Create endpoint and wait for status `Available`

---

## Task 5: Create IAM Role for EC2 with Full S3 Access
1. IAM → Roles → Create role
2. Trusted entity type: AWS service → Use case: EC2
3. Permissions policies: attach `AmazonS3FullAccess`
4. Role name: `EC2Role-S3FullAccess`
5. Create role

---

## Task 6: Launch a Private EC2 Instance
1. EC2 → Instances → Launch instances
   - Name: `PrivateS3Client`
   - AMI: Amazon Linux 2023
   - Instance type: `t3.micro`
   - Key pair: None (we will use EC2 Instance Connect via the EICE)
2. Network settings:
   - VPC: Default VPC
   - Subnet: `PrivateSubnet-NoIGW`
   - Auto-assign public IP: Disabled
   - Security group: `private-ec2-sg`
3. IAM role: select `EC2Role-S3FullAccess`

## Task 7: Connect to the Private Instance via EC2 Instance Connect
1. EC2 → Instances → select `PrivateS3Client` → Connect
2. Choose the "EC2 Instance Connect (Endpoint)" tab (or EC2 Instance Connect tab depending on console layout)
3. Select your `ec2-instance-connect` endpoint if prompted → Connect
4. You should get a browser-based shell to the instance with no public IP.

---

## Pre-Check: Verify S3 access fails (no endpoints)
From the private instance shell, confirm you cannot reach S3 yet (expected):
```bash
# This should FAIL because there is no internet egress and no VPC endpoint yet
aws s3 ls || echo "Expected failure: no S3 route (no IGW/NAT or VPC endpoint)"

```
This failure is expected until you add an S3 VPC endpoint.

---

## Task 8: Create an S3 Gateway VPC Endpoint and Verify
1. VPC → Endpoints → Create endpoint
2. Service category: AWS services
3. Search `s3` and select the service name `com.amazonaws.<region>.s3`
4. Endpoint type: `Gateway`
5. VPC: Default VPC
6. Route tables: select `PrivateOnly-RT` (the route table for your private subnet)
7. Policy: Full access (you can tighten later)
8. Create endpoint; wait until `Available`

Test from the private instance (browser shell):
```bash
# List buckets (requires the role permissions)
aws s3 ls

# Optional: create, list, and access an object using the regional endpoint
TEST_BUCKET=tiktok-s3-endpoint-lab-$(date +%s)
aws s3 mb s3://$TEST_BUCKET
echo hello > hello.txt
aws s3 cp hello.txt s3://$TEST_BUCKET/
aws s3 ls s3://$TEST_BUCKET/
```
The S3 calls should succeed without internet egress because the Gateway endpoint routes S3 traffic via the VPC prefix list.

---

## Task 9: Switch to an S3 Interface Endpoint and Verify
1. VPC → Endpoints → select the S3 Gateway endpoint → Actions → Delete endpoint → confirm
2. Create a new endpoint
   - Service category: AWS services
   - Search `s3` and select `com.amazonaws.<region>.s3`
   - Endpoint type: `Interface`
   - VPC: Default VPC
   - Subnets: select `PrivateSubnet-NoIGW`
   - Security group: create/select `s3-interface-endpoint-sg` allowing inbound HTTPS (443) from `private-ec2-sg` (or from the subnet CIDR)
   - Enable `Enable DNS name` / `Enable private DNS name` for the service (Private DNS)
   - Policy: Full access
   - Create endpoint and wait until `Available`

Test again from the private instance:
```bash
aws s3 ls
aws s3 ls s3://$TEST_BUCKET/
```
With Private DNS enabled, S3 DNS names resolve to the VPC endpoint's private IPs, keeping traffic inside the VPC.

---

## Cleanup
1. On the instance shell, remove any test data and bucket (if created):
```bash
aws s3 rm s3://$TEST_BUCKET/hello.txt || true
aws s3 rb s3://$TEST_BUCKET --force || true
```
2. EC2 → Instances → terminate `PrivateS3Client`
3. VPC → Endpoints → delete the S3 Interface endpoint
4. VPC → Endpoints → delete the EC2 Instance Connect endpoint
5. EC2 → Security Groups → delete `s3-interface-endpoint-sg`, `private-ec2-sg`, and `eice-sg` if unused
6. VPC → Route tables → disassociate and delete `PrivateOnly-RT` if unused
7. VPC → Subnets → delete `PrivateSubnet-NoIGW` if unused
8. IAM → Roles → delete `EC2Role-S3FullAccess` if not needed

---


