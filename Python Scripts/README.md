# Python pipeline orchestation



Automated data ingestion and refresh workflows using Python to synchronize CSV sources, PostgreSQL materialized views, and Power BI final reports.



###### 0.actualizar\_album\_financiero.exe

Executes the full end-to-end data refresh pipeline with a unique EXE document, automating image tracking, CSV generation, PostgreSQL ingestion, and materialized view updates required by the Power BI solution.



The next scripts are the separation of each step made in the EXE document.



###### 1.actualizar\_powerbi\_viajes

Automates the detection of changes in travel-related image assets, regenerates the corresponding reference dataset, and synchronizes updates with the assigned repository for downstream Power BI consumption.



###### 2.exportar\_a\_csv

Exports and standardizes Excel-based financial source data into clean, CSV-ready datasets to enable reliable ingestion into PostgreSQL.



###### 3.refrescar\_tablas

Automates the bulk loading of curated CSV files into PostgreSQL fact and dimension tables, serving as the ingestion step of the analytical pipeline.



###### 4.actualizar\_tablas

Automates the refresh of all materialized views in PostgreSQL to propagate newly ingested data into curated analytical datasets.

