# Hands-on Exercise 9: hedonic pricing with GWR

An executed Quarto analysis of Chapter 13 using the professor's original 2015 Singapore condominium resale files.

## Reproduce

From this exercise folder:

1. Run `Rscript scripts/download_data.R` to retrieve and fingerprint the five source files.
2. Run `Rscript scripts/test_helpers.R` for the separately labelled synthetic helper tests.
3. Render `Hands-on_Ex09.qmd` in the portfolio's R/Quarto environment.
4. Run `Rscript scripts/validate_results.R` to check the real-data exports and reproduce four local fits with base R's weighted QR solver.

The page uses a single `pacman::p_load()` call, explicit record keys, EPSG 3414 distances, `sf` preparation, a documented `sp` compatibility conversion for GWmodel, outside static map legends, and published/modified dates.

## What is included

Input audits, missing values, summaries, price/log histograms, twelve attribute histograms, an interactive price map, simple/full/revised OLS, correlation and VIF, regression tables, residual diagnostics, influence, residual mapping, `sfdep` distance-band Moran tests, cross-validated fixed/adaptive Gaussian GWR, AICc and leave-one-out comparison, local collinearity, local R-squared, coefficient/SE/pseudo-t maps and an interactive local-results map.

## Interpretation safeguards

All comparable models use the same 1,436 records and price response. Bandwidths are selected with CV rather than hard-coded. `CV_Score` contains leave-one-out residuals, so RMSE squares it. AICc is calculated with compatible Gaussian conventions. Finite permutation p-values use an explicit add-one correction and doubled smaller tail; the package's raw result is retained separately.

Improved fit is reported alongside the widespread local condition-number warnings and remaining residual spatial structure. The page does not claim causal amenity effects, independent test-set accuracy or current property valuations. Data provenance is in `data/README.md`; audit tables and transaction-linked model output are in `results/`.
