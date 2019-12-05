Param(
    [String] $logfolder              
)
 
try{
    $JsonData = (Get-Content ".\config.json" | Out-String)
    $JsonObject = ConvertFrom-Json -InputObject $JsonData -ErrorAction Stop
}
catch{
    Write-Host "Please check Json file parameters." -ForegroundColor Red
    Read-Host "Enter any key to exit"
	Write-Host "`tWe Are Exiting..." -ForegroundColor Magenta
	Start-Sleep 3
    Exit-PSSession
}
$SiteName = $JsonObject.WebSite
$ADMINDATABASE = $JsonObject.ADMINDB
$SADATABASE = $JsonObject.SADB
$STDATABASE = $JsonObject.STDB
$SWDATABASE = $JsonObject.SWDB
#$Scriptlogpath = $JsonObject.BuildLogsPath.Path
$DBServer = $JsonObject.MySQLServer
$userName = $JsonObject.MySQLUserName
$password = $JsonObject.MySQLPassword
$MySQLhost = $DBServer.DBHost
$user = $userName.UserName
$pw = $password.Password
$pass = "-p$pw"

$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'

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
Function ExecuteSchemaDataScripts{
    param([String] $SchemaScript,
        [string] $DatabaseName
    )
        
    $SCHEMAerror = "$logfolder\$DatabaseName-SCHEMAerror.txt"
    Write-Host "Executing $SchemaScript script on $DatabaseName..." -NoNewline
    LogWrite "Executing $SchemaScript script on $DatabaseName..."
    # Running Schema script on Admin Database 
    $ErrorLog =  & cmd.exe /c "mysql -h $MySQLhost -u $user $pass $DatabaseName -f < $SchemaScript >> $SCHEMAerror 2>&1"
    $exitstatus01 = $?

    if($exitstatus01){
        Write-Host "Executed Successfully!" -ForegroundColor Green
        LogWrite "Executed Successfully!" 
    }
    else{
        $ErrorLog = $Error[0].Exception.Message 
        Write-Host "Failed" -ForegroundColor Red
        LogWrite " Schema script execution failed With ==> $ErrorLog !!" $true
    }
}

function ExecuteDataScript {
    param (
        [String] $DataScript,
        [string] $DatabaseName
    )

    $Dataerror = "$logfolder\$DatabaseName-DATAerror.txt"
    Write-Host "Executing $DataScript script on $DatabaseName..." -NoNewline
    LogWrite "Executing $DataScript script on $DatabaseName..."
    $DataErrorLog = & cmd.exe /c "mysql -h $MySQLhost -u $user $pass $DatabaseName -f < $DataScript >> $Dataerror 2>&1"
    $exitstatus02  = $?

    if ($exitstatus02)
    {
        Write-Host "Executed successfully!" -ForegroundColor Green
        LogWrite "Executed successfully!" 
    }
    else
    {
        $DataErrorLog = $Error[0].Exception.Message
        Write-Host "Failed" -ForegroundColor Red
        LogWrite "Data script execution failed with ==> $DataErrorLog !!" $true
    }
}
Write-Host "`n`t ************************ SCRIPT EXECUTION ************************ `n"
LogWrite " ************************ SCRIPT EXECUTION ************************ "
# Run script on Admin DB
foreach($AdminDBName in $ADMINDATABASE){

    $AdminSchemaScript = "$logfolder\ADMIN_SCHEMA.sql"
    $AdminDataScript = "$logfolder\ADMIN_DATA.sql"
    $AdminCustomerScript = "$logfolder\CUSTOMER_ADMIN_DATA_SCRIPT.sql"
    if(Test-Path -Path $AdminSchemaScript){
        ExecuteSchemaDataScripts $AdminSchemaScript $AdminDBName.ADMIN
    }
    else {
        Write-Host "ADMIN_SCHEMA.sql Script are not available to Execute"
    }
    if(Test-Path -Path $AdminDataScript){
        ExecuteDataScript $AdminDataScript $AdminDBName.ADMIN
    }
    else{
        Write-Host "ADMIN_DATA.sql Script are not available to Execute"
    }
    if(Test-Path -Path $AdminCustomerScript ){
        ExecuteDataScript $AdminCustomerScript $AdminDBName.ADMIN
    }
    else{
        Write-Host "Customer wise Admin Data Script are not available to Execute" -ForegroundColor Yellow
    }
}

# Run script on SA Databases
foreach($SADBName in $SADATABASE){
    
    $SASchemaScript = "$logfolder\SA_SCHEMA.sql"
    $SADataScript = "$logfolder\SA_DATA.sql"
    $SACustomerScript = "$logfolder\CUSTOMER_SA_DATA_SCRIPT.sql"
    if(Test-Path -Path $SASchemaScript){
        ExecuteSchemaDataScripts $SASchemaScript $SADBName.SA
    }
    else {
        Write-Host "ADMIN_SCHEMA.sql Script are not available to Execute"
    }
    if(Test-Path -Path $SADataScript){
        ExecuteDataScript $SADataScript $SADBName.SA
    }
    else{
        Write-Host "ADMIN_DATA.sql Script are not available to Execute"
    }
    if(Test-Path -Path $SACustomerScript ){
        ExecuteDataScript $SACustomerScript $SADBName.ADMIN
    }
    else{
        Write-Host "Customer wise SA Data Script are not available to Execute" -ForegroundColor Yellow
    }
}

# Run script on ST Databases
foreach($STDBName in $STDATABASE){
    
    $STSchemaScript = "$logfolder\ST_SCHEMA.sql"
    $STDataScript = "$logfolder\ST_DATA.sql"

    if(Test-Path -Path $STSchemaScript){
        ExecuteSchemaDataScripts $STSchemaScript $STDBName.ST
    }
    else{
        Write-Host "ST_SCHEMA.sql Script are not available to Execute"
    }
    if(Test-Path -Path $STDataScript){
        ExecuteDataScript $STDataScript $STDBName.ST
    }    
    else{
        Write-Host "ST_DATA.sql Script are not available to Execute"
    }
}

# Run script on SW Databases
foreach($SWDBName in $SWDATABASE){
		
    $SWSchemaScript = "$logfolder\SW_SCHEMA.sql"
    #RunScriptOnSWDB  $SWSchemaScript 
    if(Test-Path -Path $SWSchemaScript){
        ExecuteSchemaDataScripts $SWSchemaScript $SWDBName.SW
    }
    else{
        Write-Host "SW_SCHEMA.sql Script are not available to Execute"
    }
    
}
Write-Host "`n`t ************************ IIS STARTING ************************ `n"
LogWrite " ************************ IIS STARTING ************************ "
# Web Site Start
.\WebSite_Start_Stop.ps1 'START'
# Start publishFeatures script
LogWrite "PublishFeatures start!!"
$UISITE=$($SiteName.SiteName[0])
$ErrorLog= Start-Process .\PublishFeatures.bat $UISITE -Wait

if ($?)
{
    Write-Host "Features Publish Successfully on $UISITE!!" -ForegroundColor Green
    LogWrite "Features Publish Successfully on $UISITE!!"
}
else
{
    $ErrorLog= $Error[0].Exception.Message
    Write-Host "Features not Publish!! " -ForegroundColor Red
    LogWrite "FEATURES NOT PUBLISH - $ErrorLog" $true
}

Write-Host "`n If Publish Feature Failed then First do Publish Feature by Double click on 'PublishFeatures.bat' `n"
$response = Read-Host "To Continue Click (Y/N)"

if($response.ToUpper() -eq "Y")
{
    Write-Host "`n`t ********* Build Successfully Deployed ********* `n"
    LogWrite "`n`t ********* Build Successfully Deployed ********* `n"
    Write-Host "`n`t ********* Thank You! ********* "
}
elseif($response.ToUpper() -eq "N"){
    Write-Host "`n If Publish Feature Failed then First do Publish Feature by Double click on 'PublishFeatures.bat' `n"
    LogWrite "If Publish Feature Failed then First do Publish Feature by Double click on 'PublishFeatures.bat'"
    Write-Host "`n`t ********* Thank You! ********* "
}