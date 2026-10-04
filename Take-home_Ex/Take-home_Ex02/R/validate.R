# Focused checks for the classification rules and saved statistical results.
source("R/classify.R")
z <- rep(0, 57)
p <- rep(1, 57)
stopifnot(class_eh(z, p, 0, 1) == "No pattern detected")
z[57] <- 3
p[57] <- 0.01
stopifnot(class_eh(z, p, 0, 1) == "New hot spot")
z[56] <- 3
p[56] <- 0.01
stopifnot(class_eh(z, p, 0, 1) == "Consecutive hot spot")
z[1] <- -3
p[1] <- 0.01
stopifnot(class_eh(z, p, 0, 1) == "Consecutive hot spot")
z[50] <- 3
p[50] <- 0.01
stopifnot(class_eh(z, p, 0, 1) == "Oscillating hot spot")
stopifnot(class_eh(rep(3, 57), rep(0.01, 57), 0.5, 0.001) == "Intensifying hot spot")
stopifnot(class_eh(rep(-3, 57), rep(0.01, 57), -0.5, 0.001) == "Intensifying cold spot")
z <- c(rep(3, 56), 0)
p <- c(rep(0.01, 56), 1)
stopifnot(class_eh(z, p, 0, 1) == "Historical hot spot")
for (metric in c("events", "fatalities")) {
    static <- read.csv(paste0("results/static-", metric, ".csv"))
    bins <- read.csv(paste0("results/space-time-", metric, ".csv"))
    eh <- read.csv(paste0("results/ehsa-", metric, ".csv"))
    stopifnot(nrow(static) == 330, nrow(bins) == 18810, nrow(eh) == 330)
    stopifnot(all(is.finite(bins$gi_z)), all(bins$p >= 0 & bins$p <= 1), all(bins$q >=
        bins$p - 1e-12))
    stopifnot(!anyDuplicated(bins[c("month", "TS_PCODE")]), !anyNA(eh))
    stopifnot(all(static$hotspot == "Not significant" | static$gi_p < 0.05))
}
message("Classification and saved-output checks passed.")
