# Calibrate an origin-constrained station-choice model from a genuine LTA OD file.
# EX03_OD_FILE=data/private/origin_destination_train_YYYYMM.zip Rscript R/model.R
# EX03_STATION_FILE can point to the matching station-volume ZIP for an audit.
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
stopifnot(nrow(od) > 0L, !anyNA(od$TOTAL_TRIPS), all(od$TOTAL_TRIPS >= 0),
          all(od$TIME_PER_HOUR %in% 0:23))
raw_weekday_trips <- sum(od$TOTAL_TRIPS)

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
same_station_trips <- od[!is.na(origin) & !is.na(destination) &
                           origin == destination, sum(TOTAL_TRIPS)]
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
# The independently published station-volume file is a useful reconciliation
# check. A difference is reported, never silently forced to match the OD file.
station_path <- Sys.getenv("EX03_STATION_FILE", "")
station_total <- NA_real_
od_to_station_ratio <- NA_real_
if (nzchar(station_path)) {
  if (!file.exists(station_path)) stop("EX03_STATION_FILE does not exist.")
  if (grepl("\\.zip$", station_path, ignore.case = TRUE)) {
    station_csv <- unzip(station_path, list = TRUE)$Name
    station_csv <- station_csv[grepl("\\.csv$", station_csv, ignore.case = TRUE)][1]
    stopifnot(!is.na(station_csv))
    station_path <- unzip(station_path, files = station_csv, exdir = tempdir())[1]
  }
  station_raw <- data.table::fread(station_path,
                                   colClasses = list(character = c("YEAR_MONTH", "DAY_TYPE",
                                                                    "PT_TYPE", "PT_CODE")))
  stopifnot(all(c("YEAR_MONTH", "DAY_TYPE", "PT_TYPE", "PT_CODE",
                  "TOTAL_TAP_OUT_VOLUME") %in% names(station_raw)),
            data.table::uniqueN(station_raw$YEAR_MONTH) == 1L,
            unique(station_raw$YEAR_MONTH) == month,
            !anyNA(station_raw$TOTAL_TAP_OUT_VOLUME),
            all(station_raw$TOTAL_TAP_OUT_VOLUME >= 0))
  station_raw <- station_raw[DAY_TYPE == "WEEKDAY" & PT_TYPE == "TRAIN"]
  station_raw[, destination := resolve_station(PT_CODE)]
  if (anyNA(station_raw$destination)) stop("Unmatched station code in station-volume file.")
  station_obs <- station_raw[, .(station_tapouts = sum(TOTAL_TAP_OUT_VOLUME)),
                             by = destination]
  station_check <- merge(as.data.frame(observed_dest), as.data.frame(station_obs),
                         by = "destination", all = TRUE)
  if (anyNA(station_check)) stop("OD and station-volume files have different stations.")
  station_check$gap <- station_check$station_tapouts - station_check$observed_ridership
  data.table::fwrite(station_check,
                     file.path(out_dir, "station-volume-reconciliation.csv"))
  station_total <- sum(station_check$station_tapouts)
  od_to_station_ratio <- sum(station_check$observed_ridership) / station_total
}
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
# The newly gained line at seven existing interchanges is uncertain as a
# tap-out attraction effect. Keep a second scenario with their current line
# counts so its influence is visible rather than hidden in the main estimate.
XS_no_uplift <- XS
XS_no_uplift[, 3] <- log(features$n_lines[match(scenario$destination,
                                               features$station)])
scenario$no_uplift_probability <- probabilities(XS_no_uplift, model,
                                                scenario_groups)
scenario$no_uplift_trips <- market[scenario$origin] *
  scenario$no_uplift_probability
# A distance-only counterfactual reveals how much the attraction variables
# influence the projected redistribution; it is a sensitivity, not a forecast.
base_model <- fit(X, y, groups, distance_only = TRUE)
scenario$distance_only_probability <- probabilities(XS, base_model,
                                                     scenario_groups)
scenario$distance_only_trips <- market[scenario$origin] *
  scenario$distance_only_probability
scenario_pred <- scenario |>
  group_by(destination) |>
  summarise(estimated_scenario = sum(estimated_trips),
            no_uplift_scenario = sum(no_uplift_trips),
            distance_only_scenario = sum(distance_only_trips), .groups = "drop")
comparison <- dest_table |>
  left_join(current_pred, by = "destination") |>
  left_join(scenario_pred, by = "destination") |>
  mutate(change = if_else(status == "Existing",
                          estimated_scenario - estimated_existing, NA_real_),
         change_pct = 100 * change / estimated_existing)

checks <- data.frame(
  month = month,
  raw_weekday_rows = nrow(raw[DAY_TYPE == "WEEKDAY" & PT_TYPE == "TRAIN"]),
  raw_weekday_trips = raw_weekday_trips,
  matched_trip_share = 1 - unmatched_share,
  excluded_same_station_trips = same_station_trips,
  observed_trips = sum(y),
  station_tapouts = station_total,
  od_to_station_ratio = od_to_station_ratio,
  existing_predicted_trips = sum(pairs$estimated_trips),
  scenario_predicted_trips = sum(scenario$estimated_trips),
  new_station_trips_full = sum(comparison$estimated_scenario[comparison$status == "Planned new"]),
  new_station_trips_no_uplift = sum(comparison$no_uplift_scenario[comparison$status == "Planned new"]),
  new_station_trips_distance_only = sum(comparison$distance_only_scenario[comparison$status == "Planned new"]),
  heldout_origins = length(holdout),
  heldout_logloss_per_trip = test_loss / sum(y[test_rows]),
  distance_only_logloss_per_trip = base_loss / sum(y[test_rows]),
  station_mae = mean(abs(comparison$estimated_existing[comparison$status == "Existing"] -
                           comparison$observed_ridership[comparison$status == "Existing"]))
)
stopifnot(abs(checks$existing_predicted_trips - checks$observed_trips) < 1e-4,
          abs(checks$scenario_predicted_trips - checks$observed_trips) < 1e-4,
          abs(sum(scenario$no_uplift_trips) - checks$observed_trips) < 1e-4,
          abs(sum(scenario$distance_only_trips) - checks$observed_trips) < 1e-4,
          max(abs(tapply(pairs$probability, pairs$origin, sum) - 1)) < 1e-9,
          max(abs(tapply(scenario$probability, scenario$origin, sum) - 1)) < 1e-9)

data.table::fwrite(pairs, file.path(out_dir, "interaction-existing.csv"))
data.table::fwrite(scenario, file.path(out_dir, "interaction-scenario.csv"))
data.table::fwrite(comparison, file.path(out_dir, "station-predictions.csv"))
data.table::fwrite(data.frame(term = colnames(X), coefficient = model),
                   file.path(out_dir, "coefficients.csv"))
data.table::fwrite(checks, file.path(out_dir, "checks.csv"))
writeLines(trimws(capture.output(sessionInfo()), which = "right"),
           file.path(out_dir, "session-info.txt"))
cat("Modelled", month, "weekday trips; results in", out_dir, "\n")
