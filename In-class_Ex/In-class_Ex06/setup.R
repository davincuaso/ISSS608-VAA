packages <- c("sf", "sfdep", "dplyr", "tidyr", "ggplot2", "plotly", "Kendall", "stringr", "knitr", "zoo")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly=TRUE)]
if(length(missing)) install.packages(missing, repos="https://cloud.r-project.org")
