import pandas as pd
import geopandas as gpd
import yaml
import os


CONFIG = yaml.safe_load(open(
    os.path.join(os.path.dirname(__file__), "../config.yaml"),
    encoding="utf-8"
))

# S3 paths
bucket_name = CONFIG["bucket"]

stations_s3 = f"s3://{bucket_name}/ghcn_data/processed/metadata/ghcnd-stations.csv"
gpkg_s3     = f"s3://{bucket_name}/ghcn_data/external/gadm41_RUS.gpkg"
output_s3   = f"s3://{bucket_name}/ghcn_data/processed/metadata/station_region_city.csv"

# 1) Read station metadata
stations = pd.read_csv(
    stations_s3,
    usecols=['station_id','latitude','longitude']
)

# 2) Build GeoDataFrame of station points
gdf = gpd.GeoDataFrame(
    stations,
    geometry=gpd.points_from_xy(
        stations.longitude,
        stations.latitude
    ),
    crs='EPSG:4326'
)

# 3) Read level‑1 (regions/oblasts)
regions = (
    gpd.read_file(gpkg_s3, layer='ADM_ADM_1')
       [['NAME_1','geometry']]
       .rename(columns={'NAME_1':'region'})
)
regions['centroid'] = regions.geometry.centroid
regions['region_lon'] = regions.centroid.x
regions['region_lat'] = regions.centroid.y

# 4) Spatial join → region
gdf = (
    gpd.sjoin(gdf, regions, how='left', predicate='within')
       .drop(columns=['index_right'])
)

# 5) Read level‑2 (cities/districts)
cities = (
    gpd.read_file(gpkg_s3, layer='ADM_ADM_2')
       [['NAME_2','geometry']]
       .rename(columns={'NAME_2':'city'})
)

# 6) Spatial join → city
gdf = (
    gpd.sjoin(gdf, cities, how='left', predicate='within')
       .drop(columns=['index_right'])
)

# 7) Extract and write out
out = gdf[['station_id','region','region_lat','region_lon','city']]
out.to_csv(output_s3, index=False)

print(f"Wrote {len(out)} rows to {output_s3}")
