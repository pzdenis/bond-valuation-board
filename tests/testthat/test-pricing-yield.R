testthat::test_that("par and independently calculated annual price are correct", {
  for (m in c(1, 2, 4)) {
    b <- new_bond(1000, .04, "2026-01-01", "2031-01-01", m)
    testthat::expect_equal(price_bond(b, .04)$clean, 100, tolerance = 1e-10)
  }
  b <- new_bond(100, .05, "2026-01-01", "2028-01-01", 1)
  testthat::expect_equal(price_bond(b, .04)$dirty, 5 / 1.04 + 105 / 1.04^2)
})
testthat::test_that("yield inversion, monotonicity and accrued identity hold", {
  for (m in c(1, 2, 4)) {
    b <- new_bond(200000, .03, "2026-04-15", "2035-01-01", m)
    for (y in c(-.02, 0, .03, .15)) {
      a <- price_bond(b, y)
      testthat::expect_equal(yield_from_price(b, a$clean), y, tolerance = 1e-9)
      testthat::expect_equal(a$clean + a$accrued, a$dirty)
      testthat::expect_equal(sum(a$cashflows$present_value), a$market_value)
    }
    testthat::expect_gt(price_bond(b, .02)$dirty, price_bond(b, .03)$dirty)
    testthat::expect_gt(price_bond(b, .03)$dirty, price_bond(b, .04)$dirty)
    testthat::expect_gt(accrual_info(b)$accrued, 0)
    testthat::expect_error(price_bond(b, -m))
    testthat::expect_error(yield_from_price(b, -1))
  }
})
