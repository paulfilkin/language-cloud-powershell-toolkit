Import-Module -Name CommonHelper

# Dynamic base URI resolution from CommonHelper
function script:Get-LCBaseUri
{
    return Get-BaseUri
}

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

<#
.SYNOPSIS
    Retrieves all projects available in the system.

.DESCRIPTION
    The `Get-AllProjects` function retrieves a list of all projects in the system. 
    You can optionally filter the results based on the location ID or name, and define a strategy for fetching projects from specific locations. Additionally, you can sort the projects based on a specified property.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the projects.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve projects. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve projects. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching projects in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves projects from the specified location.
        - "bloodline": Retrieves projects from the specified location and its parent folders.
        - "lineage": Retrieves projects from the specified location and its subfolders.
        - "genealogy": Retrieves projects from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) Specifies the property by which to sort the projects. You can sort by fields such as "name", "id", or other relevant project metadata fields.

.OUTPUTS
    Returns a list of projects containing relevant details such as ID, name, and analysis statistics, along with other related metadata.

.EXAMPLE
    # Example 1: Retrieve all projects from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjects -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve projects from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjects -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve projects from a specific location using the lineage strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjects -accessKey $accessKey -locationName "FolderA" -locationStrategy "lineage"

.EXAMPLE
    # Example 4: Retrieve all projects and sort by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjects -accessKey $accessKey -sortProperty "name"
#>
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

    $uri = Get-StringUri -root "$(Get-LCBaseUri)/projects" `
                         -location $location -fields "fields=id,name" `
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific project by ID or name.

.DESCRIPTION
    The `Get-Project` function retrieves the details of a specific project based on the provided project ID or name.
    Either the `projectId` or `projectName` must be provided to retrieve the project information.
    If both parameters are provided, the function will prioritize `projectId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the project.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER projectId
    (Optional) The ID of the project to retrieve. Either `projectId` or `projectName` must be provided.

.PARAMETER projectName
    (Optional) The name of the project to retrieve. Either `projectId` or `projectName` must be provided.

.OUTPUTS
    Returns the specified project with fields such as ID, name, and related metadata.

.EXAMPLE
    # Example 1: Retrieve a project by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Project -accessKey $accessKey -projectId "12345"

.EXAMPLE
    # Example 2: Retrieve a project by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Project -accessKey $accessKey -projectName "MyProject"
#>
function Get-Project 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $projectId,
        [string] $projectName
    )

    return Get-Item -accessKey $accessKey -uri "$(Get-LCBaseUri)/projects" -id $projectId -name $projectName `
        -uriQuery "?fields=id,name" `
        -propertyName "Project"
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
        Invoke-RestMethod -Uri "$(Get-LCBaseUri)/projects/$projectId/start" -Method Put     -Headers $headers
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
        $null = Invoke-RestMethod "$(Get-LCBaseUri)/projects/$projectId/source-files" -Method 'POST' -Headers $headers -Body $body
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
        Invoke-RestMethod "$(Get-LCBaseUri)/projects" -Method 'POST' -Headers $headers -Body $json;
    }
}

#region Export Project Files

<#
.SYNOPSIS
    Triggers an export of project target files as a ZIP archive.

.DESCRIPTION
    The `Export-ProjectFiles` function initiates an export of target files from a project. You can 
    optionally include reference files, filter by target languages, and choose which file versions 
    to include. Returns an export ID to poll with Get-ProjectFilesExportStatus.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER projectId
    (Mandatory) The ID of the project to export files from.

.PARAMETER includeReferenceFiles
    (Optional) Whether to include reference files in the export. Default is $false.

.PARAMETER includeVersions
    (Optional) Which target file versions to include. Default is "currentVersion".

.PARAMETER targetLanguages
    (Optional) An array of target language codes to filter the export (e.g. @("de-DE", "fr-FR")). 
    If not specified, all target languages are included.

.PARAMETER downloadFlat
    (Optional) Whether to flatten the folder structure in the ZIP. Default is $false.

.EXAMPLE
    # Example 1: Export all target files
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $export = Export-ProjectFiles -accessKey $accessKey -projectId "project-123"

.EXAMPLE
    # Example 2: Export specific languages with reference files
    $export = Export-ProjectFiles -accessKey $accessKey -projectId "project-123" `
        -includeReferenceFiles $true -targetLanguages @("de-DE", "fr-FR")
    # Then poll: Get-ProjectFilesExportStatus -accessKey $accessKey -projectId "project-123" -exportId $export.exportId
    # Then download: Save-ProjectFiles -accessKey $accessKey -projectId "project-123" -exportId $export.exportId -outputPath "C:\exports\files.zip"
#>
function Export-ProjectFiles
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectId,

        [bool] $includeReferenceFiles = $false,
        [string] $includeVersions = "currentVersion",
        [string[]] $targetLanguages,
        [bool] $downloadFlat = $false
    )

    $uri = "$(Get-LCBaseUri)/projects/$projectId/files/exports"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{
        referenceFiles = @{
            include = $includeReferenceFiles
        }
        targetFiles = [ordered]@{
            includeVersions = $includeVersions
            downloadFlat    = $downloadFlat
        }
    }

    if ($targetLanguages)
    {
        $body.targetFiles.targetLanguages = @($targetLanguages)
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
}

<#
.SYNOPSIS
    Polls the status of a project files export operation.

.DESCRIPTION
    The `Get-ProjectFilesExportStatus` function checks the status of a previously requested file 
    export. When the state is "completed", use Save-ProjectFiles to download the ZIP.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER projectId
    (Mandatory) The ID of the project.

.PARAMETER exportId
    (Mandatory) The export ID returned by Export-ProjectFiles.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-ProjectFilesExportStatus -accessKey $accessKey -projectId "project-123" -exportId "export-456"
#>
function Get-ProjectFilesExportStatus
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectId,

        [Parameter(Mandatory=$true)]
        [string] $exportId
    )

    $uri = "$(Get-LCBaseUri)/projects/$projectId/files/exports/$exportId"
    $headers = Get-RequestHeader -accessKey $accessKey

    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers }
}

<#
.SYNOPSIS
    Downloads exported project files as a ZIP archive.

.DESCRIPTION
    The `Save-ProjectFiles` function downloads the ZIP file produced by a completed export operation. 
    Poll with Get-ProjectFilesExportStatus until the state is "completed" before calling this function.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER projectId
    (Mandatory) The ID of the project.

.PARAMETER exportId
    (Mandatory) The export ID returned by Export-ProjectFiles.

.PARAMETER outputPath
    (Mandatory) The local file path where the ZIP should be saved (e.g. "C:\exports\files.zip").

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Save-ProjectFiles -accessKey $accessKey -projectId "project-123" -exportId "export-456" `
        -outputPath "C:\exports\target-files.zip"
#>
function Save-ProjectFiles
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectId,

        [Parameter(Mandatory=$true)]
        [string] $exportId,

        [Parameter(Mandatory=$true)]
        [string] $outputPath
    )

    $uri = "$(Get-LCBaseUri)/projects/$projectId/files/exports/$exportId/download"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Accept", "application/octet-stream")
    $headers.Add("Authorization", $accessKey.token)

    return Invoke-SafeMethod {
        Invoke-RestMethod -Uri $uri -Headers $headers -OutFile $outputPath
        Write-Host "Project files saved to $outputPath" -ForegroundColor Green
    }
}

#endregion

#region Reschedule Tasks

<#
.SYNOPSIS
    Reschedules the deadlines for workflow tasks in a project.

.DESCRIPTION
    The `Set-TaskDeadlines` function updates the due date for one or more workflow tasks within a project.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER projectId
    (Mandatory) The ID of the project containing the tasks.

.PARAMETER dueBy
    (Mandatory) The new deadline as an ISO 8601 datetime string (e.g. "2026-06-01T12:00:00Z").

.PARAMETER taskIds
    (Mandatory) An array of task IDs to reschedule.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Set-TaskDeadlines -accessKey $accessKey -projectId "project-123" `
        -dueBy "2026-06-01T12:00:00Z" -taskIds @("task-1", "task-2")
#>
function Set-TaskDeadlines
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectId,

        [Parameter(Mandatory=$true)]
        [string] $dueBy,

        [Parameter(Mandatory=$true)]
        [string[]] $taskIds
    )

    $uri = "$(Get-LCBaseUri)/projects/$projectId/tasks/reschedule"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{
        dueBy   = $dueBy
        taskIds = @($taskIds)
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Patch }
}

#endregion

#region Task Operations

<#
.SYNOPSIS
    Retrieves a specific task by its ID.

.DESCRIPTION
    The `Get-Task` function retrieves the details of a single workflow task using its unique identifier.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to retrieve.

.PARAMETER fields
    (Optional) A comma-separated list of fields to include in the response. When omitted, default 
    fields are returned. Supports top-level property names and nested properties in the form 
    "topLevel.subProperty".

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Task -accessKey $accessKey -taskId "df680285-adcd-4bda-8f79-0bba4a857287"

.EXAMPLE
    # Retrieve specific fields only
    Get-Task -accessKey $accessKey -taskId "task-123" -fields "id,status,taskType,input.type"
#>
function Get-Task
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId,

        [string] $fields
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId"
    if ($fields)
    {
        $uri += "?fields=$fields"
    }

    $headers = Get-RequestHeader -accessKey $accessKey
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers }
}

<#
.SYNOPSIS
    Lists all tasks assigned to the authenticated user.

.DESCRIPTION
    The `Get-AssignedTasks` function retrieves workflow tasks assigned to the current user. 
    Supports filtering by status and location, pagination via skip/top, sorting, and field 
    selection.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER fields
    (Optional) A comma-separated list of fields to include in the response.

.PARAMETER status
    (Optional) Filter tasks by status. Allowed values: created, inProgress, completed, failed, 
    skipped, canceled.

.PARAMETER location
    (Optional) An array of location identifiers to filter by.

.PARAMETER locationStrategy
    (Optional) Controls how the location filter behaves. Allowed values: location (default), 
    lineage, bloodline, genealogy.

.PARAMETER skip
    (Optional) The number of items to skip for pagination. Default is 0.

.PARAMETER top
    (Optional) The number of items to return per page. Range 1-100, default is 100.

.PARAMETER sort
    (Optional) A comma-separated list of fields to sort by. Prefix with "-" for descending order.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AssignedTasks -accessKey $accessKey

.EXAMPLE
    # Get in-progress tasks with specific fields, sorted by due date
    Get-AssignedTasks -accessKey $accessKey -status "inProgress" `
        -fields "id,status,taskType,dueBy" -sort "dueBy"

.EXAMPLE
    # Paginate through results
    Get-AssignedTasks -accessKey $accessKey -skip 0 -top 50
#>
function Get-AssignedTasks
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $fields,
        [string] $status,
        [string[]] $location,
        [string] $locationStrategy,
        [int] $skip,
        [int] $top,
        [string] $sort
    )

    $uri = "$(Get-LCBaseUri)/tasks/assigned"
    $queryParts = @()

    if ($fields)           { $queryParts += "fields=$fields" }
    if ($status)           { $queryParts += "status=$status" }
    if ($location)         { foreach ($loc in $location) { $queryParts += "location=$loc" } }
    if ($locationStrategy) { $queryParts += "locationStrategy=$locationStrategy" }
    if ($PSBoundParameters.ContainsKey('skip')) { $queryParts += "skip=$skip" }
    if ($PSBoundParameters.ContainsKey('top'))  { $queryParts += "top=$top" }
    if ($sort)             { $queryParts += "sort=$sort" }

    if ($queryParts.Count -gt 0)
    {
        $uri += "?" + ($queryParts -join "&")
    }

    $headers = Get-RequestHeader -accessKey $accessKey
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers }
}

<#
.SYNOPSIS
    Accepts a task, making the current user the task owner.

.DESCRIPTION
    The `Submit-AcceptTask` function accepts a task that has been assigned to the current user. 
    Once accepted, the task status changes to inProgress and the applicable outcomes become available.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to accept.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Submit-AcceptTask -accessKey $accessKey -taskId "task-123"
#>
function Submit-AcceptTask
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId/accept"
    $headers = Get-RequestHeader -accessKey $accessKey
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Put }
}

<#
.SYNOPSIS
    Rejects a task, returning it to the pool for other assignees.

.DESCRIPTION
    The `Submit-RejectTask` function rejects a task that has been assigned to or accepted by the 
    current user. The task is returned to the pool so that other assignees can accept it.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to reject.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Submit-RejectTask -accessKey $accessKey -taskId "task-123"
#>
function Submit-RejectTask
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId/reject"
    $headers = Get-RequestHeader -accessKey $accessKey
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Put }
}

<#
.SYNOPSIS
    Completes a task with an optional outcome and comment.

.DESCRIPTION
    The `Submit-CompleteTask` function marks a task as completed. An outcome can be specified to 
    indicate the result of the task (matching one of the task type's applicable outcomes). An 
    optional comment can be provided.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to complete.

.PARAMETER outcome
    (Optional) The outcome to apply when completing the task. Should match one of the task's 
    applicable outcomes.

.PARAMETER comment
    (Optional) A comment to associate with the task completion.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Submit-CompleteTask -accessKey $accessKey -taskId "task-123"

.EXAMPLE
    # Complete with a specific outcome and comment
    Submit-CompleteTask -accessKey $accessKey -taskId "task-123" `
        -outcome "done" -comment "Translation complete, all segments confirmed."
#>
function Submit-CompleteTask
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId,

        [string] $outcome,
        [string] $comment
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId/complete"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{}
    if ($outcome) { $body.outcome = $outcome }
    if ($comment) { $body.comment = $comment }

    if ($body.Count -gt 0)
    {
        $json = $body | ConvertTo-Json -Depth 5
        return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
    }
    else
    {
        return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Put }
    }
}

<#
.SYNOPSIS
    Releases a task from its current owner back to the pool.

.DESCRIPTION
    The `Submit-ReleaseTask` function releases a task from its owner so that other assignees 
    can accept it. The task is not reassigned automatically.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to release.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Submit-ReleaseTask -accessKey $accessKey -taskId "task-123"
#>
function Submit-ReleaseTask
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId/release"
    $headers = Get-RequestHeader -accessKey $accessKey
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Put }
}

<#
.SYNOPSIS
    Reclaims a task, removing the current owner so other assignees can accept it.

.DESCRIPTION
    The `Submit-ReclaimTask` function removes the current owner from a task. The task is not 
    reassigned automatically - other assignees will be able to accept it.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to reclaim.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Submit-ReclaimTask -accessKey $accessKey -taskId "task-123"
#>
function Submit-ReclaimTask
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId/reclaim"
    $headers = Get-RequestHeader -accessKey $accessKey
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Put }
}

<#
.SYNOPSIS
    Assigns a task to one or more users or groups.

.DESCRIPTION
    The `Set-TaskAssignment` function assigns a task to one or more users or groups by providing 
    an array of assignee objects. Each assignee must have an "id" and a "type" (e.g. "user" or 
    "group").

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER taskId
    (Mandatory) The unique identifier of the task to assign.

.PARAMETER assignees
    (Mandatory) An array of hashtables, each containing "id" and "type" keys. The type should be 
    "user" or "group".

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $assignees = @(
        @{ id = "user-abc-123"; type = "user" }
    )
    Set-TaskAssignment -accessKey $accessKey -taskId "task-123" -assignees $assignees

.EXAMPLE
    # Assign to multiple users and a group
    $assignees = @(
        @{ id = "user-abc-123"; type = "user" },
        @{ id = "group-def-456"; type = "group" }
    )
    Set-TaskAssignment -accessKey $accessKey -taskId "task-123" -assignees $assignees
#>
function Set-TaskAssignment
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $taskId,

        [Parameter(Mandatory=$true)]
        [array] $assignees
    )

    $uri = "$(Get-LCBaseUri)/tasks/$taskId/assign"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{
        assignees = @($assignees)
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
}

#endregion

Export-ModuleMember New-Project;
Export-ModuleMember Get-AllProjects;
Export-ModuleMember Get-Project;
Export-ModuleMember Export-ProjectFiles;
Export-ModuleMember Get-ProjectFilesExportStatus;
Export-ModuleMember Save-ProjectFiles;
Export-ModuleMember Set-TaskDeadlines;
Export-ModuleMember Get-Task;
Export-ModuleMember Get-AssignedTasks;
Export-ModuleMember Submit-AcceptTask;
Export-ModuleMember Submit-RejectTask;
Export-ModuleMember Submit-CompleteTask;
Export-ModuleMember Submit-ReleaseTask;
Export-ModuleMember Submit-ReclaimTask;
Export-ModuleMember Set-TaskAssignment;