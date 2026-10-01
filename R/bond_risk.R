analyze_bond <- function(bond, yield = NULL, clean_price = NULL) {
  if (is.null(yield) == is.null(clean_price)) stop("Genau einen Preis oder eine YTM angeben.")
  if (is.null(yield)) yield <- yield_from_price(bond, clean_price)
  valuation <- price_bond(bond, yield)
  duration <- bond_duration(bond, valuation)
  convexity <- bond_convexity(bond, valuation)
  c(valuation, duration, list(convexity = convexity,
    dv01 = valuation$market_value * duration$modified * .0001))
}
