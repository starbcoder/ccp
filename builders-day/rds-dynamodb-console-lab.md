# RDS + DynamoDB Builder's Day - Console Lab for CCP Beginners
**AWS Certified Cloud Practitioner**  
*End-to-end lab using AWS Management Console and simple CLI on EC2*

---

## Prerequisites
- AWS account with Administrator access
- Region: use **US West (Oregon) us-west-2** (or your preferred region)
- Default VPC must exist in the chosen region (it does by default)

## Important Notes
- We stick to defaults and avoid advanced configs.
- We will create one EC2 instance, one RDS MySQL DB, and one DynamoDB table.
- EC2 connects to RDS privately inside the default VPC. No public DB access is needed.

---

## Architecture Overview
- Default VPC → public subnet EC2 (t3.micro)
- Default VPC → RDS MySQL (db.t3.micro) in default subnets (Public access: No)
- Security: RDS SG allows MySQL only from the EC2 SG
- DynamoDB is a regional service (no VPC). EC2 gets an IAM role for DynamoDB CRUD via AWS CLI

---

## Task 1: Launch EC2 Instance (Amazon Linux, t3.micro)
1. Open AWS Management Console → EC2 → Instances → Launch instances
2. Name: `ccp-lab-ec2`
3. Application and OS Images (AMI): `Amazon Linux 2023` (default)
4. Instance type: `t3.micro` (Free Tier eligible)
5. Key pair: None required (we will use EC2 Instance Connect)
6. Network settings:
   - VPC: `default`
   - Subnet: Default subnet in your AZ
   - Auto-assign public IP: Enabled (default)
   - Security group: Create new (default wizard)
     - Inbound rule: SSH on port 22 from `My IP`
7. Storage: Keep defaults
8. Launch instance

Wait until the instance state is `Running` and status checks pass.

---

## Task 2: Create RDS MySQL (Free Tier) in Default VPC
1. Console → RDS → Databases → Create database
2. Engine options: `MySQL`
3. Templates: `Free tier`
4. Settings:
   - DB instance identifier: `ccp-lab-mysql`
   - Master username: `root` (use `root` for this lab)
   - Master password: `LabPassword123!` (use exactly this for the lab)
   - Note: You cannot retrieve the master password later from RDS. Record it now.
5. DB instance class: `db.t3.micro` (default for free tier)
6. Storage: Defaults are fine
7. Connectivity:
   - VPC: `default`
   - Public access: `No`
   - VPC security group: `Create new` (name it `rds-lab-sg`) or select an existing empty SG
   - Availability Zone: No preference (default)
   - Database authentication: Password authentication (default)
8. Additional configuration: leave defaults; do not create an initial database (we'll create one)
9. Create database

Note: Provisioning takes 10–15 minutes. Continue with the next task while it creates.

---

## Task 3: Allow EC2 to Reach RDS (Security Group to Security Group)
1. Console → EC2 → Instances → select `ccp-lab-ec2` → Security tab
2. Note the instance security group ID (e.g., `sg-xxxxxxxxxxxx`) – call it `ec2-lab-sg`
3. Console → RDS → Databases → select `ccp-lab-mysql` → Connectivity & security → VPC security groups → click the `rds-lab-sg`
4. In the security group details, Inbound rules → Edit inbound rules
5. Add rule:
   - Type: `MySQL/Aurora` (3306)
   - Source: `Custom` → choose `ec2-lab-sg` (the EC2 instance's SG)
6. Save rules

This permits private VPC traffic from the EC2 instance to the RDS instance on port 3306.

---

## Task 4: Connect to EC2 via Instance Connect and Install MySQL Client
1. Console → EC2 → Instances → select `ccp-lab-ec2` → Connect → EC2 Instance Connect → Connect
2. In the terminal, install MySQL client (Amazon Linux 2023):
```bash
sudo dnf install -y mysql
```
3. Set default region for AWS CLI (for later DynamoDB steps):
```bash
aws configure set region us-west-2
```

---

## Task 5: Connect to RDS and Perform MySQL CRUD
1. Get the RDS endpoint: Console → RDS → `ccp-lab-mysql` → Connectivity & security → Endpoint (something like `ccp-lab-mysql.xxxxxx.us-west-2.rds.amazonaws.com`)
2. From the EC2 shell, connect (replace placeholders):
```bash
mysql -h <RDS_ENDPOINT> -u root -p
```
   When prompted, enter: `LabPassword123!`
3. In the MySQL prompt, create a database and table with four columns:
```sql
CREATE DATABASE labdb;
USE labdb;
CREATE TABLE items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  category VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
4. CRUD operations:
   - Create:
```sql
INSERT INTO items (name, category) VALUES ('Widget', 'tools');
```
   - Read:
```sql
SELECT * FROM items;
```
   - Update:
```sql
UPDATE items SET name = 'Widget Pro' WHERE id = 1;
```
   - Delete:
```sql
DELETE FROM items WHERE id = 1;
```
5. Exit:
```sql
EXIT;
```

---

## Task 6: Create DynamoDB Table (4 Attributes in Items)
1. Console → DynamoDB → Tables → Create table
2. Table name: `lab-items`
3. Partition key: `id` (String)
4. Leave other settings as defaults → Create table

Note: DynamoDB is schemaless except keys. We will store four attributes per item to mirror the MySQL table: `id`, `name`, `category`, `created_at`.

---

## Task 7: Grant EC2 Access to DynamoDB (IAM Role)
1. Console → IAM → Roles → Create role
2. Trusted entity: `AWS service`
3. Use case: `EC2`
4. Permissions: attach policy `AmazonDynamoDBFullAccess` (lab simplicity)
5. Role name: `EC2DynamoDBLabRole`
6. Create role
7. Attach role to instance: Console → EC2 → Instances → select `ccp-lab-ec2` → Actions → Security → Modify IAM role → choose `EC2DynamoDBLabRole` → Update IAM role

---

## Task 8: DynamoDB CRUD from EC2 via AWS CLI
From your EC2 Instance Connect terminal:

1. Create (PutItem):
```bash
aws dynamodb put-item \
  --table-name lab-items \
  --item '{"id":{"S":"1"},"name":{"S":"Widget"},"category":{"S":"tools"},"created_at":{"S":"2025-01-01T12:00:00Z"}}'
```
2. Read (GetItem):
```bash
aws dynamodb get-item \
  --table-name lab-items \
  --key '{"id":{"S":"1"}}'
```
3. Update (UpdateItem):
```bash
aws dynamodb update-item \
  --table-name lab-items \
  --key '{"id":{"S":"1"}}' \
  --update-expression 'SET #n = :v' \
  --expression-attribute-names '{"#n":"name"}' \
  --expression-attribute-values '{":v":{"S":"Widget Pro"}}'
```
4. Read All (Scan):
```bash
aws dynamodb scan --table-name lab-items
```
5. Delete (DeleteItem):
```bash
aws dynamodb delete-item \
  --table-name lab-items \
  --key '{"id":{"S":"1"}}'
```

---

## Task 9: Cleanup
Perform cleanup to avoid charges.

1. DynamoDB: Console → DynamoDB → Tables → `lab-items` → Delete table
2. RDS: Console → RDS → Databases → `ccp-lab-mysql` → Actions → Delete →
   - Skip final snapshot (for lab) → type `delete me` → Delete
3. EC2: Console → EC2 → Instances → `ccp-lab-ec2` → Instance state → Terminate instance
4. IAM: Console → IAM → Roles → delete `EC2DynamoDBLabRole` (if not reused)

---

## Summary
- You launched an EC2 instance and used Instance Connect
- You created an RDS MySQL database in the default VPC and connected privately
- You created a table with four columns and performed CRUD with MySQL client
- You created a DynamoDB table and performed CRUD via AWS CLI from EC2 using an IAM role
- You cleaned up all resources


