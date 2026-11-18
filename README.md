# AW-miniproject4
Rental Operations Database and Data Warehouse

## Script execution order

Run the following scripts in order in SQL Server:

1. `operational_db/RentalDBDatabase.sql` — create the operational database and tables.
2. `operational_db/TestData-Part3.sql` — load the test data.
3. `operational_db/ValidationPart3.sql` — validate the operational database.
4. `data_warehouse/DW_creation.sql` — create the data warehouse tables.
5. `data_warehouse/Stored_procedure/.` - create the procedures for etl
6. `data_warehouse/execution/.` - loads data in the DW

## Importing extra rentals (NewDatainserts)

`NewDatainserts/LoadingBatch1.sql` imports a CSV batch of rentals into the
operational database. Run it after step 2, then re-run steps 4–9.

**Setup (once per person):** copy `env.example.sql` to `env.local.sql` and set your
own CSV path inside it. `env.local.sql` is gitignored, so keep your own and do not
commit it.

**Run it** with SQLCMD Mode on (Query menu → SQLCMD Mode), otherwise `:r` and
`$(CsvFile)` fail. Change the filename in `env.local.sql` to load a different batch.
