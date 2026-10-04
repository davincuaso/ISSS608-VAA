# In-Class Exercise 6

The [Quarto page](In-class_Ex06.qmd) contains the Hunan emerging hot spot analysis. Its source data are in `data/`.

To reproduce the rendered page from this directory, install [R](https://cran.r-project.org/) and [Quarto](https://quarto.org/), then run:

```sh
Rscript setup.R
quarto render In-class_Ex06.qmd
```

The setup script installs the R packages used by the analysis through `pacman::p_load()`. The code chunks run from data import through the final map without objects from an existing R session. The workflow follows [Chapter 11](https://r4gdsa.netlify.app/chap11), with row-standardised queen-contiguity weights that include a positive self-weight, 999 annual Gi* permutations, 99 EHSA simulations, and an explicit Benjamini-Hochberg check on the annual Gi* trend tests. The [source files](https://github.com/tskam/ISSS626-AY2026-27Aug/tree/master/In-class_Ex/In-class_Ex05/data) are provided by the course.
