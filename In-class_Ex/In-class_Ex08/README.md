# In-Class Exercise 8: Huff modelling and store trade areas

This exercise follows Chapter 18 and adds the categorical `TA` trade-area map from the classroom photographs. It uses the actual course files supplied on 24 October 2026.

## Run

1. Restore inputs with `Rscript scripts/import_data.R /path/to/course/data`.
2. Run `Rscript scripts/test_trade_areas.R` and `Rscript scripts/test_model.R` for the separately labelled synthetic unit tests.
3. Render `In-class_Ex08.qmd` in the portfolio's R/Quarto environment.
4. The source calculates the actual Huff probabilities, BT probability map, dominant-store map, population allocations, recorded-sales comparison and validation outputs.

All packages are attached in one `pacman::p_load()` call. Maps have outside legends, a frame, compass, scale bar and grid. The source and input provenance are documented in `data/README.md`.

## Classroom extension

The wide share matrix retains the actual store codes, which are checked against `storeCD.csv`. `huff_TA` selects the highest-probability store for each village; `huff_TA_tidied` retains the code as a categorical label; `village_TA` joins it back to the polygons by `VILLCODE`. The map uses `tm_polygons(fill = "TA")`.

The photographs do not show the assignment code preceding the map. The maximum-probability rule is stated explicitly, with runner-up probabilities, gaps and numerical ties retained. Ties are resolved by lexical store-code order only for display. Equal attractiveness means this classification also agrees with the nearest-store classification.

## Validation

The render checks counts, projected CRS, IDs, joins, positive distances, complete origin-destination coverage, probability sums, the independent Huff formula, population accounting and store labels. Both exercises use the same 28-store baseline. The separate 29-store scenario is not silently substituted.

Synthetic unit fixtures test the code only. All reported exercise results come from the uploaded course data. Raw inputs remain local; source, derived tables and rendered outputs are committed.
