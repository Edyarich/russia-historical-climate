CREATE SCHEMA IF NOT EXISTS rhcd_dim;

DROP TABLE IF EXISTS rhcd_dim.stations;

CREATE TABLE rhcd_dim.stations (
  station_id VARCHAR(11) PRIMARY KEY,
  latitude DECIMAL(8, 4),
  longitude DECIMAL(9, 4),
  elevation DECIMAL(6, 2),
  name VARCHAR(32),
  gsn_flag VARCHAR(4),
  wmo_id INTEGER
) DISTSTYLE ALL;

DROP TABLE IF EXISTS rhcd_dim.countries;

CREATE TABLE rhcd_dim.countries (code VARCHAR(2) PRIMARY KEY, name VARCHAR(64)) DISTSTYLE ALL;

DROP TABLE IF EXISTS rhcd_dim.inventory;

CREATE TABLE rhcd_dim.inventory (
  station_id VARCHAR(11) PRIMARY KEY,
  latitude DECIMAL(8, 4),
  longitude DECIMAL(9, 4),
  element CHAR(4),
  firstyear INTEGER,
  lastyear INTEGER
) DISTSTYLE ALL;

-- Move data to countries
COPY rhcd_dim.countries
FROM
  's3://russia-historical-climate-edyarich/ghcn_data/processed/metadata/ghcnd-countries.csv' IAM_ROLE 'arn:aws:iam::615299755921:role/service-role/AmazonRedshift-CommandsAccessRole-20250416T193208' FORMAT AS CSV IGNOREHEADER 1 BLANKSASNULL EMPTYASNULL;

-- Move data to inventory
COPY rhcd_dim.inventory
FROM
  's3://russia-historical-climate-edyarich/ghcn_data/processed/metadata/ghcnd-inventory.csv' IAM_ROLE 'arn:aws:iam::615299755921:role/service-role/AmazonRedshift-CommandsAccessRole-20250416T193208' FORMAT AS CSV IGNOREHEADER 1 BLANKSASNULL EMPTYASNULL;

-- 1. Staging table (no sort / dist keys needed)
DROP TABLE IF EXISTS stg_stations_raw;

CREATE TEMP TABLE stg_stations_raw (
  station_id VARCHAR(11),
  latitude DECIMAL(8, 4),
  longitude DECIMAL(9, 4),
  elevation DECIMAL(6, 2),
  state_code CHAR(2),
  name VARCHAR(30),
  gsn_flag VARCHAR(3),
  hcn_flag VARCHAR(3),
  wmo_id VARCHAR(5)
);

COPY stg_stations_raw
FROM
  's3://russia-historical-climate-edyarich/ghcn_data/processed/metadata/ghcnd-stations.csv' IAM_ROLE 'arn:aws:iam::615299755921:role/service-role/AmazonRedshift-CommandsAccessRole-20250416T193208' FORMAT AS CSV IGNOREHEADER 1 BLANKSASNULL EMPTYASNULL;

-- 2. Load the dimension
INSERT INTO
  rhcd_dim.stations (
    station_id,
    latitude,
    longitude,
    elevation,
    name,
    gsn_flag,
    wmo_id
  )
SELECT
  station_id,
  latitude,
  longitude,
  elevation,
  name,
  gsn_flag,
  wmo_id::integer
FROM
  stg_stations_raw;