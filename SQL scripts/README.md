# SQL scripts



Databases were initially created to establish clear domain boundaries across the project, while table definitions were implemented later once the final analytical schema and ingestion strategy were defined.

Detailed information about the assigned ds\_id in the document, SQL-created columns, and Power BI usage can be found in the generated\_tables.xls document.



### 1\. Data Foundation



###### 1.0\_create\_databases

Initializes the project by creating domain-specific PostgreSQL databases, including a later correction renaming deudas to creditos for consistency.



###### 1.1\_create\_schema\_album\_financiero

Creates the central album\_financiero schema and moves existing project tables from the public schema to establish a unified modeling environment.



###### 1.2\_create\_tables\_from\_csv

Creates fact and dimension tables in PostgreSQL to support CSV-based data ingestion, including controlled date parsing to ensure consistent data types.



###### 1.3\_transform\_fact\_tables

Enhances fact tables with derived analytical columns (period keys, classifications, and calculations) to support time-based analysis and Power BI modeling.



###### 1.4\_automate\_fact\_table\_updates

Implements PostgreSQL trigger-based automation to recalculate derived analytical columns whenever fact and dimension tables are inserted or updated from refreshed CSV data.



### 2\. Curated Datasets for Analytics



Datasets in this section are implemented as materialized views to persist cleaned, deduplicated, and transformed data used by the Power BI semantic model.

By storing results physically and refreshing them explicitly, these datasets provide consistent analytical snapshots, improved performance, and a clear separation between data preparation and consumption layers.



Each dataset is implemented in two versions:



•	v\_ datasets expose full joins, classifications, and calculations to allow inspection and troubleshooting directly in DBeaver.



•	Final ds\_ datasets retain only the fields required for Power BI relationships and visuals, with primary keys explicitly defined.



This approach preserves model clarity in Power BI while maintaining transparent, analyst-friendly datasets for technical validation.



###### 2.0\_datasets\_dimensions

Defines curated dimension datasets that standardize descriptive attributes and classification logic used across the Power BI data model.



###### 2.1\_datasets\_presupuesto

Defines curated budget datasets that assign each transaction to a budget identifier and structure monthly budget allocations for analytical comparison against actual spending.



###### 2.2\_datasets\_viajes

Defines curated travel datasets that isolate travel-related transactions and enrich them with geographical grouping and historical exchange rates to enable spending analysis in local and base currency.



###### 2.3\_datasets\_creditos

Defines curated credit datasets that associate transactions with their corresponding credit line and billing period, enabling analysis of spending and deposits by credit cycle.



###### 2.4\_datasets\_terceros

Defines curated datasets that identify third-party–related transactions and debt records by extracting counterparty names directly from transaction descriptions.



###### 2.5\_datasets\_movimiento

Defines curated datasets that track income sources and investment behavior, separating user-driven movements from market-driven investment performance over time.

