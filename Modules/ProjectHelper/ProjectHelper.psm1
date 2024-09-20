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

        [Parameter(Mandatory=$true)]
        [string] $name,

        
        [PArameter(Mandatory=$true)]
        [string] $dueDate,
        
        [Parameter(Mandatory=$true)]
        [string] $dueTime,
        
        [Parameter(Mandatory=$true)]
        [string] $filesPath,

        [string[]] $referenceFileNames,
        
        [string] $locationId,
        [string] $locationName,
        
        [string] $projectTemplateIdOrName,
        [string] $fileTypeConfigurationIdOrName,
        [string] $sourceLanguage,
        [string[]] $targetLanguages,
        [string[]] $userManagerIdsOrNames,
        [string[]] $groupManagerIdsOrNames,
        [string[]] $customFieldIdsOrNames,
        [string] $translationEngineIdOrName,
        [string] $pricingModelIdOrName,
        [string] $workflowIdOrName,
        [string] $tqaIdOrName,
        [string] $scheduleTemplateIdOrName,

        [string] $scheduleTemplateStrategy = "copy",
        [string] $fileTypeConfigurationStrategy = "copy",
        [string] $translationEngineStrategy = "copy",
        [string] $pricingModelStrategy = "copy",
        [string] $workflowStrategy = "copy",
        [string] $tqaStrategy = "copy",
        [bool] $includeFileDownloadSettings = $false,
        [bool] $restrictFileDownload = $false,
        [bool] $inclueGeneralSettings,
        [int] $completeDays = 90,
        [int] $archiveDays = 90,
        [int] $archiveReminderDays = 7,
        [string] $description
    )

    $projectBody = Get-ProjectBody `
        -accessKey $accessKey `
        -name $name `
        -projectTemplateIdOrName $projectTemplateIdOrName `
        -dueDate $dueDate `
        -dueTime $dueTime `
        -locationId $locationId `
        -locationName $locationName `
        -fileTypeConfigurationIdOrName $fileTypeConfigurationIdOrName `
        -sourceLanguage $sourceLanguage `
        -targetLanguages $targetLanguages `
        -userManagerIdsOrNames $userManagerIdsOrNames `
        -groupManagerIdsOrNames $groupManagerIdsOrNames `
        -customFieldIdsOrNames $customFieldIdsOrNames `
        -translationEngineIdOrName $translationEngineIdOrName `
        -pricingModelIdOrName $pricingModelIdOrName `
        -workflowIdOrName $workflowIdOrName `
        -tqaIdOrName $tqaIdOrName `
        -scheduleTemplateIdOrName $scheduleTemplateIdOrName `
        -scheduleTemplateStrategy $scheduleTemplateStrategy `
        -fileTypeConfigurationStrategy $fileTypeConfigurationStrategy `
        -translationEngineStrategy $translationEngineStrategy `
        -pricingModelStrategy $pricingModelStrategy `
        -workflowStrategy $workflowStrategy `
        -tqaStrategy $tqaStrategy `
        -includeFileDownloadSettings $includeFileDownloadSettings `
        -restrictFileDownload $restrictFileDownload `
        -inclueGeneralSettings $includeFileDownloadSettings `
        -completeDays $completeDays `
        -archiveDays $archiveDays `
        -archiveReminderDays $archiveReminderDays `
        -description $description;

    # return @($projectBody | ConvertTo-Json -Depth 10);
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

    return Invoke-SafeMethod -method {
        Invoke-RestMethod -Uri "https://lc-api.sdl.com/public-api/v1/projects/$projectId/start" -Method Put     -Headers $headers
    }
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
    
    Invoke-SafeMethod {
        $null = Invoke-RestMethod "https://lc-api.sdl.com/public-api/v1/projects/$projectId/source-files" -Method 'POST' -Headers $headers -Body $body
        Write-Host "File [" $file.Name "] added" -ForegroundColor Green
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
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $name,
        [string] $projectTemplateIdOrName,

        [string] $dueDate,
        [string] $dueTime,
        [string] $locationId,
        [string] $locationName,

        [string] $fileTypeConfigurationIdOrName,
        [string] $sourceLanguage,
        [string[]] $targetLanguages,
        [string[]] $userManagerIdsOrNames,
        [string[]] $groupManagerIdsOrNames,
        [string[]] $customFieldIdsOrNames,
        [string] $translationEngineIdOrName,
        [string] $pricingModelIdOrName,
        [string] $workflowIdOrName,
        [string] $tqaIdOrName,
        [string] $scheduleTemplateIdOrName,

        [string] $scheduleTemplateStrategy = "copy",
        [string] $fileTypeConfigurationStrategy = "copy",
        [string] $translationEngineStrategy = "copy",
        [string] $pricingModelStrategy = "copy",
        [string] $workflowStrategy = "copy",
        [string] $tqaStrategy = "copy",
        [bool] $includeFileDownloadSettings = $false,
        [bool] $restrictFileDownload = $false,
        [bool] $inclueGeneralSettings,
        [int] $completeDays = 90,
        [int] $archiveDays = 90,
        [int] $archiveReminderDays = 7,
        [string] $description
    )
    
    $body = [ordered]@{
        name = $name
        description = $description
        dueBy = $dueDate + "T" + $dueTime + "Z"
    }

    $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    if ($location)
    {
        $body.location = $location.Id
    }
    else 
    {
        return;
    }

    if ($projectTemplateIdOrName)
    {
        $projectTemplate = Get-AllProjectTemplates -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                        | Where-Object {$_.Id -eq $projectTemplateIdOrName -or $_.Name -eq $projectTemplateIdOrName } `
                        | Select-Object -First 1;

        if ($null -eq $projectTemplate)
        {
            Write-Host "Project Template does not exist or it is not related to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $body.projectTemplate = @{id = $projectTemplate.Id}
    }

    if ($fileTypeConfigurationIdOrName)
    {
        $fileTypeConfiguration = Get-AllFileTypeConfigurations -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                            | Where-Object {$_.Id -eq $fileTypeConfigurationIdOrName -or $_.Name -eq $fileTypeConfigurationIdOrName } `
                            | Select-Object -First 1;
    
        if ($null -eq $fileTypeConfiguration)
        {
            Write-Host "File Type configuration does not exist or it is not related to the location $($location.Name)" -ForegroundColor Green;
            return
        }
        $body.fileProcessingConfiguration = @{
            id = $fileTypeConfiguration.Id
            strategy = $fileTypeConfigurationStrategy
        }
    }

    if ($sourceLanguage -and $targetLanguages)
    {
        $languageDirections = Get-LanguageDirections -sourceLanguage $sourceLanguage -targetLanguages $targetLanguages -languagePairs $languagePairs;
        if ($null -eq $languageDirections)  
        {
            Write-Host "Invalid languages" -ForegroundColor;
            return;
        }

        $body.languageDirections = @($languageDirections);
    }

    if ($translationEngineIdOrName)
    {
        $translationEngine = Get-AllTranslationEngines -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                            | Where-Object {$_.Id -eq $translationEngineIdOrName -or $_.Name -eq $translationEngineIdOrName} `
                            | Select-Object -First 1;
        
        if ($null -eq $translationEngine)
        {
            Write-Host "Translation Engine not found or not related to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $body.translationEngine = [ordered] @{
            id = $translationEngine.Id
            strategy = $translationEngineStrategy
        }
    }

    if ($pricingModelIdOrName)
    {
        $pricingModel = Get-AllPricingModels -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                        | Where-Object {$_.id -eq $pricingModelIdOrName -or $_.name -eq $pricingModelIdOrName } `
                        | Select-Object -First 1;

        if ($null -eq $pricingModel)
        {
            Write-Host "Pricing Model not found or not related to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $body.pricingModel = [ordered] @{
            id = $pricingModel.Id
            strategy = $pricingModelStrategy
        }
    }

    if ($workflowIdOrName)
    {
        $workflow = Get-AllWorkflows -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.Id -eq $workflowIdOrName -or $_.Name -eq $workflowIdOrName } `
                    | Select-Object -First 1;

        if ($null -eq $workflow)
        {
            Write-Host "Workflow not found or not related to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $body.workflow = [ordered] @{
            id = $workflow.Id 
            strategy = $workflowStrategy
        }
    }

    if ($tqaIdOrName)
    {
        $tqa = Get-AllTranslationQualityAssessments -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.id -eq $tqaIdOrName -or $_.name -eq $tqaIdOrName } `
                    | Select-Object -First 1;

        if ($null -eq $tqa)
        {
            Write-Host "Translation Quality Assessment not found or not related to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $body.tqaProfile = [ordered]@{
            id = $tqa.Id 
            strategy = $tqaStrategy
        }
    }

    if ($scheduleTemplateIdOrName)
    {
        $scheduleTemplate = Get-AllScheduleTemplates -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                        | Where-Object {$_.Id -eq $scheduleTemplateIdOrName -or $_.Name -eq $scheduleTemplateIdOrName } `
                        | Select-Object -First 1

        if ($null -eq $scheduleTemplate)
        {
            Write-Host "Schedule Template not found or not relate to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $body.scheduleTemplate = @{
            id = $scheduleTemplate.Id 
            strategy = $scheduleTemplateStrategy
        }
    }

    $projectManagers = @();
    if ($userManagerIdsOrNames)
    {
        $users = Get-AllUsers -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.id -in $userManagerIdsOrNames -or $_.email -in $userManagerIdsOrNames} `
                    | Select-Object -First 1;

        if ($null -eq $users -or $users.Count -ne $userManagerIdsOrNames.Count) {   
            $missingUsers = $userManagerIdsOrNames | Where-Object { $_ -notin $users.id -and $_ -notin $users.email }
            
            Write-Host "The following user IDs or emails were not found or are not related with the location $($location.Id): $missingUsers" -ForegroundColor Green;
            return;
        }

        # Create a list of users with "id" and "type" = "user"
        $userList = $users | ForEach-Object {
            [PSCustomObject]@{
                id   = $_.id
                type = "user"
            }

        }

        $projectManagers += $userList;
    }   

    if ($groupManagerIdsOrNames)
    {
        $groups = Get-AllGroups -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.Id -in $groupManagerIdsOrNames -or $_.Name -in $groupManagerIdsOrNames} `
                    | Select-Object -First 1

        if ($null -eq $groups -or $groups.Count -ne $groupManagerIdsOrNames.Count) 
        {   
            $missingGroups = $groupManagerIdsOrNames | Where-Object { $_ -notin $groups.id -and $_ -notin $groups.email }
            
            Write-Host "The following group IDs or names were not found or are not related with the location $($location.Id): $missingGroups" -ForegroundColor Green;
            return;
        }

        # Create a list of users with "id" and "type" = "user"
        $grouList = $groups | ForEach-Object {
            [PSCustomObject]@{
                id   = $_.id
                type = "group"
            }

        }

        $projectManagers += $grouList;
    }

    if ($projectManagers)
    {
        $body.projectManagers = @($projectManagers);
    }

    if ($customFieldIdsOrNames)
    {
        $customFields = Get-AllCustomFields -accessKey $accessKey -locationId $customer.Location.Id -locationStrategy "bloodline" `
                            | Where-Object {$_.Id -in $customFieldIdsOrNames -or $_.Name -in $customFieldIdsOrNames } `
                            | Where-Object {$_.ResourceType -eq "Project"} 
        
        if ($null -eq $customFields -or
            $customFields.Count -ne $customFieldIdsOrNames.Count)
        {   
            $missingFields = $customFieldIdsOrNames | Where-Object { $_ -notin $customFields.Id -and $_ -notin $customFields.Name }
            Write-Host "The following custom fields were not found: $missingFields" -ForegroundColor Green;
            return;
        }

        $fieldDefinitions = @();
        foreach ($customField in $customFields)
        {
            $fieldDefinition = [ordered] @{
            };
            if ($customField.defaultValue)
            {
                $fieldDefinition.key = $customField.key
                $fieldDefinition.value = $customField.defaultValue;
            }
            else 
            {
                Write-Host "Enter the key for Custom Field $($customField.Name) of type $($customField.Type)" -ForegroundColor Yellow
                if ($customField.pickListOptions)
                {
                    foreach ($pickList in $customField.pickListOptions)
                    {
                        Write-Host $pickList -ForegroundColor DarkYellow;
                    }
                }

                $fieldDefinition.key = $customField.key;
                $fieldDefinition.value = Read-Host 
            }

            $fieldDefinitions += $fieldDefinition;
        }

        $body.customFields = @($fieldDefinitions);
    }

    if ($includeFileDownloadSettings)
    {
        $body.forceOnline = $restrictFileDownload
    }

    if ($includeSettings)
    {
        $project.settings = [ordered]@{
            general = [ordered] @{
                forceOnline = $restrictFileDownload
                completeConfiguration = [ordered] @{
                    completeDays = $completeDays 
                    archiveDays = $archiveDays 
                    archiveReminderDays = $archiveReminderDays
                }
            }
        }
    }

    return $body
}

function Get-ProjectCreationRequest 
{
    param (
        [psobject] $accessKey,
        [psobject] $project
    )

    $json = $project | ConvertTo-Json -Depth 10;
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    return Invoke-SafeMethod {
        Invoke-RestMethod 'https://lc-api.sdl.com/public-api/v1/projects' -Method 'POST' -Headers $headers -Body $json;
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


function Get-LanguageDirections 
{
    param (
        [String[]] $sourceLanguage,
        [String[]] $targetLanguages
    )

    $languageDirections = @();
    if ($sourceLanguage -and $targetLanguages)
    {
        foreach ($target in $targetLanguages)
        {
    
            $languageDirection = [ordered]@{
                sourceLanguage = [ordered]@{languageCode = "$sourceLanguage"}
                targetLanguage = [ordered]@{languageCode = "$target"}
            }
            
            $languageDirections += $languageDirection;
        }
    
    }

    return $languageDirections;
}

function Invoke-SafeMethod 
{
    param (
        [Parameter(Mandatory=$true)]
        [scriptblock] $method
    )

    try {
        return & $Method
    } catch {
        $response = ConvertFrom-Json $_;
        Write-Host $response.Message -ForegroundColor Green;
        return $null
    }

}

Export-ModuleMember New-Project;