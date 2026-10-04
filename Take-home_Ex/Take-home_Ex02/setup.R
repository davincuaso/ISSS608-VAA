# Install into the user's normal R library. Run once before rendering.
if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman", repos = "https://cloud.r-project.org")
}

pacman::p_load(sf, dplyr, tidyr, ggplot2, spdep, Kendall, knitr, scales)
