# Hands-on Exercise 1a data

Downloaded on 6 September 2026 for the reproducible Hands-on Exercise 1a analysis.

## Geospatial data

- `MasterPlan2014SubzoneBoundaryNoSea.geojson`
  - Dataset: Master Plan 2014 Subzone Boundary (No Sea)
  - Agency: Urban Redevelopment Authority
  - Dataset ID: `d_226cacceceff94f0c8b814962a5307c9`
  - Source: https://data.gov.sg/datasets/d_226cacceceff94f0c8b814962a5307c9/view
- `CyclingPathNetwork.geojson`
  - Dataset: Cycling Path Network
  - Agency: Land Transport Authority
  - Dataset ID: `d_8f468b25193f64be8a16fa7d8f60f553`
  - Source: https://data.gov.sg/datasets/d_8f468b25193f64be8a16fa7d8f60f553/view
- `PreSchoolsLocation.geojson`
  - Dataset: Pre-Schools Location
  - Agency: Early Childhood Development Agency
  - Dataset ID: `d_61eefab99958fd70e6aab17320a71f1c`
  - Source: https://data.gov.sg/datasets/d_61eefab99958fd70e6aab17320a71f1c/view

The original course chapter requests the Master Plan 2014 Subzone Boundary (Web) dataset. Its current collection has no downloadable child dataset, so the No Sea edition is used and disclosed in the report.

## Aspatial data

- `listings.csv`
  - Dataset: Singapore summary listings, 28 December 2024 snapshot
  - Source: https://beta.insideairbnb.com/get-the-data/

The source files remain in their downloaded formats. The Quarto document transforms the spatial data from WGS84 (EPSG:4326) to SVY21 / Singapore TM (EPSG:3414) during rendering.
