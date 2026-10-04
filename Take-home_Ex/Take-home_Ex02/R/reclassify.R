# Reuse the already computed permutation results; no new random draws.
pacman::p_load(dplyr, Kendall)
source("R/classify.R")
for (metric in c("events", "fatalities")) {
    eh <- read.csv(paste0("results/ehsa-", metric, ".csv"))
    bins <- read.csv(paste0("results/space-time-", metric, ".csv"))
    for (i in seq_len(nrow(eh))) {
        x <- bins[bins$TS_PCODE == eh$TS_PCODE[i], ]
        eh$classification[i] <- class_eh(x$gi_z, x$p, eh$tau[i], eh$mk_p[i])
        eh$fdr_classification[i] <- class_eh(x$gi_z, x$q, eh$tau[i], eh$mk_p[i])
        pairs <- combn(seq_len(nrow(x)), 2)
        eh$sen_z_per_year[i] <- 12 * median((x$gi_z[pairs[2, ]] - x$gi_z[pairs[1, ]])/(pairs[2,
            ] - pairs[1, ]))
    }
    write.csv(eh, paste0("results/ehsa-", metric, ".csv"), row.names = FALSE)
}
