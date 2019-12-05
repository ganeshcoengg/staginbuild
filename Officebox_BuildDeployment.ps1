try{
    $JsonData = (Get-Content ".\config.json" | Out-String)
    $JsonObject = ConvertFrom-Json -InputObject $JsonData -ErrorAction Stop
}
catch{
    Write-Host "Please check Json file parameters." -ForegroundColor Red
    Read-Host "Enter any key to exit"
	Write-Host "`tWe Are Exiting. Thank you!" -ForegroundColor Magenta
	Start-Sleep 3
    Exit
}

$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'

function LogWrite {
    param ([String]$logString,
    [bool] $iserror = $false)
    $time = Get-Date

    if($iserror){
        $string = '*** ' +$time.ToString() +' == ERROR == '+ $logString
    }
    else{
        $string = '*** ' +$time.ToString() +' == '+ $logString
    }
    Add-Content $logfile -Value $string
}

$SiteName = $JsonObject.WebSite
$dbServer = $JsonObject.MySQLServer.DBHost
$CustomerName = $JsonObject.CustomerName.Name
$BuildVersion = $JsonObject.BuildVersion.version
# Summary
Write-Host "`n`t`t ******************* SUMMARY *******************" -ForegroundColor Yellow
LogWrite "******************* SUMMARY *******************"

Write-Host "Customer Name -->  $CustomerName, Build Version -->" $BuildVersion -ForegroundColor Magenta
LogWrite "Customer Name -->  $CustomerName, Build Version --> $BuildVersion"

Write-Host "`n`t <== You want to Deploy the Build on ==> `n" -ForegroundColor Yellow
LogWrite "<== You want to Deploy the Build on ==> "
foreach ($item in $SiteName) {
    Write-Host $item.SiteName -ForegroundColor Cyan
    LogWrite $item.SiteName
}

Write-Host "`n`tDatabase Server Name ==> " -NoNewline
Write-Host "$dbServer" -ForegroundColor Magenta
LogWrite " <== Database Server Name ==> $dbServer "
Write-Host "`n`tAll Scripts will Executed on Database respectively`n" -ForegroundColor Yellow
LogWrite "<== All Scripts will Executed on Database respectively ==>"

foreach ($item in $JsonObject.ADMINDB) {
    Write-Host "Admin Database ==> "$item.ADMIN"`n" -ForegroundColor Cyan
    LogWrite $item.ADMIN
}

foreach ($item in $JsonObject.SADB) {
    Write-Host "SA Database ==> "$item.SA"`n" -ForegroundColor Cyan
    LogWrite $item.SA
}

foreach ($item in $JsonObject.STDB) {
    Write-Host "ST Database ==> "$item.ST"`n" -ForegroundColor Cyan
    LogWrite $item.ST
}

foreach ($item in $JsonObject.SWDB) {
    Write-Host "SW Database ==> "$item.SW"`n" -ForegroundColor Cyan
    LogWrite $item.SW
}

$response = Read-Host "`n Would you like to Continue? (Y/N) "
if($response.ToUpper() -eq "Y"){
    Write-Host "`n`t ************************ WEB SITE STOP ************************ `n"
    LogWrite " ************************ WEB SITE STOP ************************ "
    # Web Site Stoping
    .\WebSite_Start_Stop.ps1 'STOP'
    Write-Host "`n`t ****** `n"
    # Backup process started
    Write-Host "Before build process DB Bakup started `n" -ForegroundColor Yellow
    .\MySQLDatabaseBackup.ps1 'BEFORE'
}
else {
    Write-Host "`tWe Are Exiting. Thank you!" -ForegroundColor Magenta 
    LogWrite "You have Terminated the Execution"
    Start-Sleep 3
    Exit
}