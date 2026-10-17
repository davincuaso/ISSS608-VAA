# In-Class Exercise 7: geographical accessibility and catchment methods

This is a worked HTML exercise based on Dr. Kam Tin Seong's supplied `In-class_Ex07-accessibility.qmd` and [published 18-slide deck](https://isss626-ay2026-27aug.netlify.app/in-class_ex/in-class_ex07/in-class_ex07-accessibility#/title-slide), dated 17 October 2026. It follows the existing portfolio's Quarto format.

## Run

1. From this directory, run `Rscript scripts/download_data.R` if the inputs are absent.
2. Render `In-class_Ex07.qmd`. The setup installs the GitHub-only `catchment` package at commit `b96fb58adcd0e476cbb634aeb6ce27981fbc1dc3` when needed and attaches the packages through one `pacman::p_load()` call.
3. The page is written to `../../_site/In-class_Ex/In-class_Ex07/In-class_Ex07.html`.

The exercise calculates nearest-centre distance and the guide's 2SFCA, E2SFCA, Gaussian KD2SFCA, 3SFCA and M2SFCA variants. It generates six maps and writes derived tables to `results/`. Inputs and teaching-use conditions are documented in `data/README.md`.

## Guide adjustments

- Nearest-centre opportunities are drawn from the eldercare destinations, with one opportunity per centre. The output joins to origin hexagons explicitly on `id`. The professor's hexagon-based opportunity call produces identical nearest distances for these inputs because its positive-valued IDs overlap the destination IDs; the render verifies that agreement.
- `pivot_wider()` replaces `spread()`. Matrix rows and columns are aligned to the source IDs, including gaps in centre IDs.
- Gaussian KD2SFCA retains the guide's default 2 km scale and no hard cutoff. It differs from the `SpatialAcc` implementation used in Hands-on Exercise 7.
- The 3SFCA explanation records the pinned package's selection-adjusted weights, not a claim that its final weight rows simply sum to one.
- The M2SFCA map draws `hex_M2SFCA` and its `M2SFCA` field, correcting the plot-tab reference to 3SFCA in the guide.
- Maps retain the slides' frame, red centre markers, eight-point compass, scale bar and `tm_grid(alpha = 0.2)`. Legends sit outside the maps. Catchment zero scores have a separate grey class. The score palettes run in the opposite direction to the slides so darker blue consistently means better access; computed scores are unchanged.

## Checks

The render checks the input counts and cost components, verifies the nearest distance against matrix minima, compares all five models with independent formula calculations, and checks included-capacity accounting for the first four FCA variants. M2SFCA's separately downweighted allocation is recorded without imposing a conservation identity that its formula does not satisfy.

A second pass checked every slide against the exercise. The `check-slide-alignment` chunk repeats all six analytical calls using the original layer order and the slides' matrix preparation. It requires a maximum absolute difference below `1e-10` and writes `results/slide-alignment.csv`. This confirms numerical agreement without copying the plot-tab M2SFCA mistake or relying on implicit join keys.
