# Start from this project directory: shiny::runApp(".")
required <- c("shiny", "ggplot2", "plotly", "DT")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Bitte zuerst Pakete installieren: ", paste(missing, collapse = ", "))
library(shiny)
for (module in c("helpers", "bond_cashflows", "bond_pricing", "bond_yield", "bond_duration",
                 "bond_convexity", "bond_risk", "simulations", "portfolio", "presentation", "ui", "server"))
  source(file.path("R", paste0(module, ".R")), local = TRUE, encoding = "UTF-8")
shinyApp(ui = board_ui(), server = board_server)
