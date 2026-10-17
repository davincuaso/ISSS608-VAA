# In-Class Exercise 7: geographical accessibility and catchment methods

This is a worked HTML exercise based on Dr. Kam Tin Seong's supplied `In-class_Ex07-accessibility.qmd`. It follows the existing portfolio's Quarto format.

## Run

1. From this directory, run `Rscript scripts/download_data.R` if the inputs are absent.
2. Render `In-class_Ex07.qmd`. The setup installs the GitHub-only `catchment` package at commit `b96fb58adcd0e476cbb634aeb6ce27981fbc1dc3` when needed and attaches the packages through one `pacman::p_load()` call.
3. The page is written to `../../_site/In-class_Ex/In-class_Ex07/In-class_Ex07.html`.

The exercise calculates nearest-centre distance and the guide's 2SFCA, E2SFCA, Gaussian KD2SFCA, 3SFCA and M2SFCA variants. It generates six maps and writes derived tables to `results/`. Inputs and teaching-use conditions are documented in `data/README.md`.

## Guide adjustments

- Nearest-centre opportunities are drawn from the eldercare destinations, with one opportunity per centre. The output joins to origin hexagons explicitly on `id`.
- `pivot_wider()` replaces `spread()`. Matrix rows and columns are aligned to the source IDs, including gaps in centre IDs.
- Gaussian KD2SFCA retains the guide's default 2 km scale and no hard cutoff. It differs from the `SpatialAcc` implementation used in Hands-on Exercise 7.
- The 3SFCA explanation records the pinned package's selection-adjusted weights, not a claim that its final weight rows simply sum to one.
- The M2SFCA map draws `hex_M2SFCA` and its `M2SFCA` field, correcting the plot-tab reference to 3SFCA in the guide.
- Legends sit outside the maps. Catchment zero scores have a separate grey class.

## Checks

The render checks the input counts and cost components, verifies the nearest distance against matrix minima, compares all five models with independent formula calculations, and checks included-capacity accounting for the first four FCA variants. M2SFCA's separately downweighted allocation is recorded without imposing a conservation identity that its formula does not satisfy.
