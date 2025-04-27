DROP TABLE IF EXISTS rhcd_dim.station_loc;

CREATE TABLE rhcd_dim.station_loc (
  station_id VARCHAR(11) PRIMARY KEY,
  region VARCHAR(64),
  region_lat FLOAT8,
  region_lon FLOAT8,
  city VARCHAR(64)
) DISTKEY (station_id) SORTKEY (station_id);

COPY rhcd_dim.station_loc
FROM
  's3://russia-historical-climate-edyarich/ghcn_data/processed/metadata/station_region_city.csv' IAM_ROLE 'arn:aws:iam::615299755921:role/service-role/AmazonRedshift-CommandsAccessRole-20250416T193208' FORMAT AS CSV IGNOREHEADER 1 BLANKSASNULL EMPTYASNULL;
