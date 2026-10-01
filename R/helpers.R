assert_number <- function(x, label, lower = -Inf, upper = Inf) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x) || x < lower || x > upper)
    stop(paste(label, "ist ungültig."), call. = FALSE)
  x
}
new_bond <- function(nominal, coupon, settlement, maturity, frequency = 2L, name = "Bond") {
  assert_number(nominal, "Nominal", .Machine$double.eps)
  assert_number(coupon, "Kupon", 0, 1)
  if (length(frequency) != 1L || !frequency %in% c(1, 2, 4)) stop("Frequenz muss 1, 2 oder 4 sein.")
  settlement <- as.Date(settlement); maturity <- as.Date(maturity)
  if (length(settlement) != 1L || length(maturity) != 1L || is.na(settlement) || is.na(maturity) || settlement >= maturity)
    stop("Settlement muss vor Fälligkeit liegen.")
  if (as.numeric(maturity - settlement) > 36525) stop("Maximale Restlaufzeit: 100 Jahre.")
  list(nominal = nominal, coupon = coupon, settlement = settlement, maturity = maturity,
       frequency = frequency, name = as.character(name), convention = "ACT/ACT ICMA (regulär)")
}
# Each date is anchored to maturity, avoiding cumulative February truncation.
shift_months <- function(date, months) {
  date <- as.Date(date)
  index <- as.integer(format(date, "%Y")) * 12L + as.integer(format(date, "%m")) - 1L + months
  first <- as.Date(sprintf("%04d-%02d-01", index %/% 12L, index %% 12L + 1L))
  next_index <- index + 1L
  next_first <- as.Date(sprintf("%04d-%02d-01", next_index %/% 12L, next_index %% 12L + 1L))
  original_first <- as.Date(format(date, "%Y-%m-01"))
  original_next <- seq(original_first, by = "month", length.out = 2L)[2L]
  eom <- date == original_next - 1L
  day <- if (eom) as.integer(next_first - first) else min(as.integer(format(date, "%d")), as.integer(next_first - first))
  first + day - 1L
}
