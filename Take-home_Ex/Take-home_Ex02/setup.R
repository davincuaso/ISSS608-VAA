# Install into the user's normal R library. Run once before rendering.
packages <- c('sf','dplyr','tidyr','ggplot2','spdep','Kendall','knitr','scales')
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing,repos='https://cloud.r-project.org')
