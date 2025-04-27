-- State‑Year Station Counts
drop table if exists rhcd.state_yearly_stations;

CREATE TABLE rhcd.state_yearly_stations AS
SELECT
    s.region,
    s.region_lat,
    s.region_lon,
    EXTRACT(
        year
        FROM
            d.obs_date
    ) AS year,
    COUNT(DISTINCT d.station_id) AS station_count,
    'Russia' as country
FROM
    rhcd.daily d
    JOIN rhcd_dim.station_loc s ON d.station_id = s.station_id
GROUP BY
    1,
    2,
    3,
    4;

-- 10-Year Snapshot Table
DROP TABLE IF EXISTS rhcd.rs_10yr_snapshots;

CREATE TABLE rhcd.rs_10yr_snapshots AS
WITH
    raw_snapshot AS (
        SELECT
            s.region,
            EXTRACT(
                year
                FROM
                    d.obs_date
            ) AS snapshot_year,
            COUNT(DISTINCT d.station_id) AS station_count
        FROM
            rhcd.daily d
            JOIN rhcd_dim.station_loc s ON d.station_id = s.station_id
        WHERE
            EXTRACT(
                year
                FROM
                    d.obs_date
            ) % 10 = 0
        GROUP BY
            1,
            2
    ),
    region_max_counts AS (
        SELECT
            region,
            MAX(station_count) AS max_station_count
        FROM
            raw_snapshot
        GROUP BY
            region
    ),
    top_regions AS (
        SELECT
            region
        FROM
            region_max_counts
        ORDER BY
            max_station_count DESC
        LIMIT
            50
    )
SELECT
    *
FROM
    raw_snapshot
WHERE
    region IN (
        SELECT
            region
        FROM
            top_regions
    );
