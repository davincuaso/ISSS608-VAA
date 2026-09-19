pacman::p_load(
  sf, tidyverse, knitr, spatstat.geom, spatstat.explore,
  spatstat.random, scales
)

analysis_root <- if (file.exists(file.path("scripts", "analysis.R"))) {
  "."
} else {
  file.path("Take-home_Ex", "Take-home_Ex01")
}

source(file.path(analysis_root, "scripts", "download_data.R"))

raw_dir <- file.path(analysis_root, "data", "raw")
processed_dir <- file.path(analysis_root, "data", "processed")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

accident_file <- file.path(raw_dir, "thai_road_accident_2019_2022.csv")
boundary_file <- file.path(raw_dir, "geoBoundaries-THA-ADM1.geojson")
cache_file <- file.path(processed_dir, "analysis_objects.rds")
script_file <- file.path(analysis_root, "scripts", "analysis.R")

cache_is_current <- file.exists(cache_file) &&
  file.mtime(cache_file) > max(file.mtime(c(accident_file, boundary_file, script_file))) &&
  Sys.getenv("ISSS626_REBUILD") != "1"

if (cache_is_current) {
  list2env(readRDS(cache_file), envir = environment())
} else {
  set.seed(6262022)

  accidents_raw <- read.csv(
    accident_file,
    check.names = FALSE,
    na.strings = c("", "NA"),
    encoding = "UTF-8"
  )

  boundaries_raw <- st_read(boundary_file, quiet = TRUE) |>
    st_make_valid()

  bmr_boundary_names <- c(
    "Bangkok",
    "Samut Prakan Province",
    "Nonthaburi Province",
    "Pathum Thani Province",
    "Nakhon Pathom Province",
    "Samut Sakhon Province"
  )

  bmr_provinces <- boundaries_raw |>
    filter(shapeName %in% bmr_boundary_names) |>
    mutate(province = sub(" Province$", "", shapeName))

  stopifnot(nrow(bmr_provinces) == 6, all(st_is_valid(bmr_provinces)))

  bmr_window_wgs84 <- st_union(bmr_provinces)
  incident_time <- as.POSIXct(
    accidents_raw$incident_datetime,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "Asia/Bangkok"
  )

  valid_time <- !is.na(incident_time)
  in_2022 <- valid_time & format(incident_time, "%Y") == "2022"
  complete_coordinates <- complete.cases(
    accidents_raw[, c("latitude", "longitude")]
  )
  plausible_coordinates <- complete_coordinates &
    accidents_raw$latitude >= 5 & accidents_raw$latitude <= 22 &
    accidents_raw$longitude >= 97 & accidents_raw$longitude <= 106

  accidents_2022 <- accidents_raw[in_2022 & plausible_coordinates, ]
  accidents_2022$incident_time <- incident_time[in_2022 & plausible_coordinates]
  accidents_2022$report_time <- as.POSIXct(
    accidents_2022$report_datetime,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "Asia/Bangkok"
  )

  points_2022 <- st_as_sf(
    accidents_2022,
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

  inside_bmr <- lengths(st_within(points_2022, bmr_window_wgs84)) > 0
  events_pre_dedup <- points_2022[inside_bmr, ]

  event_key <- paste(
    events_pre_dedup$incident_datetime,
    round(events_pre_dedup$longitude, 6),
    round(events_pre_dedup$latitude, 6),
    events_pre_dedup$agency,
    events_pre_dedup$route,
    events_pre_dedup$accident_type,
    events_pre_dedup$number_of_fatalities,
    events_pre_dedup$number_of_injuries,
    sep = "|"
  )

  duplicate_event <- duplicated(event_key)
  events_wgs84 <- events_pre_dedup[!duplicate_event, ]

  province_index <- st_within(events_wgs84, bmr_provinces)
  events_wgs84$spatial_province <- vapply(
    province_index,
    function(index) {
      if (length(index) == 0) NA_character_ else bmr_provinces$province[index[1]]
    },
    character(1)
  )

  month_levels <- month.abb
  weekday_levels <- c(
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday"
  )

  events_wgs84 <- events_wgs84 |>
    mutate(
      month = factor(month.abb[as.integer(format(incident_time, "%m"))],
        levels = month_levels
      ),
      weekday = factor(weekdays(incident_time), levels = weekday_levels),
      hour = as.integer(format(incident_time, "%H")),
      period = cut(
        hour,
        breaks = c(-1, 5, 11, 17, 23),
        labels = c("00:00-05:59", "06:00-11:59", "12:00-17:59", "18:00-23:59")
      ),
      severity = case_when(
        number_of_fatalities > 0 ~ "Fatal",
        number_of_injuries > 0 ~ "Injury",
        TRUE ~ "No recorded casualty"
      ),
      report_delay_hours = as.numeric(difftime(report_time, incident_time, units = "hours"))
    )

  events_wgs84$severity <- factor(
    events_wgs84$severity,
    levels = c("Fatal", "Injury", "No recorded casualty")
  )

  events_utm <- st_transform(events_wgs84, 32647)
  bmr_provinces_utm <- st_transform(bmr_provinces, 32647)
  bmr_window_utm <- st_union(bmr_provinces_utm)

  analysis_window <- as.owin(bmr_window_utm)
  event_xy <- st_coordinates(events_utm)
  accidents_ppp <- ppp(
    event_xy[, 1], event_xy[, 2],
    window = analysis_window,
    checkdup = FALSE
  )

  audit_table <- data.frame(
    step = c(
      "Raw records, 2019-2022",
      "Records with a valid 2022 incident time",
      "2022 records with complete coordinates",
      "2022 records with plausible Thailand coordinates",
      "Points inside the six-province BMR boundary",
      "Distinct accident events used in analysis"
    ),
    retained = c(
      nrow(accidents_raw),
      sum(in_2022),
      sum(in_2022 & complete_coordinates),
      sum(in_2022 & plausible_coordinates),
      nrow(events_pre_dedup),
      nrow(events_wgs84)
    )
  ) |>
    mutate(removed_at_step = c(NA_integer_, -diff(retained)))

  quality_metrics <- data.frame(
    check = c(
      "Unparseable incident times in the full file",
      "Missing coordinate pairs among 2022 records",
      "Implausible coordinate pairs among complete 2022 records",
      "Exact duplicate accident codes in the full file",
      "Probable duplicate event rows inside the BMR",
      "Spatially included records with a non-BMR province label",
      "Reported province differs from spatial province",
      "Additional events at an already-used exact coordinate",
      "Events reported more than 30 days after occurrence",
      "Events with zero recorded vehicles"
    ),
    count = c(
      sum(!valid_time),
      sum(in_2022 & !complete_coordinates),
      sum(in_2022 & complete_coordinates & !plausible_coordinates),
      sum(duplicated(accidents_raw$acc_code)),
      sum(duplicate_event),
      sum(!events_wgs84$province_en %in% c(
        "Bangkok", "Samut Prakan", "Nonthaburi", "Pathum Thani",
        "Nakhon Pathom", "Samut Sakhon"
      )),
      sum(events_wgs84$province_en != events_wgs84$spatial_province),
      sum(duplicated(st_coordinates(events_wgs84))),
      sum(events_wgs84$report_delay_hours > 30 * 24, na.rm = TRUE),
      sum(events_wgs84$number_of_vehicles_involved == 0, na.rm = TRUE)
    )
  )

  bmr_area_km2 <- as.numeric(st_area(bmr_window_utm)) / 1e6

  province_summary <- events_wgs84 |>
    st_drop_geometry() |>
    count(spatial_province, name = "events") |>
    right_join(
      bmr_provinces_utm |>
        st_drop_geometry() |>
        transmute(
          spatial_province = province,
          area_km2 = as.numeric(st_area(bmr_provinces_utm)) / 1e6
        ),
      by = "spatial_province"
    ) |>
    mutate(
      events = coalesce(events, 0L),
      events_per_100_km2 = events / area_km2 * 100
    ) |>
    arrange(desc(events_per_100_km2))

  monthly_summary <- events_wgs84 |>
    st_drop_geometry() |>
    count(month, .drop = FALSE, name = "events") |>
    mutate(
      month_number = seq_len(n()),
      days = as.integer(diff(as.Date(c(
        sprintf("2022-%02d-01", 1:12),
        "2023-01-01"
      )))),
      events_per_day = events / days
    )

  hourly_summary <- events_wgs84 |>
    st_drop_geometry() |>
    count(hour, name = "events") |>
    tidyr::complete(hour = 0:23, fill = list(events = 0L))

  severity_summary <- events_wgs84 |>
    st_drop_geometry() |>
    count(severity, .drop = FALSE, name = "events") |>
    mutate(percent = events / sum(events) * 100)

  coordinate_bandwidths <- c(
    likelihood_cross_validation = unname(bw.ppl(accidents_ppp)),
    operational_primary = 3000,
    sensitivity_low = 2000,
    sensitivity_high = 6000
  )

  kde_2km <- density.ppp(
    accidents_ppp, sigma = coordinate_bandwidths["sensitivity_low"],
    edge = TRUE, eps = 500
  )
  kde_3km <- density.ppp(
    accidents_ppp, sigma = coordinate_bandwidths["operational_primary"],
    edge = TRUE, eps = 500
  )
  kde_6km <- density.ppp(
    accidents_ppp, sigma = coordinate_bandwidths["sensitivity_high"],
    edge = TRUE, eps = 500
  )

  im_to_data_frame <- function(image) {
    result <- as.data.frame(image)
    names(result) <- c("x", "y", "intensity")
    result$events_per_km2 <- result$intensity * 1e6
    result
  }

  kde_2km_df <- im_to_data_frame(kde_2km)
  kde_3km_df <- im_to_data_frame(kde_3km)
  kde_6km_df <- im_to_data_frame(kde_6km)

  point_intensity_2km <- interp.im(kde_2km, accidents_ppp$x, accidents_ppp$y) * 1e6
  point_intensity_3km <- interp.im(kde_3km, accidents_ppp$x, accidents_ppp$y) * 1e6
  point_intensity_6km <- interp.im(kde_6km, accidents_ppp$x, accidents_ppp$y) * 1e6

  intensity_rank_correlations <- data.frame(
    comparison = c("2 km versus 3 km", "3 km versus 6 km"),
    spearman_rho = c(
      cor(
        point_intensity_2km, point_intensity_3km,
        method = "spearman", use = "complete.obs"
      ),
      cor(
        point_intensity_3km, point_intensity_6km,
        method = "spearman", use = "complete.obs"
      )
    )
  )

  second_order_r <- seq(0, 15000, by = 250)
  null_intensity <- density.ppp(
    accidents_ppp,
    sigma = 6000,
    edge = TRUE,
    eps = 500,
    positive = TRUE
  )

  second_order_nsim <- 99
  observed_csr_l <- Lest(
    accidents_ppp,
    r = second_order_r,
    correction = "translation"
  )$trans
  observed_inhomogeneous_l <- Linhom(
    accidents_ppp,
    lambda = null_intensity,
    r = second_order_r,
    correction = "translation",
    update = FALSE,
    normpower = 2
  )$trans

  set.seed(6262022)
  csr_simulations <- replicate(second_order_nsim, {
    simulated_pattern <- runifpoint(
      npoints(accidents_ppp),
      win = analysis_window
    )
    Lest(
      simulated_pattern,
      r = second_order_r,
      correction = "translation"
    )$trans
  })

  set.seed(6262022)
  inhomogeneous_simulations <- replicate(second_order_nsim, {
    simulated_pattern <- rpoint(
      npoints(accidents_ppp),
      f = null_intensity,
      win = analysis_window,
      forcewin = TRUE
    )
    Linhom(
      simulated_pattern,
      lambda = null_intensity,
      r = second_order_r,
      correction = "translation",
      update = FALSE,
      normpower = 2
    )$trans
  })

  build_envelope_data <- function(observed, simulations) {
    simulation_mean <- rowMeans(simulations)
    simulation_sd <- apply(simulations, 1, sd)
    valid_sd <- simulation_sd > 0
    observed_max_deviation <- max(
      abs((observed[valid_sd] - simulation_mean[valid_sd]) /
        simulation_sd[valid_sd])
    )
    simulation_max_deviation <- apply(
      simulations[valid_sd, , drop = FALSE],
      2,
      function(curve) {
        max(abs((curve - simulation_mean[valid_sd]) / simulation_sd[valid_sd]))
      }
    )

    list(
      data = data.frame(
        r = second_order_r,
        obs = observed,
        lo = apply(simulations, 1, quantile, probs = 0.025),
        hi = apply(simulations, 1, quantile, probs = 0.975),
        observed_minus_r = observed - second_order_r,
        low_minus_r = apply(simulations, 1, quantile, probs = 0.025) - second_order_r,
        high_minus_r = apply(simulations, 1, quantile, probs = 0.975) - second_order_r
      ),
      global_p_value =
        (1 + sum(simulation_max_deviation >= observed_max_deviation)) /
        (second_order_nsim + 1)
    )
  }

  csr_envelope_result <- build_envelope_data(observed_csr_l, csr_simulations)
  inhomogeneous_envelope_result <- build_envelope_data(
    observed_inhomogeneous_l,
    inhomogeneous_simulations
  )
  csr_envelope_df <- csr_envelope_result$data
  inhomogeneous_envelope_df <- inhomogeneous_envelope_result$data
  second_order_tests <- data.frame(
    null_model = c(
      "Complete spatial randomness, conditional on event count",
      "Inhomogeneous Poisson, conditional on event count"
    ),
    simulations = second_order_nsim,
    global_deviation_p = c(
      csr_envelope_result$global_p_value,
      inhomogeneous_envelope_result$global_p_value
    )
  )

  outside_envelope_ranges <- function(result_df) {
    flagged <- result_df |>
      mutate(
        relation = case_when(
          obs > hi ~ "above",
          obs < lo ~ "below",
          TRUE ~ "inside"
        )
      ) |>
      filter(relation != "inside", r > 0)

    if (nrow(flagged) == 0) {
      return(data.frame(relation = "inside", min_m = NA, max_m = NA))
    }

    flagged |>
      group_by(relation) |>
      summarise(min_m = min(r), max_m = max(r), .groups = "drop")
  }

  csr_ranges <- outside_envelope_ranges(csr_envelope_df)
  inhomogeneous_ranges <- outside_envelope_ranges(inhomogeneous_envelope_df)

  # Sensitivity check: repeated coordinates can inflate short-distance pairs.
  # Retain one event at each exact coordinate and repeat the inhomogeneous test.
  unique_coordinate_index <- !duplicated(data.frame(
    x = event_xy[, 1],
    y = event_xy[, 2]
  ))
  unique_coordinate_ppp <- ppp(
    event_xy[unique_coordinate_index, 1],
    event_xy[unique_coordinate_index, 2],
    window = analysis_window,
    checkdup = FALSE
  )
  unique_coordinate_intensity <- density.ppp(
    unique_coordinate_ppp,
    sigma = 6000,
    edge = TRUE,
    eps = 500,
    positive = TRUE
  )
  unique_coordinate_observed_l <- Linhom(
    unique_coordinate_ppp,
    lambda = unique_coordinate_intensity,
    r = second_order_r,
    correction = "translation",
    update = FALSE,
    normpower = 2
  )$trans

  set.seed(6262023)
  unique_coordinate_simulations <- replicate(second_order_nsim, {
    simulated_pattern <- rpoint(
      npoints(unique_coordinate_ppp),
      f = unique_coordinate_intensity,
      win = analysis_window,
      forcewin = TRUE
    )
    Linhom(
      simulated_pattern,
      lambda = unique_coordinate_intensity,
      r = second_order_r,
      correction = "translation",
      update = FALSE,
      normpower = 2
    )$trans
  })

  unique_coordinate_envelope_result <- build_envelope_data(
    unique_coordinate_observed_l,
    unique_coordinate_simulations
  )
  unique_coordinate_envelope_df <- unique_coordinate_envelope_result$data
  unique_coordinate_ranges <- outside_envelope_ranges(
    unique_coordinate_envelope_df
  )

  above_range_value <- function(range_data, field) {
    value <- range_data[range_data$relation == "above", field]
    if (length(value) == 0) NA_real_ else value[[1]]
  }

  coordinate_reuse_sensitivity <- data.frame(
    sample = c(
      "All distinct accident events",
      "One event per exact coordinate"
    ),
    events = c(
      npoints(accidents_ppp),
      npoints(unique_coordinate_ppp)
    ),
    global_deviation_p = c(
      inhomogeneous_envelope_result$global_p_value,
      unique_coordinate_envelope_result$global_p_value
    ),
    above_from_m = c(
      above_range_value(inhomogeneous_ranges, "min_m"),
      above_range_value(unique_coordinate_ranges, "min_m")
    ),
    above_to_m = c(
      above_range_value(inhomogeneous_ranges, "max_m"),
      above_range_value(unique_coordinate_ranges, "max_m")
    )
  )

  event_days <- as.numeric(difftime(
    events_wgs84$incident_time,
    as.POSIXct("2022-01-01", tz = "Asia/Bangkok"),
    units = "days"
  ))

  close_pairs <- closepairs(accidents_ppp, rmax = 2000, twice = FALSE)
  knox_design <- data.frame(
    label = c("500 m / 1 day", "1 km / 7 days", "2 km / 14 days"),
    distance_m = c(500, 1000, 2000),
    time_days = c(1, 7, 14)
  )

  knox_observed <- vapply(seq_len(nrow(knox_design)), function(index) {
    sum(
      close_pairs$d <= knox_design$distance_m[index] &
        abs(event_days[close_pairs$i] - event_days[close_pairs$j]) <=
          knox_design$time_days[index]
    )
  }, numeric(1))

  knox_nsim <- 199
  set.seed(6262022)
  knox_simulations <- replicate(knox_nsim, {
    permuted_days <- sample(event_days)
    vapply(seq_len(nrow(knox_design)), function(index) {
      sum(
        close_pairs$d <= knox_design$distance_m[index] &
          abs(permuted_days[close_pairs$i] - permuted_days[close_pairs$j]) <=
            knox_design$time_days[index]
      )
    }, numeric(1))
  })

  knox_results <- knox_design |>
    mutate(
      observed_pairs = knox_observed,
      expected_pairs = rowMeans(knox_simulations),
      excess_percent = (observed_pairs / expected_pairs - 1) * 100,
      p_value = (1 + rowSums(knox_simulations >= observed_pairs)) / (knox_nsim + 1)
    )

  knox_primary_simulation <- data.frame(
    simulated_pairs = knox_simulations[2, ]
  )

  analysis_objects <- list(
    accidents_raw = accidents_raw,
    boundaries_raw = boundaries_raw,
    bmr_provinces = bmr_provinces,
    bmr_window_wgs84 = bmr_window_wgs84,
    events_wgs84 = events_wgs84,
    events_utm = events_utm,
    bmr_provinces_utm = bmr_provinces_utm,
    bmr_window_utm = bmr_window_utm,
    analysis_window = analysis_window,
    accidents_ppp = accidents_ppp,
    audit_table = audit_table,
    quality_metrics = quality_metrics,
    bmr_area_km2 = bmr_area_km2,
    province_summary = province_summary,
    monthly_summary = monthly_summary,
    hourly_summary = hourly_summary,
    severity_summary = severity_summary,
    coordinate_bandwidths = coordinate_bandwidths,
    kde_2km_df = kde_2km_df,
    kde_3km_df = kde_3km_df,
    kde_6km_df = kde_6km_df,
    intensity_rank_correlations = intensity_rank_correlations,
    csr_envelope_df = csr_envelope_df,
    inhomogeneous_envelope_df = inhomogeneous_envelope_df,
    second_order_tests = second_order_tests,
    second_order_nsim = second_order_nsim,
    csr_ranges = csr_ranges,
    inhomogeneous_ranges = inhomogeneous_ranges,
    coordinate_reuse_sensitivity = coordinate_reuse_sensitivity,
    unique_coordinate_envelope_df = unique_coordinate_envelope_df,
    unique_coordinate_ranges = unique_coordinate_ranges,
    knox_design = knox_design,
    knox_results = knox_results,
    knox_primary_simulation = knox_primary_simulation,
    knox_nsim = knox_nsim,
    duplicate_event = duplicate_event,
    in_2022 = in_2022,
    complete_coordinates = complete_coordinates,
    plausible_coordinates = plausible_coordinates,
    valid_time = valid_time
  )

  saveRDS(analysis_objects, cache_file)
  list2env(analysis_objects, envir = environment())
}

theme_set(
  theme_minimal(base_size = 12) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", colour = "#17233b"),
      plot.subtitle = element_text(colour = "#5b677a"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
)

palette_main <- c(
  navy = "#173f5f",
  blue = "#2f6f9f",
  teal = "#238a8d",
  amber = "#f2a541",
  red = "#c44e52",
  grey = "#d9e1ea"
)
