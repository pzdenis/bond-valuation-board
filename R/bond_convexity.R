bond_convexity <- function(bond, valuation) {
  cf <- valuation$cashflows
  sum(cf$present_value * cf$periods * (cf$periods + 1)) /
    (valuation$market_value * bond$frequency^2 * (1 + valuation$yield / bond$frequency)^2)
}
