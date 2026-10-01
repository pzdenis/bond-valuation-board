for (f in c("helpers", "bond_cashflows", "bond_pricing", "bond_yield", "bond_duration", "bond_convexity", "bond_risk", "simulations", "portfolio")) source(file.path("R", paste0(f, ".R")))
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
