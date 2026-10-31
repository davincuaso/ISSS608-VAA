# Take-home Exercise 3

This is one Exercise 3 project: a Quarto submission hub, technical report, and executive-summary deck. It follows the current [course brief](https://isss626-ay2026-27aug.netlify.app/take-home_ex03). The geographic analysis is complete. The station-choice model is written and tested against a temporary synthetic fixture, but **no fitted ridership result is published** because the real LTA OD Train file has not been supplied. The synthetic fixture and its output are not part of this repository.

## Files

- `Take-home_Ex03.qmd`: submission hub.
- `Take-home_Ex03-report.qmd`: methods, geographic findings, model specification, limitations, and references.
- `Executive-summary.qmd`: ten content slides, plus cover and contents.
- `R/prepare_geography.R`: public station and land-use data preparation.
- `R/model.R`: LTA OD ingestion, station-code reconciliation, Huff-type calibration, validation, and proposed-network projection.
- `data/source/`: saved station coordinate CSVs and their dataset licence.
- `results/`: non-ridership derived tables and an R session record.
- `figures/`: non-ridership maps and charts.

## Reproduce the geographic analysis

From this directory in R 4.6 or later, install `sf`, `dplyr`, `ggplot2`, and `jsonlite`. Then run:

```sh
Rscript R/prepare_geography.R
quarto render Take-home_Ex03-report.qmd
quarto render Executive-summary.qmd
```

The preparation script downloads the November 2025 [HDB Existing Building](https://data.gov.sg/datasets/d_16b157c52ed637edd6ba1232e026258d/view) layer and [Master Plan 2025 Land Use Layer](https://data.gov.sg/datasets/d_a8c3546b26712e35021f3a681d0353ae/view) from data.gov.sg into ignored `data/cache/`. If you already have the raw GeoJSON files, set `EX03_HDB_GEOJSON` and `EX03_LANDUSE_GEOJSON` to their absolute paths. Station coordinates are saved in `data/source/` and were fetched from [`elliotwutingfeng/singapore_train_station_coordinates`](https://github.com/elliotwutingfeng/singapore_train_station_coordinates) at commit `9f5972c71db8a529801eee9c527946a45a78e409` (5 March 2026).

The scenario selects `JS1–JS12`, `JW1–JW5`, `JE1–JE7`, and `CR2–CR13`: 24 JRL and 12 CRL Phase 1 line codes. It excludes `JS2A` so the JRL code count stays aligned with the brief. Interchanges are grouped by physical station name. The script uses EPSG:3414 for all metric distances and writes checks for 181 existing locations, 29 new locations and 13,436 HDB building polygons.

## Add the observed LTA OD file

Download **Passenger Volume by Origin Destination Train Stations** from [LTA DataMall](https://datamall.lta.gov.sg/content/datamall/en/dynamic-data.html) using your own Account Key. The course repository contains the Exercise 3 handout but no OD CSV. Keep the downloaded CSV or ZIP outside the public repository, or place it in ignored `data/private/`.

Run:

```sh
EX03_OD_FILE=/absolute/path/origin_destination_train_YYYYMM.csv Rscript R/model.R
quarto render Take-home_Ex03-report.qmd
quarto render Executive-summary.qmd
```

The script accepts a ZIP as well. It requires the LTA fields `YEAR_MONTH`, `DAY_TYPE`, `TIME_PER_HOUR`, `PT_TYPE`, `ORIGIN_PT_CODE`, `DESTINATION_PT_CODE`, and `TOTAL_TRIPS`. It checks for one month, non-negative trips, valid hours, and station-code reconciliation. It stops when unmatched codes carry more than 5% of trips. The model output is written to `results/model/`; the full pairwise interaction files and unmatched-code audit are ignored by Git. Review the month, station-code audit, validation metrics and scenario assumptions before publishing any derived estimates.

For a one-command full rebuild after the OD file is available:

```sh
EX03_OD_FILE=/absolute/path/origin_destination_train_YYYYMM.csv quarto render Take-home_Ex03-report.qmd -P recompute:true
```

The default report render uses the saved verified geographic results and does not require network access or a private OD file.

## Input checksums

SHA-256 hashes of the 31 October 2026 copies used for the current geographic results:

| Input | SHA-256 |
|---|---|
| `data/source/operational_stations.csv` | `bb3e876ae1ae0e342bf368c691e0db6cfbdb4ca30cdc7321c1698308c1ad6b2c` |
| `data/source/future_stations.csv` | `16f61a996ca6b9d295d3efc751ef93a8fe233a62c18f3c34f86468141ba13b28` |
| HDB Existing Building GeoJSON | `7c987511548de3a82da403cabca02702031e02ade8703a9e401417883dfeb702` |
| Master Plan 2025 Land Use GeoJSON | `69477dedbb67fc557dcb2f8da55486d32cb9938cde8a386c2d5e281e9c02d13c` |

The HDB and land-use raw files are available under the [Singapore Open Data Licence](https://data.gov.sg/open-data-licence). See `data/source/LICENSE-DATASET.md` for the coordinate compilation's source and licence notes.
