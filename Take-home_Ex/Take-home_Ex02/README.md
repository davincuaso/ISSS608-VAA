# Take-home Exercise 2: Myanmar conflict geography

Open `Take-home_Ex02.html` for the submission hub, `Take-home_Ex02-report.html`
for the technical report, and `Executive-summary.html`
for the ten-slide executive summary (plus cover). On the coursework site, the
report uses the shared site styles and linked figure assets. The slides embed
their figures and styles. Keep the files together for the slide-to-report link.

## Reproduce

1. Install R and Quarto. Run `Rscript setup.R` to install missing R packages.
2. Restore the course-supplied `ACLED_Data_Myanmar_Jan2021-Sep2025.csv` under
   `data/private/`. Alternatively, set `ACLED_CSV` to the authorised local file path.
   The shareable ZIP intentionally excludes this file.
3. From this directory run `quarto render Take-home_Ex02-report.qmd`.
   The default recomputes all analyses and figures from the raw input.
4. Run `quarto render Executive-summary.qmd`.

For presentation-only edits after a successful full run:
`quarto render Take-home_Ex02-report.qmd -P recompute:false`.
This mode reads existing results and redraws figures; it does not recompute permutations.

The local verified run uses R 4.6.1, sf 1.1.2, spdep 1.4-2 and Kendall 2.2.2.
See `results/session-info.txt` for the full package record. Results can vary with
package versions and spatial libraries. The seed is fixed at 6262026. No parallel
permutation workers are configured. The full run may take several minutes.

## Files

- `R/analysis.R`: audits, spatial join, cube, Local Moran, Gi*, space-time Gi* and robustness.
- `R/classify.R`: explicit EHSA timing rules, with priority order documented.
- `R/reclassify.R`: derives labels and Sen slopes from saved bin tests.
- `R/figures.R`: maps, charts, and event-weighted centre/month-bootstrap extension.
- `results/`: aggregated outputs, statistical tests, checksums and runtime versions.
- `figures/`: all exported figures used in the report and slides.
- `data/boundaries/SOURCE.md`: official MIMU release provenance.

The raw CSV and the event-level exclusion audit are private and ignored by Git.
The ZIP contains aggregate results, not raw ACLED event records. Confirm the
applicable course/data terms before publishing data products elsewhere.

## Reading the statistics

The main static maps use strict two-sided permutation p < .05. BH-adjusted
p-values are exported separately. EHSA bins use the current and previous month's
spatial neighbourhood, with the entire cube as the reference population. Main
EHSA maps additionally require Mann–Kendall p < .05. Full-history maps are in the
appendix. This R implementation is explicit about its permutation null and is
not an exact reproduction of ArcGIS's EHSA tool.

## Publication

- [Submission hub](https://isss-608-vaa-snowy.vercel.app/Take-home_Ex/Take-home_Ex02/Take-home_Ex02.html)
- [Technical report](https://isss-608-vaa-snowy.vercel.app/Take-home_Ex/Take-home_Ex02/Take-home_Ex02-report.html)
- [Executive summary](https://isss-608-vaa-snowy.vercel.app/Take-home_Ex/Take-home_Ex02/Executive-summary.html)
- [Reproducible source](https://github.com/davincuaso/ISSS608-VAA/tree/master/Take-home_Ex/Take-home_Ex02)

The coursework site uses the repository's connected Vercel deployment. The report and slides were checked on the live site on 4 October 2026. Submission
through eLearn remains the student's own step.
