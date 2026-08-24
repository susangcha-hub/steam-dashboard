# Steam Genre Market Analysis

## Project Overview

This Power BI project analyzes the Steam marketplace to help an aspiring game developer evaluate genre opportunities. The dashboard compares genres across competition, market reach, player engagement, satisfaction, release growth, and pricing.

The final product is a one-page, interactive dashboard designed as an executive summary. Users can select a genre and quickly understand its market position relative to Steam overall.

![Steam Genre Market Analysis Dashboard](04_images/dashboard.png)
[Download the Power BI dashboard](03_PowerBI/Steam_Genre_Analysis.pbix)

## Business Question

Which Steam genres show the strongest balance of manageable competition, market reach, player engagement, satisfaction, growth, and pricing potential?

## Tools Used

- **Power BI** — data modeling, DAX measures, dashboard design, and interactive analysis
- **Power Query** — data preparation and transformation
- **Deneb / Vega-Lite** — custom competition-versus-reach scatter plot
- **SQL / MySQL** — exploratory analysis and metric validation
- **Python / Pandas** — initial data cleaning and table preparation

## Dataset

The project uses the Steam Games Dataset by Fronkon Games from Kaggle. The cleaned model contains three primary tables:

- `games` — game information, release dates, prices, developers, categories, and supported platforms
- `metrics` — estimated owners, reviews, recommendations, and playtime
- `game_genres` — bridge table connecting games to their individual genres

## Dashboard Metrics

| Metric | Purpose |
|---|---|
| Total Games | Measures competition within the selected genre |
| Market Reach | Percentage of eligible games with at least 20,000 estimated owners |
| Median Playtime | Measures player engagement |
| Positive Review % | Measures player satisfaction among games with sufficient reviews |
| Release Growth | Compares genre releases from 2021 to 2025 |
| Median Paid Price | Shows the typical price of paid games |

Each KPI is compared with a Steam-wide baseline and translated into a clear performance tier, such as **Highly Popular**, **Highly Engaged**, or **Above Average Price**.

## Dashboard Features

- Genre slicer for interactive analysis
- Six dynamic KPI cards with Steam-wide comparisons
- Competition-versus-reach opportunity scatter plot
- Release trend from 2021 through 2025
- Price-band distribution
- Most common game categories
- Top qualifying developers and their leading games
- Dynamic written takeaway summarizing the selected genre

## Key Findings

- **RPG** and **Strategy** offered the strongest overall balance of reach, engagement, satisfaction, and competition.
- **Massively Multiplayer** games achieved strong reach but showed weaker engagement and satisfaction, suggesting higher market risk.
- **Simulation** demonstrated strong engagement but more moderate market reach.
- **Casual** served as an oversaturation comparison because of its high competition and release growth relative to its reach.

These results are intended to support further market investigation rather than identify a guaranteed genre choice. Genre performance does not account for development cost, production scope, marketing quality, or individual game execution.

## Skills Demonstrated

- Power BI data modeling and relationship design
- DAX measures, filter context, and dynamic benchmark calculations
- Interactive executive-dashboard design
- Custom Deneb visual development
- KPI definition and business-oriented metric selection
- Data cleaning, validation, and exploratory analysis
- Translating analysis into concise recommendations

## Project Files

- `02_SQL/` — SQL queries used for exploratory analysis
- `03_PowerBI/` — Power BI dashboard file
- `04_Images/` — dashboard screenshots and preview images
- `README.md` — project overview, dashboard metrics, features, and key findings

The source dataset is not included in this repository because of its size. It can be downloaded from the [Steam Games Dataset on Kaggle](https://www.kaggle.com/datasets/fronkongames/steam-games-dataset).
