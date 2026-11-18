# AW-miniproject4
Rental Operations Database and Data Warehouse

## Script execution order

Run the following scripts in order in SQL Server Management Studio:

1. `operational_db/RentalDBDatabase.sql` — create the operational database and tables.
2. `operational_db/TestData-Part3.sql` — load the test data.
3. `operational_db/ValidationPart3.sql` — validate the operational database.
4. `data_warehouse/DW_creation.sql` — create the data warehouse tables.
5. `data_warehouse/Stored_procedure/DimCustomer.sql`
6. `data_warehouse/Stored_procedure/DimDate.sql`
7. `data_warehouse/Stored_procedure/DimModel.sql`
8. `data_warehouse/Stored_procedure/Employee&RentalStation.sql`
9. `data_warehouse/Stored_procedure/FactRentalLineStoredProc.sql`
10. `data_warehouse/Execution/ExecDimCustomer.sql`
11. `data_warehouse/Execution/Employee&RentalStationEXEC.sql`
12. `data_warehouse/Execution/ExecDate.sql`
13. `data_warehouse/Execution/EXEC_DimModel.sql`
14. `data_warehouse/Execution/Exec_FactRentalline.sql`

Run step 1 in the `master` database; run all subsequent scripts in `RentalDB`.
Step 1 drops and recreates `RentalDB`, resetting the database.

## Importing extra rentals (NewDatainserts)

`NewDatainserts/loadbatchone.sql` imports a CSV batch of rentals into the
operational database. Run steps 1–2 above, optionally validate at step 3, import
the batch, then continue with steps 4–14. Do not run `ValidationPart3.sql`
after importing: its row-count checks expect only the original seed data.

**Setup (once per person):** copy `env.example.sql` to `env.local.sql` and set your
own CSV path inside it. `env.local.sql` is gitignored, so keep your own and do not
commit it.

**Run it** with SQLCMD Mode on (Query menu → SQLCMD Mode), otherwise `:r` and
`$(CsvFile)` fail. Change the filename in `env.local.sql` to load a different batch.
