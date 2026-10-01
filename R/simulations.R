standard_shocks <- c(-200, -100, -50, -25, -10, 0, 10, 25, 50, 100, 200)
bond_shocks <- function(bond, analysis, shocks = standard_shocks) {
  force(bond); force(analysis)
  if (!is.numeric(shocks) || any(!is.finite(shocks))) stop("Ungültige Zinsschocks.")
  dy <- shocks / 10000
  full <- vapply(dy, function(d) {
    tryCatch(price_bond(bond, analysis$yield + d)$market_value - analysis$market_value,
             error = function(e) NA_real_)
  }, numeric(1))
  duration <- -analysis$market_value * analysis$modified * dy
  convexity <- duration + .5 * analysis$market_value * analysis$convexity * dy^2
  data.frame(shock_bp = shocks, duration_eur = duration, convexity_eur = convexity,
             full_eur = full, duration_pct = duration / analysis$market_value * 100,
             convexity_pct = convexity / analysis$market_value * 100,
             full_pct = full / analysis$market_value * 100)
}
