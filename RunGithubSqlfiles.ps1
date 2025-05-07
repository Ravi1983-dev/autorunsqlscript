param(
    [string]$Server = "backuptest.c0fj9px3h6i3.us-east-2.rds.amazonaws.com",
    [int]$Port = 1433,
    [string]$Username = "dbadmin",
    [string]$Password = "L1ttleRagged",
    [string]$SqlFile = "C:\\Users\\ravishankarsg\\Desktop\\Dummy\\insertscript.sql"
)


# Build connection string
$connectionString = "Server=$Server,$Port;User ID=$Username;Password=$Password;Initial Catalog=master;"

# Load SQL script content
$sqlScriptContent = Get-Content $SqlFile -Raw

# Get list of user databases
$query = @"
SELECT name FROM sys.databases
WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb','rdsadmin')
"@

# Use .NET SqlClient to query and loop through DBs
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$command = $connection.CreateCommand()
$command.CommandText = $query

$connection.Open()
$reader = $command.ExecuteReader()

$databases = @()
while ($reader.Read()) {
    $databases += $reader["name"]
}
$reader.Close()
$connection.Close()

# Run script on each user DB
foreach ($db in $databases) {
    Write-Host "Running script on database: $db"
    $dbConnectionString = "Server=$Server,$Port;User ID=$Username;Password=$Password;Initial Catalog=$db;"

    $conn = New-Object System.Data.SqlClient.SqlConnection $dbConnectionString
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sqlScriptContent
    $conn.Open()
    $cmd.ExecuteNonQuery()
    $conn.Close()
}
