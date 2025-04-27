-- ── A) External schema: point at your Glue DB (only needs to run once)
CREATE EXTERNAL SCHEMA IF NOT EXISTS rhcd_spectrum
FROM
  DATA CATALOG DATABASE 'ghcn_catalog' IAM_ROLE 'arn:aws:iam::615299755921:role/service-role/AmazonRedshift-CommandsAccessRole-20250416T193208' CREATE EXTERNAL DATABASE IF NOT EXISTS;

-- ── B) Staging & final tables (you can run these any time to reset)
DROP TABLE IF EXISTS rhcd.daily_staging;

CREATE TABLE rhcd.daily_staging (
  station_id VARCHAR(11),
  obs_date DATE,
  element VARCHAR(4),
  data_value BIGINT,
  m_flag CHAR(1),
  s_flag CHAR(1),
  obs_time VARCHAR(4)
) DISTKEY (station_id) SORTKEY (obs_date);

CREATE TABLE IF NOT EXISTS rhcd.daily (
  station_id VARCHAR(11) DISTKEY,
  obs_date DATE SORTKEY,
  TMIN INT,
  TMAX INT,
  TAVG DOUBLE PRECISION,
  PRCP INT,
  SNWD INT,
  MDPR INT
);

-- ── C) Daily pipeline: pull only the last 7 days from the crawler table
TRUNCATE TABLE rhcd.daily_staging;

INSERT INTO
  rhcd.daily_staging (
    station_id,
    obs_date,
    element,
    data_value,
    m_flag,
    s_flag,
    obs_time
  )
SELECT
  id AS station_id, -- crawler’s “id” column
  date AS obs_date, -- crawler’s “date” column
  element, -- partition column
  cast(data_value as bigint) -- match your BIGINT type
,
  m_flag,
  s_flag,
  obs_time
FROM
  rhcd_spectrum.processed_by_year
WHERE
  1 = 1
  AND element IN ('TMIN', 'TMAX', 'TAVG', 'PRCP', 'SNWD', 'MDPR')
  --   AND cast(year as int) IN (
  --     EXTRACT(YEAR FROM CURRENT_DATE),
  --     EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '7 DAYS')
  --   )
  --   AND date BETWEEN DATEADD(day, -7, CURRENT_DATE) 
  --                AND DATEADD(day, -1, CURRENT_DATE)
;

-- ── D) Aggregate & upsert into your final table
MERGE INTO rhcd.daily USING (
  SELECT
    station_id,
    obs_date,
    MIN(
      CASE
        WHEN element = 'TMIN' THEN data_value
      END
    ) AS TMIN,
    MAX(
      CASE
        WHEN element = 'TMAX' THEN data_value
      END
    ) AS TMAX,
    AVG(
      CASE
        WHEN element = 'TAVG' THEN data_value
      END
    ) AS TAVG,
    MAX(
      CASE
        WHEN element = 'PRCP' THEN data_value
      END
    ) AS PRCP,
    MAX(
      CASE
        WHEN element = 'SNWD' THEN data_value
      END
    ) AS SNWD,
    MAX(
      CASE
        WHEN element = 'MDPR' THEN data_value
      END
    ) AS MDPR
  FROM
    rhcd.daily_staging
  GROUP BY
    station_id,
    obs_date
) AS src ON (
  rhcd.daily.station_id = src.station_id
  AND rhcd.daily.obs_date = src.obs_date
) WHEN MATCHED THEN
UPDATE
SET
  TMIN = src.TMIN,
  TMAX = src.TMAX,
  TAVG = src.TAVG,
  PRCP = src.PRCP,
  SNWD = src.SNWD,
  MDPR = src.MDPR WHEN NOT MATCHED THEN INSERT (
    station_id,
    obs_date,
    TMIN,
    TMAX,
    TAVG,
    PRCP,
    SNWD,
    MDPR
  )
VALUES
  (
    src.station_id,
    src.obs_date,
    src.TMIN,
    src.TMAX,
    src.TAVG,
    src.PRCP,
    src.SNWD,
    src.MDPR
  );
