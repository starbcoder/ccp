# CloudFront & Global Accelerator Lab - From S3 to Global Content Delivery
**AWS Certified Cloud Practitioner**  
*Complete lab using AWS Management Console - Building on S3 concepts*

---

## Prerequisites
- AWS Account with admin access
- Basic familiarity with AWS Management Console
- Understanding of S3 concepts (recommended to complete S3 lab first)

## Lab Overview
This lab demonstrates:
1. **S3 Static Website** → **CloudFront CDN** → **Elastic Beanstalk Applications** → **Global Accelerator**
2. Content caching and invalidation concepts
3. Multi-region application deployment
4. Traffic management and failover scenarios

---

## Task 1: Create S3 Bucket with Demo Files

### 1.1 Create S3 Bucket (AWS Management Console)
1. **Open AWS Management Console**
2. **Navigate to S3 service**
3. **Click "Create bucket"**
4. **Bucket configuration:**
   - Bucket name: `cloudfront-demo-YOUR-INITIALS-YYYYMMDD` (globally unique)
   - Region: **US West (Oregon) us-west-2**
   - **Enable "Bucket Versioning"**
   - Block Public Access settings: **Keep all defaults**
   - Default encryption: **Amazon S3 managed keys (SSE-S3)**
5. **Click "Create bucket"**

### 1.2 Download Demo Files from GitHub
1. **Visit:** https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/s3/demo_s3
2. **Download these files to your computer:**
   - `index.html`
   - `error.html`
   - `sample-image.jpg`
   - `v1/index.html` (keep the filename as-is)

### 1.3 Upload Files to S3 (AWS Management Console)
1. **Click on your bucket name**
2. **Click "Upload"**
3. **Add files:**
   - Upload `index.html`, `error.html`, `sample-image.jpg`
   - **Keep the `v1/index.html` file for later** (don't upload yet)
4. **Click "Upload"**
5. **Verify all files are uploaded successfully**

---

## Task 2: Create CloudFront Distribution

### 2.1 Create CloudFront Distribution (AWS Management Console)
1. **Navigate to CloudFront service**
2. **Click "Create a CloudFront distribution"**
3. **Origin settings:**
   - **Origin domain:** Select your S3 bucket from dropdown
   - **Origin access:** "Origin access control settings (recommended)"
   - **Origin access control:** Click "Create control setting"
     - Name: Use the suggested name
     - **Click "Create"**
   - **Enable Origin Shield:** No (for cost optimization)

4. **Default cache behavior:**
   - **Viewer protocol policy:** "Redirect HTTP to HTTPS"
   - **Allowed HTTP methods:** GET, HEAD
   - **Cache policy:** "Caching Optimized"
   - **Origin request policy:** None
   - **Response headers policy:** None

5. **Function associations:** Leave empty for now

6. **Settings:**
   - **Price class:** "Use all edge locations" (for demonstration)
   - **Supported HTTP versions:** HTTP/2
   - **Default root object:** `index.html`
   - **Standard logging:** Off (for cost optimization)
   - **IPv6:** On

7. **Click "Create distribution"**

### 2.2 S3 Bucket Policy (Automatic)
1. **Good news!** AWS automatically updates the S3 bucket policy when you use Origin Access Control
2. **No manual policy update needed** - CloudFront handles this for you
3. **Optional verification:** You can check S3 → Your bucket → Permissions tab to see the policy that was automatically added

### 2.3 Wait for Distribution Deployment
1. **Return to CloudFront**
2. **Wait for Status to change from "Deploying" to "Enabled"**
3. **This takes 5-10 minutes**
4. **Note the Distribution domain name** (looks like `d1234567890abc.cloudfront.net`)

---

## Task 3: Test CloudFront Content Delivery

### 3.1 Test Basic Access
1. **Copy the CloudFront distribution domain name**
2. **Open in new browser tab:** `https://YOUR-DISTRIBUTION-DOMAIN.cloudfront.net`
3. **Expected Result:** You should see the demo website
4. **Test error page:** `https://YOUR-DISTRIBUTION-DOMAIN.cloudfront.net/nonexistent.html`
5. **Expected Result:** You should see the custom error page



---

## Task 4: Test CloudFront Caching and Invalidation

### 4.1 Upload Modified Content (Version 1)
1. **Navigate to S3 → Your bucket**
2. **Upload the new version:**
   - Click "Upload"
   - Click "Add files"
   - Select the `v1/index.html` file you downloaded earlier
   - **Change the filename to `index.html`** during upload (this will replace the existing file)
   - Click "Upload"
3. **Confirm replacement:** Click "Upload" to replace the existing `index.html`

### 4.2 Test Caching Behavior
1. **Refresh S3 website endpoint**
   - **Expected:** Content changes immediately
2. **Refresh CloudFront endpoint**
   - **Expected:** Content DOES NOT change (cached!)
3. **Wait 5 minutes and refresh CloudFront again**
   - **Expected:** Content still may not change (TTL in effect)

### 4.3 Create CloudFront Invalidation
1. **Navigate to CloudFront service**
2. **Click on your distribution**
3. **Click "Invalidations" tab**
4. **Click "Create invalidation"**
5. **Object paths:** 
   ```
   /index.html
   ```
6. **Click "Create invalidation"**
7. **Wait 2-3 minutes for invalidation to complete**

### 4.4 Verify Cache Invalidation
1. **Refresh CloudFront endpoint**
2. **Expected:** Content now shows the updated version
3. **Check invalidation status in CloudFront console**

---

## Task 5: Create Multi-Region Elastic Beanstalk Applications

### 5.1 Create Beanstalk Application - US West 2
1. **Navigate to Elastic Beanstalk service**
2. **Ensure you're in us-west-2 region**
3. **Click "Create application"**
4. **Application information:**
   - Application name: `demo-app-west`
   - Application tags: Optional

5. **Environment information:**
   - Environment name: `demo-app-west-env`
   - Domain: Leave blank (auto-generated)
   - Platform: **Python** (or your preferred platform)
   - Platform branch: **Python 3.11 running on 64bit Amazon Linux 2023**
   - Platform version: Recommended

6. **Application code:**
   - **Sample application** (for simplicity)

7. **Presets:**
   - **High availability** (this creates a load balancer)

8. **Click "Next"**

9. **Service access:**
   - **Use an existing service role:** Create if none exists
   - **EC2 instance profile:** Create if none exists

10. **Click "Next" through remaining steps** (keep defaults)

11. **Click "Submit"**

12. **Wait 5-10 minutes for environment creation**

### 5.2 Create Beanstalk Application - US West 1
1. **Switch to us-west-1 region** (N. California)
2. **Repeat the exact same process:**
   - Application name: `demo-app-west1`
   - Environment name: `demo-app-west1-env`
   - Same settings: **High availability, NodeJS platform**
3. **Wait for deployment to complete**

### 5.3 Test Both Applications
1. **Note the endpoint URLs for both environments:**
   - US West 2: `demo-app-west-env.REGION.elasticbeanstalk.com`
   - US West 1: `demo-app-west1-env.REGION.elasticbeanstalk.com`
2. **Test both URLs in browser**
3. **Expected:** Both show sample application pages

---

## Task 6: Create Global Accelerator

### 6.1 Create Global Accelerator (AWS Management Console)
1. **Navigate to Global Accelerator service**
2. **Click "Create accelerator"**
3. **Accelerator details:**
   - Name: `demo-multi-region-accelerator`
   - IP address type: **IPv4**

4. **Click "Next"**

5. **Add listeners:**
   - Protocol: **TCP**
   - Port: **80**
   - Client affinity: **None**

6. **Click "Next"**

7. **Add endpoint groups:**
   
   **First endpoint group (us-west-2):**
   - Region: **US West (Oregon)**
   - Traffic dial: **100**
   - Health check settings: Keep defaults
   
   **Add endpoint:**
   - Endpoint type: **Application Load Balancer**
   - Endpoint: Select your us-west-2 Beanstalk ALB
   - Weight: **128** (default)

8. **Click "Add endpoint group"**

   **Second endpoint group (us-west-1):**
   - Region: **US West (N. California)**
   - Traffic dial: **100**
   - Health check settings: Keep defaults
   
   **Add endpoint:**
   - Endpoint type: **Application Load Balancer**
   - Endpoint: Select your us-west-1 Beanstalk ALB
   - Weight: **128** (default)

9. **Click "Next" → "Create accelerator"**

### 6.2 Test Global Accelerator
1. **Wait for accelerator status to become "Deployed"**
2. **Note the static IP addresses provided**
3. **Test the accelerator DNS name in browser**
4. **Expected:** You should see one of the Beanstalk applications

---

## Task 7: Test Traffic Management

### 7.1 Change Traffic Distribution
1. **Navigate to Global Accelerator**
2. **Click on your accelerator**
3. **Click on the listener (Port 80)**
4. **Click on us-west-2 endpoint group**
5. **Click "Edit"**
6. **Change Traffic dial from 100 to 0**
7. **Click "Save"**
8. **Test the accelerator URL again**
9. **Expected:** Traffic should now go to us-west-1 only

### 7.2 Restore Traffic and Test Failover
1. **Change us-west-2 traffic dial back to 100**
2. **Wait for changes to propagate (2-3 minutes)**

---

## Task 8: Simulate Application Failure

### 8.1 Break Security Group Rules
1. **Navigate to EC2 service in us-west-2**
2. **Click "Instances"**
3. **Select the Beanstalk instance** (has name like `demo-app-west-env`)
4. **Click "Security" tab**
5. **Click on the security group** (should be the default one)
6. **Click "Edit inbound rules"**
7. **Remove the HTTP (port 80) rule**
8. **Click "Save rules"**

### 8.2 Test Failover Behavior
1. **Wait 2-3 minutes** (for health checks to detect failure)
2. **Test the Global Accelerator URL multiple times**
3. **Expected Results:**
   - First few requests may fail or timeout
   - Subsequent requests should route to healthy us-west-1
   - Global Accelerator should automatically failover

### 8.3 Monitor Health Status
1. **Navigate to Global Accelerator**
2. **Click on your accelerator**
3. **Click on the listener**
4. **Click on us-west-2 endpoint group**
5. **Check endpoint health status**
6. **Expected:** Should show unhealthy for us-west-2 endpoint

### 8.4 Restore Service
1. **Go back to EC2 Security Groups**
2. **Add back the HTTP rule:**
   - Type: HTTP
   - Port: 80
   - Source: 0.0.0.0/0
3. **Save rules**
4. **Wait 2-3 minutes**
5. **Test Global Accelerator URL**
6. **Expected:** Traffic should distribute to both regions again

---

## Task 9: Cleanup Resources
1. **Delete Global Accelerator:**
   - Remove endpoint groups first
   - Delete accelerator

2. **Delete Elastic Beanstalk environments:**
   - Navigate to each environment
   - Actions → Terminate environment

3. **Delete CloudFront distribution:**
   - Disable distribution first
   - Wait for deployment
   - Delete distribution

4. **Clean up S3:**
   - Empty bucket
   - Delete bucket

---

## Summary & Key Learning Points

### 🎯 What You Accomplished:
- ✅ **S3 Static Website:** Hosted content with versioning
- ✅ **CloudFront CDN:** Global content delivery with caching
- ✅ **Cache Management:** Invalidation and TTL concepts
- ✅ **Multi-Region Apps:** Elastic Beanstalk in two regions
- ✅ **Global Accelerator:** Application performance optimization
- ✅ **Traffic Management:** Weight-based routing and failover
- ✅ **Failure Simulation:** Understanding health checks and automatic failover

### 🔑 Key CCP Concepts Demonstrated:

**CloudFront Benefits:**
- Global content delivery with 400+ edge locations
- HTTPS termination and security features
- Caching reduces origin load and improves performance
- Integration with other AWS services (S3, ALB)

**Global Accelerator Benefits:**
- Network performance optimization using AWS backbone
- Static Anycast IP addresses for simplified DNS management
- Automatic failover and health checking
- Works with any IP-based applications

**Architecture Patterns:**
- Static content delivery: S3 → CloudFront
- Dynamic content acceleration: ALB → Global Accelerator
- Multi-region for high availability and disaster recovery
- Edge computing brings processing closer to users

### 📊 Performance Comparison:
| Service | Use Case | Benefit |
|---------|----------|---------|
| S3 Direct | File storage | Reliable storage |
| CloudFront | Static content | Global caching, HTTPS |
| Global Accelerator | Applications | Network optimization, failover |

### 💰 Cost Considerations:
- CloudFront: Pay for data transfer and requests
- Global Accelerator: Fixed hourly fee + premium data transfer
- Choose based on use case: Static content = CloudFront, Dynamic apps = Global Accelerator


**This lab demonstrates real-world content delivery and application acceleration scenarios that are essential for the Cloud Practitioner exam!** 🚀 

