# Bond Valuation Board

Interactive R Shiny application for fixed-income valuation and bond portfolio simulation.

V1 provides two workspaces: **Bond Valuation** and **Portfolio Simulation**. It runs independently and uses project-relative paths on Linux and Windows. The interface takes visual inspiration from the Bond Spread Monitor while keeping its code and data separate.

## Features

- Fixed-rate bond valuation
- Clean / Dirty Price
- Yield to Maturity (YTM)
- Accrued Interest
- Macaulay Duration
- Modified Duration
- DV01
- Convexity
- Interactive Price/Yield visualization
- Cashflow analysis through explicit cashflow generation and discounted present values in the valuation engine
- Multi-bond portfolio simulation with 1–10 positions
- Explicit Long / Short positions
- Equal Weighted and Market Value Weighted portfolios
- Portfolio DV01, including signed and gross contributions
- Parallel yield-shock simulations
- Duration and Duration + Convexity approximations compared with Full Repricing

Cashflows are calculated internally; V1 does not display a cashflow table or offer a cashflow export. The portfolio has its own add/edit form and does not depend on single-bond sidebar inputs.


Limitations

V1 does not support:

- Floating Rate Notes
- Callable Bonds
- OAS
- Credit Spread Models
- Yield Curve Construction
- Key Rate Duration


