# Infrastructure as Code - Builders Day Lab (Console Edition)
**AWS Certified Cloud Practitioner / Associate Level**  
Learn Infrastructure as Code by building the same S3 bucket using CloudFormation, CDK, and Infrastructure Composer - all through the AWS Management Console.

---

## Lab Overview
Build a secure S3 bucket with environment-specific configuration using three different AWS Infrastructure as Code approaches:
1. **CloudFormation Template** (declarative YAML)
2. **AWS CDK with Python** (programmatic approach) 
3. **Infrastructure Composer** (visual drag-and-drop) - Optional

---

## Prerequisites
- AWS account with Administrator access
- Basic understanding of S3 and IAM
- **Web browser** with access to AWS Management Console

---

## Architecture & Features
We'll build an S3 bucket with:
- ✅ **Environment-specific naming** (dev/prod)
- ✅ **Conditional versioning** (enabled for prod, disabled for dev)
- ✅ **Security best practices** (block public access, SSL enforcement)
- ✅ **Proper tagging** for cost allocation
- ✅ **CloudFormation outputs** for integration

---

## Getting Started: AWS Management Console

### Step 0: Access AWS Console
1. **Sign in** to the AWS Management Console at [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. **Verify** you're in your preferred AWS region (top-right corner)
3. **Bookmark** the following services for quick access:
   - CloudFormation
   - CDK (via CloudShell for Part 2)
   - Application Composer (for Part 3)

> **💡 Console Benefits:**
> - No local software installation required
> - Visual interface for all AWS services
> - Built-in code editors and templates
> - Integrated monitoring and logging

---

## Part 1: Deploy Using CloudFormation Template

### Step 1: Access CloudFormation Console
1. **Navigate** to CloudFormation service in AWS Console
2. **Click** "Create stack" → "With new resources (standard)"
3. **Select** "Template is ready" and "Upload a template file"

### Step 2: Create CloudFormation Template
**Click "Choose file"** and create a new file called `simple-cloudformation-example.yaml` with this content:

```yaml
AWSTemplateFormatVersion: '2010-09-09'

Description: 'Simple S3 bucket with configurable name and versioning'

Parameters:
  BucketName:
    Type: String
    Default: 'my-demo-bucket'
    Description: 'Name for the S3 bucket'
  
  Environment:
    Type: String
    Default: 'dev'
    AllowedValues: [dev, prod]

Mappings:
  EnvConfig:
    dev:
      Versioning: Suspended
    prod:
      Versioning: Enabled

Conditions:
  IsProduction: !Equals [!Ref Environment, prod]

Resources:
  MyS3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${BucketName}-${Environment}'
      VersioningConfiguration:
        Status: !FindInMap [EnvConfig, !Ref Environment, Versioning]
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
      Tags:
        - Key: Environment
          Value: !Ref Environment

  BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref MyS3Bucket
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Deny
            Principal: '*'
            Action: 's3:*'
            Resource:
              - !GetAtt MyS3Bucket.Arn
              - !Join ['', [!GetAtt MyS3Bucket.Arn, '/*']]
            Condition:
              Bool:
                'aws:SecureTransport': false

Outputs:
  BucketName:
    Description: 'Created bucket name'
    Value: !Ref MyS3Bucket
    Export:
      Name: !Sub '${AWS::StackName}-Bucket'
  
  BucketArn:
    Description: 'Bucket ARN'
    Value: !GetAtt MyS3Bucket.Arn
```

**Upload the file** and click "Next"

### Step 3: Configure Stack Details
1. **Stack name**: Enter `s3-builders-day-cf`
2. **Parameters**:
   - **BucketName**: Keep default `my-demo-bucket`
   - **Environment**: Keep default `dev`
3. **Click "Next"** through the remaining screens
4. **Check** "I acknowledge that AWS CloudFormation might create IAM resources"
5. **Click "Submit"**

### Step 4: Monitor Stack Creation
1. **Watch** the "Events" tab for real-time deployment progress
2. **Wait** for Status to change from `CREATE_IN_PROGRESS` to `CREATE_COMPLETE`
3. **Note** the creation of both the S3 bucket and bucket policy resources

### Step 5: Verify S3 Bucket Creation
1. **Navigate** to S3 service in AWS Console
2. **Find** your bucket named `my-demo-bucket-dev`
3. **Click** on the bucket name
4. **Check** Properties tab:
   - ✅ Versioning should be "Suspended" (dev environment)
   - ✅ Public access should be "Blocked"

### Step 6: View Stack Outputs
1. **Return** to CloudFormation console
2. **Click** on your stack `s3-builders-day-cf`
3. **Click** "Outputs" tab
4. **Note** the exported values:
   - **BucketNameOutput**: Your bucket name
   - **BucketArnOutput**: Your bucket ARN

### Step 7: Deploy Production Environment (Optional)
**Repeat Steps 1-6** with these changes:
- **Stack name**: `s3-builders-day-cf-prod`
- **Environment parameter**: `prod`
- **BucketName parameter**: `my-prod-bucket`
- **Verify** versioning is "Enabled" for prod bucket

---

## Part 2: Deploy Using AWS CDK (Python)

### Step 1: Open CloudShell from Console
1. **Click** the CloudShell icon (>_) in the AWS Console top navigation
2. **Wait** for CloudShell to initialize (~30 seconds)
3. **Verify** you're in the home directory: `/home/cloudshell-user`

### Step 2: Setup CDK in CloudShell
Copy and paste these commands in CloudShell:
```bash
# Install CDK globally (CloudShell has Node.js pre-installed)
sudo npm install -g aws-cdk@2.99.1

# Verify CDK installation
cdk --version

# Create CDK project directory
mkdir s3-cdk-py && cd s3-cdk-py

# Initialize CDK Python project
cdk init app --language python

# Activate the virtual environment created by CDK init
source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt
```

> **💡 CloudShell CDK Benefits:**
> - Node.js and Python already installed
> - AWS credentials automatically inherited from console session
> - Persistent storage for your CDK projects

### Step 3: Replace Default App with S3 Implementation
```bash
# Remove the default app.py file
rm app.py

# Create a new app.py with our S3 stack
cat > app.py << 'EOF'
from aws_cdk import (
    App,
    Stack,
    CfnParameter,
    CfnOutput,
    CfnCondition,
    Fn,
    aws_s3 as s3,
    aws_iam as iam,
    Tags,
)
from constructs import Construct


class S3CdkPyStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Parameters (equivalent to CloudFormation Parameters)
        bucket_name_param = CfnParameter(
            self, "BucketName",
            type="String",
            default="my-demo-bucket-cdk",
            description="Name for the S3 bucket"
        )
        
        environment_param = CfnParameter(
            self, "Environment", 
            type="String",
            default="dev",
            allowed_values=["dev", "prod"],
            description="Environment type"
        )

        # Conditions (equivalent to CloudFormation Conditions)
        is_production = CfnCondition(
            self, "IsProduction",
            expression=Fn.condition_equals(environment_param.value_as_string, "prod")
        )

        # Determine versioning based on environment
        versioning_enabled = environment_param.value_as_string == "prod"

        # Create S3 Bucket (equivalent to CloudFormation Resources)
        bucket = s3.Bucket(
            self, "MyS3Bucket",
            bucket_name=f"{bucket_name_param.value_as_string}-{environment_param.value_as_string}",
            versioned=versioning_enabled,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,  # This replaces the bucket policy for SSL enforcement
        )

        # Add tags to the bucket
        Tags.of(bucket).add("Environment", environment_param.value_as_string)

        # Outputs (equivalent to CloudFormation Outputs)
        CfnOutput(
            self, "BucketNameOutput",
            description="Created bucket name",
            value=bucket.bucket_name,
            export_name=f"{self.stack_name}-Bucket"
        )
        
        CfnOutput(
            self, "BucketArnOutput", 
            description="Bucket ARN",
            value=bucket.bucket_arn
        )


# Create the CDK app and add the stack
app = App()
S3CdkPyStack(app, "S3CdkPyStack")

# Synthesize the app
app.synth()
EOF
```

### Step 4: Verify CDK Setup
```bash
# Verify the new app.py was created
ls -la app.py

# Check if CDK can parse our code
cdk list
```

### Step 5: View Generated CloudFormation Template
```bash
# Generate CloudFormation template from CDK code
cdk synth

# Optional: Save and compare templates
cdk synth > cdk-generated-template.yaml
echo "CDK generated a CloudFormation template!"
```

### Step 6: Deploy CDK Stack
```bash
# Bootstrap CDK (first time only - creates required S3 bucket and roles)
cdk bootstrap

# Deploy the stack with default parameters
cdk deploy

# View deployed resources
cdk ls
```

### Step 7: Verify CDK Deployment in Console
1. **Return to AWS Console** (keep CloudShell open)
2. **Navigate to CloudFormation** service
3. **Find** your CDK stack (name will include your app name)
4. **Click** on the stack to view details
5. **Navigate to S3** service
6. **Find** your CDK-created bucket
7. **Compare properties** with the CloudFormation-created bucket

### Step 8: Deploy Production Variant with Custom Parameters
**In CloudShell:**
```bash
# Deploy a production variant with custom parameters
cdk deploy --parameters BucketName=my-custom-bucket --parameters Environment=prod
```

**Verify the production deployment:**
1. **Return to AWS Console**
2. **Check CloudFormation** - you should now see two CDK stacks
3. **Check S3** - find the new bucket `my-custom-bucket-prod`
4. **Verify** the production bucket has **versioning enabled** (unlike the dev bucket)

---

## Part 3: Infrastructure Composer (Optional Challenge)

### Step 1: Open Infrastructure Composer
1. Navigate to **CloudFormation** → **Application Composer**
2. Choose **Create new project** → **Blank project**

### Step 2: Build Visually
1. **Drag S3 Bucket** from the resource panel
   - ✅ **Notice**: Infrastructure Composer automatically creates both the bucket AND bucket policy!
   - ✅ **Auto-generated**: Bucket policy includes SSL enforcement (`aws:SecureTransport: false`)
   - ✅ **Auto-configured**: Public access blocking and encryption settings
2. **Add Parameters section**:
   - BucketName parameter
   - Environment parameter  
4. **Add Mappings** for environment-based versioning
5. **Add Conditions** for production logic
6. **Add Outputs** section

### Step 3: Validate and Deploy
1. **Click "Validate template"** to check for errors
2. **Click "Create template"** once validation passes
3. **Choose confirm and continue to CloudFormation option** in the dialog.
4. **Follow the Create Stack process to complete the resource creation"**.

---

## Comparison & Learning Points

### CloudFormation vs CDK vs Infrastructure Composer

| Aspect | CloudFormation | CDK | Infrastructure Composer |
|--------|---------------|-----|------------------------|
| **Learning Curve** | YAML/JSON syntax | Programming concepts | Visual, intuitive |
| **Type Safety** | Runtime validation | Compile-time validation | Visual validation |
| **Reusability** | Copy/paste templates | Import as modules | Template sharing |
| **Version Control** | YAML files | Code repositories | Export templates |
| **Testing** | Deploy to test | Unit + integration tests | Visual validation |
| **IDE Support** | Basic YAML | Full IntelliSense | Browser-based |

### Key Takeaways
- **CloudFormation**: Declarative, explicit, great for learning AWS resources
- **CDK**: Programmatic, reusable, excellent for complex logic and testing
- **Infrastructure Composer**: Visual, beginner-friendly, rapid prototyping

---

## Cleanup (Console & CloudShell)

### CloudFormation Stacks (Console Method)
1. **Navigate** to CloudFormation service
2. **Select** your stack `s3-builders-day-cf`
3. **Click "Delete"** and confirm
4. **Repeat** for `s3-builders-day-cf-prod` (if created)
5. **Wait** for DELETE_COMPLETE status

### CDK Stack (CloudShell Method)
**In CloudShell:**
```bash
# Navigate to CDK directory
cd ~/s3-cdk-py

# Destroy CDK stack
cdk destroy

# Confirm deletion when prompted
```

### Alternative: Delete CDK Stack via Console
1. **Navigate** to CloudFormation service
2. **Find** your CDK stack (includes your app name)
3. **Delete** the stack normally
4. **Note**: CDK bootstrap resources can remain (they're reusable)

### Infrastructure Composer
1. **Navigate** to CloudFormation service
2. **Delete** the Infrastructure Composer stack
3. **Clean up** any exported templates

### Verify All Resources Deleted
1. **S3 service**: Ensure all test buckets are gone
2. **CloudFormation service**: Verify no active stacks remain
3. **CloudShell**: Files persist (1GB storage) - cleanup optional

---

## Resources
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS CDK Python Guide](https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-python.html)
- [Infrastructure Composer User Guide](https://docs.aws.amazon.com/infrastructure-composer/latest/dg/what-is-composer.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

---

**🎯 Learning Objectives Achieved:**
- ✅ Understand Infrastructure as Code principles
- ✅ Compare CloudFormation, CDK, and Infrastructure Composer
- ✅ Deploy identical infrastructure using different tools
- ✅ Implement AWS security best practices
- ✅ Use parameters, conditions, and outputs effectively
