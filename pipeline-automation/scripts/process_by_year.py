import sys
import os
import yaml

from pyspark.context import SparkContext
from pyspark.sql import SparkSession, functions as F
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.job import Job
from awsgluedq.transforms import EvaluateDataQuality
from awsglue.dynamicframe import DynamicFrame


CONFIG = yaml.safe_load(open(
    os.path.join(os.path.dirname(__file__), "../config.yaml"),
    encoding="utf-8"
))
BUCKET = CONFIG["bucket"]

# Parse job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'YEAR'])
year = int(args['YEAR'])

# Initialize Spark and Glue contexts
spark = SparkSession.builder.appName(args['JOB_NAME']).getOrCreate()
glueContext = GlueContext(spark.sparkContext)
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Performance tuning: adjust shuffle partitions to match cluster size
spark.conf.set("spark.sql.shuffle.partitions", "50")

# Default data quality ruleset
DEFAULT_DATA_QUALITY_RULESET = """
    Rules = [
        ColumnCount > 0
    ]
"""

# 1. Read raw data from S3 bucket
raw_dynf = glueContext.create_dynamic_frame.from_options(
    format_options={"quoteChar": "\"", "withHeader": True, "separator": ","},
    connection_type="s3",
    format="csv",
    connection_options={"paths": [f"s3://noaa-ghcn-pds/csv/by_year/{year}.csv"], "recurse": True},
    transformation_ctx="raw_dynf"
)


# Convert to DataFrame for efficient Spark transformations
df = raw_dynf.toDF()

# 2. Filter and transform in a single DataFrame pipeline
    
df_filtered = (
    df
    .filter(F.col("id").startswith("RS"))
    .filter(F.col("q_flag") == "")
    .filter((F.col("date") >= year * 10000) & (F.col("date") < (year + 1) * 10000))
    .withColumn("date", F.to_date(F.col("date").cast("string"), "yyyyMMdd"))
    .withColumn("year", F.year(F.col("date")))
    .withColumn("data_value", F.col("data_value").cast("string"))
    .select(
        "id", "date", "year", "element", 
        "data_value", "m_flag", "s_flag", "obs_time"
    )
    .cache()  # reuse this filtered data for quality and write
)

# Optional: log the number of filtered rows
logger = glueContext.get_logger()
logger.info(f"Filtered row count: {df_filtered.count()}")

# 3. Data quality check
dq_dynf = DynamicFrame.fromDF(df_filtered, glueContext, "dq_input")
EvaluateDataQuality().process_rows(
    frame=dq_dynf,
    ruleset=DEFAULT_DATA_QUALITY_RULESET,
    publishing_options={
        "dataQualityEvaluationContext": "EvaluateDataQuality_run",
        "enableDataQualityResultsPublishing": True
    },
    additional_options={
        "dataQualityResultsPublishing.strategy": "BEST_EFFORT",
        "observations.scope": "ALL"
    }
)

# 4. Write output: partitioned by year & element, Snappy-compressed Parquet
out_dynf = DynamicFrame.fromDF(df_filtered, glueContext, "output_data")
glueContext.write_dynamic_frame.from_options(
    frame=out_dynf,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": f"s3://{BUCKET}/ghcn_data/processed/by_year/",
        "partitionKeys": ["year", "element"]
    },
    transformation_ctx="write_output"
)

# Commit job
job.commit()