bond_duration <- function(bond, valuation) {
  cf <- valuation$cashflows
  macaulay <- sum(cf$time * cf$present_value) / valuation$market_value
  list(macaulay = macaulay, modified = macaulay / (1 + valuation$yield / bond$frequency))
}
