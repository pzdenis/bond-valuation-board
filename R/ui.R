board_ui <- function() shiny::fluidPage(
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
  tags$header(tags$h1("Bond-Valuation-Board"), tags$p("Fixed Income · Bond Valuation und Portfolio Simulation")),
  sidebarLayout(
    sidebarPanel(width = 3,
      h3("Bond Input"), textInput("bond_name", "Name / Identifier", "Demo Fixed Rate"),
      numericInput("nominal", "Nominal (EUR)", 100000, min = 1),
      numericInput("coupon", "Coupon Rate (% p.a.)", 4, min = 0, max = 100, step = .125),
      dateInput("settlement", "Settlement", value = "2026-10-01"),
      dateInput("maturity", "Maturity", value = "2032-04-01"),
      selectInput("frequency", "Coupon Frequency", c("Annual" = 1, "Semi-Annual" = 2, "Quarterly" = 4), selected = 2),
      radioButtons("direction", "Bewertungsrichtung", c("Clean Price → YTM" = "price", "YTM → Price" = "yield")),
      conditionalPanel("input.direction == 'price'", numericInput("clean_price", "Clean Price (je 100)", 98.5, min = .001, step = .1)),
      conditionalPanel("input.direction == 'yield'", numericInput("yield", "YTM (% p.a.)", 4.3, step = .1)),
      tags$div(class = "glass-box note", strong("ACT/ACT ICMA"), p("Reguläre Kuponperioden. Keine Geschäftstagsanpassung oder Ex-Kupon-Regel."), p("YTM: nominale Jahresrendite mit kuponfrequenter Verzinsung."))),
    mainPanel(width = 9,
      tabsetPanel(id = "page",
        tabPanel("Bond Valuation", uiOutput("bond_kpis"),
          tags$div(class = "glass-box", plotly::plotlyOutput("price_curve", height = "360px"))),
        tabPanel("Portfolio Simulation",
          tags$div(class = "glass-box", h3("Portfolio Lab"),
            tags$div(class = "portfolio-toolbar",
              selectInput("weighting", "Weighting", c("Market Value Weighted" = "market", "Equal Weighted" = "equal")),
              actionButton("add_bond", "Bond hinzufügen"), actionButton("edit_bond", "Bond bearbeiten"),
              actionButton("remove_bond", "Bond entfernen"), actionButton("reset_demo", "Demoportfolio laden"),
              actionButton("clear_portfolio", "Portfolio leeren")),
            uiOutput("portfolio_status"), uiOutput("weight_note"), DT::DTOutput("portfolio_input"),
            tags$details(tags$summary("Demoportfolio: Stammdaten und Quellen"), uiOutput("bank_sources"))),
          uiOutput("portfolio_kpis"),
          tags$div(class = "glass-box", h3("Yield Shock / Scenario P&L"),
            fluidRow(column(8, selectizeInput("portfolio_selected_shocks", "Yield Shocks (bp)",
              choices = standard_shocks, selected = standard_shocks, multiple = TRUE)),
              column(4, numericInput("portfolio_custom_shock", "Custom Yield Shock (bp)", 75, min = -10000, max = 10000, step = 1))),
            plotly::plotlyOutput("portfolio_plot"), DT::DTOutput("portfolio_shocks"),
            p(class = "note", "P&L (%) bezieht sich auf Gross Exposure. Nicht berechenbare Szenarien: NA. Finanzierung und Wertpapierleihe werden nicht modelliert."),
            tags$details(tags$summary("Scenario P&L je Bond"), DT::DTOutput("portfolio_position_shocks")))
        )
      )
    )
  ),
  tags$footer("Lern- und Analysewerkzeug mit Szenariopreisen · V1: reguläre Fixed-Rate-Bonds · EUR")
)
