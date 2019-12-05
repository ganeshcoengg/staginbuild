<#
    1. Read json file as row data 
    2. Convert Json data to Json Object
    3. Write LogWrite Method to custome log 
    4. Get the Previous Build date
    5. Method to check matching date is available in script
    6. If date availabel then extract all scripts form matching date 
#>

#Get the parameter
Param(
    [String] $logfolder             
)
$jsonData = (Get-Content ".\config.json" -Raw)
$jsonObject = ConvertFrom-Json -InputObject $jsonData
$logpath = $JsonObject.BuildLogsPath.Path
$logfile = $logpath+((Get-Date).ToString('yyyyMMdd'))+'_BuildDeploymentLogs.txt'
$isERPorCnF = $jsonObject.ERPorCnF.isERPorCnF
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

    <#
        1. Commented becouse the date wise scripts are not in use.

        # Read json file as row data 
        # Check DateDifference.json file is created or not. if yes then get the dateList
        if(Test-Path -Path $logfolder){
            $pathOfDateDifferenceJson = $logfolder+'\DateDifference.json'
            if(test-path -Path $pathOfDateDifferenceJson){
                Write-Host "DateDifference Json file found!" -ForegroundColor Green
                LogWrite "DateDifference Json file found!"
                $dateListContent =Get-Content -Path $pathOfDateDifferenceJson
            }
            else {
                Write-Host "DateDifference json file not found" -ForegroundColor red
                LogWrite "DateDifference json file not found" $true
            }
        }
        else{
            Write-Host "Pease check the Logfolder is created or not! $logfolder" -ForegroundColor Red
            LogWrite "Pease check the Logfolder is created or not! $logfolder" $true
        }
    #>

# Convert Json data to Json Object
$WebsitName.SiteName
$rootpath = $jsonObject.FolderPath.Path+$jsonObject.WebSite.SiteName[0]
$ExtractScriptHere = $logfolder
$CustomerName = $jsonObject.CustomerName.Name

if($isERPorCnF.toUpper() -eq "ERP"){
    $AdminScriptPath = $rootpath+"\App_Data\Admin\OfficeBOX"
    $CustomerAdminScriptPath = $rootpath+"\App_Data\Admin\OfficeBOX\"+$CustomerName

}
elseif ($isERPorCnF.toUpper() -eq "CNF") {
    $AdminScriptPath = $rootpath+"\App_Data\Admin\Logistics\Common"
    $CustomerAdminScriptPath = $rootpath+"\App_Data\Admin\Logistics\"+$CustomerName
}


$SAScriptPath = $rootpath+"\App_Data\Subscriber_Admin"
$CustomerSAScriptPath = $rootpath+"\App_Data\Subscriber_Admin\"+$CustomerName
$STScriptPath = $rootpath+"\App_Data\Subscriber_Transaction"
$SWScriptPath = $rootpath+"\App_Data\Subscriber_Work"

function LogWrite {
    param (
        [string] $logString
    )
    $time = Get-Date
    $string = '*** ' +$time.ToString() + ' == ' + $logString
    Add-Content $logfile -Value $string
}

# function to Extract the Script from machine date
function ExtractScriptsToBeExecuted {
    param (
        [string] $ScritpFile,
        [string] $ExecutedScriptFile
    )
    $isScriptWriteFlag = $false
    $ScritpFileContent = Get-Content $ScritpFile
    Write-Host "Extracting Script $ScritpFile..." -NoNewline
    LogWrite "Extracting Script $ScritpFile..."
    try{
        foreach($checkdate in $dateListContent){
            $isDatepresent = $ScritpFileContent | ForEach-Object {$_ -match $checkdate}
            if($isDatepresent -contains $true){
                $previousBuildDate = $checkdate
                break
            }
        }
        if(-not([string]:: IsNullOrEmpty($previousBuildDate))){
             $ScritpFileContent | ForEach-Object {
                if($_ -match $previousBuildDate){
                    $isScriptWriteFlag = $true
                }
                if($isScriptWriteFlag){
                    Add-Content -Path $ExecutedScriptFile -Value $_
                }
            }
        }
        else{
            Write-Host "Previouse build date missing for $ExecutedScriptFile!" -ForegroundColor Yellow
            LogWrite "Previouse build date missing for $ExecutedScriptFile!"
            Add-Content -Path $ExecutedScriptFile -Value "/* No Script to Execute */"
        }
    }
    catch{
        Write-Host "Missing file ==> $ExecutedScriptFile " -ForegroundColor Red
        LogWrite "Missing file ==> $ExecutedScriptFile" $true
    }
    finally{
        Write-Host "Done!" -ForegroundColor Green
        LogWrite "Done!"
    }
}

# Extract Script of Admin Schema
# Chech Script file is present 
$AdminSchema = $AdminScriptPath + "\syncSchema.sql"
$ExtractScriptHereAdminSchema = $ExtractScriptHere+"\ADMIN_SCHEMA.sql"
if(Test-Path -Path $AdminSchema){
    if(Test-Path -Path $ExtractScriptHere){
        #ExtractScriptsToBeExecuted $AdminSchema $ExtractScriptHereAdminSchema
        Copy-Item -Path $AdminSchema -Destination $ExtractScriptHereAdminSchema
    }
    else{
        Write-Host "$ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host "$AdminSchema Script is not available" -ForegroundColor Red
    LogWrite "$AdminSchema Script is not available" $true
}

# Extract Script of Admin Data
$AdminData = $AdminScriptPath + "\syncData.sql"
$ExtractScriptHereAdminData = $ExtractScriptHere+"\ADMIN_DATA.sql"
if(Test-Path -Path $AdminData){
    if(Test-Path -Path $ExtractScriptHere){
      #ExtractScriptsToBeExecuted $AdminData $ExtractScriptHereAdminData
      Copy-Item -Path $AdminData -Destination $ExtractScriptHereAdminData
    }
    else{
        Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host " $AdminData Script is not available" -ForegroundColor Red
    LogWrite "$AdminData Script is not available" $true
}


#Check Cutomer wise Script Are availabel or not
$CustomerAdminData = $CustomerAdminScriptPath + "\syncData.sql"
$ExtractScriptHereCustomerAdminData = $ExtractScriptHere+"\CUSTOMER_ADMIN_DATA_SCRIPT.sql"
if(test-path -Path $CustomerAdminData){
    if(Test-Path -Path $ExtractScriptHere){
        #ExtractScriptsToBeExecuted $AdminData $ExtractScriptHereAdminData
        Copy-Item -Path $CustomerAdminData -Destination $ExtractScriptHereCustomerAdminData
      }
      else{
          Write-Host " $ExtractScriptHereCustomerAdminData <== is not created" -ForegroundColor Yellow
          LogWrite " $ExtractScriptHereCustomerAdminData <== is not created"
      }
}
else{
    Write-Host "Customer specific admin data script is not available." -ForegroundColor Red
    LogWrite " Customer specific admin data script is not available." $true
}


# Extract Script of SA Schema
$SASchema = $SAScriptPath + "\syncSchema.sql"
$ExtractScriptHereSASchema = $ExtractScriptHere+"\SA_SCHEMA.sql"
if(Test-Path -Path $SASchema){
    if(Test-Path -Path $ExtractScriptHere){
      #ExtractScriptsToBeExecuted $SASchema $ExtractScriptHereSASchema
      Copy-Item -Path $SASchema -Destination $ExtractScriptHereSASchema
    }
    else{
        Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host "$SASchema Script is not available" -ForegroundColor Red
    LogWrite "$SASchema Script is not available" $true
}

# Extract Script of SA Data
$SAData = $SAScriptPath + "\syncData.sql"
$ExtractScriptHereSAData = $ExtractScriptHere+"\SA_DATA.sql"
if(Test-Path -Path $SAData){
    if(Test-Path -Path $ExtractScriptHere){
      #ExtractScriptsToBeExecuted $SAData $ExtractScriptHereSAData
      Copy-Item -Path $SAData -Destination $ExtractScriptHereSAData
    }
    else{
        Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host "$SAData Script is not available" -ForegroundColor Red
    LogWrite "$SAData Script is not available" $true
}

$CustomerSAData = $CustomerSAScriptPath + "\syncData.sql"
$ExtractScriptHereCustomerSAData = $ExtractScriptHere+"\CUSTOMER_SA_DATA_SCRIPT.sql"
if(test-path -Path $CustomerSAData){
    if(Test-Path -Path $ExtractScriptHere){
        #ExtractScriptsToBeExecuted $AdminData $ExtractScriptHereAdminData
        Copy-Item -Path $CustomerSAData -Destination $ExtractScriptHereCustomerSAData
      }
      else{
          Write-Host " $ExtractScriptHereCustomerSAData <== is not created" -ForegroundColor Yellow
          LogWrite " $ExtractScriptHereCustomerSAData <== is not created"
      }
}
else{
    Write-Host "Customer specific SA data script is not available." -ForegroundColor Red
    LogWrite "Customer specific SA data script is not available." $true

}

# Extract Script of ST Schema
$STSchema = $STScriptPath + "\syncSchema.sql"
$ExtractScriptHereSTSchema = $ExtractScriptHere+"\ST_SCHEMA.sql"
if(Test-Path -Path $STSchema){
    if(Test-Path -Path $ExtractScriptHere){
      #ExtractScriptsToBeExecuted $STSchema $ExtractScriptHereSTSchema
      Copy-Item -Path $STSchema -Destination $ExtractScriptHereSTSchema
    }
    else{
        Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host "$STSchema Script is not available" -ForegroundColor Red
    LogWrite "$STSchema Script is not available" $true
}

# Extract Script of ST Data
$STData = $STScriptPath + "\syncData.sql"
$ExtractScriptHereSTData = $ExtractScriptHere+"\ST_DATA.sql"
if(Test-Path -Path $STData){
    if(Test-Path -Path $ExtractScriptHere){
      #ExtractScriptsToBeExecuted $STData $ExtractScriptHereSTData
      Copy-Item -Path $STData -Destination $ExtractScriptHereSTData
    }
    else{
        Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host "$STData Script is not available" -ForegroundColor Red
    LogWrite "$STData Script is not available" $true
}

# Extract Script of SW Schema

$SWSchema = $SWScriptPath + "\syncSchema.sql"
$ExtractScriptHereSWSchema = $ExtractScriptHere+"\SW_SCHEMA.sql"
if(Test-Path -Path $SWSchema){
    if(Test-Path -Path $ExtractScriptHere){
      #ExtractScriptsToBeExecuted $SWSchema $ExtractScriptHereSWSchema
      Copy-Item -Path $SWSchema -Destination $ExtractScriptHereSWSchema
    }
    else{
        Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
        LogWrite "$ExtractScriptHere directory not available" $true
    }
}
else{
    Write-Host "$SWSchema Script is not available" -ForegroundColor Red
    LogWrite "$SWSchema Script is not available" $true
}

# # Extract Script of SW Data
# $SWData = $SWScriptPath + "\syncData.sql"
# $ExtractScriptHereSWData = $ExtractScriptHere+"\SW_DATA.sql"
# if(Test-Path -Path $SWData){
#     if(Test-Path -Path $ExtractScriptHere){
#       #ExtractScriptsToBeExecuted $SWData $ExtractScriptHereSWData
#        Copy-Item -Path $SWData -Destination $ExtractScriptHereSWData
#     }
#     else{
#         Write-Host " $ExtractScriptHere directory not available" -ForegroundColor Yellow
#         LogWrite "$ExtractScriptHere directory not available" $true
#     }
# }
# else{
#     Write-Host " $SWData Script is not available" -ForegroundColor Red
# }