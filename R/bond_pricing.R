price_bond <- function(bond, yield) {
  assert_number(yield, "YTM")
  base <- 1 + yield / bond$frequency
  if (base <= 0) stop("YTM muss größer als minus Kuponfrequenz sein.")
  cf <- bond_cashflows(bond)
  cf$discount_factor <- exp(-cf$periods * log(base))
  cf$present_value <- cf$total * cf$discount_factor
  dirty_value <- sum(cf$present_value)
  if (!is.finite(dirty_value) || dirty_value <= 0) stop("Preis außerhalb des numerisch darstellbaren Bereichs.")
  ai <- accrual_info(bond)$accrued
  list(yield = yield, dirty = dirty_value / bond$nominal * 100,
       clean = (dirty_value - ai) / bond$nominal * 100,
       accrued = ai / bond$nominal * 100, market_value = dirty_value, cashflows = cf)
}
