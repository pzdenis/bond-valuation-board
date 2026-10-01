yield_from_price <- function(bond, clean_price) {
  assert_number(clean_price, "Clean Price", .Machine$double.eps)
  target <- clean_price / 100 * bond$nominal + accrual_info(bond)$accrued
  cf <- bond_cashflows(bond)
  # Solve in log(1+y/m); log-sum-exp avoids overflow near the yield boundary.
  log_price <- function(z) {
    terms <- log(cf$total) - cf$periods * z
    largest <- max(terms)
    largest + log(sum(exp(terms - largest)))
  }
  f <- function(z) log_price(z) - log(target)
  lo <- -1; hi <- 1
  while (f(lo) < 0 && abs(lo) < 1024) lo <- lo * 2
  while (f(hi) > 0 && hi < 1024) hi <- hi * 2
  z <- uniroot(f, c(lo, hi), tol = 1e-12)$root
  y <- bond$frequency * expm1(z)
  if (!is.finite(y) || 1 + y / bond$frequency <= 0) stop("YTM außerhalb des numerisch darstellbaren Bereichs.")
  y
}
