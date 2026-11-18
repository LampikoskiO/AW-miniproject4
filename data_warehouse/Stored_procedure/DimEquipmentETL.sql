CREATE OR ALTER PROCEDURE dbo.LoadDimEquipment
AS
BEGIN
   SET NOCOUNT ON;
    SET XACT_ABORT ON;

    Declare @started datetime2 = sysdatetime();
    Declare @loaded int = 0;
    Declare @rows_read int = 0;

    Begin try
        Begin transaction

        Select @rows_read = Count(*)
        From dbo.EquipmentItem

Update d
Set d.acquired_date = e.acquired_date,
d.removed_date = e.removed_date,
d.[condition] = e.[condition],
d.is_lost = e.is_lost
From Dbo.DimEquipment as d
Join dbo.EquipmentItem as e
on d.equipment_id = e.equipment_id

CROSS apply(
Select case
when e.removed_date is null
or e.removed_date = '99991231'
then convert(date, '29990101', 112)
else e.removed_date
End as removed_date
) as x
Where exists (
Select d.acquired_date, d.removed_date, d.[condition], d.is_lost
Except
Select e.acquired_date, x.removed_date, e.[condition], e.is_lost
);

Set @loaded = @loaded + @@ROWCOUNT;

Insert into dbo.DimEquipment(
equipment_id, acquired_date, removed_date, [condition], is_lost)
Select e.equipment_id, e.acquired_date,
CASE 
When e.removed_date is null
or e.removed_date = '99991231'
then convert(date, '29990101', 112)
else e.removed_date
end,
e.[condition], e.is_lost
From dbo.EquipmentItem as e
Where not exists(
select 1 from dbo.dimeqipment as d where d.equipment_id = e.equipment_id
);

Set @loaded = @loaded + @@ROWCOUNT;

Insert into dbo.etllog
(target_table, started_at, ended_at, rows_read, rows_loaded, rows_rejected, status)
Values ('DimEquipment', @started, sysdatetime(), @rows_read, @loaded, 0, 'success');

Commit transaction

End try
Begin catch

Declare @error_number int = error_number()
declare @error_message nvarchar(500) = error_message()

if xact_state() <> 0
rollback transaction;

-- logging failed etl
Insert into dbo.etllog 
(target_table, started_at, ended_at, rows_read, rows_loaded, rows_rejected, status, error_number, error_message)
Values ('DimEquipment', @started,sysdatetime(), @rows_read, 0, null, 'failed', @error_number, @error_message);
Throw;

End catch;
End;
go