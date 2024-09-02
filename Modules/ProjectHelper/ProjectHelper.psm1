<#
.SYNOPSIS
Creates a new project with specified parameters and uploads source files.

.DESCRIPTION
The `New-Project` function creates a new project using the provided access key and project details. 
The project can be configured with various optional parameters such as source and target languages, customer details, 
location, project template, and more. The function also handles the uploading of source files and initiates the project workflow.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.PARAMETER projectName
The name of the project to be created. This is a mandatory parameter.

.PARAMETER projectDueDate
The due date for the project in a string format. This is a mandatory parameter.

.PARAMETER filesPath
The path to the directory containing the source files to be uploaded for the project. This is a mandatory parameter.

.PARAMETER referenceFileNames
An optional array of reference file names to be included in the project. These files should be located in the directory specified by `filesPath`.

.PARAMETER sourceLanguage
The source language code of the project.

.PARAMETER targetLanguages
An optional array of target language codes for the project. 

.PARAMETER customer
The customer associated with the project. This can be either the name or the ID of the customer.

.PARAMETER location
The location where the project will be managed. This can be either the name or the ID of the location.

.PARAMETER description
An optional description of the project.

.PARAMETER projectTemplate
An optional project template to be used for the project. If a template is provided, most other parameters can be omitted as the template will define them.

.PARAMETER translationEngine
The translation engine to be used for the project. This can be either the name or the ID of the engine.

.PARAMETER fileProcessingConfiguration
An optional file processing configuration to be used for the project. This can be either the name or the ID of the configuration.

.PARAMETER workflow
An optional workflow to be applied to the project. This can be either the name or the ID of the workflow.

.PARAMETER pricingModel
An optional pricing model for the project. This can be either the name or the ID of the model.

.PARAMETER restrictFileDownloadSpecified
A switch that, when specified, allows the user to control whether file downloads are restricted.

.PARAMETER restrictFileDownload
A boolean value indicating whether file downloads should be restricted. Default is `$false`.

.PARAMETER scheduletemplate
An optional schedule template to be used for the project. This can be either the name or the ID of the template.

.PARAMETER userManagers
An optional array of user managers who will oversee the project.

.PARAMETER groupsManager
An optional array of groups that will manage the project.

.PARAMETER includeSettings
A boolean value indicating whether to include additional settings in the project configuration. Default is `$false`.

.PARAMETER configCompleteDays
The number of days after which the project is considered complete. Default is `90` days.

.PARAMETER configArchiveDays
The number of days after which the project is archived. Default is `90` days.

.PARAMETER configReminderDays
The number of days before a reminder is sent out. Default is `7` days.

.EXAMPLE
New-Project -accessKey $accessKey -projectName "New Localization Project" -projectDueDate "2024-12-31" -filesPath "C:\ProjectFiles" `
            -sourceLanguage "en-us" -targetLanguages @("fr-FR", "de-DE") -location "LocationName" -fileProcessingConfiguration "File Processing Configuration Name"

This example creates a new project with the specified source and target languages, location and file type configuration, and uploads the source files from the specified path.

.EXAMPLE
New-Project -accessKey $accessKey -projectName "Template Based Project" -projectDueDate "2024-12-31" `
            -filesPath "C:\ProjectFiles" -projectTemplate "StandardTemplate"

This example creates a new project using a predefined project template. Other parameters such as languages and workflow are automatically set based on the template.

.NOTES
Either `location` or `customer` must be provided to determine where the project will be managed. If `projectTemplate` is provided, 
most other parameters can be omitted as they will be automatically configured based on the template.

#>
function New-Project 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(mandatory=$true)]
        [String] $projectName,

        [Parameter(mandatory=$true)]
        [String] $projectDueDate,

        [Parameter(Mandatory=$true)]
        [String] $filesPath,

        [String[]] $referenceFileNames,
        [String] $sourceLanguage,
        [String[]] $targetLanguages,
        [String] $customer,
        [String] $location,
        [String] $description,
        [String] $projectTemplate,
        [String] $translationEngine,
        [String] $fileProcessingConfiguration,
        [String] $workflow,
        [String] $pricingModel,
        [Switch] $restrictFileDownloadSpecified,
        [Bool] $restrictFileDownload = $false, 
        [String] $scheduletemplate,
        [String[]] $userManagers,
        [String[]] $groupsManager,
        [Bool] $includeSettings = $false,
        [Int32] $configCompleteDays = 90,
        [Int32] $configArchiveDays = 90,
        [Int32] $configReminderDays = 7
    )

    $projectBody = Get-ProjectBody -accessKey $accessKey -name $projectName -dueBy $projectDueDate `
                                   -sourceLanguage $sourceLanguage -targetLanguages $targetLanguages `
                                   -customerName $customer -location $location -description $description `
                                   -projectTemplate $projectTemplate -translationEngine $translationEngine `
                                   -fileProcessingConfiguration $fileProcessingConfiguration -workflow $workflow `
                                   -pricingModel $pricingModel -scheduletemplate $scheduletemplate `
                                   -restrictFileDownload $restrictFileDownload -userManagers $userManagers `
                                   -groupManagers $groupsManager -includeSettings $includeSettings `
                                   -configCompleteDays $configCompleteDays -configArchiveDays $configArchiveDays `
                                   -configReminderDays $configReminderDays -restrictFileDownloadSpecified $restrictFileDownloadSpecified

    $projectCreateResponse = Get-ProjectCreationRequest -accessKey $accessKey -project $projectBody
    Write-Host "Creating the project..." -ForegroundColor Green

    if ($null -eq $projectCreateResponse)
    {
        return;
    }

    $sourceLang = $projectCreateResponse.languageDirections[0].sourceLanguage.languageCode;

    Write-Host "Adding the source files..." -ForegroundColor Green
    Add-SourceFiles $accessKey $projectCreateResponse.Id $sourceLang $filesPath $referenceFileNames

    $null = Start-Project $accessKey $projectCreateResponse.Id;
    Write-Host "Project created..." -ForegroundColor Green
}

function Start-Project
{
    param (
        [psobject] $accessKey,
        [String] $projectId)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    return Invoke-RestMethod "https://lc-api.sdl.com/public-api/v1/projects/$projectId/start" -Method 'PUT' -Headers $headers
}

function Add-File
{
    param (
        [psobject] $accessKey,
        [String] $projectId,
        [psobject] $file,
        [psobject] $properties
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "multipart/form-data")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

        
    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
    $stringHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $stringHeader.Name = "properties"
    $json = $properties | ConvertTo-Json -depth 5;
    $stringContent = [System.Net.Http.StringContent]::new($json)
    $stringContent.Headers.ContentDisposition = $stringHeader
    $multipartContent.Add($stringContent)

    $multipartFile = $file.FullName
    $FileStream = [System.IO.FileStream]::new($multipartFile, [System.IO.FileMode]::Open)
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileHeader.Name = "file"
    $fileHeader.FileName = $file.FullName
    $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $multipartContent.Add($fileContent)

    $body = $multipartContent
    
    try {
     $null = Invoke-RestMethod "https://lc-api.sdl.com/public-api/v1/projects/$projectId/source-files" -Method 'POST' -Headers $headers -Body $body
     Write-Host "File [" $file.Name "] added" -ForegroundColor Green
    }
    catch 
    {
        Write-Host "Error adding the file" $file.Name "$_." -ForegroundColor Red
    }
}

function Add-SourceFiles 
{
    param (
        [psobject] $accessKey,
        [string] $projectId,
        [String] $sourceLanguage,
        [String] $filesPath,
        [string[]] $referenceFileNames
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "multipart/form-data")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    $files = @();
    if (Test-Path $filesPath) {
        $item = Get-Item $filesPath
        if ($item.PSIsContainer) {
            $files = Get-ChildItem -Path $filesPath -Recurse -File
        } else {
            $files += Get-Item $filesPath
        }
    }
    else 
    {
        return;
    }

    foreach ($file in $files)
    {
        if ($file.Name -in $referenceFileNames)
        {
            $fileRole = "reference"
        }
        else 
        {
            $fileRole = "translatable"
        }

        if ($file.FullName.EndsWith(".sdlxliff"))
        {
            $fileType = "sdlxliff"
        }
        else 
        {
            $fileType = "native"
        }

        $properties = [ordered]@{
            name = $file.Name
            role = $fileRole
            type = $fileType
            language = $sourceLanguage
        }

        $null = Add-File $accessKey $projectId $file $properties
    }   

}

function Get-ProjectBody
{
    param (
        [psobject] $accessKey,
        [String] $name,
        [String] $dueBy,
        [String] $sourceLanguage,
        [String[]] $targetLanguages,
        [String] $customerName,
        [string] $location,
        [String] $description,
        [String] $projectTemplate,
        [String] $translationEngine,
        [String] $fileProcessingConfiguration,
        [String] $workflow,
        [String] $pricingModel,
        [String] $scheduletemplate,
        [Bool] $restrictFileDownload = $false,
        [Switch] $restrictFileDownloadSpecified,
        [String[]] $userManagers,
        [String[]] $groupManagers,
        [Bool] $includeSettings = $false,
        [Int32] $configCompleteDays = 90,
        [Int32] $configArchiveDays = 90,
        [Int32] $configReminderDays = 7
    )

    $project = [ordered]@{
        "name" = $name
        "dueBy" = $dueBy
        "languageDirections" = @($(Get-LanguageDirections $sourceLanguage $targetLanguages))
        "description" = $description
    }

    if ($customerName)
    {
        $customerObject = Get-ResourceByNameOrId -accessKey $accessKey -resourceIdOrName $customerName -resourceType "Customer"
        $project.location = $customerObject.location.id
    }
    elseif ($location)
    {
        $locationObject = Get-ResourceByNameOrId -accessKey $accessKey -resourceIdOrName $location -resourceType "Location"
        $project.location = $locationObject.id;
    }

    Get-And-AssignResource -accessKey $accessKey -project $project -resourceName $projectTemplate -resourceType "ProjectTemplate" -propertyName "projectTemplate"
    Get-And-AssignResource -accessKey $accessKey -project $project -resourceName $translationEngine -resourceType "TranslationEngine" -propertyName "translationEngine"
    Get-And-AssignResource -accessKey $accessKey -project $project -resourceName $fileProcessingConfiguration -resourceType "FileProcessingConfiguration" -propertyName "fileProcessingConfiguration"
    Get-And-AssignResource -accessKey $accessKey -project $project -resourceName $workflow -resourceType "Workflow" -propertyName "workflow"
    Get-And-AssignResource -accessKey $accessKey -project $project -resourceName $pricingModel -resourceType "PricingModel" -propertyName "pricingModel"
    Get-And-AssignResource -accessKey $accessKey -project $project -resourceName $scheduleTemplate -resourceType "ScheduleTemplate" -propertyName "scheduleTemplate"
    Get-And-AssignProjectManagers -accessKey $accessKey -project $project -userManagers $userManagers -groupsManagers $groupManagers

    if ($projectTemplate -and $project.languageDirections.Count -eq 0) {
        $templateObject = Get-ResourceByNameOrId $accessKey $projectTemplate "projectTemplate"
        $project.languageDirections = $templateObject.languageDirections
    }
    
    if ($restrictFileDownloadSpecified)
    {
        $project.forceOnline = $restrictFileDownload.ToString().ToLower();
    }
    
    if ($includeSettings)
    {
        $projectsettings = @{
            "general" = @{
                "completeDays" = $configCompleteDays
                "archiveDays" = $configArchiveDays
                "archiveReminderDays" = $configReminderDays
            } 
        }

        $project.settings = $projectsettings;
    }

    return $project
}

function Get-ProjectCreationRequest 
{
    param (
        [psobject] $accessKey,
        [psobject] $project
    )

    $json = $project | ConvertTo-Json -Depth 5;
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    try 
    {
        return Invoke-RestMethod 'https://lc-api.sdl.com/public-api/v1/projects' -Method 'POST' -Headers $headers -Body $json;
    }
    catch {
        Write-Host "$_"
    }
}

function Get-And-AssignProjectManagers
{
    param (
        [psobject] $accessKey,
        [psobject] $project,
        [string[]] $userManagers,
        [string[]] $groupsManagers
    )

    $managers = @();
    if ($userManagers)
    {
        $users = Get-Items -accessKey $accessKey -resourceType "User";
        
        foreach ($manager in $userManagers) {
            $matchingUser = $users | Where-Object { 
                $_.id -eq $manager -or ($_.email -and $_.email -eq $manager) 
            }
            
            foreach ($user in $matchingUser) {
                $managers += @{
                    "id"   = $user.id
                    "type" = "user"
                }
            }
        }
    }

    if ($groupManagers) {
        $groups = Get-Items -accessKey $accessKey -resourceType "Group"
    
        foreach ($manager in $groupManagers) {
            $matchingGroup = $groups | Where-Object {
                $_.id -eq $manager -or $_.name -eq $manager
            }
            
            foreach ($group in $matchingGroup) {
                $managers += @{
                    "id"   = $group.id
                    "type" = "group"
                }
            }
        }
    }

    if ($managers.Count -gt 0) {
        $project["projectManagers"] = @($managers)
    }
}

function Get-LanguageDirections 
{
    param (
        [String] $sourceLanguage,
        [String[]] $targetLanguages
    )

    $result = @()

    foreach ($language in $targetLanguages)
    {
        $sourceLanguageObject = @{"languageCode" = $sourceLanguage}
        $targetLanguageObject = @{"languageCode" = $language}

        $result += @{
            "sourceLanguage" = $sourceLanguageObject
            "targetLanguage" = $targetLanguageObject
        }
    }

    return $result;
}

function Get-And-AssignResource
{
    param (
        [psobject] $accessKey,
        [psobject] $project,
        [string] $resourceName,
        [string] $resourceType,
        [String] $propertyName
    )

    if ($resourceName)
    {
        $resource = Get-ResourceByNameOrId $accessKey $resourceName $resourceType
        $project[$propertyName] = @{
            "id" = $resource.Id
            "strategy" = "copy"
        }

    }
}

function Get-ResourceByNameOrId
{
    param (
        [psobject] $accessKey,
        [String] $resourceIdOrName,
        [String] $resourceType
    )

    $items = Get-Items $accessKey $resourceType;
    foreach ($item in $items)
    {
        if ($item.Name -eq $resourceIdOrName -or $item.Id -eq $resourceIdOrName)
        {
            return $item;
        }
    }
}

function Get-Items 
{
    param (
        [psobject] $accessKey,
        [String] $resourceType
    )

    $resourceFunctions =  @{
        "Customer"                 = "Get-AllCustomers"
        "ProjectTemplate"          = "Get-AllProjectTemplates"
        "TranslationEngine"        = "Get-AllTranslationEngines"
        "FileProcessingConfiguration" = "Get-AllFileTypeConfigurations"
        "Workflow"                 = "Get-AllWorkflows"
        "PricingModel"             = "Get-AllPricingModels"
        "ScheduleTemplate"         = "Get-AllScheduleTemplates"
        "User"                     = "Get-AllUsers"
        "Group"                    = "Get-AllGroups"
        "Location"                 = "Get-AllLocations"
    }

    if ($resourceFunctions.ContainsKey($resourceType)) 
    {
        return & $resourceFunctions[$resourceType] $accessKey
    }
}

Export-ModuleMember New-Project;