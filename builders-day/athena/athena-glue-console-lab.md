# AWS Athena & Glue Console Lab
## Schema Evolution Demo: Manual DDL vs Glue Crawler

### Lab Overview
This lab demonstrates how AWS Glue Crawler automatically handles schema evolution, eliminating the need for manual `ALTER TABLE` commands when new columns are added to datasets.

### Dataset Structure
- **Source**: [GitHub Repository - Customer Data](https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/athena/customers)
- **001 folder**: Original customer.csv (12 columns)
- **002 folder**: Updated customer.csv (13 columns with new `account_status` field)

### Prerequisites
- AWS Console access
- S3 bucket for storing customer data
- IAM permissions for Athena and Glue

---

## Part 1: Setup S3 Data Structure

### Step 1: Create S3 Bucket (Console)
1. **Navigate to S3 Console**
2. **Click "Create bucket"**
3. **Bucket Configuration:**
   - Bucket name: `your-analytics-bucket-[yourname]` (must be globally unique)
   - Region: Choose your preferred region
   - Leave other settings as default
4. **Click "Create bucket"**

### Step 2: Create Folder Structure (Console)
1. **Open your newly created bucket**
2. **Click "Create folder"**
   - Folder name: `customers`
   - Click "Create folder"

### Step 3: Download Sample Data from GitHub
1. **Download initial customer data:**
   - Go to: [GitHub - Customer Data](https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/athena/customers)
   - Navigate to `001` folder
   - Download `customers.csv` (original schema - 12 columns)
   - Save to your local Downloads folder

### Step 4: Upload Initial Data to S3 (Console)
1. **Upload original version:**
   - Navigate to `s3://your-analytics-bucket/customers/`
   - Click "Upload"
   - Select the `customers.csv` file from your Downloads folder (from 001 folder)
   - Click "Upload"

---

## Part 2: Manual DDL Approach (Traditional Method)

### Step 3: Create Database in Athena
```sql
CREATE DATABASE IF NOT EXISTS analytics_demo;
```

### Step 4: Create Initial Table (12 columns)
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS analytics_demo.customers_manual (
  idx                 int,
  customer_id         string,
  first_name          string,
  last_name           string,
  company             string,
  city                string,
  country             string,
  phone_1             string,
  phone_2             string,
  email               string,
  subscription_date   string,
  website             string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://your-analytics-bucket/customers/'
TBLPROPERTIES (
  'skip.header.line.count'='1'
);
```

### Step 5: Query Initial Data
```sql
-- Test initial schema
SELECT * FROM analytics_demo.customers_manual LIMIT 5;

-- Count records
SELECT COUNT(*) FROM analytics_demo.customers_manual;

-- Sample business query
SELECT country, COUNT(*) as customer_count 
FROM analytics_demo.customers_manual 
GROUP BY country 
ORDER BY customer_count DESC;
```

### Step 6: Replace File with New Schema (Breaking Change!)
1. **Download updated customer data:**
   - Go back to: [GitHub - Customer Data](https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/athena/customers)
   - Navigate to `002` folder
   - Download `customers.csv` (updated schema - 13 columns with account_status)
   - Save to your local Downloads folder

2. **Replace file in S3:**
   - Navigate to S3 Console
   - Go to `s3://your-analytics-bucket/customers/`
   - Delete existing `customers.csv`
   - Click "Upload"
   - Select the new `customers.csv` file from Downloads folder (from 002 folder)
   - Click "Upload"

3. **Test the query (new column NOT visible):**
```sql
-- This query will work, but the new account_status column won't appear
SELECT * FROM analytics_demo.customers_manual LIMIT 5;

-- Verify current table schema - only shows 12 columns
DESCRIBE analytics_demo.customers_manual;
```

### Step 7: Manual Schema Fix (The Traditional Pain Point)
```sql
-- Must manually add new column to see the data
ALTER TABLE analytics_demo.customers_manual 
ADD COLUMNS (account_status string);

-- Now the new column appears in queries
SELECT * FROM analytics_demo.customers_manual LIMIT 5;

-- Verify updated schema - now shows 13 columns
DESCRIBE analytics_demo.customers_manual;

-- Query with new column
SELECT account_status, COUNT(*) 
FROM analytics_demo.customers_manual 
GROUP BY account_status;
```

---

## Part 3: AWS Glue Crawler Approach (Automated Solution)

### Step 8: Reset Data to Original Version
**Important**: Before starting the Glue demo, we need to reset back to the original data.

1. **Download original customer data:**
   - Go to: [GitHub - Customer Data](https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/athena/customers)
   - Navigate to `001` folder
   - Download `customers.csv` (original schema - 12 columns)

2. **Replace file in S3:**
   - Navigate to S3 Console
   - Go to `s3://your-analytics-bucket/customers/`
   - Delete existing `customers.csv` (the updated version from Part 2)
   - Click "Upload"
   - Select the original `customers.csv` file from Downloads folder (from 001 folder)
   - Click "Upload"

### Step 9: Create Glue Crawler (Console Steps)

1. **Navigate to AWS Glue Console**
2. **Click "Crawlers" → "Create Crawler"**
3. **Crawler Configuration:**
   - Name: `customer-data-crawler`
   - Description: `Crawls customer data with schema evolution`

4. **Data Source:**
   - Source Type: S3
   - S3 Path: `s3://your-analytics-bucket/customers/`
   - Include Path: `s3://your-analytics-bucket/customers/`

5. **IAM Role:**
   - Choose "Create new IAM role"
   - Role name: `AWSGlueServiceRole-CustomerCrawler`
   - Glue automatically creates role with required permissions

6. **Output Database:**
   - Database: `analytics_demo`
   - Table prefix: `glue_`

7. **Schedule:**
   - Frequency: On demand (for demo)

8. **Review and Create:**
   - AWS automatically creates the IAM role with policies:
     - `AWSGlueServiceRole` (for Glue operations)
     - S3 permissions for your specified bucket

### Step 10: Run Crawler on Initial Data
1. **Navigate to AWS Glue Console**
2. **Click "Crawlers"**
3. **Select `customer-data-crawler`**
4. **Click "Run crawler"**
5. **Wait for completion** (status will show "Ready" when finished)

Check results:

```sql
-- Query auto-discovered table
SELECT * FROM analytics_demo.glue_customers LIMIT 5;

-- Verify column count (should be 12)
DESCRIBE analytics_demo.glue_customers;
```

### Step 11: Replace S3 File with Updated Schema (Console)
**Note**: If you haven't already downloaded the updated file from Step 6, do this first:
1. **Download updated customer data:**
   - Go to: [GitHub - Customer Data](https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/athena/customers)
   - Navigate to `002` folder  
   - Download `customers.csv` (updated schema - 13 columns with account_status)

2. **Replace file in S3:**
   - Navigate to S3 Console
   - Go to `s3://your-analytics-bucket/customers/`
   - Delete existing `customers.csv` 
   - Click "Upload"
   - Select the new `customers.csv` file from Downloads folder (from 002 folder)
   - Click "Upload"

**Key Point**: The crawler data source stays the same (`s3://your-analytics-bucket/customers/`) - we're just replacing the file content with the new schema!

### Step 12: Re-run Crawler (Schema Evolution Magic!)
1. **In AWS Glue Console, click "Run crawler"**
2. **Wait for crawler to complete**
3. **Monitor status in "Crawlers" section**

**Key Observation**: Crawler automatically detects the schema change!

```sql
-- Query updated table - NO ALTER TABLE needed!
SELECT * FROM analytics_demo.glue_customers LIMIT 5;

-- Verify new column detected automatically
DESCRIBE analytics_demo.glue_customers;

-- Query new column immediately
SELECT account_status, COUNT(*) 
FROM analytics_demo.glue_customers 
GROUP BY account_status;
```

---

## Part 4: Comparison & Best Practices

### Manual DDL vs Glue Crawler Comparison

| Aspect | Manual DDL | Glue Crawler |
|--------|------------|--------------|
| **Initial Setup** | Write DDL manually | Configure crawler once |
| **Schema Changes** | Manual ALTER TABLE | Automatic detection |
| **Human Error** | High risk | Minimal risk |
| **Maintenance** | Manual monitoring | Scheduled automation |
| **Documentation** | Manual updates | Auto-documented |
| **Partitions** | Manual management | Auto-discovery |

### Demo Queries to Show Benefits

```sql
-- Complex analytics query that works immediately after schema evolution
WITH customer_metrics AS (
  SELECT 
    country,
    account_status,
    COUNT(*) as customer_count,
    COUNT(DISTINCT SUBSTR(subscription_date, 1, 7)) as active_months
  FROM analytics_demo.glue_customers
  WHERE account_status IS NOT NULL
  GROUP BY country, account_status
)
SELECT 
  country,
  account_status,
  customer_count,
  ROUND(customer_count * 100.0 / SUM(customer_count) OVER (PARTITION BY country), 2) as pct_of_country
FROM customer_metrics
ORDER BY country, customer_count DESC;
```

### Key Takeaways

1. **Glue Crawler eliminates manual schema management**
2. **Automatic partition discovery**
3. **Built-in data catalog for governance**
4. **Reduced operational overhead**
5. **Better data quality through automated validation**

---

## Cleanup

```sql
-- Drop manual table
DROP TABLE analytics_demo.customers_manual;

-- Drop Glue-managed table (or keep for production use)
DROP TABLE analytics_demo.glue_customers;

-- Delete database
DROP DATABASE analytics_demo;
```

**S3 Cleanup (Console):**
1. Navigate to S3 Console
2. Select your analytics bucket
3. Delete all objects in the bucket
4. Delete the bucket itself

---

## Additional Resources

- [AWS Glue Crawler Documentation](https://docs.aws.amazon.com/glue/latest/dg/add-crawler.html)
- [Athena DDL Reference](https://docs.aws.amazon.com/athena/latest/ug/ddl-sql-reference.html)
- [Data Source: Customer Sample Data](https://github.com/buildwithbrainyl/ccp/tree/main/builders-day/athena/customers)