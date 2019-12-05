param(
    [string] $webSiteStartStop        # Parameter to Stop/Start Web Site
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

LogWrite "Web Site Stoping" 
function StartStopWebSite {
    param( [string] $site )

    if($webSiteStartStop.ToUpper() -eq "STOP"){
        Write-Host "Stoping $site..." -NoNewline
        LogWrite "Stoping $site..." 
        $currentState = Get-Website | Where-Object {$_.State -eq "Started" -and $_.Name -eq $site } | Select-Object State

        If($currentState.state -eq "Started"){
            Stop-Website $site
            $currentState = Get-Website | Where-Object {$_.State -eq "Started" -and $_.Name -eq $site  } | Select-Object State
    
            If(-not $currentState.state -eq "Started"){
                Write-Host "Stoped!" -ForegroundColor Green
                LogWrite "Stoped!"
            }
            else{
                Write-Host "Please check somethig went wrong!" -ForegroundColor Red
                LogWrite "Please check somethig went wrong!!" $true
            }
        }
        else{
            Write-Host "Already Stoped!" -ForegroundColor Green
            LogWrite "Already Stoped!"
        }
    }
    if($webSiteStartStop.ToUpper() -eq "START"){
        Write-Host "Starting $site..." -NoNewline
        $currentState = Get-Website | Where-Object {$_.State -eq "Started" -and $_.Name -eq $site } | Select-Object State

        If(-not $currentState.state -eq "Started"){
            Start-Website $site
            $currentState = Get-Website | Where-Object {$_.State -eq "Started" -and $_.Name -eq $site  } | Select-Object State

            If($currentState.state -eq "Started"){
            Write-Host "Started!" -ForegroundColor Green
            }
            else{
            Write-Host "Please check somethig went wrong!" -ForegroundColor Red
            }
        }
        else{
            Write-Host "Already Started!" -ForegroundColor Green
        }
    }
}
# Database backup process Start
foreach($WebSiteName in $SiteName){
    $site = $WebSiteName.SiteName
    StartStopWebSite $site
}