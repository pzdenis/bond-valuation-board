fmt <- function(x, digits = 2) formatC(x, digits = digits, format = "f", big.mark = ".", decimal.mark = ",")
kpi <- function(label, value, unit) tags$div(class = "glass-box kpi", tags$div(class = "kpi-label", label), tags$strong(value), tags$div(class = "unit", unit))
bond_cards <- function(a) tags$div(class = "kpi-grid bond-kpis",
  kpi("YTM", fmt(a$yield * 100, 3), "% p.a."), kpi("Clean Price", fmt(a$clean, 4), "je 100 Nominal"),
  kpi("Dirty Price", fmt(a$dirty, 4), "je 100 Nominal"), kpi("Accrued Interest", fmt(a$accrued, 4), "je 100 Nominal"),
  kpi("Macaulay Duration", fmt(a$macaulay, 3), "Jahre"), kpi("Modified Duration", fmt(a$modified, 3), "Jahre"),
  kpi("DV01", fmt(a$dv01), "EUR / bp"), kpi("Convexity", fmt(a$convexity, 3), "Jahre²"))
board_table <- function(data, labels = names(data), digits = 4) {
  force(data)
  table <- DT::datatable(data, rownames = FALSE, colnames = labels,
    options = list(paging = FALSE, lengthChange = FALSE, scrollX = TRUE, autoWidth = TRUE), escape = TRUE)
  numeric_cols <- names(data)[vapply(data, is.numeric, logical(1))]
  if (length(numeric_cols)) table <- DT::formatRound(table, numeric_cols, digits = digits)
  table
}
board_plot <- function(p) plotly::ggplotly(p + ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(plot.title = ggplot2::element_text(color = "#003366", face = "bold"),
                 panel.grid.minor = ggplot2::element_blank()), tooltip = c("x", "y", "colour"))
shock_plot <- function(table, title) {
  long <- rbind(data.frame(shock = table$shock_bp, pnl = table$duration_eur, method = "Duration"),
    data.frame(shock = table$shock_bp, pnl = table$convexity_eur, method = "Duration + Convexity"),
    data.frame(shock = table$shock_bp, pnl = table$full_eur, method = "Full Repricing"))
  board_plot(ggplot2::ggplot(long, ggplot2::aes(shock, pnl, color = method)) +
    ggplot2::geom_hline(yintercept = 0, color = "#819cd6") + ggplot2::geom_line(na.rm = TRUE) + ggplot2::geom_point(na.rm = TRUE) +
    ggplot2::scale_color_manual(values = c("Duration" = "#9560ad", "Duration + Convexity" = "#e69725", "Full Repricing" = "#1e70cf")) +
    ggplot2::labs(title = title, x = "Paralleler Yield-Schock (bp)", y = "P&L (EUR)", color = NULL))
}
shock_labels <- c("Shock (bp)", "Duration P&L (EUR)", "Duration + Convexity P&L (EUR)",
  "Full Repricing P&L (EUR)", "Duration P&L (%)", "Duration + Convexity P&L (%)", "Full Repricing P&L (%)")
