# AW-miniproject4
Rental Operations Database and Data Warehouse

## Script execution order

Run the following scripts in order in SQL Server:

1. `operational_db/RentalDBDatabase.sql` — create the operational database and tables.
2. `operational_db/TestData-Part3.sql` — load the test data.
3. `operational_db/ValidationPart3.sql` — validate the operational database.
4. `data_warehouse/DW_creation.sql` — create the data warehouse tables.
5. `data_warehouse/ETLdimcustomer.sql` — load the customer dimension.
6. `data_warehouse/ETLEmployee&RentalStation.sql` — load the employee and rental station dimensions.
7. `data_warehouse/Date_ETL.sql` — populate the date dimension.
8. `data_warehouse/load_dimModel.sql` — load the model dimension.
9. `data_warehouse/load_factRentalLine.sql` — load the rental fact table.

The model dimension script is named `load_dimModel.sql` in the repository.
