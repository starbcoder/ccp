# S3 Builder's Day - Console Lab for CCP Beginners
**AWS Certified Cloud Practitioner**  
*Complete S3 lab using AWS Management Console - No CLI required*

---

## Prerequisites
- AWS Account with admin access
- All resources will be created in **us-west-2** (except replication bucket in us-west-1)
- Basic familiarity with AWS Management Console

## ⚠️ Important Note
**This lab uses the AWS Management Console for ALL resource creation and configuration. The ONLY CLI commands used are for testing access points in CloudShell. Everything else is done through the web interface.**

---

## Task 1: Create Demo Files Structure

### 1.1 Create demo_s3 folder with files
Create the following folder structure and files on your local machine:

```
demo_s3/
├── index.html
├── error.html
├── sample-image.jpg
├── v1/
│   └── index.html
├── v2/
│   └── index.html
└── dev/
    └── test-file.txt
```

**Use the HTML files provided in the `builders-day/demo_s3/` folder.**

### 1.2 Sample Image
Download any AWS architecture image and save it as `sample-image.jpg` in the demo_s3 folder.

---

## Task 2: Create S3 Bucket and IAM User

### 2.1 Create S3 Bucket (AWS Management Console)
1. **Open AWS Management Console**
2. **Navigate to S3 service**
3. **Click "Create bucket"**
4. **Bucket configuration:**
   - Bucket name: `your-unique-bucket-name` (globally unique)
   - Region: **US West (Oregon) us-west-2**
   - Block Public Access settings: **Keep all defaults** (we'll change later)
   - Bucket Versioning: **Disable** (we'll enable later)
   - Tags: Optional
5. **Click "Create bucket"**
6. Upload the files inside **demo_s3**

### 2.2 Create IAM User (AWS Management Console)
1. **Navigate to IAM service**
2. **Click "Users" → "Create user"**
3. **User details:**
   - User name: `s3-user`
   - Access type: **Management Console**
4. **Click "Next: Permissions"**
5. **Attach policies:**
   - **Attach the AWSCloudShellFullAccess policy**
6. **Click "Next: Tags" → "Next: Review" → "Create user"**

### 2.3 Test User Access (Should Fail)
1. **Open a new browser tab**
2. **Navigate to AWS Management Console**
3. **Sign in with s3-user credentials:**
4. **Try to access S3 service using CloudShell**
5. ```bash
   aws sts get-caller-identity

   aws s3api list-objects --bucket YOUR_S3_BUCKET

   aws s3api get-object --bucket YOUR_S3_BUCKET --key dev/test-file.txt
   ```
6. **Expected Result:** Access Denied error

**Note:** All resource creation is done through the AWS Management Console. Only testing will be done via CloudShell CLI commands.

---

## Task 3: Grant S3 Permissions via IAM

### 3.1 Create IAM Policy (AWS Management Console)
1. **Navigate to IAM service** (as admin user)
2. **Click "Policies" → "Create policy"**
3. **Choose JSON tab and paste:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-unique-bucket-name",
                "arn:aws:s3:::your-unique-bucket-name/*"
            ]
        }
    ]
}
```
4. **Click "Next: Tags" → "Next: Review"**
5. **Policy name:** `S3DemoPolicy`
6. **Click "Create policy"**

### 3.2 Attach Policy to User (AWS Management Console)
1. **Navigate to IAM → Users**
2. **Click on `s3-user`**
3. **Click "Add permissions"**
4. **Choose "Attach existing policies directly"**
5. **Search for `S3DemoPolicy` and select it**
6. **Click "Next: Review" → "Add permissions"**

### 3.3 Test Access (Should Work)
**This testing is done through CloudShell**
1. **Sign in as s3-user again**
2. **Navigate to the CloudShell service**
3. ```bash
   aws sts get-caller-identity

   aws s3api list-objects --bucket YOUR_S3_BUCKET

   aws s3api get-object --bucket YOUR_S3_BUCKET --key dev/test-file.txt
   ```
4. **Expected Result:** You can see the bucket contents

---

## Task 4: Remove IAM Permissions and Use Bucket Policy

### 4.1 Remove IAM Policy (AWS Management Console)
1. **Navigate to IAM → Users** (as admin user)
2. **Click on `s3-user`**
3. **Click "Permissions" tab**
4. **Find `S3DemoPolicy` and click "Detach"**
5. **Confirm detachment**

### 4.2 Test Access (Should Fail)
**This testing is done through CloudShell**
1. **Sign in as s3-user again**
2. **Navigate to the CloudShell service**
3. ```bash
   aws sts get-caller-identity

   aws s3api list-objects --bucket YOUR_S3_BUCKET

   aws s3api get-object --bucket YOUR_S3_BUCKET --key dev/test-file.txt
   ```
4. **Expected Result:** Access Denied error

### 4.3 Create Bucket Policy (AWS Management Console)
1. **Navigate to S3 service** (as admin user)
2. **Click on your bucket name**
3. **Click "Permissions" tab**
4. **Scroll to "Bucket policy" section**
5. **Click "Edit"**
6. **Paste this policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3UserAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::YOUR-ACCOUNT-ID:user/s3-user"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-unique-bucket-name",
                "arn:aws:s3:::your-unique-bucket-name/*"
            ]
        }
    ]
}
```
7. **Replace `YOUR-ACCOUNT-ID` with your 12-digit account ID**
8. **Replace `your-unique-bucket-name` with your actual bucket name**
9. **Click "Save changes"**

### 4.4 Test Access (Should Work)
**This testing is done through CloudShell**
1. **Sign in as s3-user again**
2. **Navigate to the CloudShell service**
3. ```bash
   aws sts get-caller-identity

   aws s3api list-objects --bucket YOUR_S3_BUCKET

   aws s3api get-object --bucket YOUR_S3_BUCKET --key dev/test-file.txt
   ```
4. **Expected Result:** You can access the bucket

---

## Task 5: Upload Files and Enable Static Hosting

### 5.1 Upload Demo Files (AWS Management Console)
1. **Navigate to S3 bucket** (as admin user)
2. **Click "Upload"**
3. **Click "Add files" and select all files from demo_s3 folder**
4. **Click "Upload"**
5. **Verify all files are uploaded**

### 5.2 Enable Static Website Hosting (AWS Management Console)
1. **In your S3 bucket, click "Properties" tab**
2. **Scroll to "Static website hosting" section**
3. **Click "Edit"**
4. **Select "Enable"**
5. **Index document:** `index.html`
6. **Error document:** `error.html`
7. **Click "Save changes"**
8. **Note the website endpoint URL**

### 5.3 Configure Bucket for Public Read Access (AWS Management Console)
1. **Click "Permissions" tab**
2. **Scroll to "Block public access" section**
3. **Click "Edit"**
4. **Uncheck all boxes** (for demo purposes only)
5. **Click "Save changes"**
6. **Update bucket policy to allow public read:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-unique-bucket-name/*"
        },
        {
            "Sid": "AllowS3UserAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::YOUR-ACCOUNT-ID:user/s3-user"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-unique-bucket-name",
                "arn:aws:s3:::your-unique-bucket-name/*"
            ]
        }
    ]
}
```

### 5.4 Test Static Website
**This testing is done through a web browser - no CLI commands needed.**
1. **Copy the website endpoint URL**
2. **Open in a new browser tab**
3. **Expected Result:** You see the main index.html page

---

## Task 6: Test Object Versioning

### 6.1 Enable Versioning (AWS Management Console)
1. **In your S3 bucket, click "Properties" tab**
2. **Scroll to "Bucket Versioning" section**
3. **Click "Edit"**
4. **Select "Enable"**
5. **Click "Save changes"**

### 6.2 Upload Version 1 (AWS Management Console)
1. **Click "Objects" tab**
2. **Click "Upload"**
3. **Upload `v1/index.html` as `index.html`**
4. **This overwrites the existing index.html**

### 6.3 Upload Version 2 (AWS Management Console)
1. **Click "Upload" again**
2. **Upload `v2/index.html` as `index.html`**
3. **This creates a new version**

### 6.4 View Versions (AWS Management Console)
1. **Click on `index.html`**
2. **Click "Versions" tab**
3. **You should see multiple versions**

### 6.5 Delete Current Version (AWS Management Console)
1. **Select the current version of `index.html`**
2. **Click "Delete"**
3. **This creates a delete marker**

### 6.6 Restore Previous Version (AWS Management Console)
1. **In the "Versions" tab, find the previous version**
2. **Select it and click "Delete" (this removes the delete marker)**
3. **Or copy the previous version to create a new current version**

**Verify the website now shows the restored content.**

---

## Task 7: Test Cross-Region Replication

### 7.1 Create Destination Bucket (AWS Management Console)
1. **Navigate to S3 service**
2. **Click "Create bucket"**
3. **Bucket name:** `your-unique-bucket-name-replicated`
4. **Region:** **US West (N. California) us-west-1**
5. **Enable versioning during creation**
6. **Click "Create bucket"**

### 7.2 Create Replication Role (AWS Management Console)
1. **We can ignore this as we are doing it from the Management Console and an IAM role would be created for us**

### 7.3 Configure Replication (AWS Management Console)
1. **Navigate to source bucket**
2. **Click "Management" tab**
3. **Scroll to "Replication rules"**
4. **Click "Create replication rule"**
5. **Rule name:** `ReplicateAll`
6. **Source:** Entire bucket
7. **Destination:** Choose your replicated bucket
8. **IAM role:** Select `Create new role`
9. **Click "Create rule"**

### 7.4 Test Replication (AWS Management Console)
1. **Upload a new file to source bucket**
2. **Wait 15-30 minutes**
3. **Navigate to destination bucket (us-west-1)**
4. **Check if file appears**

---

## Task 8: S3 Access Points

### 8.1 Create Access Point (AWS Management Console)
1. **Navigate to S3 service**
2. **Click "Access points" in left sidebar**
3. **Click "Create access point"**
4. **Access point name:** `dev-access-point`
5. **Bucket:** Select your bucket
6. **Network access:** Internet
7. **Click "Create access point"**

### 8.2 Update Bucket Policy for Access Point (AWS Management Console)
1. **Navigate to your bucket**
2. **Click "Permissions" tab**
3. **Update bucket policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "*",
            "Resource": [
                "arn:aws:s3:::your-unique-bucket-name",
                "arn:aws:s3:::your-unique-bucket-name/*"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:DataAccessPointAccount": "YOUR-ACCOUNT-ID"
                }
            }
        }
    ]
}
```

### 8.3 Create Access Point Policy (AWS Management Console)
1. **Navigate to Access Points**
2. **Click on `dev-access-point`**
3. **Click "Permissions" tab**
4. **Click "Edit" for access point policy**
5. **Paste this policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowOnlyDevFolder",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::YOUR-ACCOUNT-ID:user/s3-user"
            },
            "Action": ["s3:GetObject"],
            "Resource": "arn:aws:s3:us-west-2:YOUR-ACCOUNT-ID:accesspoint/dev-access-point/object/dev/*"
        }
    ]
}
```
6. **Click "Save changes"**

### 8.4 Test Access Point (CloudShell CLI Commands)
**This is the ONLY section that uses CLI commands - everything else is done through the AWS Management Console.**
1. **Open CloudShell in AWS Console**
2. **Test access point access:**
```bash
export AWS_PAGER=""
aws s3api get-object --bucket arn:aws:s3:us-west-2:YOUR-ACCOUNT-ID:accesspoint/dev-access-point --key dev/test-file.txt test-file-downloaded.txt
cat test-file-downloaded.txt
```
3. **Test direct bucket access (should fail):**
```bash
aws s3api get-object --bucket your-unique-bucket-name --key dev/test-file.txt test-file-direct.txt
```

---

## Task 9: Cleanup

### 9.1 Remove Replication (AWS Management Console)
1. **Navigate to source bucket**
2. **Click "Management" tab**
3. **Delete replication rule**

### 9.2 Delete Access Point (AWS Management Console)
1. **Navigate to Access Points**
2. **Select and delete `dev-access-point`**

### 9.3 Delete Buckets (AWS Management Console)
1. **Empty both buckets first**
2. **Delete both buckets**

### 9.4 Delete IAM Resources (AWS Management Console)
1. **Navigate to IAM service**
2. **Delete `s3-user`**
3. **Delete `S3ReplicationRole`**
4. **Delete `S3DemoPolicy`**

---

## Summary

This console-based lab covered:
- ✅ IAM user creation and S3 permissions
- ✅ Bucket policies vs IAM policies
- ✅ Static website hosting
- ✅ Object versioning and restoration
- ✅ Cross-region replication
- ✅ S3 Access Points with restricted access

**Key Learning Points for CCP:**
- Understanding IAM policies vs bucket policies
- Configuring S3 static website hosting
- Managing object versioning for data protection
- Setting up replication for disaster recovery
- Using access points for fine-grained access control 
