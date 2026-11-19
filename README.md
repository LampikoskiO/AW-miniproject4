# AW-miniproject4
Rental Operations Database and Data Warehouse

## How to run

Run each script in order in SSMS.
Run **step 1 connected to `master`** (it wipes and recreates `RentalDB`). Everything after runs in `RentalDB`.

### Operational database
1. `operational_db/RentalDBDatabase.sql`
2. `operational_db/TestData-Part3.sql`
3. `operational_db/ValidationPart3.sql`

### Create the warehouse and procedures
4. `data_warehouse/DW_creation.sql`
5. `data_warehouse/Stored_procedure/DimCustomer.sql`
6. `data_warehouse/Stored_procedure/DimDate.sql`
7. `data_warehouse/Stored_procedure/DimModel.sql`
8. `data_warehouse/Stored_procedure/Employee&RentalStation.sql`
9. `data_warehouse/Stored_procedure/DimEquipmentETL.sql`
10. `data_warehouse/Stored_procedure/FactRentalLineStoredProc.sql`
11. `data_warehouse/Stored_procedure/FactMaintenance.sql`

### Run the loads
12. `data_warehouse/Execution/ExecDimCustomer.sql`
13. `data_warehouse/Execution/Employee&RentalStationEXEC.sql`
14. `data_warehouse/Execution/ExecDate.sql`
15. `data_warehouse/Execution/EXEC_DimModel.sql`
16. `data_warehouse/Execution/EXECEquipment.sql`
17. `data_warehouse/Execution/Exec_FactRentalline.sql`
18. `data_warehouse/Execution/EXEC FactMaintenance.sql`

### Validate
19. `data_warehouse/Validation.sql`

---

## Optional: import extra rental batches

To load extra CSV rental batches (`NewDatainserts/`), do it **between step 2 and step 4**:

1. Copy `NewDatainserts/env.example.sql` to `NewDatainserts/env.local.sql` and set your own CSV path inside it (gitignored, do not commit).
2. Turn on SQLCMD Mode (Query menu → SQLCMD Mode).
3. Run `NewDatainserts/loadbatchone.sql`.

Do not run `ValidationPart3.sql` after importing, its row counts expect only the original seed data.
