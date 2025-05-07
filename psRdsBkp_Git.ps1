
# Database info
$script:dataSource = 'backuptest.c0fj9px3h6i3.us-east-2.rds.amazonaws.com'
$script:cmsdb = 'Apple'
$script:dbcount = 1
$username = 'dbadmin'
$password = 'L1ttleRagged'

			
$Query = "select * from dbo.serverlist"				
$ServerList  = @(Invoke-SQLCmd -ServerInstance $dataSource -Database $cmsdb -query $Query -Username $username -Password $password) | select-object -expand servername


[System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMO’) | out-null
ForEach ($ServerName in $ServerList)
{
    $serverConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($ServerName, $username, $password)
    $SQLServer = New-Object Microsoft.SqlServer.Management.Smo.Server($serverConnection)
    try 
    {
    Foreach($Database in $SQLServer.Databases)
    {
        #Skip system databases and Operations DBA from listing
        if($Database.Name -notin ('master','msdb','model','tempdb','OperationsDBA','rdsadmin'))
        {
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $filename = $($Database.Name)+"_"+$timestamp.ToString()
            write-host $filename
            $connStr = "Server=$ServerName;Database=msdb;User ID=$username;Password=$password;"

            # Build the SQL command
            $sql = "
            EXEC msdb.dbo.rds_backup_database 
                @source_db_name = $Database, 
                @s3_arn_to_backup_to = 'arn:aws:s3:::clouds3basic/$($filename).bak',
                @overwrite_S3_backup_file = 1;
            "

            # Run the SQL command
            $conn = New-Object System.Data.SqlClient.SqlConnection $connStr
            $conn.Open()
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $sql
            $cmd.ExecuteNonQuery()
            $conn.Close()


            #To avoid asyncronous execution
            
            do {
                    # SQL command to get the latest task for the specific database
                    $sql = "SELECT top 1 lifecycle FROM msdb.dbo.rds_fn_task_status(NULL,0) order by task_id desc"
                   
                    
                    # Run SQL and get output
                    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database msdb -Username $username -Password $password -Query $sql

                        if ($result.lifecycle -eq "SUCCESS") {
                            Write-Host "Task is complete."
                            break
                             } else {
                            Write-Host "Task is still running... Sleeping 10s."
                            Start-Sleep -Seconds 15
                        }

                } while ($true)

        }
    }
    }
    Catch
    {
        Write-Host $_.Exception.Message -BackgroundColor DarkRed
    }
}
