library(sf)
library(dplyr)
library(tidyr)
library(ggplot2)
a <- readRDS("results/analysis.rds")
b <- a$boundaries
cube <- a$cube
se <- read.csv("results/static-events.csv")
sfat <- read.csv("results/static-fatalities.csv")
ee <- read.csv("results/ehsa-events.csv")
ef <- read.csv("results/ehsa-fatalities.csv")
rob <- read.csv("results/robustness.csv")
theme_set(theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold",
    size = 17), plot.subtitle = element_text(color = "#52616b"), plot.caption = element_text(color = "#52616b",
    hjust = 0), legend.position = "bottom"))
# State outlines provide orientation without obscuring township-level fill.
states <- b |>
    group_by(ST) |>
    summarise()
cap <- "Sources: ACLED supplied extract; MIMU v9.4. Analysis: Jan 2021–Sep 2025."
savep <- function(p, name, w = 10, h = 8) {
    p$labels$title <- paste(strwrap(p$labels$title, width = floor(w * 6.5)), collapse = "\n")
    p$labels$subtitle <- paste(strwrap(p$labels$subtitle, width = floor(w * 9)), collapse = "\n")
    p <- p + theme(plot.caption = element_text(size = 9))
    ggsave(paste0("figures/", name, ".png"), p, width = w, height = h, dpi = 180, bg = "white")
}

base_map <- function(data, var, title, subtitle) ggplot(data) + geom_sf(aes(fill = .data[[var]]),
    color = "white", linewidth = 0.06) + geom_sf(data = states, fill = NA, color = "#59636d",
    linewidth = 0.22) + coord_sf(datum = NA) + labs(title = title, subtitle = subtitle,
    fill = NULL, caption = cap) + theme(axis.text = element_blank(), axis.title = element_blank(),
    panel.grid = element_blank())
# A labelled overview makes the regional references in the findings traceable.
locator <- ggplot(states) + geom_sf(fill = "#e8eff1", color = "#637786", linewidth = 0.3) +
    geom_sf_text(aes(label = ST), size = 2.5, check_overlap = TRUE) + coord_sf(datum = NA) +
    labs(title = "Myanmar: geographical reference", subtitle = "State and region outlines assembled from MIMU v9.4 townships",
        caption = cap) + theme(axis.text = element_blank(), axis.title = element_blank(),
    panel.grid = element_blank())
savep(locator, "locator", 8, 10)

for (metric in c("events", "fatalities")) {
    label <- if (metric == "events")
        "Recorded violence events" else "Reported fatalities"
    p <- base_map(b, metric, label, "Township totals • counts, not population-adjusted risk") +
        scale_fill_viridis_c(trans = "sqrt", option = "C", labels = scales::comma)
    savep(p, paste0("distribution-", metric), 7, 9)
    s <- if (metric == "events")
        se else sfat
    d <- left_join(b, s[, c("TS_PCODE", "lisa", "hotspot")], by = "TS_PCODE")
    pal <- c(`High–high` = "#b2182b", `Low–low` = "#2166ac", `High–low` = "#ef8a62",
        `Low–high` = "#67a9cf", `Not significant` = "#e7e9ec")
    savep(base_map(d, "lisa", paste(label, "| Local Moran’s I"), "Two-sided permutation p < .05 • 9,999 permutations") +
        scale_fill_manual(values = pal), paste0("lisa-", metric), 7, 9)
    savep(base_map(d, "hotspot", paste(label, "| Gi*"), "Two-sided permutation p < .05 • self included") +
        scale_fill_manual(values = c(`Hot spot` = "#b2182b", `Cold spot` = "#2166ac",
            `Not significant` = "#e7e9ec")), paste0("hotspot-", metric), 7, 9)
    eh <- if (metric == "events")
        ee else ef
    d <- left_join(b, eh[, c("TS_PCODE", "classification", "tau", "mk_p")], by = "TS_PCODE")
    levels <- c("New hot spot", "Consecutive hot spot", "Intensifying hot spot", "Persistent hot spot",
        "Diminishing hot spot", "Sporadic hot spot", "Oscillating hot spot", "Historical hot spot",
        "New cold spot", "Consecutive cold spot", "Intensifying cold spot", "Persistent cold spot",
        "Diminishing cold spot", "Sporadic cold spot", "Oscillating cold spot", "Historical cold spot",
        "No pattern detected")
    colors <- c("#fdae61", "#f46d43", "#a50026", "#d73027", "#fdbf6f", "#e78ac3", "#8e0152",
        "#a6611a", "#abd9e9", "#74add1", "#053061", "#2166ac", "#92c5de", "#80cdc1", "#5e4fa2",
        "#4393c3", "#e7e9ec")
    savep(base_map(d, "classification", paste(label, "| emerging patterns"), "57 months • queen neighbours + previous month • bin p < .05") +
        scale_fill_manual(values = setNames(colors, levels)) + guides(fill = guide_legend(ncol = 2)),
        paste0("ehsa-", metric), 8, 10)
    d$significant_class <- ifelse(d$mk_p < 0.05 & d$classification != "No pattern detected",
        d$classification, "No significant classified trend")
    savep(base_map(d, "significant_class", paste(label, "| EHSA with trend filter"), "Classified bin history and Mann–Kendall p < .05") +
        scale_fill_manual(values = c(setNames(colors, levels), `No significant classified trend` = "#e7e9ec")) +
        guides(fill = guide_legend(ncol = 2)), paste0("ehsa-significant-", metric), 8,
        10)
    d$trend <- ifelse(d$mk_p < 0.05, ifelse(d$tau > 0, "Increasing Gi*", "Decreasing Gi*"),
        "Not significant")
    savep(base_map(d, "trend", paste(label, "| Gi* trend"), "Mann–Kendall p < .05 • unadjusted for serial dependence") +
        scale_fill_manual(values = c(`Increasing Gi*` = "#b2182b", `Decreasing Gi*` = "#2166ac",
            `Not significant` = "#e7e9ec")), paste0("trend-", metric), 7, 9)
}
monthly <- cube |>
    group_by(month) |>
    summarise(events = sum(events), fatalities = sum(fatalities), .groups = "drop") |>
    pivot_longer(-month, names_to = "measure", values_to = "count")
savep(ggplot(monthly, aes(month, count)) + geom_line(color = "#126b78", linewidth = 0.8) +
    facet_wrap(~measure, ncol = 1, scales = "free_y") + scale_y_continuous(labels = scales::comma) +
    labs(title = "Recorded violence varies sharply across the study period", subtitle = "Monthly national totals • separate vertical scales",
        x = NULL, y = "Count", caption = cap), "monthly", 10, 6)
# Compare significant Gi* classifications across assumptions, including neutral
# townships.
rob$status <- ifelse(rob$baseline == "Hot spot" & rob$precise_only == "Hot spot" & rob$knn4 ==
    "Hot spot", "Hot in all three", ifelse(rob$baseline == "Hot spot", "Baseline hot: sensitive",
    "Other townships"))
d <- left_join(b, rob[, c("TS_PCODE", "status")], by = "TS_PCODE")
savep(base_map(d, "status", "Which event hot spots survive both checks?", "Precision-1-only records and symmetric 4-nearest-neighbour weights") +
    scale_fill_manual(values = c(`Hot in all three` = "#8c1738", `Baseline hot: sensitive` = "#f4a259",
        `Other townships` = "#e7e9ec")), "robustness", 7, 9)
# A separate geospatial extension: displacement of the event-weighted centre.  Use
# Jan–Sep in every year so that the partial 2025 year is comparable.
xy <- st_coordinates(st_centroid(st_geometry(b)))
coords <- data.frame(TS_PCODE = b$TS_PCODE, x = xy[, 1], y = xy[, 2])
mcent <- cube |>
    filter(as.integer(format(month, "%m")) <= 9) |>
    left_join(coords, by = "TS_PCODE") |>
    mutate(year = format(month, "%Y")) |>
    group_by(year, month) |>
    summarise(sx = sum(x * events), sy = sum(y * events), n = sum(events), .groups = "drop")
centres <- mcent |>
    group_by(year) |>
    summarise(x = sum(sx)/sum(n), y = sum(sy)/sum(n), events = sum(n), .groups = "drop")
set.seed(6262026)
boot <- lapply(split(mcent, mcent$year), function(d) t(replicate(1999, {
    s <- d[sample(seq_len(nrow(d)), replace = TRUE), ]
    c(sum(s$sx)/sum(s$n), sum(s$sy)/sum(s$n))
})))
delta <- boot[["2025"]] - boot[["2021"]]
dist <- sqrt(rowSums(delta^2))/1000
actual <- as.numeric(centres[centres$year == "2025", c("x", "y")] - centres[centres$year ==
    "2021", c("x", "y")])
summary <- data.frame(dx_km = actual[1]/1000, dy_km = actual[2]/1000, distance_km = sqrt(sum(actual^2))/1000,
    boot_low = quantile(dist, 0.025), boot_high = quantile(dist, 0.975))
write.csv(summary, "results/centre-shift.csv", row.names = FALSE)
write.csv(centres, "results/annual-centres.csv", row.names = FALSE)
cloud <- bind_rows(lapply(names(boot), function(y) data.frame(year = y, x = boot[[y]][,
    1], y = boot[[y]][, 2])))
# Zoom to the centres so the annual displacement is visible at presentation size.
centres$label_x <- centres$x + c(45000, -70000, 65000, -70000, 40000)
centres$label_y <- centres$y + c(12000, 18000, -2000, -18000, -18000)
p <- ggplot() + geom_sf(data = states, fill = "#f0f2f4", color = "#8794a0", linewidth = 0.4) +
    geom_point(data = cloud, aes(x, y, color = year), alpha = 0.08, size = 0.7) + geom_path(data = centres,
    aes(x, y), color = "#263746", arrow = arrow(length = grid::unit(0.12, "inches"))) +
    geom_point(data = centres, aes(x, y, color = year), size = 3) + geom_segment(data = centres,
    aes(x = x, y = y, xend = label_x, yend = label_y), color = "#52616b", linewidth = 0.3) +
    geom_label(data = centres, aes(label_x, label_y, label = year, color = year), fill = "white",
        size = 4, show.legend = FALSE) + annotate("segment", x = -1e+05, xend = -50000, y = 85000, yend = 85000,
    linewidth = 1) + annotate("text", x = -75000, y = 76000, label = "50 km", size = 3.5) +
    coord_sf(datum = NA, xlim = c(-130000, 135000), ylim = c(65000, 280000), expand = FALSE) +
    scale_color_brewer(palette = "Dark2") + labs(title = "The event-weighted centre moves south",
    subtitle = "Central Myanmar detail • January–September each year", color = "Year",
    caption = cap) + theme(axis.text = element_blank(), axis.title = element_blank(),
    panel.grid = element_blank())
savep(p, "centre-shift", 8, 8)
# Representative township trajectories make the EHSA labels inspectable.
top <- ee |>
    filter(hot_months > 0) |>
    arrange(desc(hot_months)) |>
    slice_head(n = 6)
st <- read.csv("results/space-time-events.csv")
st$month <- as.Date(st$month)
st <- st |>
    inner_join(top[, c("TS_PCODE", "TS", "classification")], by = "TS_PCODE") |>
    mutate(sig = ifelse(p < 0.05 & gi_z > 0, "Hot", ifelse(p < 0.05 & gi_z < 0, "Cold",
        "Not significant")))
savep(ggplot(st, aes(month, gi_z)) + geom_hline(yintercept = 0, color = "grey70") + geom_line(color = "#8794a0") +
    geom_point(aes(color = sig), size = 1.1) + facet_wrap(~TS, ncol = 2) + scale_color_manual(values = c(Hot = "#b2182b",
    Cold = "#2166ac", `Not significant` = "#b6bec6")) + labs(title = "The six townships with the most hot months",
    subtitle = "Spatio-temporal Gi* • points use permutation significance, not a fixed Z cutoff",
    x = NULL, y = "Gi* standard score", color = NULL, caption = cap), "trajectories",
    11, 8)
message("Figures complete")
