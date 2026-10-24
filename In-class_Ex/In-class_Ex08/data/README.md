# Taichung course-data record

## Source and versions

These are the teaching files supplied by the user on 24 October 2026 for [Chapter 18](https://r4gdsa.netlify.app/chap18). They are not substituted datasets or reconstructions from the chapter's figures. The files were copied unchanged from the supplied data folder; the import script verifies source and destination fingerprints.

The analysis uses `STORES_TC` (28 stores), `TOWN_TC` (28 town boundaries), `VILLAGE_TC` (622 village boundaries), `pop2019.csv` (625 rows), `Store_sales_data.csv` (5,499 rows) and the 28-code `storeCD.csv` lookup. All spatial layers declare EPSG 3826, TWD97 / TM2 zone 121.

The separate `STORES_TC1` layer has 29 locations, including a new store called NS. It is not used in the baseline chapter/classroom analysis. QGIS metadata files with a `.qmd` extension are not treated as executable Quarto documents.

## Field meanings and preparation

- `VILLCODE` is the village-layer key. The population table's `V_ID` has a hyphen that is removed before an explicit one-to-one join.
- `P_CNT` is population; `H_CNT`, `M_CNT` and `F_CNT` are households, male population and female population. `INFO_TIME = 108Y12M` identifies December 2019.
- Five polygons have no matching population. They remain as grey map context but are excluded from the model, leaving 617 origins and population 2,804,359.
- `Store_CD` identifies the 28 modelled locations. The sales table has 234 code categories; only those matching the supplied locations enter the mapped comparison.
- `Store Code` contains literal text `NA` in 29 sales rows. The reader preserves that text with `na = ""` and records it among the unmatched categories rather than inferring a location.
- `Bills` and `Amount` are aggregated by store. No sales reporting period or currency unit is asserted where the supplied CSV provides none.
- The chapter's attraction assumption is `Store_size = 100`. The lookup's `Capacity = 50` field is not used as a different attractiveness or demand measure.

## Reproduce locally

Raw teaching inputs remain local rather than being redistributed in Git. Run `Rscript scripts/import_data.R /path/to/course/data` from the exercise folder before rendering a fresh checkout. The script copies only the required shapefile components and CSV tables, and refuses to overwrite a different existing input. No download URL is invented for the course files.

The render writes input MD5 fingerprints to `results/input-checksums.csv`. Key source-file SHA-256 fingerprints are:

```text
69fd4b3760159d324565e826006b0fc70e6d77d2865ee0facefa0233cb1c4f57  geospatial/STORES_TC.shp
a54ba8fe3e027adac41286dc92811140865530f56ffc6a4992ae59174c5530e9  geospatial/TOWN_TC.shp
a33a26b03a4f798b206ba08f38245754bbbe7a10c3064e398001657d7e9d6651  geospatial/VILLAGE_TC.shp
8c23bc4c68c5b85e8929dc6978fba90ab6baaa6086b4735f62fcbd4ddb15a204  aspatial/pop2019.csv
007c65b6d73f33cf42d8fcf8d7c91a9b672bb05384d88f47cb9c44a0e620b3bf  aspatial/Store_sales_data.csv
50a2b98bb6fdebea3b3e364c7728cd51d4992af0858a6ab48f8ddd30265163d9  aspatial/storeCD.csv
```
