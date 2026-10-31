# Synthetic unit fixtures only; these are never used as the exercise data.
# Run from the exercise folder: Rscript scripts/test_helpers.R
source("scripts/analysis_helpers.R")
stopifnot(
  finite_permutation_p(10, 1:9) == 0.2,
  finite_permutation_p(0, 1:9) == 0.2,
  finite_permutation_p(5, rep(5, 9)) == 1,
  finite_permutation_p(10, rep(0, 499)) == 0.004
)
x <- seq_len(30)
fit <- lm((x + sin(x)) ~ x)
n <- nobs(fit)
p <- length(coef(fit))
rss <- sum(residuals(fit)^2)
gwr_book_aicc <- n * log(rss / n) + n * log(2 * pi) + n * (n + p) / (n - p - 2)
stopifnot(abs(aicc_lm(fit) - gwr_book_aicc) < 1e-10)
cat("PASS: finite permutation tails, ties, simulation resolution and comparable Gaussian AICc.\n")
