# AW-miniproject4
Rental Operations Database and Data Warehouse

## Script execution order

Run the following scripts in order in SQL Server Management Studio:

### Operational database

1. `operational_db/RentalDBDatabase.sql` — create the operational database and tables.
2. `operational_db/TestData-Part3.sql` — load the test data.
3. `operational_db/ValidationPart3.sql` — validate the operational database.

### Rental data batches

4. `rental_data_all_batches/initialize_rentaldb.sql` — clear existing table rows and seed the reference data. This replaces the data loaded by `TestData-Part3.sql`.
5. In `rental_data_all_batches/load_rental_batches.sql`, set `@Directory` to the folder readable by the SQL Server service and set `@Batch` to `1`. Run it once for each batch, in order, changing `@Batch` to `2` and then `3`. Each run loads the matching `equipment_items_batch_XX.csv`, `maintenance_batch_XX.csv`, and `rentals_batch_XX.csv` files.

### Data warehouse

6. `data_warehouse/DW_creation.sql` — create the data warehouse tables.
7. `data_warehouse/Stored_procedure/DimCustomer.sql`
8. `data_warehouse/Stored_procedure/DimDate.sql`
9. `data_warehouse/Stored_procedure/DimModel.sql`
10. `data_warehouse/Stored_procedure/Employee&RentalStation.sql`
11. `data_warehouse/Stored_procedure/FactRentalLineStoredProc.sql`
12. `data_warehouse/Execution/ExecDimCustomer.sql`
13. `data_warehouse/Execution/Employee&RentalStationEXEC.sql`
14. `data_warehouse/Execution/ExecDate.sql`
15. `data_warehouse/Execution/EXEC_DimModel.sql`
16. `data_warehouse/Execution/Exec_FactRentalline.sql`
