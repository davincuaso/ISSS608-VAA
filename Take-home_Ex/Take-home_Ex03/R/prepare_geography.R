# Prepare the station scenario and two independent land-use measures.
# Run from the Take-home_Ex03 directory: Rscript R/prepare_geography.R
suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(ggplot2)
})

dir.create("data/cache", recursive = TRUE, showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

download_dgs <- function(id, path) {
  if (file.exists(path)) return(path)
  endpoint <- paste0("https://api-open.data.gov.sg/v1/public/api/datasets/",
                     id, "/poll-download")
  response <- jsonlite::fromJSON(endpoint)
  stopifnot(response$code == 0L, nzchar(response$data$url))
  download.file(response$data$url, path, mode = "wb", quiet = TRUE)
  path
}

hdb_path <- Sys.getenv("EX03_HDB_GEOJSON", "data/cache/hdb_existing_building.geojson")
land_path <- Sys.getenv("EX03_LANDUSE_GEOJSON", "data/cache/masterplan2025_landuse.geojson")
hdb_path <- download_dgs("d_16b157c52ed637edd6ba1232e026258d", hdb_path)
land_path <- download_dgs("d_a8c3546b26712e35021f3a681d0353ae", land_path)

raw_now <- read.csv("data/source/operational_stations.csv", stringsAsFactors = FALSE)
raw_future <- read.csv("data/source/future_stations.csv", stringsAsFactors = FALSE)
stopifnot(nrow(raw_now) == 213L, nrow(raw_future) == 65L,
          !anyNA(raw_now[, c("station_code", "station_name", "lat", "lon")]),
          !anyNA(raw_future[, c("station_code", "station_name", "lat", "lon")]),
          !anyDuplicated(raw_now$station_code),
          !anyDuplicated(raw_future$station_code))

# The brief asks for 24 JRL and 12 CRL Phase 1 station codes. JS2A Forest Hill
# is an additional code in the source file, so it is outside this fixed scenario.
future <- raw_future |>
  filter(grepl("^(JS[0-9]+|JW[1-5]|JE[1-7]|CR([2-9]|1[0-3]))$", station_code)) |>
  mutate(line = if_else(grepl("^CR", station_code), "CRL1", "JRL"))
stopifnot(sum(future$line == "JRL") == 24L,
          sum(future$line == "CRL1") == 12L,
          !anyDuplicated(future$station_code))

# One point per physical station. Interchange line codes share a name and are
# averaged to one point; the constituent codes remain in station_codes.
collapse_stations <- function(x) {
  x |>
    group_by(station_name) |>
    summarise(station_codes = paste(sort(station_code), collapse = "-"),
              lon = mean(lon), lat = mean(lat),
              n_lines = n(), .groups = "drop") |>
    rename(station = station_name)
}
existing <- collapse_stations(raw_now) |> mutate(status = "Existing")
planned <- collapse_stations(future) |>
  mutate(status = if_else(station %in% existing$station,
                          "Existing interchange", "Planned new"))
new_stations <- planned |>
  filter(status == "Planned new") |>
  mutate(line = if_else(grepl("^CR", station_codes), "CRL1", "JRL"))
all_stations <- bind_rows(existing, new_stations) |>
  arrange(status, station) |>
  mutate(station_id = sprintf("S%03d", row_number()))
stopifnot(!anyDuplicated(all_stations$station), nrow(existing) == 181L)

station_sf <- st_as_sf(all_stations, coords = c("lon", "lat"), crs = 4326,
                       remove = FALSE) |> st_transform(3414)
now_sf <- station_sf |> filter(status == "Existing")
new_sf <- station_sf |> filter(status == "Planned new")

# HDB block centroids are a count of buildings, not residents or households.
hdb <- st_read(hdb_path, quiet = TRUE) |> st_transform(3414)
stopifnot(nrow(hdb) > 10000L)
hdb_pts <- st_centroid(hdb)
dist_now <- st_distance(hdb_pts, now_sf) |> unclass()
dist_new <- st_distance(hdb_pts, new_sf) |> unclass()
nearest_now <- max.col(-dist_now, ties.method = "first")
nearest_new <- max.col(-dist_new, ties.method = "first")
d_now <- apply(dist_now, 1, min)
d_new <- apply(dist_new, 1, min)
newly_reached <- d_now > 800 & d_new <= 800
shifted <- d_new < d_now
hdb_tab <- data.frame(
  block_id = seq_len(nrow(hdb_pts)),
  x = st_coordinates(hdb_pts)[, 1], y = st_coordinates(hdb_pts)[, 2],
  current_nearest = now_sf$station[nearest_now],
  new_nearest = new_sf$station[nearest_new],
  new_line = new_sf$line[nearest_new],
  current_distance_m = round(d_now), new_distance_m = round(d_new),
  newly_within_800m = newly_reached,
  nearer_to_new_station = shifted
)
write.csv(hdb_tab, "results/hdb-block-proximity.csv", row.names = FALSE)

# This is a proxy for destination activity, using the mapped area of commercial,
# business, civic, education and health parcels. A polygon is counted where its
# centroid falls within 800 m; this is documented as an approximation.
land <- st_read(land_path, quiet = TRUE) |> st_transform(3414)
land$category <- trimws(land$LU_DESC)
activity_codes <- c("COMMERCIAL", "BUSINESS 1", "BUSINESS 2", "BUSINESS PARK",
                    "COMMERCIAL & RESIDENTIAL", "COMMERCIAL / INSTITUTION",
                    "RESIDENTIAL WITH COMMERCIAL AT 1ST STOREY",
                    "CIVIC & COMMUNITY INSTITUTION", "EDUCATIONAL INSTITUTION",
                    "HEALTH & MEDICAL CARE", "HOTEL", "WHITE",
                    "BUSINESS 1 - WHITE", "BUSINESS 2 - WHITE",
                    "BUSINESS PARK - WHITE")
land <- land |> filter(category %in% activity_codes)
land$area_ha <- as.numeric(st_area(land)) / 10000
land_pts <- st_centroid(land)
within_800 <- st_is_within_distance(station_sf, land_pts, dist = 800)
activity_ha <- vapply(within_800, function(idx) sum(land$area_ha[idx]), numeric(1))
hdb_within_800 <- st_is_within_distance(station_sf, hdb_pts, dist = 800)
blocks_800 <- lengths(hdb_within_800)
features <- st_drop_geometry(station_sf) |>
  mutate(hdb_blocks_800m = blocks_800,
         activity_hectares_800m = round(activity_ha, 2),
         scenario_lines = n_lines + if_else(station %in% planned$station &
                                              status == "Existing", 1L, 0L))
write.csv(features, "results/station-features.csv", row.names = FALSE)

coverage <- data.frame(
  metric = c("Existing physical stations", "New physical stations",
             "HDB blocks in source", "HDB blocks within 800 m of existing rail",
             "HDB blocks newly within 800 m", "HDB blocks nearer to a new station"),
  value = c(nrow(existing), nrow(new_stations), nrow(hdb_pts),
            sum(d_now <= 800), sum(newly_reached), sum(shifted))
)
write.csv(coverage, "results/coverage-summary.csv", row.names = FALSE)

distance_sensitivity <- data.frame(
  threshold_m = c(600, 800, 1000),
  existing_blocks = vapply(c(600, 800, 1000),
                           function(r) sum(d_now <= r), integer(1)),
  newly_reached_blocks = vapply(c(600, 800, 1000),
                                function(r) sum(d_now > r & d_new <= r), integer(1))
)
write.csv(distance_sensitivity, "results/distance-sensitivity.csv", row.names = FALSE)

new_station_coverage <- hdb_tab |>
  filter(newly_within_800m) |>
  count(new_nearest, name = "newly_reached_blocks") |>
  right_join(new_stations |> select(station), by = c("new_nearest" = "station")) |>
  mutate(newly_reached_blocks = coalesce(newly_reached_blocks, 0L)) |>
  arrange(desc(newly_reached_blocks))
write.csv(new_station_coverage, "results/new-station-coverage.csv", row.names = FALSE)

line_coverage <- hdb_tab |>
  filter(newly_within_800m) |>
  count(new_line, name = "newly_reached_blocks") |>
  arrange(new_line)
write.csv(line_coverage, "results/line-coverage.csv", row.names = FALSE)

# All graphics use the same visual language as Exercise 2: restrained colours,
# direct labels and a source note in the caption.
theme_set(theme_minimal(base_size = 12))
blue <- "#1d4e89"; orange <- "#d47529"; grey <- "#a9b4bf"
plot_hdb <- hdb_tab |> filter(newly_within_800m)
p_map <- ggplot() +
  geom_point(data = hdb_tab, aes(x, y), size = .1, colour = "#d7dfe5", alpha = .4) +
  geom_point(data = plot_hdb, aes(x, y), size = .65, colour = orange, alpha = .8) +
  geom_sf(data = now_sf, size = .7, colour = blue, alpha = .75) +
  geom_sf(data = new_sf, shape = 21, fill = orange, colour = "#823e10", size = 2) +
  coord_sf(datum = NA) +
  labs(title = "Proposed stations and nearby HDB blocks",
       subtitle = "Orange blocks are beyond 800 m from existing rail but within 800 m of a proposed station",
       caption = "Straight-line distance in SVY21; HDB existing buildings (Nov 2025); rail coordinates from data.gov.sg/URA via Wu Tingfeng") +
  theme(panel.grid = element_blank(), axis.title = element_blank(),
        axis.text = element_blank(), plot.title = element_text(face = "bold"))
ggsave("figures/hdb-new-coverage.png", p_map, width = 10, height = 6.5, dpi = 180)

p_bar <- new_station_coverage |>
  slice_max(newly_reached_blocks, n = 14) |>
  ggplot(aes(x = reorder(new_nearest, newly_reached_blocks),
             y = newly_reached_blocks)) +
  geom_col(fill = orange, width = .72) + coord_flip() +
  labs(title = "HDB blocks newly within 800 m of rail",
       subtitle = "Each block is assigned to its nearest proposed station",
       x = NULL, y = "HDB blocks",
       caption = "Straight-line proximity, not a walking catchment; HDB existing buildings (Nov 2025)") +
  theme(plot.title = element_text(face = "bold"))
ggsave("figures/new-station-blocks.png", p_bar, width = 8.5, height = 6, dpi = 180)

p_activity <- features |>
  filter(status == "Planned new") |>
  slice_max(activity_hectares_800m, n = 14) |>
  ggplot(aes(x = reorder(station, activity_hectares_800m),
             y = activity_hectares_800m, fill = line)) +
  geom_col(width = .72) + coord_flip() +
  scale_fill_manual(values = c(CRL1 = blue, JRL = orange), name = "Line") +
  labs(title = "Mapped activity land near proposed stations",
       subtitle = "Commercial, business, civic, education and health parcels within 800 m",
       x = NULL, y = "Approximate hectares",
       caption = "Parcels counted when their centroid is within 800 m; URA Master Plan 2025") +
  theme(plot.title = element_text(face = "bold"))
ggsave("figures/proposed-activity.png", p_activity,
       width = 8.5, height = 6, dpi = 180)

writeLines(capture.output(sessionInfo()), "results/geography-session-info.txt")
cat("Prepared", nrow(existing), "existing stations,", nrow(new_stations),
    "new station locations and", sum(newly_reached), "newly reached HDB blocks.\n")
