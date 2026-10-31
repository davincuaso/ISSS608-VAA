# Two-sided, doubled-tail Monte Carlo p-value, with the observed draw included.
finite_permutation_p <- function(observed, simulations) {
  stopifnot(length(observed) == 1L, is.finite(observed),
            length(simulations) > 0L, all(is.finite(simulations)))
  denominator <- length(simulations) + 1L
  upper <- (1 + sum(simulations >= observed)) / denominator
  lower <- (1 + sum(simulations <= observed)) / denominator
  min(1, 2 * min(upper, lower))
}

aicc_lm <- function(model) {
  n <- stats::nobs(model)
  k <- attr(stats::logLik(model), "df")
  stopifnot(n > k + 1)
  stats::AIC(model) + 2 * k * (k + 1) / (n - k - 1)
}
