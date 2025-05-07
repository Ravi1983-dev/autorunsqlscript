-- Rebuild all indexes on all user tables
DECLARE @TableName NVARCHAR(255)

DECLARE TableCursor CURSOR FOR
SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
FROM sys.tables
WHERE is_ms_shipped = 0 -- exclude system tables

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Rebuilding indexes on ' + @TableName
    EXEC('ALTER INDEX ALL ON ' + @TableName + ' REBUILD')
    PRINT('ALTER INDEX ALL ON ' + @TableName + ' REBUILD')
    FETCH NEXT FROM TableCursor INTO @TableName
END

CLOSE TableCursor
DEALLOCATE TableCursor
