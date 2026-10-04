library(sf)
library(dplyr)
library(tidyr)
library(ggplot2)
library(spdep)
library(Kendall)
set.seed(6262026)
raw_path <- Sys.getenv("ACLED_CSV", unset = "data/private/ACLED_Data_Myanmar_Jan2021-Sep2025.csv")
if (!file.exists(raw_path)) stop("ACLED CSV not found. Restore data/private/ or set ACLED_CSV.")
raw <- read.csv(raw_path, fileEncoding = "UTF-8-BOM")
stopifnot(!anyDuplicated(raw$event_id_cnty))
raw$event_date <- as.Date(raw$event_date)
write.csv(as.data.frame(table(raw$event_type)), "results/event-types.csv", row.names = FALSE)
b <- st_read("data/boundaries/mimu-v9.4.geojson", quiet = TRUE) |>
    arrange(TS_PCODE)
stopifnot(nrow(b) == 330, all(b$PCode_V == "9.4"), !anyDuplicated(b$TS_PCODE))
b <- st_transform(st_make_valid(b), "+proj=aea +lat_1=10 +lat_2=28 +lat_0=19 +lon_0=96 +datum=WGS84 +units=m +no_defs")
audit <- data.frame(stage = "Source records", n = nrow(raw))
add_audit <- function(x, label) {
    audit <<- rbind(audit, data.frame(stage = label, n = nrow(x)))
    x
}
e <- raw |>
    filter(event_date >= as.Date("2021-01-01"), event_date <= as.Date("2025-09-30")) |>
    add_audit("Within study dates")
e <- e |>
    filter(country == "Myanmar") |>
    add_audit("Myanmar country label")
e <- e |>
    filter(event_type %in% c("Battles", "Explosions/Remote violence", "Violence against civilians")) |>
    add_audit("Three core violence event types")
e <- e |>
    filter(geo_precision %in% c(1, 2)) |>
    add_audit("Coordinate precision 1 or 2")
e <- e |>
    filter(is.finite(longitude), is.finite(latitude), abs(longitude) <= 180, abs(latitude) <=
        90) |>
    add_audit("Valid coordinates")
stopifnot(all(is.finite(e$fatalities)), all(e$fatalities >= 0))
pts <- st_transform(st_as_sf(e, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE),
    st_crs(b))
matches <- st_intersects(pts, b)
e$join_n <- lengths(matches)
write.csv(e[e$join_n != 1, c("event_id_cnty", "event_date", "admin3", "longitude", "latitude",
    "geo_precision", "join_n")], "results/excluded-spatial-records.csv", row.names = FALSE)
e$TS_PCODE <- vapply(matches, function(z) if (length(z) == 1) b$TS_PCODE[z] else NA_character_,
    character(1))
e <- e |>
    filter(join_n == 1) |>
    add_audit("Exactly one township match")
e$month <- as.Date(format(e$event_date, "%Y-%m-01"))
write.csv(audit, "results/audit.csv", row.names = FALSE)
months <- seq(as.Date("2021-01-01"), as.Date("2025-09-01"), by = "month")
# Absent recorded events become zero only after validating the source values.
counts <- e |>
    group_by(TS_PCODE, month) |>
    summarise(events = n(), fatalities = sum(fatalities), precise = sum(geo_precision ==
        1), .groups = "drop")
cube <- expand_grid(month = months, TS_PCODE = b$TS_PCODE) |>
    left_join(counts, by = c("TS_PCODE", "month")) |>
    mutate(across(c(events, fatalities, precise), ~replace_na(.x, 0L))) |>
    arrange(month, TS_PCODE)
stopifnot(nrow(cube) == 330 * 57, sum(cube$events) == nrow(e))
write.csv(cube, "results/township-month-cube.csv", row.names = FALSE)
totals <- cube |>
    group_by(TS_PCODE) |>
    summarise(across(c(events, fatalities, precise), sum), .groups = "drop")
b <- left_join(b, totals, by = "TS_PCODE")
# Queen neighbors include shared vertices. Isolates receive a symmetric nearest
# link.
nb <- poly2nb(b, queen = TRUE)
cent <- st_coordinates(st_centroid(st_geometry(b)))
iso <- which(card(nb) == 0)
links <- data.frame(from = character(), to = character())
for (i in iso) {
    d <- rowSums((cent - matrix(cent[i, ], nrow(b), 2, byrow = TRUE))^2)
    d[i] <- Inf
    j <- which.min(d)
    nb[[i]] <- as.integer(j)
    nb[[j]] <- sort(unique(as.integer(c(nb[[j]][nb[[j]] > 0], i))))
    links <- rbind(links, data.frame(from = b$TS_PCODE[i], to = b$TS_PCODE[j]))
}
write.csv(links, "results/island-links.csv", row.names = FALSE)
# Select the two-sided permutation column, not the folded (one-tail) column.
getp <- function(m) {
    k <- grep("Sim", colnames(m))
    k <- k[!grepl("folded", colnames(m)[k])]
    stopifnot(length(k) == 1)
    as.numeric(m[, k])
}
class_g <- function(z, p) ifelse(p < 0.05 & z > 0, "Hot spot", ifelse(p < 0.05 & z < 0,
    "Cold spot", "Not significant"))
static <- function(x, neighbors = nb) {
    w <- nb2listw(neighbors, style = "W")
    lm <- localmoran_perm(x, w, nsim = 9999, iseed = 6262026, no_repeat_in_row = TRUE,
        alternative = "two.sided")
    zz <- as.numeric(scale(x))
    lag <- lag.listw(w, zz)
    p <- getp(lm)
    cl <- ifelse(p < 0.05, ifelse(zz > 0, ifelse(lag > 0, "High–high", "High–low"),
        ifelse(lag > 0, "Low–high", "Low–low")), "Not significant")
    g <- localG_perm(x, nb2listw(include.self(neighbors), style = "W"), nsim = 9999, iseed = 6262026,
        no_repeat_in_row = TRUE, alternative = "two.sided")
    gp <- getp(attr(g, "internals"))
    data.frame(moran_I = lm[, 1], moran_p = p, moran_q = p.adjust(p, "BH"), lisa = cl,
        gi_z = as.numeric(g), gi_p = gp, gi_q = p.adjust(gp, "BH"), hotspot = class_g(as.numeric(g),
            gp))
}
for (metric in c("events", "fatalities")) {
    s <- static(b[[metric]])
    write.csv(cbind(st_drop_geometry(b)[, c("TS_PCODE", "TS", "ST")], s), paste0("results/static-",
        metric, ".csv"), row.names = FALSE)
}
# Space-time Gi*: current and previous month, including self and spatial neighbors.
# The full cube is the reference population. January has only its current slice.
n <- nrow(b)
nt <- length(months)
stnb <- vector("list", n * nt)
for (t in seq_len(nt)) for (i in seq_len(n)) {
    spatial <- sort(unique(c(i, nb[[i]])))
    v <- (t - 1L) * n + spatial
    if (t > 1)
        v <- c(v, (t - 2L) * n + spatial)
    stnb[[(t - 1L) * n + i]] <- as.integer(sort(v))
}
class(stnb) <- "nb"
attr(stnb, "region.id") <- as.character(seq_len(n * nt))
attr(stnb, "sym") <- FALSE
attr(stnb, "self.included") <- TRUE
stlw <- nb2listw(stnb, style = "B")
source("R/classify.R")

for (metric in c("events", "fatalities")) {
    message("Space-time permutations: ", metric)
    g <- localG_perm(cube[[metric]], stlw, nsim = 999, iseed = 6262026, no_repeat_in_row = TRUE,
        alternative = "two.sided")
    gp <- getp(attr(g, "internals"))
    z <- as.numeric(g)
    bins <- cbind(cube[, c("month", "TS_PCODE")], gi_z = z, p = gp, q = p.adjust(gp, "BH"))
    write.csv(bins, paste0("results/space-time-", metric, ".csv"), row.names = FALSE)
    eh <- lapply(seq_len(n), function(i) {
        idx <- seq(i, n * nt, by = n)
        mk <- MannKendall(z[idx])
        tau <- as.numeric(mk$tau)
        mp <- as.numeric(mk$sl)
        data.frame(TS_PCODE = b$TS_PCODE[i], TS = b$TS[i], ST = b$ST[i], tau = tau, mk_p = mp,
            hot_months = sum(gp[idx] < 0.05 & z[idx] > 0), cold_months = sum(gp[idx] <
                0.05 & z[idx] < 0), classification = class_eh(z[idx], gp[idx], tau, mp),
            fdr_classification = class_eh(z[idx], bins$q[idx], tau, mp))
    }) |>
        bind_rows()
    eh$mk_q <- p.adjust(eh$mk_p, "BH")
    write.csv(eh, paste0("results/ehsa-", metric, ".csv"), row.names = FALSE)
}
source("R/reclassify.R")
# Added value: how much conclusions depend on geocoding precision and weights.
prec <- static(b$precise)
knb <- make.sym.nb(knn2nb(knearneigh(cent, k = 4)))
alt <- static(b$events, knb)
base <- read.csv("results/static-events.csv")
write.csv(data.frame(TS_PCODE = b$TS_PCODE, TS = b$TS, baseline = base$hotspot, precise_only = prec$hotspot,
    knn4 = alt$hotspot), "results/robustness.csv", row.names = FALSE)
saveRDS(list(boundaries = b, nb = nb, audit = audit, cube = cube, months = months, precision = table(e$geo_precision)),
    "results/analysis.rds")
writeLines(capture.output(sessionInfo()), "results/session-info.txt")
write.csv(data.frame(file = c("ACLED CSV", "MIMU GeoJSON"), md5 = unname(tools::md5sum(c(raw_path, "data/boundaries/mimu-v9.4.geojson")))), "results/input-checksums.csv", row.names = FALSE)
message("Analysis complete")
