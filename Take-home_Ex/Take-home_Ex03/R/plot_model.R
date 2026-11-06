# Plot the fitted model and the proposed-network comparison.
# Run after R/model.R, from the Take-home_Ex03 directory.
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(sf)
})

checks <- read.csv("results/model/checks.csv")
stopifnot(nrow(checks) == 1L, checks$matched_trip_share == 1)
pred <- read.csv("results/model/station-predictions.csv")
features <- read.csv("results/station-features.csv")
existing <- pred |> filter(status == "Existing")
new <- pred |> filter(status == "Planned new")
stopifnot(nrow(existing) == 184L, nrow(new) == 29L,
          all(existing$observed_ridership > 0),
          !anyNA(pred$estimated_scenario))
dir.create("figures", showWarnings = FALSE)
theme_set(theme_minimal(base_size = 12))
blue <- "#1d4e89"; orange <- "#d47529"
fmt <- scales::label_comma()

# The dashed diagonal shows exact station-level agreement.
r2 <- 1 - sum((existing$observed_ridership - existing$estimated_existing)^2) /
  sum((existing$observed_ridership - mean(existing$observed_ridership))^2)
p_fit <- ggplot(existing, aes(observed_ridership, estimated_existing)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "#708090") +
  geom_point(colour = blue, alpha = .72, size = 2) +
  scale_x_log10(labels = fmt) + scale_y_log10(labels = fmt) +
  labs(title = "Recorded versus fitted station tap-outs",
       subtitle = sprintf("September 2026 weekdays · in-sample station R² = %.2f · MAE = %s trips",
                          r2, fmt(round(checks$station_mae))),
       x = "Recorded monthly tap-outs (log scale)",
       y = "Fitted monthly tap-outs (log scale)",
       caption = "Dashed line = exact agreement. LTA OD Train; fitted origin-constrained choice model.") +
  theme(plot.title = element_text(face = "bold"))
ggsave("figures/model-fit.png", p_fit, width = 8.4, height = 6.2, dpi = 180)

# A same-month holdout of three newly opened CCL6 destinations reveals whether
# coefficients learned from older stations transfer to genuinely new stops.
recent <- read.csv("results/model/new-station-holdout.csv")
recent$destination <- factor(recent$destination,
                             levels = rev(recent$destination))
p_recent <- ggplot(recent, aes(y = destination)) +
  geom_segment(aes(x = observed_from_older_origins,
                   xend = predicted_from_older_origins,
                   yend = destination), colour = "#9aa7b0", linewidth = 1) +
  geom_point(aes(x = observed_from_older_origins),
             colour = orange, size = 3.3) +
  geom_point(aes(x = predicted_from_older_origins),
             colour = blue, size = 3.3) +
  geom_text(aes(x = predicted_from_older_origins * 1.13,
                label = sprintf("%.1f×", predicted_to_observed)),
            hjust = 0, size = 3.8) +
  scale_x_log10(labels = fmt, limits = c(1500, 500000)) +
  labs(title = "A new-station holdout exposes the forecast gap",
       subtitle = "Orange: observed · blue: modelled · label: overprediction factor",
       x = "Monthly weekday tap-outs from older origins (log scale)",
       y = NULL,
       caption = "CCL6 opened July 2026; same-month transfer check.") +
  theme(plot.title = element_text(face = "bold"))
ggsave("figures/new-station-holdout.png", p_recent,
       width = 9.4, height = 4.9, dpi = 180)

# Compare the fitted model with a distance-only reference for new stations.
top_new <- new |> slice_max(estimated_scenario, n = 12)
chart_new <- bind_rows(
  data.frame(station = top_new$destination,
             trips = top_new$estimated_scenario / 1000,
             specification = "Full choice model"),
  data.frame(station = top_new$destination,
             trips = top_new$distance_only_scenario / 1000,
             specification = "Distance only"))
chart_new$station <- factor(chart_new$station,
                            levels = top_new$destination[order(top_new$estimated_scenario)])
p_new <- ggplot(chart_new, aes(station, trips, fill = specification)) +
  geom_col(position = position_dodge(width = .8), width = .72) +
  coord_flip() +
  scale_fill_manual(values = c("Full choice model" = blue,
                               "Distance only" = orange), name = "Model") +
  labs(title = "Trips captured by proposed destinations",
       subtitle = "Top 12 under the fitted model; fixed September 2026 origin totals",
       x = NULL, y = "Monthly weekday tap-outs (thousands)",
       caption = "Scenario estimates, not observed trips or total future station ridership. LTA OD Train + geographic predictors.") +
  theme(plot.title = element_text(face = "bold"))
ggsave("figures/new-station-modelled-trips.png", p_new,
       width = 9.2, height = 6.4, dpi = 180)

# Compare the same stations with and without the future line-count uplift.
gains <- existing |> filter(change > 0)
losses <- existing |> slice_min(change, n = 8)
change_chart <- bind_rows(gains, losses)
change_chart$destination <- factor(change_chart$destination,
                                   levels = change_chart$destination[order(change_chart$change)])
change_chart$no_uplift_change <- (change_chart$no_uplift_scenario -
                                  change_chart$estimated_existing) / 1000
change_chart$full_change <- change_chart$change / 1000
change_long <- bind_rows(
  data.frame(destination = change_chart$destination,
             change = change_chart$full_change,
             assumption = "New lines increase interchange attraction"),
  data.frame(destination = change_chart$destination,
             change = change_chart$no_uplift_change,
             assumption = "No interchange attraction uplift"))
p_change <- ggplot() +
  geom_vline(xintercept = 0, colour = "#56616a") +
  geom_segment(data = change_chart,
               aes(x = no_uplift_change, xend = full_change,
                   y = destination, yend = destination),
               colour = "#9ca8b2", linewidth = .7) +
  geom_point(data = change_long,
             aes(x = change, y = destination, colour = assumption), size = 2.8) +
  scale_colour_manual(values = c("New lines increase interchange attraction" = blue,
                                 "No interchange attraction uplift" = orange),
                      name = "Scenario") +
  labs(title = "Existing stations under the expanded choice set",
       subtitle = "Seven proposed interchanges and eight largest losses; each pair changes one assumption",
       x = "Change in monthly weekday tap-outs (thousands)", y = NULL,
       caption = "LTA September 2026 OD Train; fixed origin totals. Conditional estimates.") +
  theme(plot.title = element_text(face = "bold"))
ggsave("figures/existing-station-change.png", p_change,
       width = 9.2, height = 6.7, dpi = 180)

# Locate new-station estimates relative to existing rail and HDB blocks.
station_sf <- st_as_sf(features, coords = c("lon", "lat"), crs = 4326) |>
  st_transform(3414) |>
  left_join(pred |> select(destination, estimated_scenario),
            by = c("station" = "destination"))
now_sf <- station_sf |> filter(status == "Existing")
new_sf <- station_sf |> filter(status == "Planned new")
hdb <- read.csv("results/hdb-block-proximity.csv")
p_map <- ggplot() +
  geom_point(data = hdb, aes(x, y), size = .12, colour = "#bcc8d1", alpha = .35) +
  geom_sf(data = now_sf, colour = blue, alpha = .6, size = .65) +
  geom_sf(data = new_sf, aes(size = estimated_scenario / 1000),
          shape = 21, fill = orange, colour = "#71350f", alpha = .85) +
  scale_size_continuous(range = c(1.5, 5.5),
                        name = "Captured tap-outs\n(thousands)") +
  coord_sf(datum = NA) +
  labs(title = "Where the model places new destination demand",
       subtitle = "29 proposed station locations; September 2026 origin market held fixed",
       caption = "Blue: existing rail; orange size: modelled captured trips. Grey: HDB blocks. Station points use SVY21; not a forecast.") +
  theme(panel.grid = element_blank(), axis.title = element_blank(),
        axis.text = element_blank(), plot.title = element_text(face = "bold"))
ggsave("figures/modelled-new-station-map.png", p_map,
       width = 10, height = 6.5, dpi = 180)

# Show the change in an existing station's origin market. These dots are
# *boarding stations*, not residential catchment polygons. The outcome is a
# difference in choice probability from the same origin under two networks.
current_pairs <- read.csv("results/model/interaction-existing.csv") |>
  select(origin, destination, current_probability = probability)
future_pairs <- read.csv("results/model/interaction-scenario.csv") |>
  select(origin, destination, future_probability = probability)
market_shift <- inner_join(current_pairs, future_pairs,
                           by = c("origin", "destination")) |>
  filter(destination %in% c("Ang Mo Kio", "Outram Park")) |>
  left_join(features |> select(origin = station, lon, lat), by = "origin") |>
  mutate(change_pp = 100 * (future_probability - current_probability),
         destination = factor(destination, levels = c("Ang Mo Kio", "Outram Park")))
stopifnot(nrow(market_shift) == 366L, !anyNA(market_shift$change_pp))
market_sf <- st_as_sf(market_shift, coords = c("lon", "lat"), crs = 4326) |>
  st_transform(3414)
market_xy <- cbind(st_drop_geometry(market_sf), st_coordinates(market_sf))
target_sf <- station_sf |>
  filter(station %in% c("Ang Mo Kio", "Outram Park"))
target_xy <- cbind(st_drop_geometry(target_sf), st_coordinates(target_sf)) |>
  mutate(destination = factor(station, levels = c("Ang Mo Kio", "Outram Park")))
p_market <- ggplot() +
  geom_point(data = hdb, aes(x, y), size = .1, colour = "#d4dce2", alpha = .35) +
  geom_point(data = market_xy,
             aes(X, Y, colour = change_pp), size = 2, alpha = .9) +
  geom_point(data = target_xy, aes(X, Y), shape = 8, size = 3,
             colour = "#192b38") +
  facet_wrap(~destination, nrow = 1) +
  scale_colour_gradient2(low = orange, mid = "#c9d1d8", high = blue,
                         midpoint = 0, limits = c(-2, 2),
                         name = "Change in choice\nprobability (pp)") +
  coord_sf(datum = NA) +
  labs(title = "How two existing stations' origin markets shift",
       subtitle = "Dots are current boarding stations; star marks the destination",
       caption = "Expanded versus current network, same origin totals. Colour is a percentage-point change, not residents or a walking catchment.") +
  theme(panel.grid = element_blank(), axis.title = element_blank(),
        axis.text = element_blank(), plot.title = element_text(face = "bold"))
ggsave("figures/existing-market-area-map.png", p_market,
       width = 11.5, height = 6.1, dpi = 180)

# A spatial residual check asks whether large station errors are geographically
# patterned. Row-standardised k-nearest-station weights avoid an arbitrary
# fixed radius; 999 label permutations provide the reference distribution.
resid_sf <- station_sf |>
  filter(status == "Existing") |>
  left_join(existing |> select(destination, observed_ridership,
                               estimated_existing), by = c("station" = "destination"))
stopifnot(!anyNA(resid_sf$observed_ridership))
resid_sf$log_ratio <- log2((resid_sf$observed_ridership + 1) /
                             (resid_sf$estimated_existing + 1))
distance <- as.matrix(st_distance(resid_sf))
diag(distance) <- Inf
z <- resid_sf$log_ratio - mean(resid_sf$log_ratio)
moran <- function(v, nn) {
  centred <- v - mean(v)
  sum(centred[row(nn)] * centred[as.vector(nn)]) /
    (ncol(nn) * sum(centred^2))
}
set.seed(626)
spatial_audit <- do.call(rbind, lapply(c(4L, 6L, 8L), function(k) {
  nn <- t(apply(distance, 1, order))[, seq_len(k), drop = FALSE]
  observed_i <- moran(z, nn)
  random_i <- replicate(999, moran(sample(z), nn))
  data.frame(neighbours = k, moran_i = observed_i,
             permutation_p = (1 + sum(random_i >= observed_i)) / 1000,
             permutations = 999L)
}))
write.csv(spatial_audit, "results/model/residual-spatial-audit.csv", row.names = FALSE)
labels <- resid_sf |>
  filter(station %in% c("Changi Airport", "Boon Lay", "Keppel", "Teck Lee"))
p_resid <- ggplot() +
  geom_point(data = hdb, aes(x, y), size = .1, colour = "#d4dce2", alpha = .35) +
  geom_sf(data = resid_sf, aes(colour = log_ratio), size = 2) +
  geom_sf_text(data = labels, aes(label = station), nudge_y = 1200,
               size = 3.2, check_overlap = TRUE, colour = "#172b39") +
  scale_colour_gradient2(low = orange, mid = "#e5e9ed", high = blue,
                         midpoint = 0, limits = c(-3, 3),
                         oob = scales::squish,
                         breaks = c(-3, -1, 0, 1, 3),
                         labels = c("≤1/8", "1/2", "1", "2", "≥8"),
                         name = "Recorded / fitted\ntap-outs") +
  coord_sf(datum = NA) +
  labs(title = "Station errors are geographically patterned",
       subtitle = sprintf("Log-ratio residuals · six-neighbour Moran's I = %.2f · permutation p = %.3f",
                          spatial_audit$moran_i[spatial_audit$neighbours == 6],
                          spatial_audit$permutation_p[spatial_audit$neighbours == 6]),
       caption = "Blue = more observed than fitted; orange = less. Colours capped at 1/8 and 8 times. LTA September 2026 OD Train.") +
  theme(panel.grid = element_blank(), axis.title = element_blank(),
        axis.text = element_blank(), plot.title = element_text(face = "bold"))
ggsave("figures/station-residual-map.png", p_resid,
       width = 10, height = 6.5, dpi = 180)

cat("Saved seven model graphics and the spatial residual audit for",
    checks$month, ".\n")
