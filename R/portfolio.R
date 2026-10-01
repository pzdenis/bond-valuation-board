portfolio_columns <- c("name", "isin", "position", "nominal", "coupon", "clean_price", "settlement", "maturity", "frequency")
empty_portfolio <- function() data.frame(name = character(), isin = character(), position = character(), nominal = numeric(), coupon = numeric(), clean_price = numeric(), settlement = character(), maturity = character(), frequency = numeric())
validate_portfolio_data <- function(data, allow_empty = FALSE) {
  if (!all(portfolio_columns %in% names(data))) stop("Unvollständige Portfolio-Eingabe.")
  if (nrow(data) > 10 || (!allow_empty && nrow(data) < 1)) stop("Portfolio benötigt 1 bis 10 Bonds.")
  if (!nrow(data)) return(invisible(data))
  if (anyNA(data$position) || any(!data$position %in% c("Long", "Short"))) stop("Position muss Long oder Short sein.")
  if (anyNA(data$name) || any(!nzchar(trimws(data$name)))) stop("Bond Name ist erforderlich.")
  dates <- as.Date(data$settlement)
  if (anyNA(dates) || length(unique(dates)) != 1) stop("Portfolio benötigt ein gemeinsames Settlement.")
  for (i in seq_len(nrow(data))) {
    new_bond(data$nominal[i], data$coupon[i] / 100, data$settlement[i], data$maturity[i], data$frequency[i], data$name[i])
    assert_number(data$clean_price[i], "Scenario Clean Price", .Machine$double.eps)
  }
  invisible(data)
}
portfolio_upsert <- function(data, row, index = NULL) {
  if (nrow(row) != 1) stop("Genau eine Position angeben.")
  row <- row[, portfolio_columns, drop = FALSE]
  if (is.null(index)) {
    if (nrow(data) >= 10) stop("Maximal zehn Positionen. Bitte zuerst einen Bond entfernen.")
    candidate <- rbind(data[, portfolio_columns, drop = FALSE], row)
  } else {
    if (length(index) != 1 || !index %in% seq_len(nrow(data))) stop("Bitte einen Bond auswählen.")
    candidate <- data[, portfolio_columns, drop = FALSE]; candidate[index, ] <- row
  }
  validate_portfolio_data(candidate)
  # Inversion validates that all positions are actually numerically priceable.
  portfolio_from_data(candidate, "market")
  candidate
}
portfolio_from_data <- function(data, weighting = "market") {
  if (!weighting %in% c("equal", "market")) stop("Unbekannte Gewichtung.")
  validate_portfolio_data(data)
  bonds <- lapply(seq_len(nrow(data)), function(i) new_bond(data$nominal[i], data$coupon[i] / 100,
    data$settlement[i], data$maturity[i], data$frequency[i], data$name[i]))
  analyses <- lapply(seq_along(bonds), function(i) analyze_bond(bonds[[i]], clean_price = data$clean_price[i]))
  original_mv <- vapply(analyses, function(a) a$market_value, numeric(1))
  target <- if (weighting == "equal") rep(sum(original_mv) / length(bonds), length(bonds)) else original_mv
  for (i in seq_along(bonds)) {
    bonds[[i]]$nominal <- data$nominal[i] * target[i] / original_mv[i]
    analyses[[i]] <- analyze_bond(bonds[[i]], yield = analyses[[i]]$yield)
  }
  metric <- function(key) vapply(analyses, function(a) a[[key]], numeric(1))
  signs <- ifelse(data$position == "Long", 1, -1)
  mv <- metric("market_value"); gross <- sum(mv); weights <- mv / gross
  signed_mv <- signs * mv
  positions <- data.frame(name = data$name, position = data$position, nominal = vapply(bonds, function(b) b$nominal, numeric(1)),
    coupon = data$coupon, clean_price = metric("clean"), yield_pct = metric("yield") * 100,
    settlement = data$settlement, maturity = data$maturity, frequency = data$frequency,
    market_value = signed_mv, modified = metric("modified"), dv01 = signs * metric("dv01"),
    weight_pct = weights * 100, convexity = metric("convexity"), isin = data$isin)
  list(bonds = bonds, analyses = analyses, signs = signs, positions = positions, weighting = weighting,
    gross_value = gross, long_value = sum(mv[signs > 0]), short_value = sum(mv[signs < 0]), market_value = sum(signed_mv),
    yield = sum(weights * metric("yield")), modified = sum(weights * metric("modified")),
    convexity = sum(weights * metric("convexity")), dv01 = sum(signs * metric("dv01")), gross_dv01 = sum(metric("dv01")))
}
portfolio_position_shocks <- function(portfolio, shocks = standard_shocks) {
  do.call(rbind, lapply(seq_along(portfolio$bonds), function(i) {
    table <- bond_shocks(portfolio$bonds[[i]], portfolio$analyses[[i]], shocks)
    for (key in setdiff(names(table), "shock_bp")) table[[key]] <- portfolio$signs[i] * table[[key]]
    data.frame(bond = portfolio$positions$name[i], position = portfolio$positions$position[i], table)
  }))
}
portfolio_shocks <- function(portfolio, shocks = standard_shocks) {
  tables <- lapply(seq_along(portfolio$bonds), function(i) bond_shocks(portfolio$bonds[[i]], portfolio$analyses[[i]], shocks))
  result <- tables[[1]]
  for (key in c("duration_eur", "convexity_eur", "full_eur"))
    result[[key]] <- Reduce(`+`, lapply(seq_along(tables), function(i) portfolio$signs[i] * tables[[i]][[key]]))
  for (method in c("duration", "convexity", "full"))
    result[[paste0(method, "_pct")]] <- result[[paste0(method, "_eur")]] / portfolio$gross_value * 100
  result
}
