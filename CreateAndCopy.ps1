Param(
    [String] $BuildVersion,
    [String] $CustomerName
)

#Start:: Set the default parameters 
try{
	$JsonData = (Get-Content ".\config.json" | Out-String)
	$JsonObject = ConvertFrom-Json -InputObject $JsonData -ErrorAction Stop
}
catch{
	Write-Host "Please check Json file parameters." -ForegroundColor Red
	Read-Host "Enter any key to exit"
	Exit-PSSession
}
$SiteNameList = $JsonObject.WebSite
$AppFolder = $JsonObject.FolderPath
$sitepath = $($AppFolder.Path)
$skipfolder='DOCS','Images','crystalreportviewers13','Subscriber_Data','Temp_Data','TempImageFiles','aspnet_client'
$siteAlliesList = 'MAIN_APP','ACCOUNT','AUTH','DASHBOARD','INVENTORY','SAP','CRM','HR','LOGISTICSPARK'
$excludeToCopy = @('web.config','app_offline1.htm','Areas', 'Views','DOCS','Images','crystalreportviewers13','Subscriber_Data','Temp_Data','TempImageFiles')
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'
#$isFromMain = $JsonObject.GetBuildFrom.IsDevORMain	#Input from config.json to mention the is build is from dev branch or from main branch
#$BuildVersion = $JsonObject.BuildVersion.Version	#Input from config.json comment coz input getting at run tiem
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

# Delete file and Folder in WebSite
Function StartDeleteFileAndFolder {
	Param([string] $website   
	)
	# Delete All Folder exclude (TEMP_DATA DOCS IMAGES crystalreportviewers13 Subscriber_Data TempImageFiles)	
	Write-Host "Removing data of $website..." -NoNewline
	LogWrite "Removing data of $website..."
    Get-ChildItem "$sitepath$website" -Exclude $skipfolder | Where-Object { $_.PSIsContainer } | Remove-Item -Recurse -Force    # Only remove the Containers(Folders)
    Remove-Item "$sitepath$website\*.*" -Exclude "Web.config","app_offline1.htm" | Where-Object { ! $_.PSIsContainer }
   
   if ( $? )
	{
        Write-Host "Removed!" -ForegroundColor Green
        LogWrite "Removed!"  
	}
	else {
        $ErrorLog= $Error[0].Exception.Message 
        Write-Host "REMOVING FAILED!" -ForegroundColor Red
        LogWrite "SITE DATA REMOVING FAILED - $ErrorLog !!" $true
	}  
}	
Write-Host "`n`t ************************ REMOVING FILES ************************ `n"
LogWrite " ************************ REMOVING FILES ************************ "
# Delete file and Folder in WebSite
foreach($WebsitName in $SiteNameList){
	StartDeleteFileAndFolder $WebsitName.SiteName
}
Write-Host "`n`t ************************ MAP TFS-SERVER GITBUILDS AS Q ************************ `n"
LogWrite " ************************ MAP TFS-SERVER GITBUILDS AS Q ************************ "
#Create Log Folder with date 
$getbackdate = $((Get-Date).ToString('yyyyMMddHHmm'))
$logfolder = "$logpath$getbackdate"

if(-not (Test-Path  $logfolder -PathType Container))
{
	New-Item -ItemType Directory $logfolder 
    #check status 
	if ( $? )
	{
		Write-Host "$logfolder Folder successfully created" -ForegroundColor Green
		LogWrite "$logfolder Folder successfully created!!"    
	}
	else {
		$ErrorLog= $Error[0].Exception.Message 
        Write-Host "Folder Not Created" -ForegroundColor Red
        LogWrite "FOLDER NOT CREATED - $ErrorLog !!", $true
	}  
} 

#$net = New-Object -comobject Wscript.Network
#$net.MapNetworkDrive("Q:","\\tfs-server\GITBUILDS\OB01-ERP\$BuildVersion\_PublishedWebsites",0,"officebox\obbuild",'Box!123')
New-PSDrive -Name 'Q' -PSProvider 'FileSystem' -Root '\\tfs-server\GITBUILDS\OB01-ERP\'
$tfs_buildpath = 'Q:\' + $BuildVersion + '\_PublishedWebsites\'
$DeploySiteNameList = $JsonObject.BuildSiteName
$getbackdate = $((Get-Date).ToString('yyyyMMddHHmm'))
$CopyLogFolder="$logpath\$getbackdate"
function BuildSite {
    param (
        [string] $buildDestinationSite,
        [string] $buildSourceSite,
        [string] $sitealise
    )
    process{
        
        $buildSourceSitepath = $tfs_buildpath + $buildSourceSite
        $buildDestinationSitepath = $AppFolder.path + $buildDestinationSite
        $copylogfile = $CopyLogFolder + '\' + $sitealise + '_log.txt'
        Write-Host "Copying $buildSourceSitepath to $buildDestinationSitepath..." -NoNewline
        LogWrite "Copying $buildSourceSitepath to $buildDestinationSitepath..."

        try{
            Copy-Item -Path $buildSourceSitepath\* -Destination $buildDestinationSitepath -Exclude $excludeToCopy -Recurse -PassThru | Out-File $copylogfile -Append

            if($sitealise -eq 'MAIN_APP'){
               Copy-Item -Path $buildSourceSitepath\Areas -Destination $buildDestinationSitepath -Recurse -PassThru | Out-File $copylogfile -Append
               Copy-Item -Path $buildSourceSitepath\Views -Destination $buildDestinationSitepath -Recurse  -PassThru | Out-File $copylogfile -Append
            }
            if ( $? ){
                Write-Host "Copied!" -ForegroundColor Green
                LogWrite "Copied!"
            }
            else{
                $ErrorLog= $Error[0].Exception.Message
                Write-Host "Failed to Copy" -ForegroundColor Red
                LogWrite "Failed to Copy - $ErrorLog !!" $true
            }
        }
        catch{
				$ErrorLog= $Error[0].Exception.Message
                Write-Host "Failed to Copy Error==> $ErrorLog" -ForegroundColor Red
                LogWrite "Failed to Copy - $ErrorLog !!" $true
				Exit   	#Do not proceed if build deployment failed
        }
    }
}
Write-Host "`n`t ************************ BUILD DEPLOYMENT ************************  `n"
LogWrite " ************************ BUILD DEPLOYMENT ************************ "
$mainSite = $SiteNameList.SiteName[0]
$maindeployesite = $DeploySiteNameList.SiteName[0]
BuildSite $mainSite $maindeployesite 'MAIN_APP'

# Invoke the BuildSite Method for the other sites
$valueat = 0
do {
    $SiteNameList | ForEach-Object{
        $site = $_
        if($site -match $siteAlliesList[$valueat])
        {
            $DeploySiteNameList | foreach-Object{
                if($_ -match $siteAlliesList[$valueat])
                {
                    #Write-Host $siteAlliesList[$valueat] -ForegroundColor Magenta
                    $buildDestinationSite = $_.SiteName
                    $buildSourceSite = $site.SiteName
                    BuildSite $buildSourceSite $buildDestinationSite $siteAlliesList[$valueat]
                }
            }
        }
    }
    $valueat++
} while ($valueat -lt 9)

#Disconet maped drive 
#net use Q: /delete
Remove-PSDrive -Name 'Q'
# Set New Bild Version AND Sync Version 
$Newbuildversion = $BuildVersion
$NewSyncVersion=$Newbuildversion.Substring(0,8)

# Get the old build version from web.config file 
# And save on oldbuildVersion.txt file
# Replace new build version and syncversion in web.config file
$config = $AppFolder.path + $SiteNameList.SiteName[0] + "\Web.config"
$doc = (Get-Content $config) -as [Xml]
$root = $doc.get_DocumentElement();
$SyncVersion = $root.appSettings.add | Where-Object {$_.key -eq 'SyncVersion'};
$BuildVersion1 = $root.appSettings.add | Where-Object {$_.key -eq 'BuildVersion'};
#$SyncVersionvalue = $SyncVersion.value
$BuildVersionValue = $BuildVersion1.value
$BuildVersionValue | Out-File $logfolder\oldbuildVersion.txt

$SyncVersion.SetAttribute("value", "$NewSyncVersion");
$BuildVersion1.SetAttribute("value", "$Newbuildversion");
$doc.Save($config) 
Write-Host "`n`t ************************ EXTRATING SCRIPT ************************ `n"
LogWrite " ************************ EXTRATING SCRIPT ************************ "
# Extract the SQL Script which need to be execute on Respective database.
$ErrorLog = .\ExtractScript.ps1 $logfolder $CustomerName -Wait
if ( $? )
{
    Write-Host "All Script are Extracted!" -ForegroundColor Green
    LogWrite "All Script are Extracted!"
}
else {         
    $ErrorLog= $Error[0].Exception.Message 
    Write-Host "ERROR :- SCRIPT FILES NOT CREATED" -ForegroundColor Red
    LogWrite "ERROR :- SCRIPT FILE NOT CREATED - $ErrorLog !!"
}
#Start Script execution ON Database
.\SQLScriptExecute.ps1 $logfolder