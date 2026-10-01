testthat::test_that("duration and convexity agree with independent numerical derivatives", {
  b <- new_bond(100000, .04, "2026-04-01", "2036-01-01", 2)
  a <- analyze_bond(b, yield = .035)
  h <- 1e-5
  low <- price_bond(b, a$yield - h)$market_value
  high <- price_bond(b, a$yield + h)$market_value
  testthat::expect_equal(a$modified, (low - high) / (2 * h * a$market_value), tolerance = 1e-7)
  testthat::expect_equal(a$convexity, (high + low - 2 * a$market_value) / (h^2 * a$market_value), tolerance = 1e-5)
  repricing_loss <- a$market_value - price_bond(b, .0351)$market_value
  testthat::expect_lt(abs(a$dv01 / repricing_loss - 1), .002)
  short <- new_bond(100000, .04, "2026-04-01", "2028-01-01", 2)
  testthat::expect_gt(a$macaulay, analyze_bond(short, yield = .035)$macaulay)
  s <- bond_shocks(b, a, c(-100, 0, 100))
  testthat::expect_true(all(abs(s$convexity_eur[c(1, 3)] - s$full_eur[c(1, 3)]) < abs(s$duration_eur[c(1, 3)] - s$full_eur[c(1, 3)])))
  testthat::expect_equal(s$full_eur[2], 0)
})
