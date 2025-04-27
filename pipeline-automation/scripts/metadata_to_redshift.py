#!/usr/bin/env python3
"""
AWS Glue ETL Job — Convert three NOAA GHCN fixed‑width metadata files to **CSV** and store in S3.

*Source bucket* :  noaa‑ghcn‑pds  
*Files processed*: ghcnd‑countries.txt, ghcnd‑inventory.txt, ghcnd‑stations.txt

For *inventory* and *stations* rows are kept only when the first column (station_id) starts with
“RS”.  Each output file is a single CSV object with a header row.

IAM: the same S3 read‑from‑NOAA / write‑to‑destination permissions shown earlier are sufficient.
"""
import sys
from datetime import datetime
from io import StringIO
from typing import List
import csv
import boto3
import yaml
import os

from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.job import Job


CONFIG = yaml.safe_load(open(
    os.path.join(os.path.dirname(__file__), "../config.yaml"),
    encoding="utf-8"
))

#------------------------------------------------------------------------------
# Glue job parameters
#------------------------------------------------------------------------------
opts = getResolvedOptions(sys.argv, ["JOB_NAME"])
DEST_BUCKET = CONFIG['bucket']
DEST_PREFIX = "ghcn_data/processed/metadata"          # *no* trailing slash

SOURCE_BUCKET = "noaa-ghcn-pds"

#------------------------------------------------------------------------------
# Spark / Glue contexts & Job wrapper
#------------------------------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(opts["JOB_NAME"], opts)
logger = glueContext.get_logger()

s3 = boto3.client("s3")

#------------------------------------------------------------------------------
# Fixed‑width specs (1‑based indices, per NOAA docs)
#------------------------------------------------------------------------------
files = [
    {
        "key": "ghcnd-countries.txt",
        "columns": ["code", "name"],
        "indices": [1, 4],
        "filter_rs": False,
    },
    {
        "key": "ghcnd-inventory.txt",
        "columns": [
            "station_id", "latitude", "longitude",
            "element_code", "first_year", "last_year",
        ],
        "indices": [1, 13, 22, 32, 37, 42],
        "filter_rs": True,
    },
    {
        "key": "ghcnd-stations.txt",
        "columns": [
            "station_id", "latitude", "longitude", "elevation",
            "state", "name", "gsn_flag", "hcn_flag", "wmo_id",
        ],
        "indices": [1, 13, 22, 32, 39, 42, 73, 77, 81],
        "filter_rs": True,
    },
]

#------------------------------------------------------------------------------
# Helper functions
#------------------------------------------------------------------------------
def parse_line(line: str, indices: List[int]) -> List[str]:
    """Slice a fixed‑width line into trimmed fields (indices are *1‑based*)."""
    z = [i - 1 for i in indices]
    return [line[z[i]: z[i + 1] if i + 1 < len(z) else None].strip()
            for i in range(len(z))]


def rows_to_csv(header: List[str], rows: List[List[str]]) -> str:
    """Return a CSV string (including header)."""
    buf = StringIO()
    writer = csv.writer(buf)
    writer.writerow(header)
    writer.writerows(rows)
    return buf.getvalue()


#------------------------------------------------------------------------------
# Main loop
#------------------------------------------------------------------------------
for spec in files:
    s3_uri = f"s3://{SOURCE_BUCKET}/{spec['key']}"
    logger.info(f"Reading {s3_uri}")

    # Tiny files → collect on driver
    rdd = spark.read.text(s3_uri).rdd.map(lambda r: r.value)
    parsed = rdd.map(lambda ln: parse_line(ln, spec["indices"]))
    if spec["filter_rs"]:
        parsed = parsed.filter(lambda row: row[0].startswith("RS"))

    rows = parsed.collect()
    logger.info(f"{spec['key']}: {len(rows)} rows after parsing/filtering")

    csv_blob = rows_to_csv(spec["columns"], rows).encode("utf-8")
    obj_key = f"{DEST_PREFIX}/{spec['key'].replace('.txt', '.csv')}"
    s3.put_object(Bucket=DEST_BUCKET, Key=obj_key, Body=csv_blob)

    logger.info(f"Uploaded → s3://{DEST_BUCKET}/{obj_key}")

#------------------------------------------------------------------------------
# Finish
#------------------------------------------------------------------------------
logger.info(f"Job completed at {datetime.utcnow().isoformat()}Z")
job.commit()
