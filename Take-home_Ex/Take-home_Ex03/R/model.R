# Calibrate an origin-constrained station-choice model from a genuine LTA OD file.
# EX03_OD_FILE=/absolute/path/origin_destination_train_YYYYMM.csv Rscript R/model.R
# The output directory can be changed for testing with EX03_OUTPUT_DIR.
suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(sf)
})

od_path <- Sys.getenv("EX03_OD_FILE", "")
if (!nzchar(od_path) || !file.exists(od_path)) {
  stop("Set EX03_OD_FILE to an LTA OD Train CSV or ZIP. No ridership is fabricated.")
}
out_dir <- Sys.getenv("EX03_OUTPUT_DIR", "results/model")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (grepl("\\.zip$", od_path, ignore.case = TRUE)) {
  files <- unzip(od_path, list = TRUE)$Name
  csv_name <- files[grepl("\\.csv$", files, ignore.case = TRUE)][1]
  stopifnot(!is.na(csv_name))
  extracted <- unzip(od_path, files = csv_name, exdir = tempdir())
  od_path <- extracted[1]
}
raw <- data.table::fread(od_path, colClasses = list(character = c(
  "YEAR_MONTH", "DAY_TYPE", "PT_TYPE", "ORIGIN_PT_CODE", "DESTINATION_PT_CODE")))
required <- c("YEAR_MONTH", "DAY_TYPE", "TIME_PER_HOUR", "PT_TYPE",
              "ORIGIN_PT_CODE", "DESTINATION_PT_CODE", "TOTAL_TRIPS")
stopifnot(all(required %in% names(raw)),
          data.table::uniqueN(raw$YEAR_MONTH) == 1L)
month <- unique(raw$YEAR_MONTH)
od <- raw[DAY_TYPE == "WEEKDAY" & PT_TYPE == "TRAIN"]
stopifnot(nrow(od) > 0L, all(od$TOTAL_TRIPS >= 0, na.rm = TRUE),
          all(od$TIME_PER_HOUR %in% 0:23))

code_table <- read.csv("data/source/operational_stations.csv") |>
  select(station_code, station_name)
code_to_name <- setNames(code_table$station_name, code_table$station_code)
resolve_station <- function(x) {
  vapply(strsplit(x, "[-/]"), function(tokens) {
    matched <- unique(unname(code_to_name[tokens]))
    matched <- matched[!is.na(matched)]
    if (length(matched) == 1L) matched else NA_character_
  }, character(1))
}
all_codes <- unique(c(od$ORIGIN_PT_CODE, od$DESTINATION_PT_CODE))
code_lookup <- setNames(resolve_station(all_codes), all_codes)
od[, origin := unname(code_lookup[ORIGIN_PT_CODE])]
od[, destination := unname(code_lookup[DESTINATION_PT_CODE])]
unmatched <- od[is.na(origin) | is.na(destination),
                .(rows = .N, trips = sum(TOTAL_TRIPS)),
                by = .(ORIGIN_PT_CODE, DESTINATION_PT_CODE)]
data.table::fwrite(unmatched, file.path(out_dir, "unmatched-codes.csv"))
unmatched_share <- sum(unmatched$trips) / sum(od$TOTAL_TRIPS)
if (unmatched_share > .05) {
  stop(sprintf("%.1f%% of trips have unmatched station codes; inspect unmatched-codes.csv.",
               100 * unmatched_share))
}
od <- od[!is.na(origin) & !is.na(destination) & origin != destination,
         .(trips = sum(TOTAL_TRIPS)), by = .(origin, destination)]
features <- read.csv("results/station-features.csv")
existing <- features |> filter(status == "Existing")
stopifnot(all(unique(c(od$origin, od$destination)) %in% existing$station))

# Build a complete choice set, including zero observed flows. The same station
# cannot be both origin and destination in this station-choice model.
make_pairs <- function(origin_names, destinations, features, proposed = FALSE) {
  pairs <- expand.grid(origin = origin_names, destination = destinations,
                       stringsAsFactors = FALSE) |>
    filter(origin != destination)
  coords <- st_as_sf(features, coords = c("lon", "lat"), crs = 4326) |>
    st_transform(3414)
  dist <- st_distance(coords)
  dimnames(dist) <- list(features$station, features$station)
  pairs$distance_km <- as.numeric(dist[cbind(pairs$origin, pairs$destination)]) / 1000
  j <- match(pairs$destination, features$station)
  pairs$hdb_blocks_800m <- features$hdb_blocks_800m[j]
  pairs$activity_hectares_800m <- features$activity_hectares_800m[j]
  pairs$line_count <- if (proposed) features$scenario_lines[j] else features$n_lines[j]
  pairs
}

origin_market <- od[, .(market_potential = sum(trips)), by = origin]
observed_dest <- od[, .(observed_ridership = sum(trips)), by = destination]
dest_table <- features |>
  transmute(destination = station, status, hdb_blocks_800m,
            activity_hectares_800m, line_count_current = n_lines,
            line_count_scenario = scenario_lines) |>
  left_join(as.data.frame(observed_dest), by = "destination") |>
  mutate(observed_ridership = coalesce(observed_ridership, 0))
data.table::fwrite(dest_table |>
                     filter(status == "Existing", observed_ridership == 0),
                   file.path(out_dir, "zero-observed-stations.csv"))
data.table::fwrite(origin_market, file.path(out_dir, "origins.csv"))
data.table::fwrite(dest_table, file.path(out_dir, "destinations.csv"))

pairs <- make_pairs(origin_market$origin, existing$station, existing) |>
  left_join(as.data.frame(od), by = c("origin", "destination")) |>
  mutate(trips = coalesce(trips, 0))
groups <- split(seq_len(nrow(pairs)), pairs$origin)
X <- cbind(log1p(pairs$hdb_blocks_800m),
           log1p(pairs$activity_hectares_800m),
           log(pairs$line_count),
           -log(pairs$distance_km + .25))
colnames(X) <- c("HDB blocks", "Activity hectares", "Line count", "Distance decay")
y <- pairs$trips

# The objective is the multinomial log likelihood conditional on each origin's
# observed monthly weekday departures. Bounds prevent a counterintuitive
# negative attraction or distance-decay exponent in the scenario projection.
loss <- function(b, X, y, groups) {
  utility <- as.vector(X %*% b)
  total <- 0
  for (idx in groups) {
    u <- utility[idx]
    log_denom <- max(u) + log(sum(exp(u - max(u))))
    total <- total + sum(y[idx] * (log_denom - u))
  }
  total
}
fit <- function(X, y, groups, distance_only = FALSE) {
  if (distance_only) {
    f <- function(v) loss(c(0, 0, 0, v), X, y, groups)
    opt <- optim(1, f, method = "L-BFGS-B", lower = 0, upper = 4)
    stopifnot(opt$convergence == 0L)
    return(c(0, 0, 0, opt$par))
  }
  opt <- optim(c(.4, .4, .3, 1), loss, X = X, y = y, groups = groups,
               method = "L-BFGS-B", lower = rep(0, 4), upper = c(3, 3, 3, 4),
               control = list(maxit = 300))
  stopifnot(opt$convergence == 0L)
  opt$par
}
probabilities <- function(X, b, groups) {
  u <- as.vector(X %*% b)
  p <- numeric(length(u))
  for (idx in groups) {
    z <- exp(u[idx] - max(u[idx]))
    p[idx] <- z / sum(z)
  }
  p
}

set.seed(626)
origin_names <- sort(unique(pairs$origin))
holdout <- sample(origin_names, size = max(1L, floor(.2 * length(origin_names))))
train_rows <- which(!pairs$origin %in% holdout)
test_rows <- which(pairs$origin %in% holdout)
train_groups <- split(seq_along(train_rows), pairs$origin[train_rows])
test_groups <- split(seq_along(test_rows), pairs$origin[test_rows])
b_train <- fit(X[train_rows, , drop = FALSE], y[train_rows], train_groups)
b_base <- fit(X[train_rows, , drop = FALSE], y[train_rows], train_groups,
              distance_only = TRUE)
test_loss <- loss(b_train, X[test_rows, , drop = FALSE], y[test_rows], test_groups)
base_loss <- loss(b_base, X[test_rows, , drop = FALSE], y[test_rows], test_groups)
model <- fit(X, y, groups)
pairs$attraction <- exp(X[, 1:3, drop = FALSE] %*% model[1:3])
pairs$probability <- probabilities(X, model, groups)
market <- setNames(origin_market$market_potential, origin_market$origin)
pairs$estimated_trips <- market[pairs$origin] * pairs$probability

current_pred <- pairs |>
  group_by(destination) |>
  summarise(estimated_existing = sum(estimated_trips), .groups = "drop")

# The counterfactual keeps today's observed origin totals fixed. New stations
# enter as destination alternatives; it estimates captured tap-outs from
# existing origins, not complete future boardings or induced rail travel.
scenario <- make_pairs(origin_market$origin, features$station, features,
                       proposed = TRUE)
XS <- cbind(log1p(scenario$hdb_blocks_800m),
            log1p(scenario$activity_hectares_800m),
            log(scenario$line_count),
            -log(scenario$distance_km + .25))
scenario_groups <- split(seq_len(nrow(scenario)), scenario$origin)
scenario$attraction <- exp(XS[, 1:3, drop = FALSE] %*% model[1:3])
scenario$probability <- probabilities(XS, model, scenario_groups)
scenario$estimated_trips <- market[scenario$origin] * scenario$probability
scenario_pred <- scenario |>
  group_by(destination) |>
  summarise(estimated_scenario = sum(estimated_trips), .groups = "drop")
comparison <- dest_table |>
  left_join(current_pred, by = "destination") |>
  left_join(scenario_pred, by = "destination") |>
  mutate(change = if_else(status == "Existing",
                          estimated_scenario - estimated_existing, NA_real_),
         change_pct = 100 * change / estimated_existing)

checks <- data.frame(
  month = month,
  raw_weekday_rows = nrow(raw[DAY_TYPE == "WEEKDAY" & PT_TYPE == "TRAIN"]),
  matched_trip_share = 1 - unmatched_share,
  observed_trips = sum(y),
  existing_predicted_trips = sum(pairs$estimated_trips),
  scenario_predicted_trips = sum(scenario$estimated_trips),
  heldout_origins = length(holdout),
  heldout_logloss_per_trip = test_loss / sum(y[test_rows]),
  distance_only_logloss_per_trip = base_loss / sum(y[test_rows]),
  station_mae = mean(abs(comparison$estimated_existing[comparison$status == "Existing"] -
                           comparison$observed_ridership[comparison$status == "Existing"]))
)
stopifnot(abs(checks$existing_predicted_trips - checks$observed_trips) < 1e-4,
          abs(checks$scenario_predicted_trips - checks$observed_trips) < 1e-4,
          max(abs(tapply(pairs$probability, pairs$origin, sum) - 1)) < 1e-9,
          max(abs(tapply(scenario$probability, scenario$origin, sum) - 1)) < 1e-9)

data.table::fwrite(pairs, file.path(out_dir, "interaction-existing.csv"))
data.table::fwrite(scenario, file.path(out_dir, "interaction-scenario.csv"))
data.table::fwrite(comparison, file.path(out_dir, "station-predictions.csv"))
data.table::fwrite(data.frame(term = colnames(X), coefficient = model),
                   file.path(out_dir, "coefficients.csv"))
data.table::fwrite(checks, file.path(out_dir, "checks.csv"))
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("Modelled", month, "weekday trips; results in", out_dir, "\n")
