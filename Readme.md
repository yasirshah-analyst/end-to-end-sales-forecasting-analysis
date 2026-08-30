# Walmart Sales Forecast: Trend, Seasonality & Holiday Impact

A sales forecasting project built with SQL (PostgreSQL), Excel, and Power BI, examining historical Walmart weekly sales data to forecast near-term revenue and identify the key drivers behind seasonal fluctuations.

---

## Business Question

> What will total company-wide weekly sales look like over the next 3 months, and how much of that pattern is driven by holiday periods?

This question guided every stage of the project — from the SQL analysis used to understand historical patterns, to the choice of forecasting method, to the KPIs featured on the final dashboard.

---

## Data Source & License

**Dataset**: Walmart Weekly Sales (2010–2012)
**Source**: [Kaggle — Walmart Dataset](https://www.kaggle.com/datasets/yasserh/walmart-dataset)
**License**: CC0: Public Domain
**Size**: 6,435 rows, 45 stores, weekly sales from February 2010 to November 2012 (~2.7 years)

**Columns**: Store, Date, Weekly_Sales, Holiday_Flag, Temperature, Fuel_Price, CPI, Unemployment

The raw CSV is not included in this repository per standard practice for third-party datasets — download it directly from the Kaggle link above to reproduce this project. Data was loaded into a PostgreSQL database for cleaning, validation, and analysis.

---

## Repository Structure

```
├── README.md
├── sql/
│   ├── 01_data_cleaning.sql
│   ├── 02_monthly_trend.sql
│   ├── 03_holiday_vs_nonholiday.sql
│   ├── 04_holiday_breakdown_by_date.sql
│   └── 05_year_over_year.sql
├── excel/
│   └── walmart_forecast.xlsx        (FORECAST.ETS, confidence intervals, backtest)
├── dashboard/
│   └── walmart_sales_dashboard.pbix
└── images/
    └── dashboard_screenshot.png
```

Full SQL scripts and the Excel/Power BI files are included above for anyone who wants to verify or extend the analysis. The sections below summarize the approach and results; they're not a full step-by-step log.

---

## Dashboard

![Dashboard Screenshot](images/dashboard_screenshot.png)

*(Add your dashboard screenshot to `images/dashboard_screenshot.png` — this is usually the first thing people look at, so it's worth having front and center.)*

---

## Methodology

### 1. Data Loading & Cleaning (SQL)
- Loaded raw CSV into PostgreSQL, converting mixed date formats (`DD-MM-YYYY` with inconsistent separators) into proper `DATE` types.
- Added a composite primary key (`store`, `sale_date`) to enforce uniqueness.
- Verified data quality: zero missing values, zero impossible values (negative sales, out-of-range percentages), and confirmed all 45 stores had complete, even history (143 weeks each).

### 2. Exploratory & Business-Question SQL Analysis
- Calculated monthly sales trends across the full time range.
- Compared average sales on holiday vs. non-holiday weeks.
- Broke down sales by individual holiday date to identify which specific holidays drive the effect.
- Ran a year-over-year comparison to confirm which monthly patterns are genuinely seasonal (repeat every year) vs. noise (don't repeat consistently).
- Identified top 5 and bottom 5 performing stores by average weekly sales.

### 3. Forecasting (Two independent methods, for comparison)
- **Excel**: `FORECAST.ETS()` with explicit 12-month seasonality, plus `FORECAST.ETS.CONFINT()` for a 95% confidence interval.
- **Power BI**: built-in forecast visual (Analytics pane), same 3-month horizon and seasonality setting, for cross-validation against the Excel result.

### 4. Accuracy Validation (Backtesting)
- Held out the last 3 known months (Aug–Oct 2012) from the training data.
- Forecasted those months using only prior history, then compared forecasted vs. actual values.
- Calculated Mean Absolute Percentage Error (MAPE) to quantify forecast reliability.

### 5. Dashboard (Power BI)
- KPI cards: Total Sales, Excel Forecast (Dec 2012), Forecast Accuracy (MAPE).
- Line chart: historical monthly trend with 3-month forecast and confidence band.
- Bar chart: average weekly sales, holiday vs. non-holiday weeks.

---

## A Closer Look: The Holiday Finding

This was the sharpest insight in the project, so it's worth showing the actual query behind it rather than just the conclusion.

Averaging all holiday weeks together gave a modest 7.8% lift — too small to explain the ~50% December spike seen in the monthly trend. Breaking the average back apart by individual holiday date revealed why:

```sql
SELECT
    sale_date,
    AVG(weekly_sales) AS avg_sales
FROM weekly_sales
WHERE holiday_flag = true
GROUP BY sale_date
ORDER BY sale_date;
```

This showed Thanksgiving week averaging ~$1.46M–$1.48M (a ~40% spike), while Super Bowl and Labor Day were only marginally above the $1.04M non-holiday baseline — and the flagged "Christmas" date (Dec 31) was actually *below* average, since it lands after the real shopping rush. See `sql/04_holiday_breakdown_by_date.sql` for the full script and `sql/03_holiday_vs_nonholiday.sql` for the initial blended comparison.

---

## Key Findings

**1. Sales show a strong, consistent seasonal pattern — but only for December and January.**
December peaked at $288.76M (2010) and $288.08M (2011) — nearly identical, and dramatically above every other month both years. January was consistently the lowest month immediately after ($163.70M in 2011, $168.89M in 2012). Other mid-year months fluctuated without a consistent year-over-year direction, so they weren't treated as seasonal.

**2. The "holiday" effect is real but concentrated almost entirely in Thanksgiving week.**
Averaged across all flagged holidays, the lift was only 7.8% ($1,122,888 vs. $1,041,256 per week). Breaking this down by individual holiday showed why: Thanksgiving week alone shows a ~40% spike, while Super Bowl and Labor Day are only marginally above average. The dataset's "Christmas" flag is placed on December 31st — after the shopping rush — so it doesn't capture the real holiday surge, and the blended average understates Thanksgiving's true impact.

**3. The forecast correctly reproduced the seasonal pattern, with moderate accuracy.**
December 2012 was forecasted at $293.75M (95% CI: $253.6M–$333.9M) via Excel, closely matching real December 2010/2011 totals. Power BI's independent forecast produced a similar peak (~$290M), cross-validating the result across two tools. Backtesting on 3 held-out months produced a MAPE of 14.4% — accuracy was weaker specifically on non-seasonal mid-year months.

---

## Recommendations

- Plan inventory and staffing for a substantial December surge (historically 40–50% above baseline months) and a corresponding January drop-off.
- Target Thanksgiving week specifically — not "holidays" broadly — for promotional and staffing planning, as it's the single strongest short-term driver identified.
- Treat forecasts for non-seasonal (mid-year) months with more caution, given the higher error rate observed there during backtesting.
- Consider extending this analysis to the store level in future work, since the current forecast is company-wide and may mask meaningful differences in performance across locations.

---

## Limitations

- Only 2.7 years of history — enough to confirm December/January seasonality twice, but limited for rarer or longer-cycle patterns.
- The dataset's `holiday_flag` for Christmas is mislabeled (Dec 31 instead of the pre-Christmas period), limiting its reliability as a standalone seasonality signal.
- The forecast is company-wide and does not account for the large performance variation between individual stores.

---

## Tools Used

SQL (PostgreSQL) · Excel (FORECAST.ETS, DAX-style confidence intervals) · Power BI (DAX measures, forecast visuals, dashboard design)