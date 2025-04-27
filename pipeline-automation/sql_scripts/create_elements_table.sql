DROP TABLE IF EXISTS rhcd_dim.element;

CREATE TABLE rhcd_dim.element (
    element_code VARCHAR(4) PRIMARY KEY,
    description VARCHAR(160)
) DISTSTYLE ALL;

-- /* Base temperature / precip codes already in your sample + full glossary */
INSERT INTO
    rhcd_dim.element (element_code, description)
VALUES -- ── temperature / precipitation ────────────────────────────────────────────
    ('PRCP', 'Precipitation (tenths of mm)'),
    ('SNOW', 'Snowfall (mm)'),
    ('SNWD', 'Snow depth (mm)'),
    (
        'TMAX',
        'Maximum temperature (tenths of degrees C)'
    ),
    (
        'TMIN',
        'Minimum temperature (tenths of degrees C)'
    ),
    -- ── average‑/derived‑day statistics ───────────────────────────────────────
    (
        'ACMC',
        'Average cloudiness midnight‑to‑midnight from 30‑sec ceilometer data (percent)'
    ),
    (
        'ACMH',
        'Average cloudiness midnight‑to‑midnight from manual observations (percent)'
    ),
    (
        'ACSC',
        'Average cloudiness sunrise‑to‑sunset from 30‑sec ceilometer data (percent)'
    ),
    (
        'ACSH',
        'Average cloudiness sunrise‑to‑sunset from manual observations (percent)'
    ),
    (
        'ADPT',
        'Average Dew‑Point Temperature for the day (tenths °C)'
    ),
    (
        'ASLP',
        'Average Sea‑Level Pressure for the day (hPa × 10)'
    ),
    (
        'ASTP',
        'Average Station‑Level Pressure for the day (hPa × 10)'
    ),
    (
        'AWBT',
        'Average Wet‑Bulb Temperature for the day (tenths °C)'
    ),
    ('AWDR', 'Average daily wind direction (degrees)'),
    ('AWND', 'Average daily wind speed (tenths m s‑¹)'),
    -- ── “number‑of‑days included …” counters for multiday totals ──────────────
    (
        'DAEV',
        'Days included in multiday evaporation total (MDEV)'
    ),
    (
        'DAPR',
        'Days included in multiday precipitation total (MDPR)'
    ),
    (
        'DASF',
        'Days included in multiday snowfall total (MDSF)'
    ),
    (
        'DATN',
        'Days included in multiday minimum temperature (MDTN)'
    ),
    (
        'DATX',
        'Days included in multiday maximum temperature (MDTX)'
    ),
    (
        'DAWM',
        'Days included in multiday wind movement (MDWM)'
    ),
    (
        'DWPR',
        'Days with non‑zero precip in multiday precipitation total (MDPR)'
    ),
    -- ── multiday totals themselves ────────────────────────────────────────────
    ('EVAP', 'Evaporation from pan (tenths mm)'),
    (
        'MDEV',
        'Multiday evaporation total (tenths mm; use with DAEV)'
    ),
    (
        'MDPR',
        'Multiday precipitation total (tenths mm; use with DAPR/DWPR)'
    ),
    ('MDSF', 'Multiday snowfall total'),
    (
        'MDTN',
        'Multiday minimum temperature (tenths °C; use with DATN)'
    ),
    (
        'MDTX',
        'Multiday maximum temperature (tenths °C; use with DATX)'
    ),
    ('MDWM', 'Multiday wind movement (km)'),
    -- ── other hydrology / soil / sunshine etc. ────────────────────────────────
    ('FRGB', 'Base of frozen‑ground layer (cm)'),
    ('FRGT', 'Top of frozen‑ground layer (cm)'),
    ('FRTH', 'Thickness of frozen‑ground layer (cm)'),
    (
        'GAHT',
        'Difference between river & gauge height (cm)'
    ),
    (
        'MNPN',
        'Daily min temp of water in evaporation pan (tenths °C)'
    ),
    (
        'MXPN',
        'Daily max temp of water in evaporation pan (tenths °C)'
    ),
    ('PGTM', 'Peak‑gust time (HHMM)'),
    ('PSUN', 'Percent possible sunshine (percent)'),
    ('RHAV', 'Average relative humidity (percent)'),
    ('RHMN', 'Minimum relative humidity (percent)'),
    ('RHMX', 'Maximum relative humidity (percent)'),
    (
        'TAXN',
        'Average daily temperature (TMAX+TMIN)/2 (tenths °C)'
    ),
    ('TAVG', 'Average daily temperature (tenths °C)'),
    ('THIC', 'Thickness of ice on water (tenths mm)'),
    (
        'TOBS',
        'Temperature at time of observation (tenths °C)'
    ),
    ('TSUN', 'Total sunshine (minutes)'),
    -- ── wind direction / speed, movement, gusts ───────────────────────────────
    (
        'FMTM',
        'Time of fastest mile or fastest 1‑min wind (HHMM)'
    ),
    (
        'WDF1',
        'Direction of fastest 1‑min wind (degrees)'
    ),
    (
        'WDF2',
        'Direction of fastest 2‑min wind (degrees)'
    ),
    (
        'WDF5',
        'Direction of fastest 5‑sec wind (degrees)'
    ),
    ('WDFG', 'Direction of peak wind gust (degrees)'),
    (
        'WDFI',
        'Direction of highest instantaneous wind (degrees)'
    ),
    ('WDFM', 'Fastest mile wind direction (degrees)'),
    ('WDMV', '24‑h wind movement (km)'),
    (
        'WESD',
        'Water equivalent of snow on ground (tenths mm)'
    ),
    (
        'WESF',
        'Water equivalent of snowfall (tenths mm)'
    ),
    ('WSF1', 'Fastest 1‑min wind speed (tenths m s‑¹)'),
    ('WSF2', 'Fastest 2‑min wind speed (tenths m s‑¹)'),
    ('WSF5', 'Fastest 5‑sec wind speed (tenths m s‑¹)'),
    ('WSFG', 'Peak‑gust wind speed (tenths m s‑¹)'),
    (
        'WSFI',
        'Highest instantaneous wind speed (tenths m s‑¹)'
    ),
    ('WSFM', 'Fastest mile wind speed (tenths m s‑¹)'),
    -- ── ice / snow water equivalents ──────────────────────────────────────────
    (
        'WESD',
        'Water equivalent of snow on ground (tenths mm)'
    ),
    (
        'WESF',
        'Water equivalent of snowfall (tenths mm)'
    ),
    -- ── weather‑type indicators (WT**) ────────────────────────────────────────
    (
        'WT01',
        'Weather type: Fog, ice fog, or freezing fog'
    ),
    (
        'WT02',
        'Weather type: Heavy fog or heavy freezing fog'
    ),
    ('WT03', 'Weather type: Thunder'),
    (
        'WT04',
        'Weather type: Ice pellets / sleet / small hail'
    ),
    ('WT05', 'Weather type: Hail'),
    ('WT06', 'Weather type: Glaze or rime'),
    (
        'WT07',
        'Weather type: Dust / ash / blowing obstruction'
    ),
    ('WT08', 'Weather type: Smoke or haze'),
    ('WT09', 'Weather type: Blowing or drifting snow'),
    (
        'WT10',
        'Weather type: Tornado / waterspout / funnel cloud'
    ),
    ('WT11', 'Weather type: High or damaging winds'),
    ('WT12', 'Weather type: Blowing spray'),
    ('WT13', 'Weather type: Mist'),
    ('WT14', 'Weather type: Drizzle'),
    ('WT15', 'Weather type: Freezing drizzle'),
    (
        'WT16',
        'Weather type: Rain (may include freezing rain / drizzle)'
    ),
    ('WT17', 'Weather type: Freezing rain'),
    ('WT18', 'Weather type: Snow / ice crystals'),
    (
        'WT19',
        'Weather type: Unknown source of precipitation'
    ),
    ('WT21', 'Weather type: Ground fog'),
    ('WT22', 'Weather type: Ice fog or freezing fog'),
    -- ── “weather in the vicinity” indicators (WV**) ───────────────────────────
    (
        'WV01',
        'Weather in vicinity: Fog / ice fog / freezing fog'
    ),
    ('WV03', 'Weather in vicinity: Thunder'),
    (
        'WV07',
        'Weather in vicinity: Ash / dust / sand / blowing obstruction'
    ),
    (
        'WV18',
        'Weather in vicinity: Snow or ice crystals'
    ),
    (
        'WV20',
        'Weather in vicinity: Rain or snow shower'
    );