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

## Tech Stack

- R
- Shiny
- ggplot2 and Plotly
- DT
- testthat

The pricing and portfolio engines are plain R functions independent of Shiny.

## Installation

Install R and the required packages:

```r
install.packages(c("shiny", "ggplot2", "plotly", "DT", "testthat"))
```

Open R or RStudio in the project directory and start the application:

```r
shiny::runApp(".")
```

Alternatively, from the project directory in a terminal:

```sh
Rscript --vanilla -e 'shiny::runApp(".")'
```

R 4.1 or newer is required for native pipe syntax. The application was tested on Linux/Fedora with R 4.6.1. Native Windows execution and visual browser checks have not been verified. On Linux, package installation may require system development libraries. No external fonts or icons are loaded by the application.

## Usage

**Bond Valuation:** Enter nominal, coupon, settlement, maturity and coupon frequency, then choose Clean Price → YTM or YTM → Price. Eight core KPI cards and the Price/Yield chart update automatically.

**Portfolio Simulation:** Load the demo or clear it and create your own portfolio. Select a table row to edit or remove a bond. Each position has an explicit Long/Short direction and a positive input nominal. All portfolio positions must share a settlement date. Empty portfolios show an instruction rather than numerical results; an eleventh position is rejected with a clear message.

Choose portfolio weighting and yield shocks within the portfolio tab. The chart compares Duration, Duration + Convexity and Full Repricing P&L; an expandable table shows individual position results.

## Methodology

### Discounted cashflow valuation and Price ↔ Yield

V1 models regular fixed-rate bonds with redemption at par, annual, semi-annual or quarterly coupons, and **ACT/ACT ICMA for regular coupon periods**.

The coupon schedule is generated backward from maturity and explicitly includes the previous coupon date. Month-end anchors are preserved. A coupon due on settlement is treated as already paid and excluded from future cashflows; accrued interest is zero on that date.

For face value `N`, annual decimal coupon `c`, frequency `m`, and annual nominal YTM `y` compounded `m` times:

```text
alpha = actual days(previous coupon, settlement)
        / actual days(previous coupon, next coupon)
Accrued Interest = N * c / m * alpha
q_i = i - alpha
 t_i = q_i / m
Discount Factor_i = (1 + y/m)^(-q_i)
PV_i = Cashflow_i * Discount Factor_i
Dirty Market Value = sum(PV_i)
Clean Market Value = Dirty Market Value - Accrued Interest
```

`t_i` measures ICMA coupon years, not ACT/365 calendar years. Quoted prices and accrued interest cards use a **per-100-nominal** basis; cashflows and market values use **EUR**. Thus `sum(PV_i) = Dirty Price / 100 * N`.

Price → Yield uses `uniroot()` with an expanding bracket in `log(1+y/m)` and log-sum-exp pricing to avoid intermediate overflow. YTM must exceed `-m`. Numerically unrepresentable values produce an input error.

A par bond has price 100 when coupon equals YTM on a coupon date. Between coupon dates, fractional-period discounting and linear accrual can produce a small clean-price deviation.

### Duration, Modified Duration, DV01 and Convexity

With `P = Dirty Market Value`:

```text
Macaulay Duration = sum(t_i * PV_i) / P
Modified Duration = Macaulay Duration / (1 + y/m)
DV01 = P * Modified Duration * 0.0001
Convexity = sum(PV_i * q_i * (q_i + 1))
            / (P * m^2 * (1 + y/m)^2)
```

Duration is expressed in years, DV01 in EUR/bp and convexity in years². Single-bond DV01 is the positive local loss sensitivity to a 1 bp yield increase; tests compare it against full repricing.

### Portfolio weighting and KPIs

**Market Value Weighted:** Input nominals remain unchanged. Weights equal absolute dirty market values divided by Gross Exposure.

**Equal Weighted:** Each position receives `1/n` of the original Gross Exposure as its absolute dirty market value. Simulated nominals are adjusted while stored input nominals remain available in the edit form. Five bonds have 20% weights each; their nominals can differ because prices and accrued interest differ. Changing weighting does not change stored inputs.

For absolute dirty market value `V_i`, position sign `s_i = +1` for Long and `-1` for Short, `G = sum(V_i)`, and `w_i = V_i/G`:

| KPI | Definition |
|---|---|
| Gross Exposure | Sum of absolute dirty market values |
| Long Exposure | Sum of Long dirty market values |
| Short Exposure | Absolute market value of Short positions |
| Net Exposure | Long Exposure − Short Exposure |
| Portfolio Modified Duration | `sum(w_i * ModifiedDuration_i)` |
| Signed Portfolio DV01 | `sum(s_i * V_i * ModifiedDuration_i * 0.0001)` |
| Gross DV01 | Sum of absolute position DV01 contributions |
| Portfolio Convexity | `sum(w_i * Convexity_i)` |
| Gross-Exposure-weighted YTM | `sum(w_i * YTM_i)` |

Portfolio duration and convexity describe the **gross composition**, not hedge effectiveness. They remain defined when Net Exposure is zero. Signed DV01 and signed scenario P&L show the hedge effect. The weighted YTM is a descriptive average, not a portfolio yield or the return of a Long/Short trade.

### Parallel yield shocks and full repricing

Standard shocks are −200, −100, −50, −25, −10, 0, +10, +25, +50, +100 and +200 bp, with an additional custom shock. One bp equals `0.0001` decimal yield.

For each position:

```text
Duration P&L = s_i * V_i * (-D_i * dy)
Duration + Convexity P&L = s_i * V_i * (-D_i * dy + 0.5 * C_i * dy^2)
Full Repricing P&L = s_i * [V_i(y_i + dy) - V_i(y_i)]
```

Position P&Ls are summed. Relative portfolio P&L uses Gross Exposure as the denominator. Settlement and cashflows remain unchanged. Unsupported or numerically unrepresentable repricing scenarios appear as NA and are not silently treated as zero.

## Demo Data

The bundled demo contains five EUR covered bonds from **ING Bank N.V.** and **Erste Group Bank AG**. Issuer, ISIN, coupon and maturity come from public information and official final terms. Source links are recorded in `data/demo_portfolio.csv` and displayed in the application.

**Scenario Clean Prices are freely assigned scenario values, not current market prices.** The demo settlement date is 2026-10-01. No Bloomberg or proprietary data is used. Position directions and nominals are educational scenario assumptions.

| Issuer | ISIN | Coupon | Maturity |
|---|---|---:|---|
| ING Bank N.V. | XS1805257265 | 0.875% | 2028-04-11 |
| ING Bank N.V. | XS2744125001 | 2.625% | 2028-01-10 |
| Erste Group Bank AG | AT0000A3HN08 | 3.000% | 2032-04-20 |
| ING Bank N.V. | XS2585966505 | 3.000% | 2033-02-15 |
| Erste Group Bank AG | AT0000A3M7Y2 | 3.100% | 2035-05-28 |

These are covered bank bonds, not unsecured senior bank debt. Only the regular fixed-rate phase through scheduled maturity is modeled. The initial short coupon of AT0000A3HN08 predates the demo settlement; settlement before its first regular annual period is outside the V1 model.

Public issuer references: [ING covered bonds](https://ing.com/investors/fixed-income-information/debt-securities-ing-bank-nv/hard-and-soft-bullet-covered-bonds), [Erste Group covered bond programme](https://www.erstegroup.com/de/ueber-uns/erste-group-emissionen/prospekte/anleihen/cbp16122024).

## Limitations

V1 does not support:

- Floating Rate Notes
- Callable Bonds
- OAS
- Credit Spread Models
- Yield Curve Construction
- Key Rate Duration

Additional boundaries:

- ACT/365 Fixed, 30/360 and ACT/ACT ISDA are not implemented.
- No irregular first/last coupon periods, issue-date model, business-day adjustments, holiday calendars, ex-coupon rules or settlement-lag model.
- No soft-bullet maturity extension or subsequent floating-rate phase.
- Maximum remaining maturity: 100 years. Positive nominal and clean price are required; coupon input is limited to 0–100%.
- No financing, repo, securities-lending costs, margin or ongoing Short coupon payments in immediate shock P&L.
- No live market-data feed or proprietary pricing-system certification.

## Tests

Run the complete suite from the project directory:

```sh
Rscript --vanilla tests/testthat.R
```

Tests cover independent pricing examples, all coupon frequencies, negative yields, price/yield round trips, accrued-interest identities, coupon settlement boundaries, month ends and leap years, numerical duration/convexity derivatives, DV01 repricing, weighting, signed exposures, portfolio P&L aggregation and hedged Long/Short pairs.

Shiny server tests cover independent portfolio forms, adding up to ten positions, rejection of an eleventh, edit/remove/clear/reload actions, two-tab navigation, eight single-bond KPIs and independence from invalid sidebar inputs.

## Project Structure

```text
app.R                 Shiny entry point
R/                    Pricing, analytics, portfolio, UI and server modules
data/demo_portfolio.csv  Public bond terms and scenario inputs
www/styles.css        Shared visual styling
tests/testthat.R      Test runner
tests/testthat/       Calculation and reactive regression tests
```

Methodology references: [Bond prices and accrued interest](https://www.mathworks.com/help/finance/bndprice.html), [Yield from clean price](https://www.mathworks.com/help/finance/bndyield.html), [Duration and convexity sensitivity](https://de.mathworks.com/help/finance/sensitivity-of-bond-prices-to-interest-rates.html).
