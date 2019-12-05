$JsonData = (Get-Content ".\config.json" -Raw)
$JsonObject = ConvertFrom-Json -InputObject $JsonData
$SiteName = $JsonObject.WebSite$UISITE=$($SiteName.SiteName[0]) 
$time = Get-Date
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'$User = "mail-noreply@officebox.co.in"$Pass = ConvertTo-SecureString -String "office!box" -AsPlainText -Force$Cred = New-Object System.Management.Automation.PSCredential $User, $Pass   $From = "mail-noreply@officebox.co.in"$To = "nikhil.mohinkar@officebox.co.in", "ganesh.vahinde@officebox.co.in"$Subject = "OfficeBOX - Production Build Deployed successfully on $UISITE $time !"$Body = @" 
Hello Sir/Ma'am,
                                 
Build Deployed successfully on $UISITE ! 
 
Thank you, 
IT Department 
BIZSENSE SOLUTIONS PVT LTD
it.infra@officebox.co.in
"@  $SMTPServer = "smtp.gmail.com"$SMTPPort = "587"Send-MailMessage -From $From -to $To -Subject $Subject `-Body $Body -Attachments $logfile -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `-Credential $Cred