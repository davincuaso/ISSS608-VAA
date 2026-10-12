# Hands-on Exercise 7: geographical accessibility

Open `Hands-on_Ex07.qmd` in RStudio. The page follows Chapter 17 and compares Hansen, KD2SFCA and SAM access to the supplied eldercare locations.

## Run

1. From this folder run `Rscript scripts/download_data.R` to restore the pinned teaching inputs.
2. Render `Hands-on_Ex07.qmd`. The setup chunk installs `pacman` if needed and uses one `pacman::p_load()` call for the chapter's packages and `knitr`.
3. The website output is `../../_site/Hands-on_Ex/Hands-on_Ex07/Hands-on_Ex07.html`.

The render executes the model calculations and writes aggregate score tables, regional summaries, sensitivity comparisons and the R package record to `results/`. All scores use kilometres, demand 100 per hexagon and capacity 100 per centre. Main parameters are Hansen beta 2, KD2SFCA cutoff 5 km and power 2, and SAM power 2 without a cutoff.

The source checks the distance-matrix ID alignment and all three model formulas. It dissolves subzones into regions before assigning a cell by its largest overlap, preventing repeated cells in regional summaries. See `data/README.md` for provenance and teaching-use conditions.
