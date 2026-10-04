if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman", repos = "https://cloud.r-project.org")
}

pacman::p_load(sf, sfdep, tmap, plotly, tidyverse, Kendall, knitr, zoo)
