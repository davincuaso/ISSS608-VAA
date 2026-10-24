# Synthetic unit tests only. These are not the Taichung teaching data.
source("scripts/trade_areas.R")

shares <- data.frame(
  VILLCODE = c("v3", "v1", "v2"),
  C = c(1, .1, .1), B = c(0, .8, .45), A = c(0, .1, .45)
)
areas <- dominant_trade_areas(shares, c("B", "C", "A"))
stopifnot(
  identical(areas$VILLCODE, c("v1", "v2", "v3")),
  identical(areas$TA, c("B", "A", "C")),
  identical(areas$Tied_stores, c(1L, 2L, 1L)),
  abs(areas$Probability_gap[2]) < 1e-15,
  identical(areas, dominant_trade_areas(
    shares[c(3, 1, 2), c("A", "VILLCODE", "B", "C")], c("C", "A", "B")
  ))
)

must_fail <- function(expr) {
  stopifnot(inherits(tryCatch(force(expr), error = identity), "error"))
}
bad_sum <- shares
bad_sum$A[1] <- .1
must_fail(dominant_trade_areas(bad_sum, c("A", "B", "C")))
missing <- shares
missing$B[2] <- NA_real_
must_fail(dominant_trade_areas(missing, c("A", "B", "C")))
negative <- shares
negative$A[2] <- -.1
must_fail(dominant_trade_areas(negative, c("A", "B", "C")))
must_fail(dominant_trade_areas(shares[c(1, 1), ], c("A", "B", "C")))
must_fail(dominant_trade_areas(shares, c("A", "B", "missing")))
must_fail(dominant_trade_areas(shares, c("A", "A", "C")))
must_fail(dominant_trade_areas(shares, c("A", "B", "C"), tolerance = NA_real_))

# A single-store system allocates probability one to that store.
single <- dominant_trade_areas(data.frame(VILLCODE = "x", BT = 1), "BT")
stopifnot(single$TA == "BT", single$Tied_stores == 1L,
          is.na(single$Second_probability), is.na(single$Probability_gap))
cat("PASS: winner labels, ID alignment, ties, missing values, invalid shares,",
    "duplicate keys and single-store case. Synthetic fixtures only.\n")
