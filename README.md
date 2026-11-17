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

## Importing extra rentals (NewDatainserts)

The `NewDatainserts/` folder holds additional rental batches as CSV files and
`LoadingBatch1.sql`, which imports one batch into the **operational** database
(Customer, RENTAL, RentalLine, etc.). Run it after step 2, then re-run the data
warehouse loads (steps 4–9) so the new rentals flow through to the warehouse.

### One-time setup (each group member)

The CSV path is different on every machine, so it is kept out of git. Set yours once:

1. In the `NewDatainserts` folder, copy the template to your own local file:
   ```
   cp env.example.sql env.local.sql
   ```
2. Open `env.local.sql` and set the path to your CSV folder:
   ```
   :setvar CsvFile "C:\your\path\to\NewDatainserts\rentals_batch_01.csv"
   ```
3. `env.local.sql` is listed in `.gitignore`, so it stays on your machine only.
   **Never commit it.** Only `env.example.sql` is shared.

### Running the import

1. Open `NewDatainserts/LoadingBatch1.sql` in SSMS.
2. Turn on SQLCMD Mode: **Query menu → SQLCMD Mode**. This is required, otherwise
   `:r env.local.sql` and `$(CsvFile)` are reported as errors.
3. Execute. To load another batch, change the filename in your `env.local.sql`
   (e.g. `rentals_batch_02.csv`) and run again.

### CSV line endings

The batch CSV files use Windows line endings (CRLF). The `BULK INSERT` in
`LoadingBatch1.sql` must use `ROWTERMINATOR = '0x0d0a'` to match, otherwise the
trailing carriage return breaks the last column and the import fails with
"invalid, blank, or unconvertible field". If git rewrites line endings differently
on different machines, add a `.gitattributes` with `*.csv binary` so the files stay
byte-for-byte identical for everyone.
