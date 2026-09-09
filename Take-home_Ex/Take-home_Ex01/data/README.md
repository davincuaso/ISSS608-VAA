# Data record for Take-home Exercise 1

Do not commit restricted or oversized raw data without checking its licence. Keep every raw file unchanged and record its source here.

## Option B inputs used

1. **Thailand Road Accident 2019–2022**

   Source: <https://www.kaggle.com/datasets/thaweewatboy/thailand-road-accident-2019-2022>

   Original local files: `thailand-road-accident-2019-2022.zip`, `thai_road_accident_2019_2022.csv`, and `thai_road_accident_2019_2022.parquet`.

   Study subset: records from 2022 spatially located inside the BMR boundary.

   Access date: 9 September 2026.

   ZIP SHA-256: `225158d012a604bdf14497bbe6edc3b75ff38893a30e42e9136290598cf7b9ce`.

   CSV SHA-256: `40131c32ad417aa3a8b642cc366a3876ace4e86d8a858ee25a8c04bda9fb629c`.

   Licence shown by Kaggle API: CC0 Public Domain.

2. **Thailand ADM1 boundaries**

   Source: <https://www.geoboundaries.org/api/current/gbOpen/THA/ADM1/>.

   Original local file: `geoBoundaries-THA-ADM1.geojson`.

   Study subset: Bangkok, Samut Prakan, Nonthaburi, Pathum Thani, Nakhon Pathom, and Samut Sakhon.

   Boundary year represented: 2017; build date: 12 December 2023.

   Access date: 9 September 2026.

   SHA-256: `145beb11e52785a42e16997c92a65426b3df8d009941db6b012ec8e411f3e33c`.

   Licence: Open Data Commons Open Database Licence 1.0.

## Required audit fields

For each local file, record:

- original file name and unmodified storage path;
- publisher or compiler and original data owner where known;
- download URL and access date;
- licence and redistribution limits;
- file size and SHA-256 checksum;
- row or feature count before processing;
- temporal and geographic coverage;
- known metadata or quality limitations.

Raw and processed files are ignored by Git. `scripts/download_data.R` retrieves the original files, and `scripts/analysis.R` regenerates the processed analysis objects. Never edit the raw source files in place.
