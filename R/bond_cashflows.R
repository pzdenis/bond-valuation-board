coupon_schedule <- function(bond) {
  dates <- bond$maturity
  k <- 1L
  while (tail(dates, 1L) > bond$settlement) {
    dates <- c(dates, shift_months(bond$maturity, -k * 12L / bond$frequency))
    k <- k + 1L
  }
  sort(dates)
}
accrual_info <- function(bond) {
  dates <- coupon_schedule(bond)
  previous <- max(dates[dates <= bond$settlement])
  next_date <- min(dates[dates > bond$settlement])
  fraction <- as.numeric(bond$settlement - previous) / as.numeric(next_date - previous)
  list(previous = previous, next_date = next_date, fraction = fraction,
       accrued = bond$nominal * bond$coupon / bond$frequency * fraction)
}
bond_cashflows <- function(bond) {
  dates <- coupon_schedule(bond)
  dates <- dates[dates > bond$settlement]
  q <- seq_along(dates) - accrual_info(bond)$fraction
  coupon <- rep(bond$nominal * bond$coupon / bond$frequency, length(dates))
  principal <- ifelse(dates == bond$maturity, bond$nominal, 0)
  data.frame(payment_date = dates, coupon = coupon, principal = principal,
             total = coupon + principal, periods = q, time = q / bond$frequency)
}
