-- Fact table: monthly aggregates
DROP TABLE IF EXISTS rhcd.monthly_agg;

CREATE TABLE rhcd.monthly_agg (
  region VARCHAR(64),
  region_lat FLOAT8,
  region_lon FLOAT8,
  city VARCHAR(64),
  year INT,
  month INT,
  tmin DECIMAL(7, 2),
  tavg DECIMAL(7, 2),
  tmax DECIMAL(7, 2),
  avg_tmin DECIMAL(7, 2),
  avg_tmax DECIMAL(7, 2),
  total_prcp DECIMAL(10, 2),
  max_snowd DECIMAL(10, 2)
) DISTKEY (region) SORTKEY (year, month);

INSERT INTO
  rhcd.monthly_agg
SELECT
  loc.region,
  loc.region_lat,
  loc.region_lon,
  loc.city,
  EXTRACT(
    YEAR
    FROM
      d.obs_date
  )::INT AS year,
  EXTRACT(
    MONTH
    FROM
      d.obs_date
  )::INT AS month,
  MIN(tmin / 10.0) AS tmin,
  AVG(tavg / 10.0) AS tavg,
  MAX(tmax / 10.0) AS tmax,
  AVG(tmin / 10.0) AS avg_tmin,
  AVG(tmax / 10.0) AS avg_tmax,
  SUM(prcp / 10.0) AS total_prcp,
  AVG(snwd) AS max_snowd
FROM
  rhcd.daily AS d
  JOIN rhcd_dim.station_loc AS loc ON d.station_id = loc.station_id
GROUP BY
  1,
  2,
  3,
  4,
  5,
  6;

DROP TABLE IF EXISTS rhcd.yearly_agg;

CREATE TABLE rhcd.yearly_agg (
  region VARCHAR(64),
  region_lat FLOAT8,
  region_lon FLOAT8,
  city VARCHAR(64),
  year INT,
  tmin DECIMAL(7, 2),
  tavg DECIMAL(7, 2),
  tmax DECIMAL(7, 2),
  avg_tmin DECIMAL(7, 2),
  avg_tmax DECIMAL(7, 2),
  total_prcp DECIMAL(10, 2),
  max_snowd DECIMAL(10, 2)
) DISTKEY (region) SORTKEY (year);

INSERT INTO
  rhcd.yearly_agg
SELECT
  loc.region,
  loc.region_lat,
  loc.region_lon,
  loc.city,
  EXTRACT(
    YEAR
    FROM
      d.obs_date
  )::INT AS year,
  MIN(tmin / 10.0) AS tmin,
  MAX(tmax / 10.0) AS tmax,
  AVG(tmin / 10.0) AS avg_tmin,
  AVG(tmax / 10.0) AS avg_tmax,
  SUM(prcp / 10.0) AS total_prcp,
  MAX(snwd) AS max_snowd
FROM
  rhcd.daily AS d
  JOIN rhcd_dim.station_loc AS loc ON d.station_id = loc.station_id
GROUP BY
  1,
  2,
  3,
  4,
  5;

create schema if not exists rhcd_vw;

CREATE OR REPLACE VIEW rhcd_vw.yesterday_weather AS
SELECT
  s.station_id,
  s.latitude,
  s.longitude,
  s.name AS station_name,
  MAX(tmax / 10.0) AS tmax_c,
  MIN(tmin / 10.0) AS tmin_c,
  SUM(tavg / 10.0) AS prcp_mm,
  MAX(snwd) AS snow_depth_mm
FROM
  rhcd.daily AS d
  JOIN rhcd_dim.stations AS s USING (station_id)
WHERE
  d.obs_date = CURRENT_DATE - 1
GROUP BY
  1,
  2,
  3,
  4;