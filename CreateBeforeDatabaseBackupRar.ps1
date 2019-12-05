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


$Backuppath=$JsonObject.DatabaseBackupPath.path

Write-Host "Creating RAR for before deployment..."
LogWrite "Creating RAR for before deployment..."
try{
    if (Test-Path -path  "C:\Program Files (x86)\WinRAR\Rar.exe"){
        $rar = "C:\Program Files (x86)\WinRAR\Rar.exe"
    }
    else{
        $rar = "C:\Program Files\WinRAR\Rar.exe"
    }
    $filedate=((Get-Date).ToString('yyyyMMddHHmm'))
    $FileName="mysqldumpIndiDB_BEFORE_$filedate"
    $date=((Get-Date).ToString('yyyyMMdd'))
    $separater = "_before_"
    $dirInfo = Get-ChildItem $BackupPath
    if($dirinfo.Length -eq 0){
        LogWrite "File not founnd" $true
        throw [System.IO.FileNotFoundException]  "File not found"         # Throw an exception if sql file not created for rar 
    }
    else{
        $ErrorLog =  & $rar u -r $Backuppath$FileName.rar $Backuppath$date*$separater*.sql

        if($?){
            Write-Host "Database RAR for before deployment has created!"
            LogWrite "Database RAR for before deployment has created!"
        }
        else{
            $ErrorLog = $Error[0].Exception.Message 
            Write-Host "Database RAR for before deployment has failed" -ForegroundColor Red
            LogWrite "Database RAR for before deployment has failed $ErrorLog" $true
        }
    }
}
catch [System.IO.FileNotFoundException]{
    Write-Host "Database sql file not avaiable for Rar" -foregroundcolor Red
    LogWrite "Database sql file not avaiable for Rar" $true
}
catch{
    Write-Host "An Error has Occured!" -ForegroundColor Red
    LogWrite "An Error has Occured! System Error." $true
}