# Actual-data checks, to be run from the exercise folder after rendering.
if (!requireNamespace("pacman", quietly = TRUE)) {
  stop("Render the exercise first to install the declared packages.")
}
pacman::p_load(sf, sfdep, GWmodel, tidyverse)
source("scripts/analysis_helpers.R")
raw <- read_csv("data/aspatial/Condo_resale_2015.csv", show_col_types = FALSE)
audit <- read_csv("results/input-audit.csv", show_col_types = FALSE)
checksums <- read_csv("results/input-checksums.csv", show_col_types = FALSE)
metrics <- read_csv("results/model-comparison.csv", show_col_types = FALSE)
bandwidth <- read_csv("results/bandwidths.csv", show_col_types = FALSE)
adaptive <- read_csv("results/adaptive-gwr-output.csv", show_col_types = FALSE)
fixed <- read_csv("results/fixed-gwr-output.csv", show_col_types = FALSE)
moran <- read_csv("results/residual-moran.csv", show_col_types = FALSE)
stopifnot(
  nrow(raw) == 1436, nrow(adaptive) == nrow(raw), nrow(fixed) == nrow(raw),
  identical(adaptive$transaction_id, as.numeric(seq_len(nrow(raw)))),
  identical(fixed$transaction_id, adaptive$transaction_id),
  identical(checksums$MD5, unname(tools::md5sum(checksums$File))),
  max(abs(adaptive$y - raw$SELLING_PRICE)) < 1e-6,
  max(abs(fixed$y - raw$SELLING_PRICE)) < 1e-6,
  max(abs(adaptive$y - adaptive$yhat - adaptive$residual)) < 1e-6,
  max(abs(fixed$y - fixed$yhat - fixed$residual)) < 1e-6,
  abs(bandwidth$Bandwidth[1] - 971.3405) < 0.02,
  bandwidth$Bandwidth[2] == 30,
  max(abs(metrics$AICc - c(42967.14, 42263.61, 41982.22))) < 0.02,
  abs(metrics$Training_RMSE[2] - sqrt(mean(fixed$residual^2))) < 1e-6,
  abs(metrics$Training_RMSE[3] - sqrt(mean(adaptive$residual^2))) < 1e-6,
  abs(metrics$LOO_RMSE[2] - sqrt(mean(fixed$CV_Score^2))) < 1e-6,
  abs(metrics$LOO_RMSE[3] - sqrt(mean(adaptive$CV_Score^2))) < 1e-6,
  all(moran$Simulations == 499), all(moran$Permutation_p >= 0.004),
  all(abs(moran$Permutation_p - c(0.004, 0.008, 0.024)) < 1e-12),
  sum(adaptive$local_CN > 30) == 1432,
  max(abs(adaptive$AREA_SQM / adaptive$AREA_SQM_SE - adaptive$AREA_SQM_TV)) < 1e-8
)

# Reproduce selected local fits with base R's weighted QR solver, independently
# of the normal-equation implementation used for the returned GWR coefficients.
formula <- SELLING_PRICE ~ AREA_SQM + AGE + PROX_CBD + PROX_CHILDCARE +
  PROX_ELDERLYCARE + PROX_URA_GROWTH_AREA + PROX_MRT + PROX_PARK +
  PROX_PRIMARY_SCH + PROX_SHOPPING_MALL + PROX_BUS_STOP + NO_Of_UNITS +
  FAMILY_FRIENDLY + FREEHOLD
X <- model.matrix(formula, raw)
y <- raw$SELLING_PRICE
points <- st_as_sf(raw, coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
  st_transform(3414)
coordinates <- st_coordinates(points)
ids <- c(1L, 149L, 718L, 1436L)
output_names <- colnames(X)
output_names[output_names == "(Intercept)"] <- "Intercept"
for (id in ids) {
  distances <- as.numeric(st_distance(points[id, ], points))
  weights <- gw.weight(distances, bandwidth$Bandwidth[2], kernel = "gaussian", adaptive = TRUE)
  independent <- lm.wfit(X, y, w = weights)$coefficients
  reported <- as.numeric(adaptive[id, output_names])
  stopifnot(all(is.finite(independent)),
            max(abs(independent - reported) / pmax(1, abs(reported))) < 1e-4)
}
cat("PASS: original inputs, record alignment, chapter calibration, fit/CV identities,\n")
cat("finite permutation p-values, local diagnostics and four independent weighted-QR fits.\n")
