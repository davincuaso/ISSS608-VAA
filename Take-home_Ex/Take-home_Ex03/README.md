# Take-home Exercise 3

This is one Exercise 3 submission following the [course brief](https://isss626-ay2026-27aug.netlify.app/take-home_ex03). It contains a Quarto submission hub, technical report and ten-content-slide executive summary. The station-choice model is fitted to **September 2026 LTA train origin–destination data**, with an independent station-volume reconciliation. Results are conditional on a fixed current-origin market; the report shows the fit errors and scenario sensitivity.

## Project files

- Take-home_Ex03.qmd: submission hub.
- Take-home_Ex03-report.qmd: methods, results, validation, limitations and sources.
- Executive-summary.qmd: presentation, plus cover and contents.
- R/prepare_geography.R: station, HDB, land-use and bus-stop preparation.
- R/download_lta.R: downloads one month of LTA OD and station-volume ZIPs using an account key from the environment.
- R/model.R: code reconciliation, full interaction tables, calibration, holdout check and proposed-network comparison.
- R/plot_model.R: model-fit and scenario charts.
- data/source/: checked station coordinate CSVs and licence notes.
- results/: derived station and model summaries. Full pairwise interaction files are excluded from Git.
- figures/: maps and charts used in the report and deck.

## Reproduce

Run these commands from this Exercise 3 directory. Use R 4.6 or later with sf, dplyr, ggplot2, jsonlite, data.table, httr, scales and knitr installed, plus Quarto. The geographic script downloads public HDB, land-use and bus-stop GeoJSON into excluded data/cache/. If local copies exist, set EX03_HDB_GEOJSON, EX03_LANDUSE_GEOJSON and EX03_BUS_GEOJSON to their paths.

    Rscript R/prepare_geography.R

Set LTA_ACCOUNT_KEY in your shell environment without saving the key in this project, then request the matching month:

    Rscript R/download_lta.R 202609

The LTA DataMall API returns short-lived download links and, according to its [API guide](https://datamall.lta.gov.sg/content/dam/datamall/datasets/LTA_DataMall_API_User_Guide.pdf), only recent monthly files. Reproducing this exact September run later requires retained authentic ZIPs or authorised access to that release; the public repository cannot recreate the raw file from its aggregate outputs.

    EX03_OD_FILE=data/private/origin_destination_train_202609.zip EX03_STATION_FILE=data/private/transport_node_train_202609.zip Rscript R/model.R
    Rscript R/plot_model.R
    quarto render Take-home_Ex03-report.qmd
    quarto render Executive-summary.qmd
    quarto render Take-home_Ex03.qmd

The default Quarto render reads checked aggregate files, so it does not require an account key. To rebuild the report and data together, pass the same two EX03 file variables to Quarto and render the report with its recompute parameter set to true.

## Data and checks

The saved coordinate compilation comes from [Singapore Train Station Coordinates](https://github.com/elliotwutingfeng/singapore_train_station_coordinates) at commit 9f5972c71db8a529801eee9c527946a45a78e409 (5 March 2026). It predates the July 2026 [Circle Line Stage 6](https://www.lta.gov.sg/content/ltagov/en/upcoming_projects/rail_expansion/circle_line_6.html) opening. Keppel, Cantonment and Prince Edward Road were added using centroids of their station polygons from LTA's September 2026 Train Station geospatial layer, downloaded through DataMall on 6 November 2026. Bayfront and Marina Bay use their current CC34 and CC33 codes. Points are projected to SVY21 / Singapore TM (EPSG:3414) for distances.

The proposed scenario uses JS1–JS12, JW1–JW5, JE1–JE7 and CR2–CR13: 24 JRL and 12 CRL1 codes. The extra JS2A record is outside the brief's 24-code JRL scope. Interchanges are grouped by physical station name: 216 current code records become 184 physical current stations; seven of the 36 proposed codes are current interchange sites, leaving 29 new destinations.

The September OD extract has 475,395 weekday rows and 66,784,543 weekday trips. The model excludes 238 same-station trips. All recorded station codes matched; 66,784,305 trips enter the fitted market. The independent station-volume extract has 67,421,973 weekday tap-outs across the same 184 stations, 637,668 more than the OD destination sum. The available fields do not establish the cause, so the model is not rescaled. The script checks month, day type, hours, non-negative trips, code coverage, trip conservation and origin probabilities. It keeps zero-flow pairs in the choice set, holds out 20% of origins, and saves the station-volume reconciliation.

Raw LTA ZIPs and the account key are not committed. The .gitignore file excludes data/private/ and data/cache/, plus the full pairwise interaction CSVs. The public aggregate model files are checks.csv, coefficients.csv, origins.csv, destinations.csv, station-predictions.csv and station-volume-reconciliation.csv.

## Input checksums

SHA-256 hashes for the inputs used in this run:

| Input | SHA-256 |
|---|---|
| data/source/operational_stations.csv (reconciled) | b9d3e153f251bfb8e674acd8a7b64e7c48bbc552b68233b2f8269e2e5199423a |
| data/source/future_stations.csv | 16f61a996ca6b9d295d3efc751ef93a8fe233a62c18f3c34f86468141ba13b28 |
| September 2026 LTA OD Train ZIP | d45b050867d5ae36913fad3b8c4cd89025e771f40c9b0f146028011165298343 |
| September 2026 LTA station-volume ZIP | b1ca1a25e947ca2b80f416cb79971f418a4e6a46aeff8a2a049fabacbb7c7f50 |
| LTA Train Station geospatial ZIP downloaded 6 Nov 2026 | f6d745bfd3f23af5656f58cbc1cd264e8185f61ec38ac786406a9e2958b2b8f4 |
| HDB Existing Building GeoJSON | 7c987511548de3a82da403cabca02702031e02ade8703a9e401417883dfeb702 |
| Master Plan 2025 Land Use GeoJSON | 69477dedbb67fc557dcb2f8da55486d32cb9938cde8a386c2d5e281e9c02d13c |
| LTA Bus Stop GeoJSON | ea16db2e53038b2b3352b57cb008e484c253091367b45bc3564b6cc3fe8d491b |

The public geographic layers are from [data.gov.sg](https://data.gov.sg) under the [Singapore Open Data Licence](https://data.gov.sg/open-data-licence). See data/source/LICENSE-DATASET.md for coordinate-source notes. LTA's [DataMall dynamic data page](https://datamall.lta.gov.sg/content/datamall/en/dynamic-data.html) and [API guide](https://datamall.lta.gov.sg/content/dam/datamall/datasets/LTA_DataMall_API_User_Guide.pdf) document the trip extracts.
