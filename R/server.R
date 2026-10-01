board_server <- function(input, output, session) {
  safe <- function(expr) {
    expression <- substitute(expr)
    caller <- parent.frame()
    tryCatch(eval(expression, envir = caller), error = function(e) {
      validate(need(FALSE, conditionMessage(e)))
    })
  }
  current_bond <- reactive(safe(new_bond(input$nominal, input$coupon / 100,
    input$settlement, input$maturity, as.numeric(input$frequency), input$bond_name)))
  analysis <- reactive(safe(if (input$direction == "price") analyze_bond(current_bond(), clean_price = input$clean_price)
    else analyze_bond(current_bond(), yield = input$yield / 100)))
  output$bond_kpis <- renderUI(bond_cards(analysis()))
  output$price_curve <- plotly::renderPlotly({
    b <- current_bond(); a <- analysis()
    ys <- seq(max(-b$frequency + .001, a$yield - .03), a$yield + .03, length.out = 81)
    d <- data.frame(yield = ys * 100, price = vapply(ys, function(y) price_bond(b, y)$clean, numeric(1)))
    board_plot(ggplot2::ggplot(d, ggplot2::aes(yield, price)) + ggplot2::geom_line(color = "#1e70cf", linewidth = .8) +
      ggplot2::geom_point(data = data.frame(yield = a$yield * 100, price = a$clean), color = "#e69725", size = 4) +
      ggplot2::labs(title = "Bond Price vs. Yield", x = "YTM (% p.a.)", y = "Clean Price (je 100)"))
  })
  read_demo <- function() read.csv(file.path("data", "demo_portfolio.csv"), stringsAsFactors = FALSE)[, portfolio_columns]
  universe <- reactiveVal(read_demo())
  editing <- reactiveVal(NULL)
  form_error <- reactiveVal(NULL)
  modal_error <- reactiveVal(NULL)
  portfolio <- reactive({ validate(need(nrow(universe()) > 0, "Noch keine Positionen. Bond hinzufügen oder Demoportfolio laden.")); safe(portfolio_from_data(universe(), input$weighting)) })
  open_editor <- function(index = NULL) {
    editing(index); modal_error(NULL)
    d <- universe()
    row <- if (is.null(index)) list(name = "", isin = "", position = "Long", nominal = 100000, coupon = 3,
      clean_price = 100, settlement = if (nrow(d)) d$settlement[1] else "2026-10-01", maturity = "2031-10-01", frequency = 1) else as.list(d[index, ])
    showModal(modalDialog(title = if (is.null(index)) "Bond hinzufügen" else "Bond bearbeiten", size = "l", easyClose = TRUE,
      fluidRow(column(6, textInput("pf_name", "Name / Identifier", row$name), textInput("pf_isin", "ISIN (optional)", row$isin),
        numericInput("pf_nominal", "Nominal (EUR, absolut)", row$nominal, min = 1), numericInput("pf_coupon", "Coupon Rate (% p.a.)", row$coupon, min = 0, max = 100),
        numericInput("pf_clean", "Scenario Clean Price (je 100)", row$clean_price, min = .001)),
        column(6, selectInput("pf_position", "Position", c("Long", "Short"), row$position),
          dateInput("pf_settlement", "Settlement", as.Date(row$settlement)), dateInput("pf_maturity", "Maturity", as.Date(row$maturity)),
          selectInput("pf_frequency", "Coupon Frequency", c("Annual" = 1, "Semi-Annual" = 2, "Quarterly" = 4), row$frequency))),
      uiOutput("portfolio_form_error"),
      footer = tagList(modalButton("Abbrechen"), actionButton("save_bond", if (is.null(index)) "Zum Portfolio hinzufügen" else "Änderungen speichern"))))
  }
  output$portfolio_form_error <- renderUI(if (!is.null(modal_error())) tags$p(class = "error-note", modal_error()))
  observeEvent(input$add_bond, {
    if (nrow(universe()) >= 10) { form_error("Maximal zehn Positionen. Bitte zuerst einen Bond entfernen."); return() }
    open_editor()
  })
  selected_index <- function() {
    i <- input$portfolio_input_rows_selected
    if (length(i) != 1 || !i %in% seq_len(nrow(universe()))) stop("Bitte einen Bond in der Tabelle auswählen.")
    i
  }
  observeEvent(input$edit_bond, tryCatch(open_editor(selected_index()), error = function(e) form_error(conditionMessage(e))))
  observeEvent(input$save_bond, {
    tryCatch({
      row <- data.frame(name = trimws(input$pf_name), isin = trimws(input$pf_isin), position = input$pf_position,
        nominal = input$pf_nominal, coupon = input$pf_coupon, clean_price = input$pf_clean,
        settlement = as.character(input$pf_settlement), maturity = as.character(input$pf_maturity), frequency = as.numeric(input$pf_frequency))
      universe(portfolio_upsert(universe(), row, editing())); form_error(NULL); modal_error(NULL); removeModal()
    }, error = function(e) modal_error(conditionMessage(e)))
  })
  observeEvent(input$remove_bond, tryCatch({
    universe(universe()[-selected_index(), , drop = FALSE]); form_error(NULL)
  }, error = function(e) form_error(conditionMessage(e))))
  observeEvent(input$reset_demo, { universe(read_demo()); form_error(NULL) })
  observeEvent(input$clear_portfolio, { universe(empty_portfolio()); form_error(NULL) })
  output$portfolio_status <- renderUI(tagList(tags$p(class = "note", sprintf("%d / 10 Positionen · Scenario Clean Prices, keine aktuellen Marktpreise", nrow(universe()))),
    if (!is.null(form_error())) tags$p(class = "error-note", form_error())))
  output$weight_note <- renderUI(tags$p(class = "note", if (input$weighting == "equal")
    "Equal Weighted: gleicher absoluter Dirty-Marktwert je Position. Simulierte Nominale werden angepasst; Eingaben bleiben im Bearbeitungsformular erhalten."
    else "Market Value Weighted: Eingabenominale bleiben erhalten. Gewichte = absolute Dirty-Marktwerte / Gross Exposure."))
  output$portfolio_input <- DT::renderDT({
    if (!nrow(universe())) return(DT::datatable(data.frame(Bond = character()), rownames = FALSE, options = list(paging = FALSE, lengthChange = FALSE)))
    table <- DT::datatable(portfolio()$positions, rownames = FALSE, selection = "single", escape = TRUE,
      colnames = c("Bond", "Position", "Nominal (EUR)", "Coupon (%)", "Scenario Clean Price", "YTM (%)", "Settlement", "Maturity", "Frequency", "Market Value (EUR)", "Mod. Duration (Jahre)", "Signed DV01 (EUR/bp)", "Weight (%)", "Convexity (Jahre²)", "ISIN"),
      options = list(paging = FALSE, lengthChange = FALSE, order = list(), scrollX = TRUE,
        columnDefs = list(list(visible = FALSE, targets = c(13, 14)))))
    DT::formatRound(table, c("nominal", "market_value", "dv01"), digits = 2) |>
      DT::formatRound(c("coupon", "clean_price", "yield_pct", "modified", "weight_pct", "convexity"), digits = 3)
  })
  output$bank_sources <- renderUI({
    sources <- read.csv(file.path("data", "demo_portfolio.csv"), stringsAsFactors = FALSE)
    tagList(p(class = "note", "Öffentliche Stammdaten; editierbare Szenariopreise. Bewertet wird die reguläre Festzinsphase bis planmäßige Fälligkeit, ohne Soft-Bullet-Verlängerung oder Geschäftstagsanpassung."),
      tags$ul(lapply(seq_len(nrow(sources)), function(i) tags$li(tags$a(href = sources$source_url[i], target = "_blank", rel = "noopener noreferrer", paste(sources$name[i], "·", sources$isin[i]))))))
  })
  output$portfolio_kpis <- renderUI({
    if (!nrow(universe())) return(NULL)
    p <- portfolio()
    tagList(tags$div(class = "kpi-grid portfolio-kpis",
      kpi("Gross Exposure", fmt(p$gross_value), "EUR · Summe |Dirty Market Value|"),
      kpi("Long Exposure", fmt(p$long_value), "EUR · Long Dirty Market Values"),
      kpi("Short Exposure", fmt(p$short_value), "EUR · |Short Dirty Market Values|"),
      kpi("Net Exposure", fmt(p$market_value), "EUR · Long − Short")),
      tags$div(class = "kpi-grid portfolio-kpis",
        kpi("Portfolio Modified Duration", fmt(p$modified, 2), "Jahre · nach Gross Exposure gewichtet"),
        kpi("Signed Portfolio DV01", fmt(p$dv01), "EUR/bp · Summe signed DV01"),
        kpi("Gross DV01", fmt(p$gross_dv01), "EUR/bp · Summe |Positions-DV01|"),
        kpi("Portfolio Convexity", fmt(p$convexity, 2), "Jahre² · nach Gross Exposure gewichtet")),
      tags$p(class = "note", sprintf("Gross-Exposure-weighted YTM: %s %% · deskriptiver Durchschnitt, keine Portfolio-YTM. Duration und Convexity beschreiben die Bruttozusammensetzung; Hedge-Wirkung: Signed DV01 und Scenario P&L.", fmt(p$yield * 100, 2))))
  })
  portfolio_shock_values <- reactive({
    chosen <- as.numeric(input$portfolio_selected_shocks)
    custom <- input$portfolio_custom_shock
    if (!is.null(custom) && length(custom) == 1 && is.finite(custom)) chosen <- c(chosen, custom)
    chosen <- sort(unique(chosen[is.finite(chosen)]))
    validate(need(length(chosen) > 0, "Mindestens einen Yield Shock auswählen.")); chosen
  })
  portfolio_scenarios <- reactive(safe(portfolio_shocks(portfolio(), portfolio_shock_values())))
  output$portfolio_shocks <- DT::renderDT(board_table(portfolio_scenarios(), shock_labels))
  output$portfolio_plot <- plotly::renderPlotly(shock_plot(portfolio_scenarios(), "Portfolio Scenario P&L"))
  output$portfolio_position_shocks <- DT::renderDT(board_table(portfolio_position_shocks(portfolio(), portfolio_shock_values()), c("Bond", "Position", shock_labels)))
}
