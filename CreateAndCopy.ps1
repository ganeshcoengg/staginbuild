# Start:: Set the default parameters 
# $JsonData = (Get-Content ".\config.json" -Raw)
# $JsonObject = ConvertFrom-Json -InputObject $JsonData
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

$SiteNameList = $JsonObject.WebSite
$AppFolder = $JsonObject.FolderPath
$sitepath = $($AppFolder.Path)
$SiteBackup = $JsonObject.SiteBackupPath
$BuildFolder = $JsonObject.ToBeDeployedPath
$skipfolder='DOCS','Images','crystalreportviewers13','Subscriber_Data','Temp_Data','TempImageFiles','aspnet_client'
$siteAlliesList = 'MAIN_APP','ACCOUNT','AUTH','DASHBOARD','INVENTORY','SAP','CRM','HR','LOGISTICSPARK'
$excludeToCopy = @('web.config','app_offline1.htm','Areas', 'Views','DOCS','Images','crystalreportviewers13','Subscriber_Data','Temp_Data','TempImageFiles','aspnet_client')
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'
$sitebackupdate = $((Get-Date).ToString('yyyyMMddHHmm'))
$sitebackdestination = $($SiteBackup.path+$sitebackupdate)
$Newbuildversion = $JsonObject.BuildVersion.version     # Build Version parameter defined in config.json file
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
LogWrite "Site Backup Start!!"

#Create Site Backup Folder with date 
if(-not (Test-Path  $sitebackdestination -PathType Container)){
    #$ErrorLog= mkdir $sitebackdestination
    New-Item -ItemType Directory $sitebackdestination
    LogWrite " $sitebackdestination Folder successfully created!!"
}

# Site Backup
Function StartSiteBackup {
    Param(
        [string] $SiteBackupFolderName
    )
    if(Test-Path -Path $sitepath$SiteBackupFolderName)
    {
        Write-Host "Site $SiteBackupFolderName backup started..." -NoNewline
        LogWrite "Site $SiteBackupFolderName  backup started..."
        $ErrorLog=   Copy-item -Force -Recurse  $sitepath$SiteBackupFolderName -Destination $sitebackdestination\  
        #check status          
        if ( $? ){
            Write-Host "Done!" -ForegroundColor Green
            LogWrite "Site $SiteBackupFolderName backup Done"
        }
        else{
            $ErrorLog= $Error[0].Exception.Message 
            Write-Host "SITE BACKUP FAILED!" -ForegroundColor Red
            LogWrite "SITE BACKUP HAS BEEN FAILED - $ErrorLog !!" $true
        }  
    }
    else {
        Write-Host "$sitepath$SiteBackupFolderName Site not found" -forgroundcolor Red
        LogWrite "$sitepath$SiteBackupFolderName Site not found" $true
        Write-Host "Exiting Build Process!" -foregroundcolor Red
        Start-Sleep 3
        Exit-PSSession
    }
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


Write-Host "`n`t ************************ SITE BACKUP ************************ `n"
LogWrite " ************************ SITE BACKUP ************************ "
# Site Backup
foreach($SiteBackupFolderName in $SiteNameList){
    StartSiteBackup $SiteBackupFolderName.SiteName
}

Write-Host "`n`t ************************ REMOVING FILES ************************ `n"
LogWrite " ************************ REMOVING FILES ************************ "
# Delete file and Folder in WebSite
foreach($WebsitName in $SiteNameList){
    StartDeleteFileAndFolder $WebsitName.SiteName
}
#Create Log Folder with date 
$getbackdate = $((Get-Date).ToString('yyyyMMddHHmm'))
$logfolder = "$logpath$getbackdate"

if(-not (Test-Path  $logfolder -PathType Container)){
    $ErrorLog= New-Item -ItemType Directory $logfolder

    if ( $? ){
        Write-Host "$logfolder Folder successfully created" -ForegroundColor Green
        LogWrite "$logfolder Folder successfully created!!"       
    }
    else{
        $ErrorLog= $Error[0].Exception.Message 
        Write-Host "Folder Not Created" -ForegroundColor Red
        LogWrite "FOLDER NOT CREATED - $ErrorLog !!", $true
    }  
}

# EXTRACT BUILD ZIP FILE
# Set winrar path
if (Test-Path -path  "C:\Program Files (x86)\WinRAR\unrar.exe"){
   $unrar="C:\Program Files (x86)\WinRAR\unrar.exe"
}
else{
    $unrar = "C:\Program Files\WinRAR\unrar.exe"
}

$DeployedPath = $BuildFolder.Path
$Newestfile = (Get-ChildItem -r -path "$DeployedPath" -fi *.rar | Sort-Object @{expression={$_.LastWriteTime};Descending=$true} | Select-Object Directory,
Name, LastWriteTime | Group-Object Directory | ForEach-Object {$_.Group | Select-Object -first 1})
$new = $Newestfile.Name
$Zips = Get-ChildItem -filter "$new" -path $DeployedPath -Recurse

#Extract WebSite rar File
LogWrite "$Zips.FullName Extract WebSite rar File!!"
&$unrar x -y -r $Zips.FullName $DeployedPath
#Get-Process $unrar | Wait-Process

$SiteNameList = $JsonObject.WebSite
$AppFolder = $JsonObject.FolderPath
$DeploySiteNameList = $JsonObject.BuildSiteName
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'
$getbackdate = $((Get-Date).ToString('yyyyMMddHHmm'))
$toBeDeployedPath = $JsonObject.ToBeDeployedPath
$sortedfile = Get-ChildItem -Path $toBeDeployedPath.Path | Where-Object {$_.PSIsContainer} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$pathseparater = $sortedfile.Name + '\'
$CopyLogFolder = $logfolder
function BuildSite {
    param (
        [string] $buildDestinationSite,
        [string] $buildSourceSite,
        [string] $sitealise
    )
    process{

        $buildSourceSitepath = $toBeDeployedPath.Path + $pathseparater + $buildSourceSite
        $buildDestinationSitepath =  $AppFolder.path + $buildDestinationSite
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

        if($site -match $siteAlliesList[$valueat]){
            $DeploySiteNameList | foreach-Object{
                if($_ -match $siteAlliesList[$valueat]){
                    $buildDestinationSite = $_.SiteName
                    $buildSourceSite = $site.SiteName
                    BuildSite $buildSourceSite $buildDestinationSite $siteAlliesList[$valueat]
                }
            }
        }
    }
    $valueat++
} while ($valueat -lt 9)

# Set New Bild Version AND Sync Version 
$NewSyncVersion=$Newbuildversion.Substring(0,8)
# Get the old build version for web.config file 
# And save on oldbuildVersion.txt file
# Replace build version and syncversion in web.config file
$configfilepath =  $AppFolder.path + $mainSite
$config = "$configfilepath\Web.config"
$doc = (Get-Content $config) -as [Xml]
$root = $doc.get_DocumentElement();
$SyncVersion = $root.appSettings.add | Where-Object {$_.key -eq 'SyncVersion'};
$BuildVersion = $root.appSettings.add | Where-Object {$_.key -eq 'BuildVersion'};
$BuildVersionValue = $BuildVersion.value
$BuildVersionValue | Out-File $logfolder\oldbuildVersion.txt
$SyncVersion.SetAttribute("value", "$NewSyncVersion");
$BuildVersion.SetAttribute("value", "$Newbuildversion");
$doc.Save($config)

    <#
        1. Code to get the Date difference between the Previouse build and current build
        2. Commented becouse the date wise scripts are not in use.

        # Get the build date difference 
        [String] $SyncFormatedDate = ([datetime]::parseexact($SyncVersionvalue,"yyyyMMdd",[System.Globalization.CultureInfo]::InvariantCulture)).ToString("yyyy-MM-dd")
        [String] $NewSyncFormatedDate = ([datetime]::parseexact($NewSyncVersion,"yyyyMMdd",[System.Globalization.CultureInfo]::InvariantCulture)).ToString("yyyy-MM-dd")
        $outputjson = $logfolder+'\DateDifference.json'
        $startDate = Get-Date $SyncFormatedDate
        $endDate = Get-Date $NewSyncFormatedDate

        while($startDate -le $endDate)
        {
            $nextDate = $startDate.ToString('yyyyMMdd')
            Out-File -FilePath $outputjson -InputObject $nextDate -Append 
            $startDate = $startDate.AddDays(1)
        }

        if ( $? )
        {
            Write-Host "New Build difference File created successfully!!" -ForegroundColor Green
            LogWrite "New Build difference File created successfully!!"        
        }
        else{
            $ErrorLog= $Error[0].Exception.Message 
            Write-Host "ERROR :- New Build difference File not created  $sapdeployesite to $SAPSITE!!" -ForegroundColor Red
            LogWrite "BUILD DIFFERENECE OUTPUT FILE NOT CREATED - $ErrorLog !!" $true
        } 
    #>


# Extract the Admin, SA, ST, SW Schema and Data Script 
Write-Host "`n`t ************************ EXTRATING SCRIPT ************************ `n"
LogWrite " ************************ EXTRATING SCRIPT ************************ "
$ErrorLog = .\ExtractScript.ps1 $logfolder -Wait
if ( $? ){
    Write-Host "New Script File crated successfully!!" -ForegroundColor Green
    LogWrite "New Script File crated successfully!!"
}
else {
    $ErrorLog= $Error[0].Exception.Message 
    Write-Host "ERROR :- Script File not created  $sapdeployesite to $SAPSITE!!" -ForegroundColor Red
    LogWrite "SCRIPT FILE NOT CREATED - $ErrorLog !!" $true
} 

#Start Script execution ON Database
.\SQLScriptExecute.ps1 $logfolder

