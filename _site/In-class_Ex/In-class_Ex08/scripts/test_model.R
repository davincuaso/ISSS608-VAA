# Small, explicitly synthetic API tests. Not the Taichung course analysis.
if (!requireNamespace("pacman", quietly = TRUE)) {
  stop("Install pacman before running the draft tests.")
}
suppressPackageStartupMessages(pacman::p_load(sf, tidyverse, MCI, tmap, ragg))
source("scripts/trade_areas.R")

interaction_matrix <- expand_grid(
  VILLCODE = c("test-1", "test-2", "test-3"), Store_CD = c("A", "B")
) |>
  mutate(Store_size = 100, distance = c(100, 200, 200, 100, 150, 150)) |>
  as.data.frame()
huff_share <- huff.shares(
  interaction_matrix, "VILLCODE", "Store_CD", "Store_size", "distance",
  gamma = 1, lambda = -2
)
independent <- interaction_matrix |>
  group_by(VILLCODE) |>
  mutate(weight = Store_size / distance^2, probability = weight / sum(weight)) |>
  ungroup()
stopifnot(max(abs(huff_share$p_ij - independent$probability)) < 1e-12)
huff_share_pp <- as_tibble(huff_share) |>
  left_join(tibble(VILLCODE = c("test-1", "test-2", "test-3"),
                   P_CNT = c(100, 200, 300)), by = "VILLCODE")
huff_total <- shares.total(huff_share_pp, "VILLCODE", "Store_CD", "p_ij", "P_CNT")
stopifnot(abs(sum(huff_total$sum_E_j) - 600) < 1e-10)
wide <- as_tibble(huff_share) |>
  select(VILLCODE, Store_CD, p_ij) |>
  pivot_wider(names_from = Store_CD, values_from = p_ij)
huff_TA <- dominant_trade_areas(wide, c("A", "B"))
stopifnot(identical(huff_TA$TA, c("A", "B", "A")),
          identical(huff_TA$Tied_stores, c(1L, 1L, 2L)))

square <- function(x) st_polygon(list(matrix(
  c(x, 0, x + 100, 0, x + 100, 100, x, 100, x, 0),
  ncol = 2, byrow = TRUE
)))
villages <- st_sf(
  VILLCODE = c("test-1", "test-2", "test-3"),
  geometry = st_sfc(square(0), square(100), square(200), crs = 3826)
)
village_TA <- left_join(villages, huff_TA, by = "VILLCODE") |>
  mutate(TA = factor(TA, levels = c("A", "B")))
tmap_mode("plot")
plot <- tm_shape(village_TA) +
  tm_polygons(
    fill = "TA", col = "grey35", lwd = 0.5,
    fill.scale = tm_scale_categorical(values = c(A = "#4267A5", B = "#D78B52"),
                                     label.na = FALSE),
    fill.legend = tm_legend(title = "TA", position = tm_pos_out("right", "center"))
  ) +
  tm_title("SYNTHETIC map API test: not course results") +
  tm_layout(frame = TRUE) +
  tm_borders(col = "grey30", col_alpha = 0.5, lwd = 0.5) +
  tm_compass(type = "8star", size = 2, position = tm_pos_in("right", "bottom")) +
  tm_scalebar(position = tm_pos_in("left", "bottom")) + tm_grid(alpha = 0.2)
map_file <- file.path(tempdir(), "synthetic-map-api-test.png")
agg_png(map_file, width = 14, height = 12, units = "in", res = 72)
print(plot)
invisible(dev.off())
stopifnot(file.exists(map_file), file.info(map_file)$size > 1000)
cat("PASS: MCI probabilities, population accounting, named trade areas and",
    "tmap rendering API. Synthetic fixtures only.\n")
