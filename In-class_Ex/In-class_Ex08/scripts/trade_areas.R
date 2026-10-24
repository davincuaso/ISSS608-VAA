# Derive a categorical trade-area summary from an existing Huff share matrix.
# This function does not estimate or replace the underlying probabilities.
dominant_trade_areas <- function(share_wide, store_codes,
                                id_column = "VILLCODE",
                                tolerance = 1e-10,
                                tie_tolerance = 1e-12) {
  if (!is.data.frame(share_wide) || nrow(share_wide) == 0L) {
    stop("share_wide must be a nonempty data.frame.")
  }
  if (!is.numeric(tolerance) || length(tolerance) != 1L ||
      !is.finite(tolerance) || tolerance <= 0 ||
      !is.numeric(tie_tolerance) || length(tie_tolerance) != 1L ||
      !is.finite(tie_tolerance) || tie_tolerance < 0) {
    stop("Supply finite, nonnegative tie tolerance and positive sum tolerance.")
  }
  store_codes <- as.character(store_codes)
  if (!length(store_codes) || anyNA(store_codes) ||
      any(!nzchar(store_codes)) || anyDuplicated(store_codes)) {
    stop("Store codes must be present, nonempty and unique.")
  }
  store_codes <- sort(store_codes)
  required <- c(id_column, store_codes)
  if (anyDuplicated(names(share_wide)) ||
      !all(required %in% names(share_wide))) {
    stop("The share table must contain the ID and each named store column once.")
  }
  origin_id <- as.character(share_wide[[id_column]])
  if (anyNA(origin_id) || any(!nzchar(origin_id)) || anyDuplicated(origin_id)) {
    stop("Origin IDs must be present, nonempty and unique.")
  }
  if (!all(vapply(share_wide[store_codes], is.numeric, logical(1)))) {
    stop("Every store probability column must be numeric.")
  }
  probabilities <- as.matrix(share_wide[store_codes])
  if (any(!is.finite(probabilities)) ||
      any(probabilities < 0 | probabilities > 1)) {
    stop("Huff probabilities must be finite and within [0, 1].")
  }
  if (any(abs(rowSums(probabilities) - 1) > tolerance)) {
    stop("The probabilities across stores must sum to one for each origin.")
  }
  maximum <- apply(probabilities, 1, max)
  tied <- abs(sweep(probabilities, 1, maximum, "-")) <= tie_tolerance
  # In a tie, select the first actual store code in lexical order.
  winner <- max.col(tied * 1, ties.method = "first")
  runner_up <- if (length(store_codes) > 1L) {
    apply(probabilities, 1, function(x) sort(x, decreasing = TRUE)[2])
  } else {
    rep(NA_real_, nrow(probabilities))
  }
  result <- data.frame(
    origin_id, TA = store_codes[winner], Max_probability = maximum,
    Second_probability = runner_up,
    Probability_gap = maximum - runner_up,
    Tied_stores = as.integer(rowSums(tied)),
    stringsAsFactors = FALSE
  )
  names(result)[1] <- id_column
  result <- result[order(result[[id_column]]), , drop = FALSE]
  rownames(result) <- NULL
  result
}
