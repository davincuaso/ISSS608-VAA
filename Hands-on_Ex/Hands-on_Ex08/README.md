# Hands-on Exercise 8: market area analysis using the Huff model

A worked Quarto analysis of Chapter 18 using the actual Taichung course files supplied on 24 October 2026.

## Run

1. Restore inputs with `Rscript scripts/import_data.R /path/to/course/data`.
2. Render `Hands-on_Ex08.qmd` in the portfolio's R/Quarto environment.
3. Review the interactive input map, BT patronage-probability map, population-weighted store allocations, recorded-sales association and wide probability matrix.

The package setup uses one `pacman::p_load()` call. All joins name their keys, maps use `tmap`, and static legends sit outside the map.

## Checks and interpretation

The analysis checks raw counts, EPSG 3826, key uniqueness, unmatched records, complete village-store distances, probability sums, direct-formula agreement and population conservation. It preserves the literal sales code `NA` and does not treat excluded population as zero.

The Huff model uses the chapter's equal attractiveness, `gamma = 1` and `lambda = -2`. Probability-weighted population is not monetary sales. The sales comparison is descriptive, not a calibrated revenue forecast.

The in-class exercise adds the classroom's dominant-store `TA` map; the chapter exercise retains the baseline workflow without that additional classification.

See `data/README.md` for provenance and fingerprints. Raw inputs remain local; source, derived tables and rendered outputs are committed.
