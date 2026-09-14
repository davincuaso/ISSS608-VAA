# Shared exercise data

These files support Hands-on Exercises 2, 4, 5, and 6. They are committed so the Quarto pages render without API keys or network access.

## Singapore

- `geospatial/MP2019_Subzone.geojson` — URA Master Plan 2019 Subzone Boundary (No Sea), data.gov.sg dataset `d_8594ae9ff96d0c708bc2af633048edfb`.
- `geospatial/MP2019_PlanningArea.geojson` — URA Master Plan 2019 Planning Area Boundary (No Sea), data.gov.sg dataset `d_4765db0e87b9c86336792efe8a1f7a66`.
- `geospatial/ChildCareServices.geojson` — ECDA Child Care Services, data.gov.sg dataset `d_5d668e3f544335f8028f546827b773b4` (download metadata reports December 2021 source data).
- `aspatial/resident_population_2020.csv` — Singapore Department of Statistics, Resident Population by Planning Area/Subzone of Residence, Age Group and Sex, Census of Population 2020, data.gov.sg dataset `d_d95ae740c0f8961a0b10435836660ce0`.

The Hands-on Exercise 1b course notes use a newer SingStat CSV. The 2020 Census table is used here because it is available as a stable public download and provides the same subzone-by-age fields needed for the dependency-ratio workflow.

## Bangka Belitung

- `temporal/forestfires_2023.csv` — 898 records spatially filtered to the Bangka Belitung province from the public `indonesia2023.csv` snapshot in `apkirana/project_forestfire`; the original data source is NASA FIRMS.
- `temporal/BangkaBelitung.geojson` — GADM 4.1 Indonesia level-1 feature for `BangkaBelitung`.
- `temporal/BangkaBelitung_Districts.geojson` — GADM 4.1 Indonesia level-2 features inside the province.

The Chapter 6 project-local fire and Indonesia geospatial files are not published through the chapter URL. The public NASA-derived snapshot and GADM boundaries preserve the same study year, province, projected-analysis workflow, and research questions while making Hands-on Exercise 3 reproducible.
