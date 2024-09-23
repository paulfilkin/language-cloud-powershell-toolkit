$baseUri = "https://lc-api.sdl.com/public-api/v1"

<#
.SYNOPSIS
Creates a new project with specified parameters and uploads source files.

.DESCRIPTION
The `New-Project` function creates a new project using the provided access key and project details. 
The project can be configured with various optional parameters such as source and target languages, customer details, 
location, project template, and more. **All dependencies used for project creation must be in a bloodline relationship with the location where the project will be created.** 
The function also handles the uploading of source files and initiates the project workflow.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER name
(Mandatory) The name of the project to be created.

.PARAMETER dueDate
(Mandatory) The due date for the project in a string format (e.g., "2024-12-31").

.PARAMETER dueTime
(Mandatory) The due time for the project in a string format (e.g., "23:59").

.PARAMETER filesPath
(Mandatory) The path to the directory containing the source files to be uploaded for the project.

.PARAMETER referenceFileNames
(Optional) An array of reference file names to be included in the project. These files should be located in the directory specified by `filesPath`.

.PARAMETER sourceLanguage
(Optional) The source language code of the project (e.g., "en-US").

.PARAMETER targetLanguages
(Optional) An array of target language codes for the project (e.g., @("fr-FR", "de-DE")).

.PARAMETER locationId
(Optional) The ID of the location where the project will be managed.

.PARAMETER locationName
(Optional) The name of the location where the project will be managed.

.PARAMETER projectTemplateIdOrName
(Optional) The ID or name of a project template to be used for the project. If a template is provided, most other parameters can be omitted as the template will define them.

.PARAMETER translationEngineIdOrName
(Optional) The ID or name of the translation engine to be used for the project.

.PARAMETER fileTypeConfigurationIdOrName
(Optional) The ID or name of the file processing configuration to be used for the project.

.PARAMETER workflowIdOrName
(Optional) The ID or name of the workflow to be applied to the project.

.PARAMETER scheduleTemplateIdOrName
(Optional) The ID or name of the schedule template to be applied to the project.

.PARAMETER customFieldIdsOrNames
(Optional) And array of custom fields IDs or names which will be applied on the project.

.PARAMETER tqaIdOrName
(Optional) The Id or Name of the Translation Quality Assessment that will be applied to the project.

.PARAMETER pricingModelIdOrName
(Optional) The ID or name of the pricing model for the project. This should match the source and target languages of the project.

.PARAMETER userManagerIdsOrNames
(Optional) An array of user manager IDs or names who will oversee the project.

.PARAMETER groupManagerIdsOrNames
(Optional) An array of group manager IDs or names that will manage the project.

.PARAMETER scheduleTemplateStrategy
(Optional) A string indicating whether the project will create a copy or use the provided schedule template.

Allowed values are "copy" or "use"
By default the value is "copy"

.PARAMETER fileTypeConfigurationStrategy
(Optional) A string indicating whether the project will create a copy or use the provided file type configuration.

Allowed values are "copy" or "use"
By default the value is "copy"

.PARAMETER translationEngineStrategy
(Optional) A string indicating whether the project will create a copy or use the provided translation engine.

Allowed values are "copy" or "use"
By default the value is "copy"

.PARAMETER pricingModelStrategy
(Optional) A string indicating whether the project will create a copy or use the provided pricing model.

Allowed values are "copy" or "use"
By default the value is "copy"

.PARAMETER workflowStrategy
(Optional) A string indicating whether the project will create a copy or use the provided workflow.

Allowed values are "copy" or "use"
By default the value is "copy"

.PARAMETER tqaStrategy
(Optional) A string indicating whether the project will create a copy or use the provided translation quality assessment.

Allowed values are "copy" or "use"
By default the value is "copy"

.PARAMETER includeFileDownloadSettings
(Optional) A boolean value indicating whether to specify the option for resticting file download.

.PARAMETER restrictFileDownload
(Optional) A boolean value indicating whether the files can be donwloaded after the project creation.

.PARAMETER description
(Optional) Project description.

.PARAMETER inclueGeneralSettings
(Optional) A boolean value indicating whether to include additional settings in the project configuration. Default is `$false`.

.PARAMETER completeDays
(Optional) The number of days after which the project is considered complete. Default is `90` days.

.PARAMETER archiveDays
(Optional) The number of days after which the project is archived. Default is `90` days.

.PARAMETER archiveReminderDays
(Optional) The number of days before a reminder is sent out. Default is `7` days.

.EXAMPLE
    # Example 1: Create a new project with specified languages and location
    New-Project -accessKey $accessKey -projectName "New Localization Project" -projectDueDate "2024-12-31" `
                -dueTime "23:59" -filesPath "C:\ProjectFiles" -sourceLanguage "en-US" `
                -targetLanguages @("fr-FR", "de-DE") -locationName "LocationName" `
                -fileProcessingConfiguration "File Processing Configuration Name"

This example creates a new project with the specified source and target languages, location, and file processing configuration, and uploads the source files from the specified path.

.EXAMPLE
    # Example 2: Create a new project using a template
    New-Project -accessKey $accessKey -projectName "Template Based Project" -projectDueDate "2024-12-31" `
                -dueTime "23:59" -filesPath "C:\ProjectFiles" -projectTemplate "StandardTemplate"

This example creates a new project using a predefined project template. Other parameters such as languages and workflow are automatically set based on the template.
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

function Get-AllProjects {
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    
    $location = @{}
    if ($locationId -or $locationName) 
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/projects" `
                         -location $location -fields "fields=id,name,analysisStatistics" `
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-Project 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $projectId,
        [string] $projectName
    )

    return Get-ProjectItem -accessKey $accessKey -uri "$baseUri/projects" -id $projectId -name $projectName `
        -uriQuery "?fields=id,name,analysisStatistics" `
        -propertyName "Project "
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

    $languages = @();
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

        foreach ($item in $projectTemplate.languageDirections) {
            # Create a new PSObject with the desired properties
            $newObject = [PSCustomObject]@{
                sourceLanguage = @{languageCode = $item.sourceLanguage.languageCode}
                targetLanguage = @{languageCode = $item.targetLanguage.languageCode}
            }
            # Add the new object to the results array
            $languages += $newObject
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

        $languages = @($languageDirections);
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

    if ($languages)
    {
        $body.languageDirections = @($languages);
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
        return $_;
        $response = ConvertFrom-Json $_;
        Write-Host $response.Message -ForegroundColor Green;
        return $null
    }

}

function Get-ProjectItem 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $uri,

        [String] $uriQuery,
        [String] $id,
        [string] $name,
        [string] $propertyName
    )

    if ($id)
    {
        $uri += "/$id/$uriQuery"
        $headers = Get-RequestHeader -accessKey $accessKey;

        $item = Invoke-SafeMethod { Invoke-RestMethod -uri $uri -Headers $headers }
    }
    elseif ($name)
    {
        $items = Get-AllItems -accessKey $accessKey -uri $($uri + $uriQuery);
        if ($items)
        {
            $item = $items | Where-Object {$_.Name -eq $name } | Select-Object -First 1;
        }

        if ($null -eq $item)
        {
            Write-Host "$propertyName could not be found" -ForegroundColor Green;
        }
    }

    if ($item)
    {
        return $item;
    }
}

function Get-AllItems
{
    param (
        [psobject] $accessKey,
        [String] $uri)

    $headers = Get-RequestHeader -accessKey $accessKey;

    $response = Invoke-SafeMethod { Invoke-RestMethod -uri $uri -Headers $headers}
    if ($response)
    {
        return $response.Items;
    }
}

function Get-FilterString 
{
    param (
        [Parameter(Mandatory=$true)]
        [String[]] $propertyNames,

        [Parameter(Mandatory=$true)]
        [String[]] $propertyValues
    )

    return "";

    if ($propertyNames -and $propertyValues)
    {
        $elements = @();
        for ($i = 0; $i -lt $propertyName.Count; $i++)
        {
            $element = $propertyNames[$i] + "=" + $propertyValues[$i]
            $elements += $element;
        }
    
        $output = $elements -join "&"
        return $output;        
    }
}

function Get-LocationStrategy 
{
    param (
        [Parameter(Mandatory=$true)]
        [Bool] $includeSubFolders
    )

    if ($includeSubFolders)
    {
        return "lineage"
    }

    return "location"
}

function Get-RequestHeader
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    return $headers;
}

function Get-StringUri 
{
    param (
        [String] $root,
        [String] $name,
        [psobject] $location,
        [string] $locationStrategy,
        [string] $sort,
        [string] $fields
    )

    $filter = Get-FilterString -name $name -location $location -locationStrategy $locationStrategy -sort $sort
    if ($filter -and $fields)
    {
        return $root + "?" + $filter + "&" + $($fields);
    }
    elseif ($filter)
    {
        return $root + "?" + $filter
    }
    elseif ($fields)
    {
        return $root + "?" + $fields
    }
    else 
    {
        return $root;
    }
}

function Get-FilterString {
    param (
        [string] $name,
        [psobject] $location,
        [string] $locationStrategy,
        [string] $sort
    )

    # Initialize an empty array for filters
    $filter = @()
    
    # Check if the parameters are not null or empty, and add them to the filter array
    if (-not [string]::IsNullOrEmpty($name)) {
        $filter += "name=$name"
    }
    if ($location -and $(-not [string]::IsNullOrEmpty($locationStrategy))) 
    {
        $filter += "location=$($location.Id)&locationStrategy=$locationStrategy"
    }
    if (-not [string]::IsNullOrEmpty($sort)) {
        $filter += "sort=$sort"
    }

    # Return the filter string by joining with "&"
    return $filter -join '&'
}

Export-ModuleMember New-Project;
Export-ModuleMember Get-AllProjects;
Export-ModuleMember Get-Project;