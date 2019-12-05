﻿$JsonData = (Get-Content ".\config.json" -Raw)
$JsonObject = ConvertFrom-Json -InputObject $JsonData
$SiteName = $JsonObject.WebSite
$time = Get-Date
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'
Hello Sir/Ma'am,
                                 
Build Deployed successfully on $UISITE ! 
 
Thank you, 
IT Department 
BIZSENSE SOLUTIONS PVT LTD
it.infra@officebox.co.in
"@  