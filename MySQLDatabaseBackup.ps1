#Start:: Set the default parameters 
Param(
    [string] $DB_Before_OR_After            #Paramer for to decide the Database backup time Before OR After
)
try{
    $JsonData = (Get-Content ".\config.json" -Raw)
    $JsonObject = ConvertFrom-Json -InputObject $JsonData -ErrorAction Stop
}
catch {
    Write-Host "Please correct Json file parameters." -ForegroundColor Red
    Exit
}
$ADMINDATABASE = $JsonObject.ADMINDB
$SADATABASE = $JsonObject.SADB
$STDATABASE = $JsonObject.STDB
$SWDATABASE = $JsonObject.SWDB
$BackupPath	=	$JsonObject.DatabaseBackupPath
$HostName = $JsonObject.MySQLServer
$password = $JsonObject.MySQLPassword
$userName = $JsonObject.MySQLUserName
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'
$isTriggers = $JsonObject.WithTrigger.isTrigger
$user = $userName.UserName
$pw = $password.Password
$pass = "-p$pw"
$DBServer = $HostName.DBHost

# Function to write the Log
function LogWrite { 
    param (
        [String]$logString,
        [bool] $iserror = $false
        )

    $time = Get-Date

    if($iserror){
        $string = '*** ' +$time.ToString() +' == ERROR == '+ $logString
    }
    else{
        $string = '*** ' +$time.ToString() +' == '+ $logString
    }
    Add-Content $logfile -Value $string
}

# Delete all old sql backup files older than 1 day(s)
$BackupFilePath = $Backuppath.path + "*.sql"
$Daysback = "-1"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem $BackupFilePath | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -Force

LogWrite "Before deployment Database Backup Started" 
# START ADMIN Database backup  

Function GetDatabaseBackup {
    Param([string] $DBName
    )
    
    $date = ((Get-Date).ToString('yyyyMMddHHmm'))
    $separater = $date +'_' + $DB_Before_OR_After + '_'
    $databasepath = $Backuppath.path + $separater + $DBName
    Write-Host "$DBName Database Backup Started..." -NoNewline
    
    if($isTriggers.ToUpper() -eq "YES"){
        LogWrite "$DBName Backup Started with Triggers"
        $ErrorLog = & cmd.exe /c "mysqldump -h $DBServer -u $user $pass $DBName > $databasepath.sql"
    }
    else {
        LogWrite "$DBName Backup Started without Triggers"
        $ErrorLog = & cmd.exe /c "mysqldump -h $DBServer -u $user $pass $DBName --skip-triggers > $databasepath.sql"
    }

    #check status
    if ($?){
        Write-Host "Completed!" -ForegroundColor Green
        LogWrite "$DBName database backup successfully completed!"
    }
    else{
        $ErrorLog = $Error[0].Exception.Message
        Write-Host "$DBName DATABASE BACKUP FAILED" -ForegroundColor Red
        LogWrite "$DBName DATABASE BACKUP HAS BEEN FAILED - $ErrorLog !" $true
    }
}
Write-Host "`n`t ************************ DATABASE BACKUP ************************ `n"
LogWrite " ************************ DATABASE BACKUP ************************ "
foreach($AdminDatabaseName in $ADMINDATABASE){	
    $admindatabase = $AdminDatabaseName.ADMIN
    GetDatabaseBackup $admindatabase
}

foreach($SADatabaseName in $SADATABASE){
    $sadatabase = $SADatabaseName.SA
    GetDatabaseBackup $sadatabase
}

foreach($STDatabaseName in $STDATABASE){
    $stdatabase = $STDatabaseName.ST
    GetDatabaseBackup $stdatabase
}

foreach($SWDatabaseName in $SWDATABASE){
    $swdatabase = $SWDatabaseName.SW
    GetDatabaseBackup $swdatabase
}

#Set rar path 
LogWrite "Backup zip file process start!"
if($DB_Before_OR_After -eq 'BEFORE'){
    # 1. Once the Database backup has done, Create the RAR file 
    # 2. Then Start the further process
    #   a. Site Backup and Site Copy 
    Start-Process .\CreateBeforeDatabaseBackupRar.ps1            # Open New Console for Creating RAR File
    .\CreateAndCopy.ps1                    # Execute on Same Console
}
elseif ($DB_Before_OR_After -eq 'AFTER') {
    Start-Process .\CreateAfterDatabaseBackupRar.ps1
    Write-Host "`n`t ************************ WEB SITE START ************************ `n"
    LogWrite " ************************ WEB SITE START ************************ "
    .\WebSite_Start_Stop.ps1 'START'

    if ($?){
        #send email
        LogWrite "Build deployed successfully completed And send the email!"
        .\email-sending.ps1
    }
    else{
        $ErrorLog= $Error[0].Exception.Message 
        LogWrite "AFTER DATABASE BACKUP HAS BEEN FAILED - $ErrorLog !" $true
    }
}