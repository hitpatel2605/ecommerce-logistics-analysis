Supply Chain & Logistics EDA: Olist E-Commerce

🔗 [View Live Interactive Dashboard on Tableau Public](https://public.tableau.com/views/SupplyChainLogisticsDashboard_17843670849740/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

📌 Project Overview

This project analyzes over 100,000 real e-commerce orders from Olist (a Brazilian marketplace) to identify logistical bottlenecks, calculate delivery performance metrics, and pinpoint high-risk seller behaviors. The goal of this analysis was to provide actionable recommendations to leadership regarding carrier SLAs and seller onboarding.

Tools Used:

Python (Pandas): Data extraction, cleaning, handling missing values, and feature engineering (calculating delivery delays).

SQL (MySQL): Relational database design, CTEs, Window Functions (LAG, RANK), and complex aggregations.

Tableau: Data visualization, geographic mapping, and executive dashboard design.

🗂️ Data Pipeline & Architecture

Data Cleaning (Python): Raw datasets were joined and cleaned in a Jupyter Notebook. Null timestamps were handled, and new features like is_late and delivery_delay_days were engineered.

Database Modeling (SQL): The cleaned CSVs were loaded into a localized MySQL database.

Data Aggregation (SQL): Authored high-performance SQL scripts to calculate rolling 3-month late rates, seller performance rankings, and category revenue-to-risk ratios.

Visualization (Tableau): Aggregated metrics were connected to Tableau to build an interactive, executive-level layout.

[📊](https://github.com/hitpatel2605/ecommerce-logistics-analysis/blob/main/Ecommerce%20Project/Image/Dashboard.png) Executive Dashboard

💡 Key Business Insights

The Logistics Bottleneck: A specific cluster of Northern regions experiences significantly higher late delivery rates, indicating a failure in regional carrier SLAs.

High-Risk Sellers: A concentrated segment of top-offending sellers (e.g., Seller 2709a...) suffer from late delivery rates exceeding 50%, acting as a major bottleneck to the overall platform reputation.

Revenue vs. Risk: The "Security and Services" category suffers a massive 50% bad review rate despite generating negligible revenue, whereas heavy-hitting categories like "Bed Bath Table" maintain stable satisfaction.

🛠️ Recommendations

Audit Underperforming Sellers: Implement a temporary onboarding pause for sellers exceeding a 30% late-delivery threshold.

Renegotiate Regional SLAs: Carrier contracts in the Northern states must be renegotiated or supplemented with local warehousing solutions to reduce the 3-month rolling delay trend.

Category Delisting: Consider delisting or heavily monitoring high-risk, low-reward product categories that actively damage the brand's Net Promoter Score (NPS) without driving bottom-line revenue.
