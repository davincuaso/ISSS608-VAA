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

# Compare the fitted model with a distance-only reference for new stations.
top_new <- new |> slice_max(estimated_scenario, n = 12)
chart_new <- bind_rows(
  data.frame(station = top_new$destination,
             trips = top_new$estimated_scenario / 1000,
             specification = "Housing, activity, lines + distance"),
  data.frame(station = top_new$destination,
             trips = top_new$distance_only_scenario / 1000,
             specification = "Distance only"))
chart_new$station <- factor(chart_new$station,
                            levels = top_new$destination[order(top_new$estimated_scenario)])
p_new <- ggplot(chart_new, aes(station, trips, fill = specification)) +
  geom_col(position = position_dodge(width = .8), width = .72) +
  coord_flip() +
  scale_fill_manual(values = c("Housing, activity, lines + distance" = blue,
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

cat("Saved four model graphics for", checks$month, ".\n")
