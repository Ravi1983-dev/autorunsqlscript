-- Update statistics on all user tables
DECLARE @TableName NVARCHAR(255)

DECLARE TableCursor CURSOR FOR
SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
FROM sys.tables
WHERE is_ms_shipped = 0 -- exclude system tables

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Updating statistics on ' + @TableName
    EXEC('UPDATE STATISTICS ' + @TableName + ' WITH FULLSCAN')

    FETCH NEXT FROM TableCursor INTO @TableName
END

CLOSE TableCursor
DEALLOCATE TableCursor
