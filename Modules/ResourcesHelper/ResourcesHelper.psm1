$baseUri = "https://lc-api.sdl.com/public-api/v1"

<#
.SYNOPSIS
    Retrieves all the project templates from the specified location or strategy.

.DESCRIPTION
    The `Get-AllProjectTemplates` function retrieves a list of all project templates available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve project templates from specific locations such as subfolders, parent folders, or a combination of both.
    Additionally, if the `name` parameter is provided, only templates that contain the specified name will be returned along with the other filters.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the project templates.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve project templates. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve project templates. You can specify either a location ID or name, but not both.

.PARAMETER name
    (Optional) The name of the project template to filter the results. Only templates containing this name will be returned along with other filters.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching project templates in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves project templates from the specified location.
        - "bloodline": Retrieves project templates from the specified location and its parent folders.
        - "lineage": Retrieves project templates from the specified location and its subfolders.
        - "genealogy": Retrieves project templates from both subfolders and parent folders of the specified location.

.OUTPUTS
    Returns a list of project templates containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all project templates from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjectTemplates -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve project templates from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjectTemplates -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve project templates from a specific location using the bloodline strategy and filtering by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllProjectTemplates -accessKey $accessKey -locationName "FolderA" -locationStrategy "bloodline" -name "TemplateName"
#>
function Get-AllProjectTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $name,
        [string] $locationStrategy = "location"
    )

    
    $location = @{};
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName;
    }

    $uri = Get-StringUri -root "$baseUri/project-templates" `
                         -name $name -location $location `
                         -locationStrategy $locationStrategy `
                         -fields "&fields=id,name,description,languageDirections,location"

    Get-AllItems -accessKey $accessKey -uri $uri
}

<#
.SYNOPSIS
    Retrieves a specific project template by ID or name.

.DESCRIPTION
    The `Get-ProjectTemplate` function retrieves the details of a specific project template based on the provided project template ID or name.
    Either the `projectTemplateId` or `projectTemplateName` must be provided to retrieve the project template information.
    If both parameters are provided, the function will prioritize `projectTemplateId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the project template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER projectTemplateId
    (Optional) The ID of the project template to retrieve. Either `projectTemplateId` or `projectTemplateName` must be provided.

.PARAMETER projectTemplateName
    (Optional) The name of the project template to retrieve. Either `projectTemplateId` or `projectTemplateName` must be provided.

.OUTPUTS
    Returns the specified project template with fields such as ID, name, description, and associated configurations.

.EXAMPLE
    # Example 1: Retrieve a project template by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-ProjectTemplate -accessKey $accessKey -projectTemplateId "67890"

.EXAMPLE
    # Example 2: Retrieve a project template by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-ProjectTemplate -accessKey $accessKey -projectTemplateName "MyProjectTemplate"
#>
function Get-ProjectTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $projectTemplateId,
        [String] $projectTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/project-templates" -uriQuery "?fields=id,name,description,languageDirections,location" `
                    -id $projectTemplateId -name $projectTemplateName -propertyName "Project template";
}

function New-ProjectTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectTemplateName,

        [string] $locationId,
        [string] $locationName,

        [Parameter(Mandatory=$true)]
        [string] $fileTypeConfigurationIdOrName,

        [string] $sourceLanguage,
        [string[]] $targetLanguages,
        [psobject[]] $languagePairs,
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
        [bool] $restrictFileDownload = $false,
        [bool] $customerPortalVisibility = $true,
        [int] $completeDays = 90,
        [int] $archiveDays = 90,
        [int] $archiveReminderDays = 7,
        [string] $description
    )

    $uri = "$baseUri/project-templates"
    $headers = Get-RequestHeader -accessKey $accessKey
    $body = [ordered]@{
        name = $projectTemplateName
        description = $description
        settings = [ordered]@{
            general = [ordered] @{
                forceOnline = $restrictFileDownload
                customerPortalVisibility = $customerPortalVisibility
                completeConfiguration = [ordered] @{
                    completeDays = $completeDays 
                    archiveDays = $archiveDays 
                    archiveReminderDays = $archiveReminderDays
                }
            }
        }
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

    if (($sourceLanguage -and $targetLanguages) -or $languagePairs)
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

        $body.settings.qualityManagement = @{
            tqaProfile = [ordered]@{
                id = $tqa.Id 
                strategy = $tqaStrategy
            }
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

    $json = $body | ConvertTo-Json -Depth 100;
    return Invoke-SafeMethod {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json;
    }
}

<#
.SYNOPSIS
    Removes a specified project template from the system.

.DESCRIPTION
    The `Remove-ProjectTemplate` function deletes a project template identified by either its ID or name. 
    The function first retrieves the project template using the provided credentials, then constructs the URI 
    for the deletion request and invokes the delete method. If the project template is successfully removed, 
    a confirmation message is displayed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to delete the project template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER projectTemplateId
    (Optional) The ID of the project template to be removed. Either `projectTemplateId` or `projectTemplateName` must be provided.

.PARAMETER projectTemplateName
    (Optional) The name of the project template to be removed. Either `projectTemplateId` or `projectTemplateName` must be provided.

.OUTPUTS
    If the project template is successfully removed, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Remove a project template by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-ProjectTemplate -accessKey $accessKey -projectTemplateId "67890"

.EXAMPLE
    # Example 2: Remove a project template by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-ProjectTemplate -accessKey $accessKey -projectTemplateName "SampleProjectTemplate"
#>
function Remove-ProjectTemplate
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $projectTemplateId,
        [string] $projectTemplateName
    )

    $projectTemplate = Get-ProjectTemplate -accessKey $accessKey -id $projectTemplateId -name $projectTemplateName;

    if ($projectTemplate)
    {
        $uri = "$baseUri/project-templates/$($projectTemplate.Id)"
        $headers = Get-RequestHeader -accessKey $accessKey
        Invoke-SafeMethod { 
                Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete;
                Write-Host "Project Template removed" -ForegroundColor Green}
    }
}

function Update-ProjectTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $projectTemplateId,
        [string] $projectTemplateName,

        [string] $name,
        [string] $description,
        [string] $sourceLanguage,
        [string[]] $targetLanguages,
        [psobject[]] $languagePairs,
        [string[]] $userManagerIdsOrNames,
        [string[]] $groupManagerIdsOrNames,
        [string[]] $customFieldIdsOrNames,
        [string] $fileTypeConfigurationIdOrName,
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
        [switch] $inclueGeneralSettings,
        [bool] $restrictFileDownload = $false,
        [bool] $customerPortalVisibility = $true,
        [int] $completeDays = 90,
        [int] $archiveDays = 90,
        [int] $archiveReminderDays = 7
    )

    $template = Get-ProjectTemplate -accessKey $accessKey -projectTemplateId $projectTemplateId -projectTemplateName $projectTemplateName
    if ($null -eq $template)
    {
        return;
    }
    $uri = "$baseUri/project-templates/$($template.Id)";
    $headers = Get-RequestHeader $accessKey;

    $body = @{}
    if ($name)
    {
        $body.name = $name
    }
    if ($description)
    {
        $body.description = $description;
    }

    if ($fileTypeConfigurationIdOrName)
    {
        $fileTypeConfiguration = Get-AllFileTypeConfigurations -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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

    if (($sourceLanguage -and $targetLanguages) -or $languagePairs)
    {
        $languageDirections = Get-LanguageDirections -sourceLanguage $sourceLanguage -targetLanguages $targetLanguages -languagePairs $languagePairs;
        if ($null -eq $languageDirections)  
        {
            Write-Host "Invalid languages" -ForegroundColor;
            return;
        }

        $body.languageDirections = @($languageDirections);
    }

    $projectManagers = @();
    if ($userManagerIdsOrNames)
    {
        $users = Get-AllUsers -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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
        $groups = Get-AllGroups -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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

    if ($translationEngineIdOrName)
    {
        $translationEngine = Get-AllTranslationEngines -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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
        $pricingModel = Get-AllPricingModels -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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
        $workflow = Get-AllWorkflows -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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

    $settings = $null;
    if ($tqaIdOrName)
    {
        $tqa = Get-AllTranslationQualityAssessments -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
                    | Where-Object {$_.id -eq $tqaIdOrName -or $_.name -eq $tqaIdOrName } `
                    | Select-Object -First 1;

        if ($null -eq $tqa)
        {
            Write-Host "Translation Quality Assessment not found or not related to the location $($location.Name)" -ForegroundColor Green;
            return;
        }

        $settings = @{
            qualityManagement = @{
                tqaProfile = [ordered] @{
                    id = $tqa.Id 
                    strategy = $tqaStrategy
                }
            }
        }
    }

    if ($scheduleTemplateIdOrName)
    {
        $scheduleTemplate = Get-AllScheduleTemplates -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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

    
    if ($customFieldIdsOrNames)
    {
        $customFields = Get-AllCustomFields -accessKey $accessKey -locationId $template.location.id -locationStrategy "bloodline" `
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

    if ($settings)
    {
        $body.settings = $settings;
    }

    $json = $body | ConvertTo-Json -Depth 100;
    Invoke-SafeMethod {
        Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put;
        Write-Host "Project Template updated successfully" -ForegroundColor Green;
    }
}

<#
.SYNOPSIS
    Retrieves all the translation engines from the specified location or strategy.

.DESCRIPTION
    The `Get-AllTranslationEngines` function retrieves a list of all translation engines available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve translation engines from specific locations such as subfolders, parent folders, or a combination of both.
    Additionally, you can sort the results based on a specified property.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the translation engines.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve translation engines. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve translation engines. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching translation engines in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves translation engines from the specified location.
        - "bloodline": Retrieves translation engines from the specified location and its parent folders.
        - "lineage": Retrieves translation engines from the specified location and its subfolders.
        - "genealogy": Retrieves translation engines from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property by which to sort the list of translation engines. If not specified, the results will not be sorted.

.OUTPUTS
    Returns a list of translation engines containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all translation engines from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationEngines -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve translation engines from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationEngines -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve translation engines from a specific location using the lineage strategy and sort by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationEngines -accessKey $accessKey -locationName "FolderA" -locationStrategy "lineage" -sortProperty "name"
#>
function Get-AllTranslationEngines 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )
    
    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/translation-engines" `
                         -location $location -fields "fields=name,description,location,definition"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific translation engine by ID or name.

.DESCRIPTION
    The `Get-TranslationEngine` function retrieves the details of a specific translation engine based on the provided translation engine ID or name.
    Either the `translationEngineId` or `translationEngineName` must be provided to retrieve the translation engine information.
    If both parameters are provided, the function will prioritize `translationEngineId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the translation engine.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER translationEngineId
    (Optional) The ID of the translation engine to retrieve. Either `translationEngineId` or `translationEngineName` must be provided.

.PARAMETER translationEngineName
    (Optional) The name of the translation engine to retrieve. Either `translationEngineId` or `translationEngineName` must be provided.

.OUTPUTS
    Returns the specified translation engine with fields such as ID, name, description, supported languages, and configurations.

.EXAMPLE
    # Example 1: Retrieve a translation engine by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-TranslationEngine -accessKey $accessKey -translationEngineId "67890"

.EXAMPLE
    # Example 2: Retrieve a translation engine by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-TranslationEngine -accessKey $accessKey -translationEngineName "MyTranslationEngine"
#>
function Get-TranslationEngine 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $translationEngineId,
        [String] $translationEngineName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/translation-engines" `
         -uriQuery "?fields=name,description,location,definition" -id $translationEngineId `
         -name $translationEngineName -propertyName "Translation engine"
}

<#
.SYNOPSIS
    Retrieves all the customers from the specified location or strategy.

.DESCRIPTION
    The `Get-AllCustomers` function retrieves a list of all customers available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve customers from specific locations such as subfolders, parent folders, or a combination of both.
    Additionally, you can sort the results based on a specified property.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the customers.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve customers. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve customers. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching customers in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves customers from the specified location.
        - "bloodline": Retrieves customers from the specified location and its parent folders.
        - "lineage": Retrieves customers from the specified location and its subfolders.
        - "genealogy": Retrieves customers from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property by which to sort the list of customers. If not specified, the results will not be sorted.

.OUTPUTS
    Returns a list of customers containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all customers from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllCustomers -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve customers from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllCustomers -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve customers from a specific location using the bloodline strategy and sort by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllCustomers -accessKey $accessKey -locationName "FolderA" -locationStrategy "bloodline" -sortProperty "name"
#>
function Get-AllCustomers 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    $location = @{};
    if ($locationId -or $locationName)
    {

        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/customers" `
                         -location $location -fields "fields=id,name,location"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific customer by ID or name.

.DESCRIPTION
    The `Get-Customer` function retrieves the details of a specific customer based on the provided customer ID or name.
    Either the `customerId` or `customerName` must be provided to retrieve the customer information.
    If both parameters are provided, the function will prioritize `customerId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the customer.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER customerId
    (Optional) The ID of the customer to retrieve. Either `customerId` or `customerName` must be provided.

.PARAMETER customerName
    (Optional) The name of the customer to retrieve. Either `customerId` or `customerName` must be provided.

.OUTPUTS
    Returns the specified customer with fields such as ID, name, contact details, and associated projects.

.EXAMPLE
    # Example 1: Retrieve a customer by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Customer -accessKey $accessKey -customerId "67890"

.EXAMPLE
    # Example 2: Retrieve a customer by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Customer -accessKey $accessKey -customerName "Acme Corp"
#>
function Get-Customer 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,
        
        [string] $customerId,
        [string] $customerName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/customers" -uriQuery "?fields=id,name,location" -id $customerId -name $customerName -propertyName "Customer";
}

<#
.SYNOPSIS
    Removes a specified customer from the system.

.DESCRIPTION
    The `Remove-Customer` function deletes a customer identified by either their ID or name. 
    The function first retrieves the customer using the provided credentials, then constructs the URI 
    for the deletion request and invokes the delete method. If the customer is successfully removed, 
    a confirmation message is displayed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to delete the customer.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER customerId
    (Optional) The ID of the customer to be removed. Either `customerId` or `customerName` must be provided.

.PARAMETER customerName
    (Optional) The name of the customer to be removed. Either `customerId` or `customerName` must be provided.

.OUTPUTS
    If the customer is successfully removed, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Remove a customer by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Customer -accessKey $accessKey -customerId "12345"

.EXAMPLE
    # Example 2: Remove a customer by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Customer -accessKey $accessKey -customerName "SampleCustomer"
#>
function Remove-Customer
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $customerId,
        [string] $customerName
    )

    $uri = "$baseUri/customers"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $customer = Get-Customer -accessKey $accessKey -customerId $customerId -customerName $customerName
    if ($customer)
    {
        $uri += "/$($customer.Id)";
        Invoke-SafeMethod -method {
            $null = Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri;
            Write-Host "Customer removed" -ForegroundColor Green;
        }
    }
}

<#
.SYNOPSIS
    Creates a new customer in the system.

.DESCRIPTION
    The `New-Customer` function allows you to create a new customer record by providing the necessary details. 
    You must specify either the `locationId` or `locationName` for the customer’s location. If you wish to include 
    key contact details, you must provide `firstName`, `lastName`, and `email` together.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to create the customer.
    
    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary 
    credentials for API access.

.PARAMETER customerName
    (Mandatory) The name of the customer to be created.

.PARAMETER locationId
    (Optional) The ID of the location associated with the customer. Either `locationId` or `locationName` must be provided.

.PARAMETER locationName
    (Optional) The name of the location associated with the customer. Either `locationId` or `locationName` must be provided.

.PARAMETER firstName
    (Optional) The first name of the key contact for the customer. Must be provided along with `lastName` and `email` if included.

.PARAMETER lastName
    (Optional) The last name of the key contact for the customer. Must be provided along with `firstName` and `email` if included.

.PARAMETER email
    (Optional) The email address of the key contact for the customer. Must be provided along with `firstName` and `lastName` if included.

.OUTPUTS
    Returns the newly created customer object if the operation is successful. If the customer cannot be created, 
    no output will be returned.

.EXAMPLE
    # Example 1: Create a new customer with location ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Customer -accessKey $accessKey -customerName "Acme Corp" -locationId "12345"

.EXAMPLE
    # Example 2: Create a new customer with location name and key contact details
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Customer -accessKey $accessKey -customerName "Beta LLC" -locationName "Main Office" -firstName "John" -lastName "Doe" -email "john.doe@example.com"
#>
function New-Customer
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $customerName,

        [string] $locationId,
        [string] $locationName,
        [string] $firstName,
        [string] $lastName,
        [string] $email
    )
    
    $uri = "$baseUri/customers"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        name = $customerName;
    }

    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName;
        if ($null -eq $location)
        {
            return;
        }
        else 
        {
            $body.location = $location.id;
        }
    }

    if ($firstName -and $lastName -and $email)
    {
        $body.firstName = $firstName
        $body.lastName = $lastName 
        $body.email = $email
    }

    $json = $body | ConvertTo-Json;
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post}
}

<#
.SYNOPSIS
    Updates the details of an existing customer in the system.

.DESCRIPTION
    The `Update-Customer` function modifies the properties of a specified customer. 
    You must provide either the `customerId` or `customerName` to identify the customer to be updated. 
    The function allows for changing the customer name, RAG status (Red, Amber, Green), folder visibility (Default or Private), 
    and custom fields. Additionally, you can update the key contact details using the user email or user ID of an existing user.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to update the customer.
    
    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary 
    credentials for API access.

.PARAMETER customerId
    (Optional) The ID of the customer to be updated. You must provide either `customerId` or `customerName`.

.PARAMETER customerName
    (Optional) The name of the customer to be updated. You must provide either `customerId` or `customerName`.

.PARAMETER name
    (Optional) The new name for the customer. If provided, this will replace the current name.

.PARAMETER ragStatus
    (Optional) The new RAG (Red, Amber, Green) status for the customer. Acceptable values are "Red", "Amber", or "Green".

.PARAMETER folderVisibility
    (Optional) The visibility setting for the customer's folder. Acceptable values are "Default" or "Private".

.PARAMETER customFieldIdsOrNames
    (Optional) An array of custom field IDs or names to be updated at the customer level. 
    If specified, the function will check if these fields exist.

.PARAMETER userEmail
    (Optional) The email of the key contact for the customer. If provided, this will be used to update the key contact details.

.PARAMETER userId
    (Optional) The ID of the key contact for the customer. If provided, this will be used to update the key contact details.

.OUTPUTS
    Returns a confirmation message if the customer is updated successfully. If the update fails, no output will be returned.

.EXAMPLE
    # Example 1: Update a customer name and RAG status
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Customer -accessKey $accessKey -customerId "12345" -name "Updated Corp" -ragStatus "green"

.EXAMPLE
    # Example 2: Update folder visibility and custom fields
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Customer -accessKey $accessKey -customerName "Beta LLC" -folderVisibility "private" -customFieldIdsOrNames @("Field1", "Field2")

.EXAMPLE
    # Example 3: Update key contact details using user email
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Customer -accessKey $accessKey -customerId "12345" -userEmail "new.email@example.com"
#>
function Update-Customer 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $customerId,
        [string] $customerName,

        [string] $name,
        [string] $ragStatus,
        [string] $folderVisibility,
        [string[]] $customFieldIdsOrNames,

        [string] $userEmail,
        [string] $userId
    )

    $customer = Get-Customer -accessKey $accessKey -customerId $customerId -customerName $customerName
    if ($null -eq $customer)
    {
        Write-Host "Customer must be provided" -ForegroundColor Green;
        return;
    }

    $uri = "$baseUri/customers/$($customer.Id)";
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{};

    if ($name)
    {
        $body.name = $name
    }
    if ($ragStatus)
    {
        $body.ragStatus = $ragStatus
    }
    if ($folderVisibility)
    {
        $body.folderVisibility = $folderVisibility
    }

    if ($customFieldIdsOrNames)
    {
        $customFields = Get-AllCustomFields -accessKey $accessKey -locationId $customer.Location.Id -locationStrategy "bloodline" `
                            | Where-Object {$_.Id -in $customFieldIdsOrNames -or $_.Name -in $customFieldIdsOrNames } `
                            | Where-Object {$_.ResourceType -eq "Customer"} 
        
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

        $body.customFieldDefinitions = @($fieldDefinitions);
    }

    if ($userEmail -or $userId)
    {
        $user = Get-User -accessKey $accessKey -userId $userId -userEmail $userEmail;
        if ($user)
        {
            $body.keyContactId = $user.Id
        }
        else 
        {
            return;
        }
    }

    $json = $body | ConvertTo-Json -Depth 3;
    Invoke-SafeMethod { 
        $null = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $json; 
        Write-Host "Customer updated successfully" -ForegroundColor Green; }
}

<#
.SYNOPSIS
    Retrieves all the file type configurations from the specified location or strategy.

.DESCRIPTION
    The `Get-AllFileTypeConfigurations` function retrieves a list of all file type configurations available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve file type configurations from specific locations such as subfolders, parent folders, or a combination of both.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the file type configurations.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve file type configurations. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve file type configurations. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching file type configurations in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves file type configurations from the specified location.
        - "bloodline": Retrieves file type configurations from the specified location and its parent folders.
        - "lineage": Retrieves file type configurations from the specified location and its subfolders.
        - "genealogy": Retrieves file type configurations from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property by which to sort the results. If specified, the list will be sorted based on this property.

.OUTPUTS
    Returns a list of file type configurations containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all file type configurations from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFileTypeConfigurations -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve file type configurations from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFileTypeConfigurations -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve file type configurations from a specific location using the lineage strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFileTypeConfigurations -accessKey $accessKey -locationName "FolderA" -locationStrategy "lineage"
#>
function Get-AllFileTypeConfigurations
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    $location = @{}
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/file-processing-configurations" `
                        -location $location -fields "fields=id,name,location" `
                        -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific file type configuration by ID or name.

.DESCRIPTION
    The `Get-FileTypeConfiguration` function retrieves the details of a specific file type configuration based on the provided file type ID or name.
    Either the `fileTypeId` or `fileTypeName` must be provided to retrieve the file type configuration information.
    If both parameters are provided, the function will prioritize `fileTypeId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the file type configuration.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER fileTypeId
    (Optional) The ID of the file type configuration to retrieve. Either `fileTypeId` or `fileTypeName` must be provided.

.PARAMETER fileTypeName
    (Optional) The name of the file type configuration to retrieve. Either `fileTypeId` or `fileTypeName` must be provided.

.OUTPUTS
    Returns the specified file type configuration with fields such as ID, name, description, and settings.

.EXAMPLE
    # Example 1: Retrieve a file type configuration by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-FileTypeConfiguration -accessKey $accessKey -fileTypeId "45678"

.EXAMPLE
    # Example 2: Retrieve a file type configuration by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-FileTypeConfiguration -accessKey $accessKey -fileTypeName "PDF Document"
#>
function Get-FileTypeConfiguration 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $fileTypeId,
        [string] $fileTypeName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/file-processing-configurations" `
        -uriQuery "?fields=id,name,location" -id $fileTypeId -name $fileTypeName `
        -propertyName "File processing configuration"
}

<#
.SYNOPSIS
    Retrieves all the workflows from the specified location or strategy.

.DESCRIPTION
    The `Get-AllWorkflows` function retrieves a list of all workflows available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve workflows from specific locations such as subfolders, parent folders, or a combination of both.
    Additionally, you can sort the results based on a specified property.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the workflows.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve workflows. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve workflows. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching workflows in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves workflows from the specified location.
        - "bloodline": Retrieves workflows from the specified location and its parent folders.
        - "lineage": Retrieves workflows from the specified location and its subfolders.
        - "genealogy": Retrieves workflows from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property by which to sort the list of workflows. If not specified, the results will not be sorted.

.OUTPUTS
    Returns a list of workflows containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all workflows from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllWorkflows -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve workflows from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllWorkflows -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve workflows from a specific location using the lineage strategy and sort by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllWorkflows -accessKey $accessKey -locationName "FolderA" -locationStrategy "lineage" -sortProperty "name"
#>
function Get-AllWorkflows 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/workflows" `
                         -location $location -fields "fields=id,name,description,location,workflowTemplate,languageDirections"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific workflow by ID or name.

.DESCRIPTION
    The `Get-Workflow` function retrieves the details of a specific workflow based on the provided workflow ID or name.
    Either the `workflowId` or `workflowName` must be provided to retrieve the workflow information.
    If both parameters are provided, the function will prioritize `workflowId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the workflow.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER workflowId
    (Optional) The ID of the workflow to retrieve. Either `workflowId` or `workflowName` must be provided.

.PARAMETER workflowName
    (Optional) The name of the workflow to retrieve. Either `workflowId` or `workflowName` must be provided.

.OUTPUTS
    Returns the specified workflow with fields such as ID, name, description, and associated tasks.

.EXAMPLE
    # Example 1: Retrieve a workflow by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Workflow -accessKey $accessKey -workflowId "12345"

.EXAMPLE
    # Example 2: Retrieve a workflow by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Workflow -accessKey $accessKey -workflowName "Translation Workflow"
#>
function Get-Workflow 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $workflowId,
        [string] $workflowName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/workflows" `
         -uriQuery "?fields=id,name,description,location,workflowTemplate,languageDirections" `
         -id $workflowId -name $workflowName -propertyName "Workflow";
}

<#
.SYNOPSIS
    Retrieves all the pricing models from the specified location or strategy.

.DESCRIPTION
    The `Get-AllPricingModels` function retrieves a list of all pricing models available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve pricing models from specific locations such as subfolders, parent folders, or a combination of both.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the pricing models.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve pricing models. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve pricing models. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching pricing models in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves pricing models from the specified location.
        - "bloodline": Retrieves pricing models from the specified location and its parent folders.
        - "lineage": Retrieves pricing models from the specified location and its subfolders.
        - "genealogy": Retrieves pricing models from both subfolders and parent folders of the specified location.

.OUTPUTS
    Returns a list of pricing models containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all pricing models from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllPricingModels -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve pricing models from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllPricingModels -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve pricing models from a specific location using the bloodline strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllPricingModels -accessKey $accessKey -locationName "FolderA" -locationStrategy "bloodline"
#>
function Get-AllPricingModels 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/pricing-models" `
                         -location $location -fields "fields=id,name,description,currencyCode,location,languageDirectionPricing"`
                         -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific pricing model by ID or name.

.DESCRIPTION
    The `Get-PricingModel` function retrieves the details of a specific pricing model based on the provided pricing model ID or name.
    Either the `pricingModelId` or `pricingModelName` must be provided to retrieve the pricing model information.
    If both parameters are provided, the function will prioritize `pricingModelId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the pricing model.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER pricingModelId
    (Optional) The ID of the pricing model to retrieve. Either `pricingModelId` or `pricingModelName` must be provided.

.PARAMETER pricingModelName
    (Optional) The name of the pricing model to retrieve. Either `pricingModelId` or `pricingModelName` must be provided.

.OUTPUTS
    Returns the specified pricing model with fields such as ID, name, and pricing details.

.EXAMPLE
    # Example 1: Retrieve a pricing model by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-PricingModel -accessKey $accessKey -pricingModelId "54321"

.EXAMPLE
    # Example 2: Retrieve a pricing model by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-PricingModel -accessKey $accessKey -pricingModelName "Standard Pricing"
#>
function Get-PricingModel {
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $pricingModelId,
        [String] $pricingModelName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/pricing-models" `
        -uriQuery "?fields=id,name,description,currencyCode,location" -id $pricingModelId -name $pricingModelName `
        -propertyName "Pricing model"
}

<#
.SYNOPSIS
    Retrieves all the schedule templates from the specified location or strategy.

.DESCRIPTION
    The `Get-AllScheduleTemplates` function retrieves a list of all schedule templates available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve schedule templates from specific locations such as subfolders, parent folders, or a combination of both.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the schedule templates.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve schedule templates. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve schedule templates. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching schedule templates in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves schedule templates from the specified location.
        - "bloodline": Retrieves schedule templates from the specified location and its parent folders.
        - "lineage": Retrieves schedule templates from the specified location and its subfolders.
        - "genealogy": Retrieves schedule templates from both subfolders and parent folders of the specified location.

.OUTPUTS
    Returns a list of schedule templates containing fields such as ID, name, description, and associated locations.

.EXAMPLE
    # Example 1: Retrieve all schedule templates from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllScheduleTemplates -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve schedule templates from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllScheduleTemplates -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve schedule templates from a specific location using the lineage strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllScheduleTemplates -accessKey $accessKey -locationName "FolderA" -locationStrategy "lineage"
#>
function Get-AllScheduleTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/schedule-templates" `
                         -location $location -fields "fields=name,description,location" `
                         -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific schedule template by ID or name.

.DESCRIPTION
    The `Get-ScheduleTemplate` function retrieves the details of a specific schedule template based on the provided schedule template ID or name.
    Either the `scheduleTemplateId` or `scheduleTemplateName` must be provided to retrieve the schedule template information.
    If both parameters are provided, the function will prioritize `scheduleTemplateId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the schedule template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER scheduleTemplateId
    (Optional) The ID of the schedule template to retrieve. Either `scheduleTemplateId` or `scheduleTemplateName` must be provided.

.PARAMETER scheduleTemplateName
    (Optional) The name of the schedule template to retrieve. Either `scheduleTemplateId` or `scheduleTemplateName` must be provided.

.OUTPUTS
    Returns the specified schedule template with fields such as ID, name, description, and scheduling details.

.EXAMPLE
    # Example 1: Retrieve a schedule template by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-ScheduleTemplate -accessKey $accessKey -scheduleTemplateId "98765"

.EXAMPLE
    # Example 2: Retrieve a schedule template by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-ScheduleTemplate -accessKey $accessKey -scheduleTemplateName "Weekly Schedule"
#>
function Get-ScheduleTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $scheduleTemplateId,
        [string] $scheduleTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/schedule-templates" `
        -uriQuery "?fields=name,description,location" -id $scheduleTemplateId -name $scheduleTemplateName `
        -propertyName "Schedule template"
}

<#
.SYNOPSIS
    Removes a specified schedule template from the system.

.DESCRIPTION
    The `Remove-ScheduleTemplate` function deletes a schedule template identified by either its ID or name. 
    The function first retrieves the schedule template using the provided credentials, then constructs the URI 
    for the deletion request and invokes the delete method. If the schedule template is successfully removed, 
    a confirmation message is displayed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to delete the schedule template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER scheduleTemplateId
    (Optional) The ID of the schedule template to be removed. Either `scheduleTemplateId` or `scheduleTemplateName` must be provided.

.PARAMETER scheduleTemplateName
    (Optional) The name of the schedule template to be removed. Either `scheduleTemplateId` or `scheduleTemplateName` must be provided.

.OUTPUTS
    If the schedule template is successfully removed, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Remove a schedule template by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-ScheduleTemplate -accessKey $accessKey -scheduleTemplateId "12345"

.EXAMPLE
    # Example 2: Remove a schedule template by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-ScheduleTemplate -accessKey $accessKey -scheduleTemplateName "SampleScheduleTemplate"
#>
function Remove-ScheduleTemplate
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $scheduleTemplateId,
        [string] $scheduleTemplateName
    )

    $uri = "$baseUri/schedule-templates"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $scheduleTemplate = Get-ScheduleTemplate -accessKey $accessKey -scheduleTemplateId $scheduleTemplateId -scheduleTemplateName $scheduleTemplateName

    if ($scheduleTemplate)
    {
        $uri += "/$($scheduleTemplate.Id)";
        Invoke-SafeMethod -method {
            $null = Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri;
            Write-Host "Schedule template removed" -ForegroundColor Green;
        }
    }
}

<#
.SYNOPSIS
    Retrieves all locations available in the system.

.DESCRIPTION
    The `Get-AllLocations` function retrieves a list of all locations (folders) from the system. 
    This function does not require any additional parameters other than the access key for authentication.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the locations.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.OUTPUTS
    Returns a list of locations containing fields such as ID, name, description, and other related metadata.

.EXAMPLE
    # Example: Retrieve all locations
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllLocations -accessKey $accessKey
#>
function Get-AllLocations 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey "$baseUri/folders"
}

<#
.SYNOPSIS
    Retrieves a specific location by ID or name.

.DESCRIPTION
    The `Get-Location` function retrieves the details of a specific location based on the provided location ID or name.
    Either the `locationId` or `locationName` must be provided to retrieve the location information.
    If both parameters are provided, the function will prioritize `locationId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the location.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the location to retrieve. Either `locationId` or `locationName` must be provided.

.PARAMETER locationName
    (Optional) The name of the location to retrieve. Either `locationId` or `locationName` must be provided.

.OUTPUTS
    Returns the specified location with fields such as ID, name, description, and parent folder.

.EXAMPLE
    # Example 1: Retrieve a location by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Location -accessKey $accessKey -locationId "78910"

.EXAMPLE
    # Example 2: Retrieve a location by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Location -accessKey $accessKey -locationName "Main Folder"
#>
function Get-Location 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $locationId,
        [String] $locationName
    )

    return Get-Item -accessKey $accessKey -id $locationId -name $locationName -uri "$baseUri/folders" -propertyName "Folder";
}

<#
.SYNOPSIS
    Retrieves all custom fields available in the system.

.DESCRIPTION
    The `Get-AllCustomFields` function retrieves a list of all custom fields from the system. 
    You can optionally filter the results based on the location ID or name and define a strategy for fetching custom fields from specific locations. 
    Additionally, the results can be sorted based on the specified sort property.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the custom fields.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve custom fields. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve custom fields. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching custom fields in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves custom fields from the specified location.
        - "bloodline": Retrieves custom fields from the specified location and its parent folders.
        - "lineage": Retrieves custom fields from the specified location and its subfolders.
        - "genealogy": Retrieves custom fields from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property by which to sort the retrieved custom fields. If a value is provided with a `-` prefix, the sort will be in descending order; otherwise, the sort will be in ascending order.

.OUTPUTS
    Returns a list of custom fields containing relevant details such as ID, name, description, and other related metadata.

.EXAMPLE
    # Example 1: Retrieve all custom fields from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllCustomFields -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve custom fields from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllCustomFields -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve custom fields from a specific location and sort them by name in descending order
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllCustomFields -accessKey $accessKey -locationName "FolderA" -sortProperty "-name"
#>
function Get-AllCustomFields
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/custom-field-definitions" `
                         -location $location -fields "fields=id,name,key,description,defaultValue,type,location,resourceType,isMandatory,pickListOptions" `
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific custom field by ID or name.

.DESCRIPTION
    The `Get-CustomField` function retrieves the details of a specific custom field based on the provided custom field ID or name.
    Either the `customFieldId` or `customFieldName` must be provided to retrieve the custom field information.
    If both parameters are provided, the function will prioritize `customFieldId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the custom field.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER customFieldId
    (Optional) The ID of the custom field to retrieve. Either `customFieldId` or `customFieldName` must be provided.

.PARAMETER customFieldName
    (Optional) The name of the custom field to retrieve. Either `customFieldId` or `customFieldName` must be provided.

.OUTPUTS
    Returns the specified custom field with fields such as ID, name, type, and options.

.EXAMPLE
    # Example 1: Retrieve a custom field by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-CustomField -accessKey $accessKey -customFieldId "12345"

.EXAMPLE
    # Example 2: Retrieve a custom field by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-CustomField -accessKey $accessKey -customFieldName "Project Type"
#>
function Get-CustomField 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $customFieldId,
        [String] $customFieldName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/custom-field-definitions" `
         -propertyName "Custom field definition" `
         -uriQuery "?fields=id,name,key,description,defaultValue,type,location,resourceType,isMandatory,pickListOptions" `
         -id $customFieldId -name $customFieldName;
}

<#
.SYNOPSIS
    Retrieves all translation memories available in the system.

.DESCRIPTION
    The `Get-AllTranslationMemories` function retrieves a list of all translation memories. 
    You can optionally filter the results based on the location ID or name and define a strategy for fetching translation memories from specific locations. 

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the translation memories.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve translation memories. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve translation memories. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching translation memories in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves translation memories from the specified location.
        - "bloodline": Retrieves translation memories from the specified location and its parent folders.
        - "lineage": Retrieves translation memories from the specified location and its subfolders.
        - "genealogy": Retrieves translation memories from both subfolders and parent folders of the specified location.

.OUTPUTS
    Returns a list of translation memories containing relevant details such as ID, name, description, and other related metadata.

.EXAMPLE
    # Example 1: Retrieve all translation memories from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationMemories -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve translation memories from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationMemories -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve translation memories from a specific location using the bloodline strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationMemories -accessKey $accessKey -locationName "FolderA" -locationStrategy "bloodline"
#>
function Get-AllTranslationMemories 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    $location = @{}
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/translation-memory" `
                         -location $location `
                         -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific translation memory by ID or name.

.DESCRIPTION
    The `Get-TranslationMemory` function retrieves the details of a specific translation memory based on the provided translation memory ID or name.
    Either the `translationMemoryId` or `translationMemoryName` must be provided to retrieve the translation memory information.
    If both parameters are provided, the function will prioritize `translationMemoryId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the translation memory.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER translationMemoryId
    (Optional) The ID of the translation memory to retrieve. Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER translationMemoryName
    (Optional) The name of the translation memory to retrieve. Either `translationMemoryId` or `translationMemoryName` must be provided.

.OUTPUTS
    Returns the specified translation memory with fields such as ID, name, description, and language pair.

.EXAMPLE
    # Example 1: Retrieve a translation memory by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-TranslationMemory -accessKey $accessKey -translationMemoryId "78901"

.EXAMPLE
    # Example 2: Retrieve a translation memory by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-TranslationMemory -accessKey $accessKey -translationMemoryName "MyTranslationMemory"
#>
function Get-TranslationMemory 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $translationMemoryId,
        [string] $translationMemoryName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/translation-memory" -id $translationMemoryId -name $translationMemoryName -propertyName "Translation memory";
}

<#
.SYNOPSIS
    Creates a new translation memory in the system.

.DESCRIPTION
    The `New-TranslationMemory` function creates a new translation memory with specified properties. 
    It requires the translation memory name, a language processing rule ID or name, a field template ID or name, 
    and optionally location, source language, target languages, and language pairs. 
    The language processing rule and field template must be in a bloodline relationship with the specified location.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to create the translation memory.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER name
    (Mandatory) The name of the new translation memory.

.PARAMETER languageProcessingIdOrName
    (Mandatory) The ID or name of the language processing rule to be used for the translation memory. 
    This must be in a bloodline relationship with the specified location.

.PARAMETER fieldTemplateIdOrName
    (Mandatory) The ID or name of the field template to be used for the translation memory. 
    This must be in a bloodline relationship with the specified location.

.PARAMETER locationId
    (Optional) The ID of the location where the translation memory will be created. 
    If not provided, the `locationName` parameter can be used.

.PARAMETER locationName
    (Optional) The name of the location where the translation memory will be created. 
    If not provided, the `locationId` parameter can be used.

.PARAMETER sourceLanguage
    (Mandatory) The source language code for the translation memory.

.PARAMETER targetLanguages
    (Optional) An array of target language codes for the translation memory.

.PARAMETER languagePairs
    (Optional) An array of language pairs as PowerShell objects. 
    This can be provided when multiple source languages are needed.

    This can be provided when multiple source languages are needed and can be retrieved using the `Get-LanguagePair` method.

.PARAMETER copyRight
    (Optional) Copyright information for the translation memory.

.PARAMETER description
    (Optional) A description of the translation memory.

.OUTPUTS
    Returns the newly created translation memory object if successful. 

.EXAMPLE
    # Example 1: Create a new translation memory with source and target languages
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-TranslationMemory -accessKey $accessKey -name "MyTranslationMemory" -languageProcessingIdOrName "LPR123" `
                          -fieldTemplateIdOrName "FieldTemplate456" -locationId "Location789" `
                          -sourceLanguage "en-US" -targetLanguages @("fr-FR", "de-DE")

.EXAMPLE
    # Example 2: Create a new translation memory using language pairs
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $languagePairs = Get-LanguagePair -sourceLanguage "en-US" -targetLanguages @("fr-FR", "de-DE")
    New-TranslationMemory -accessKey $accessKey -name "MyTranslationMemory" -languageProcessingIdOrName "LPR123" `
                          -fieldTemplateIdOrName "FieldTemplate456" -locationName "New York" `
                          -languagePairs $languagePairs -copyRight "2024" -description "New translation memory for 2024 projects"
#>
function New-TranslationMemory 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [Parameter(Mandatory=$true)]
        [string] $languageProcessingIdOrName,

        [Parameter(Mandatory=$true)]
        [string] $fieldTemplateIdOrName,
        
        [string] $locationId,  
        [string] $locationName,
        
        [string] $sourceLanguage,
        [string[]] $targetLanguages,
        [psobject[]] $languagePairs,
        
        [string] $copyRight,
        [string] $description
    )

    # Create the http request basic data
    $uri = "$baseUri/translation-memory"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        name = $name
        copyright = $copyRight
        description = $description;
    }

    # Verify the location and add it to the request body
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName;
        if ($null -eq $location)
        {
            return;
        }
    }

    if ($location)
    {
        $body.location = $location.Id
    }

    # Verify language processing rule
    $lpr = Get-AllLanguageProcessingRules -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.Id -eq $languageProcessingIdOrName -or $_.Name -eq $languageProcessingIdOrName } `
                    | Select-Object -First 1
    if ($null -eq $lpr)
    {
        Write-Host "Language Processing Rule does not exist or is not related to the location $($location.Name)" -ForegroundColor Green;
        return;
    }

    # Verify the field template
    $fieldTemplate = Get-AllFieldTemplates -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.Id -eq $fieldTemplateIdOrName -or $_.Name -eq $fieldTemplateIdOrName} `
                    | Select-Object -First 1

    if ($null -eq $fieldTemplate)
    {
        Write-Host "Field Template does not exist or is not related to the location $($location.Name)" -ForegroundColor Green;
        return;
    }

    # Assigns the Language Processing Rule and the Field Template
    $body.languageProcessingRuleId = $lpr.Id;
    $body.fieldTemplateId = $fieldTemplate.Id;

    # Verify and Assigns the language directions
    $languageDirections = Get-LanguageDirections -sourceLanguage $sourceLanguage -target $targetLanguages -languagePairs $languagePairs;
    if ($languageDirections)
    {
        $body.languageDirections = @($languageDirections);
    }
    else 
    {
        Write-Host "Translation Memory should have at least on source-target language pair" -ForegroundColor Green;
        return;
    }
    
    $json = $body | ConvertTo-Json -Depth 10;
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json }
}

<#
.SYNOPSIS
    Removes a specified translation memory from the system.

.DESCRIPTION
    The `Remove-TranslationMemory` function deletes a translation memory identified by either its ID or name. 
    The function first retrieves the translation memory using the provided credentials, then constructs the URI 
    for the deletion request and invokes the delete method. If the translation memory is successfully removed, 
    a confirmation message is displayed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to delete the translation memory.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER translationMemoryId
    (Optional) The ID of the translation memory to be removed. Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER translationMemoryName
    (Optional) The name of the translation memory to be removed. Either `translationMemoryId` or `translationMemoryName` must be provided.

.OUTPUTS
    If the translation memory is successfully removed, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Remove a translation memory by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-TranslationMemory -accessKey $accessKey -translationMemoryId "12345"

.EXAMPLE
    # Example 2: Remove a translation memory by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-TranslationMemory -accessKey $accessKey -translationMemoryName "SampleTranslationMemory"
#>
function Remove-TranslationMemory
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $translationMemoryId, 
        [String] $translationMemoryName
    )

    $uri = "$baseUri/translation-memory"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $tm = Get-TranslationMemory -accessKey $accessKey -translationMemoryId $translationMemoryId -translationMemoryName $translationMemoryName;

    if ($tm)
    {
        $uri += "/$($tm.Id)"
        Invoke-SafeMethod { 
            $null = Invoke-RestMethod -uri $uri -Headers $headers -Method Delete; # can be added in a more generic method
            Write-host "Translation Memory removed" -ForegroundColor Green; }
    }
}

<#
.SYNOPSIS
    Updates an existing translation memory in the system.

.DESCRIPTION
    The `Update-TranslationMemory` function modifies an existing translation memory based on the specified properties. 
    It requires either the translation memory ID or name to identify the translation memory, and allows updating various attributes. 
    If a parameter is not provided, that attribute will remain unchanged.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to update the translation memory.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER translationMemoryId
    (Optional) The ID of the translation memory to be updated. Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER translationMemoryName
    (Optional) The name of the translation memory to be updated. Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER name
    (Optional) The new name for the translation memory. If not provided, the name will remain unchanged.

.PARAMETER copyRight
    (Optional) The updated copyright information for the translation memory. If not provided, the copyright will remain unchanged.

.PARAMETER description
    (Optional) The updated description of the translation memory. If not provided, the description will remain unchanged.

.PARAMETER sourceLanguage
    (Optional) The updated source language code for the translation memory. This can be provided alongside target languages or language pairs.

.PARAMETER targetLanguages
    (Optional) An array of updated target language codes for the translation memory. This can be provided alongside the source language or language pairs.

.PARAMETER languagePairs
    (Optional) An array of language pairs as PowerShell objects. This can be provided when multiple source languages are needed and can be retrieved using the `Get-LanguagePair` method.
    This can be provided when multiple source languages are needed and can be retrieved using the `Get-LanguagePair` method.

.PARAMETER languageProcessingIdOrName
    (Optional) The ID or name of the language processing rule to be associated with the translation memory. 
    This must be in a bloodline relationship with the location of the translation memory.

.PARAMETER fieldTemplateIdOrName
    (Optional) The ID or name of the field template to be associated with the translation memory. 
    This must also be in a bloodline relationship with the location of the translation memory.

.EXAMPLE
    # Example 1: Update a translation memory by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-TranslationMemory -accessKey $accessKey -translationMemoryId "TM123" -name "UpdatedTranslationMemory" `
                             -copyRight "2024" -description "Updated translation memory for 2024 projects" -sourceLanguage "en" `
                             -targetLanguages @("fr", "es") -languageProcessingIdOrName "LPR123"

.EXAMPLE
    # Example 2: Update a translation memory by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-TranslationMemory -accessKey $accessKey -translationMemoryName "OldTranslationMemory" -fieldTemplateIdOrName "FieldTemplate456"
#>
function Update-TranslationMemory 
{
    param (
        [Parameter(Mandatory=$true)]
        [Psobject] $accessKey,

        [string] $translationMemoryId,
        [string] $translationMemoryName,

        [string] $name,

        [string] $copyRight,
        [string] $description, 

        [string] $sourceLanguage,
        [string[]] $targetLanguages,
        [psobject[]] $languagePairs,
        
        [string] $languageProcessingIdOrName,
        [string] $fieldTemplateIdOrName
    )

    # Checks the existence of the Translation Memory
    $tm = Get-TranslationMemory -accessKey $accessKey -translationMemoryId $translationMemoryId -translationMemoryName $translationMemoryName;
    if ($null -eq $tm)
    {
        Write-Host "Translation Memory must be provided" -ForegroundColor Green;
        return;
    }

    # Create the http request basic data
    $uri = "$baseuri/translation-memory/$($tm.Id)";
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{}

    # Updates the body with the provided paramters
    if ($name)
    {
        $body.name = $name
    }
    if ($description)
    {
        $body.description = $description;
    }
    if ($copyRight)
    {
        $body.copyright = $copyRight;
    }

    if (($sourceLanguage -and $targetLanguages) -or $languagePairs)
    {
        $languageDirections = Get-LanguageDirections -sourceLanguage $sourceLanguage -targetLanguages $targetLanguages -languagePairs $languagePairs;
        if ($languageDirections)
        {
            $body.languageDirections = @($languageDirections);
        }
        else 
        {
            Write-Host "Invalid languages" -ForegroundColor Green;
            return;
        }
    }

    if ($languageProcessingIdOrName)
    {
        $lpr = Get-AllLanguageProcessingRules -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
                    | Where-Object {$_.Id -eq $languageProcessingIdOrName -or $_.Name -eq $languageProcessingIdOrName } `
                    | Select-Object -First 1
        if ($null -eq $lpr)
        {
            Write-Host "Language Processing Rule does not exist or is not related to the location of this Translation Memory" -ForegroundColor Green;
            return;
        }

        $body.languageProcessingRuleId = $lpr.Id;
    }

    if ($fieldTemplateIdOrName)
    {
          # Verify the field template
        $fieldTemplate = Get-AllFieldTemplates -accessKey $accessKey -locationId $location.Id -locationStrategy "bloodline" `
        | Where-Object {$_.Id -eq $fieldTemplateIdOrName -or $_.Name -eq $fieldTemplateIdOrName} `
        | Select-Object -First 1

        if ($null -eq $fieldTemplate)
        {
            Write-Host "Field Template does not exist or is not related to this Translation Memory" -ForegroundColor Green;
            return;
        }

        $body.fieldTemplateId = $fieldTemplate.Id;
    }

    $json = $body | ConvertTo-Json -Depth 5;
    return Invoke-SafeMethod {Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -body $json }
}

<#
.SYNOPSIS
    Copies an existing translation memory to create a new one.

.DESCRIPTION
    The `Copy-TranslationMemory` function duplicates a specified translation memory identified by either its ID or name. 
    The new translation memory is created in the same location as the original, with the same name appended with " (copy)". 
    The function first retrieves the existing translation memory using the provided credentials, constructs the URI for 
    the copy request, and invokes the method to create the new translation memory.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to copy the translation memory.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER translationMemoryId
    (Optional) The ID of the translation memory to be copied. Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER translationMemoryName
    (Optional) The name of the translation memory to be copied. Either `translationMemoryId` or `translationMemoryName` must be provided.

.OUTPUTS
    If the translation memory is successfully copied, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Copy a translation memory by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Copy-TranslationMemory -accessKey $accessKey -translationMemoryId "12345"

.EXAMPLE
    # Example 2: Copy a translation memory by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Copy-TranslationMemory -accessKey $accessKey -translationMemoryName "SampleTranslationMemory"
#>
function Copy-TranslationMemory 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $translationMemoryId,
        [string] $translationMemoryName
    )

    $tm = Get-TranslationMemory -accessKey $accessKey -translationMemoryId $translationMemoryId -translationMemoryName $translationMemoryName;
    if ($null -eq $tm)
    {
        return;
    }

    $uri = "$baseUri/translation-memory/$($tm.Id)/copy";
    $headers = Get-RequestHeader -accessKey $accessKey;
    Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Post; }
}

<#
.SYNOPSIS
    Imports translation units from an external file into an existing translation memory.

.DESCRIPTION
    The `Import-TranslationMemory` function allows for the import of translation units from a specified file into an existing translation memory. 
    The function supports multiple import options, including handling of target segments, unknown fields, and confirmation levels. 
    It is designed to work with various file formats, including .tmx, .sdltm, .zip, .tmx.gz, and .sdlxliff.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to perform the import operation.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER sourceLanguage
    (Mandatory) The source language code for the translation units being imported.

.PARAMETER targetLanguage
    (Mandatory) The target language code for the translation units being imported.

.PARAMETER translationMemoryId
    (Optional) The ID of the translation memory where the translation units will be imported. 
    Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER translationMemoryName
    (Optional) The name of the translation memory where the translation units will be imported. 
    Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER importFileLocation
    (Mandatory) The file path to the import file containing the translation units. 
    Supported file formats include .tmx, .sdltm, .zip, .tmx.gz, and .sdlxliff.

.PARAMETER importAsPlainText
    (Optional) A boolean value indicating whether to import the translation units as plain text. Defaults to $false.

.PARAMETER exportInvalidTranslationUnits
    (Optional) A boolean value indicating whether to export translation units that are invalid. Defaults to $false.

.PARAMETER triggerRecomputeStatistics
    (Optional) A boolean value indicating whether to trigger a recomputation of statistics after the import. Defaults to $false.

.PARAMETER targetSegmentsDifferOption
    (Optional) Specifies how to handle target segments that differ. Acceptable values are:
        - "addNew": Add new segments to the translation memory.
        - "overwrite": Overwrite existing segments with the new ones.
        - "leaveUnchanged": Keep existing segments unchanged.
        - "keepMostRecent": Retain the most recently added segment.

.PARAMETER unknownFieldsOption
    (Optional) Specifies how to handle unknown fields during the import process. Acceptable values are:
        - "addToTranslationMemory": Add unknown fields to the translation memory.
        - "failTranslationUnitImport": Fail the import for units with unknown fields.
        - "ignore": Ignore unknown fields during the import.
        - "skipTranslationUnit": Skip translation units with unknown fields.

.PARAMETER onlyImportSegmentsWithConfirmationLevels
    (Optional) An array of confirmation levels to filter which segments to import. 
    Acceptable values include:
        - "translated"
        - "approvedSignOff"
        - "approvedTranslation"
        - "draft"
        - "rejectedTranslation"
        - "rejectedSignOff"

.OUTPUTS
    Returns the result of the import operation, including any details about successfully imported segments or errors encountered.

.EXAMPLE
    # Example 1: Import translation units from a TMX file into an existing translation memory
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Import-TranslationMemory -accessKey $accessKey -sourceLanguage "de-DE" -targetLanguage "en-US" `
                            -translationMemoryId "TM123" -importFileLocation "C:\path\to\your\file.tmx" `
                            -importAsPlainText $false -exportInvalidTranslationUnits $true

.EXAMPLE
    # Example 2: Import SDLTM file while skipping unknown fields
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Import-TranslationMemory -accessKey $accessKey -sourceLanguage "de-DE" -targetLanguage "en-US" `
                            -translationMemoryName "MyTranslationMemory" -importFileLocation "C:\path\to\your\file.sdltm" `
                            -unknownFieldsOption "skipTranslationUnit"
#>
function Import-TranslationMemory
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $sourceLanguage,
        
        [Parameter(Mandatory=$true)]
        [string] $targetLanguage,

        [string] $translationMemoryId,
        [string] $translationMemoryName,

        [Parameter(Mandatory=$true)]
        [string] $importFileLocation,
        [bool] $importAsPlainText = $false,
        [bool] $exportInvalidTranslationUnits = $false,
        [bool] $triggerRecomputeStatistics = $false, 
        [string] $targetSegmentsDifferOption = "addNew",
        [string] $unknownFieldsOption = "addToTranslationMemory",
        [string[]] $onlyImportSegmentsWithConfirmationLevels = @("translated", "approvedSignOff", "approvedTranslation")
    )

    # Retrieve translation memory object
    $tm = Get-TranslationMemory -accessKey $accessKey -translationMemoryId $translationMemoryId -translationMemoryName $translationMemoryName;
    if ($null -eq $tm) {
        Write-Host "A Translation Memory should be provided" -ForegroundColor Green
        return
    }

    # Check if the import file exists
    if (-not (Test-Path $importFileLocation)) {
        Write-Host "File does not exist" -ForegroundColor Green
        return
    }

    # Construct the import URI
    $importUri = "$baseUri/translation-memory/$($tm.Id)/imports";

    # Prepare the body for the import request
    $importBody = [ordered]@{
        sourceLanguageCode = $sourceLanguage
        targetLanguageCode = $targetLanguage
        importAsPlainText = $importAsPlainText
        exportInvalidTranslationUnits = $exportInvalidTranslationUnits
        triggerRecomputeStatistics = $triggerRecomputeStatistics
        targetSegmentsDifferOption = $targetSegmentsDifferOption
        unknownFieldsOption = $unknownFieldsOption
        onlyImportSegmentsWithConfirmationLevels = @($onlyImportSegmentsWithConfirmationLevels)
    }

    $importJson = $importBody | ConvertTo-Json -Depth 5

    # Create headers for the request
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    # Create multipart form data content
    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()

    # Add JSON content to multipart
    $stringContent = [System.Net.Http.StringContent]::new($importJson, [System.Text.Encoding]::UTF8, "application/json")
    $stringHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $stringHeader.Name = "properties"
    $stringContent.Headers.ContentDisposition = $stringHeader
    $multipartContent.Add($stringContent)

    # Prepare to add the file content
    if (Test-Path $importFileLocation) {
        $fileStream = [System.IO.FileStream]::new($importFileLocation, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
        
        # Set file content disposition header
        $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
        $fileHeader.Name = "file"
        $fileHeader.FileName = [System.IO.Path]::GetFileName($importFileLocation)
        $fileContent.Headers.ContentDisposition = $fileHeader
        
        # Add file content to multipart
        $multipartContent.Add($fileContent)
    }

    $response = Invoke-SafeMethod { Invoke-RestMethod -Uri $importUri -Method "Post" -Headers $headers -Body $multipartContent };
    if ($response)
    {
        Write-Host "Translation Memory Improt queued" -ForegroundColor Green
        return $response;
    }
}

<#
.SYNOPSIS
    Exports translation units from an existing translation memory based on source and target languages.

.DESCRIPTION
    The `Export-TranslationMemory` function allows for the export of translation units from an existing translation memory into a specified file format.
    The function supports exporting translation units based on provided source and target languages, saving the output in a .tmx.gz format.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to perform the export operation.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER sourceLanguage
    (Mandatory) The source language code for the translation units to be exported.

.PARAMETER targetLanguage
    (Mandatory) The target language code for the translation units to be exported.

.PARAMETER outputFilePath
    (Mandatory) The file path where the exported translation units will be saved. 
    The allowed file format for export is .tmx.gz.

.PARAMETER translationMemoryId
    (Optional) The ID of the translation memory from which the translation units will be exported. 
    Either `translationMemoryId` or `translationMemoryName` must be provided.

.PARAMETER translationMemoryName
    (Optional) The name of the translation memory from which the translation units will be exported. 
    Either `translationMemoryId` or `translationMemoryName` must be provided.

.OUTPUTS
    Returns the result of the export operation, including details about successfully exported segments or errors encountered.

.EXAMPLE
    # Example 1: Export translation units from a TM to a .tmx.gz file
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Export-TranslationMemory -accessKey $accessKey -sourceLanguage "en" -targetLanguage "fr" `
                            -outputFilePath "C:\path\to\exported_file.tmx.gz" -translationMemoryId "TM123"

.EXAMPLE
    # Example 2: Export translation units using translation memory name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Export-TranslationMemory -accessKey $accessKey -sourceLanguage "de" -targetLanguage "en" `
                            -outputFilePath "C:\path\to\exported_file.tmx.gz" -translationMemoryName "MyTranslationMemory"
#>
function Export-TranslationMemory
{ 
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $sourceLanguage,

        [Parameter(Mandatory=$true)]
        [string] $targetLanguage,

        [Parameter(Mandatory=$true)]
        [string] $outputFilePath,

        [string] $translationMemoryId,
        [string] $translationMemoryName

    )

    $tm = Get-TranslationMemory -accessKey $accessKey -translationMemoryId $translationMemoryId -translationMemoryName $translationMemoryName;
    if ($null -eq $tm)
    {
        Write-Host "A Translation Memory should be provided" -ForegroundColor Green
        return;
    }

    $uri = "$baseUri/translation-memory/$($tm.Id)/exports"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        languageDirection = @{
            sourceLanguage = @{
                languageCode = $sourceLanguage
            }
            targetLanguage = @{
                languageCode = $targetLanguage
            }
        }
    }

    $json = $body | ConvertTo-Json -Depth 2;

    $response = Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -body $json; }
    if ($null -eq $response)
    {
        return;
    }

    $pollUri = "$baseUri/translation-memory/exports/$($response.Id)"

    while ($true)
    {
        $pollResponse = Invoke-RestMethod -Uri $pollUri -Headers $headers;
        Start-Sleep -Seconds 1;
        if ($pollResponse.Status -eq "failed")
        {
            "Export failed"
            return
        }

        if ($pollResponse.Status -eq "done")
        {
            break;
        }
    }

    $downloadUri = "$baseUri/translation-memory/exports/$($pollResponse.Id)/download"
    $null = Invoke-RestMethod -Uri $downloadUri -Headers $headers -OutFile $outputFilePath;
}

<#
.SYNOPSIS
    Retrieves all translation quality assessments available in the system.

.DESCRIPTION
    The `Get-AllTranslationQualityAssessments` function retrieves a list of all translation quality assessments. 
    You can optionally filter the results based on the location ID or name, define a strategy for fetching quality assessments from specific locations, 
    and sort the results based on a specified property.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the translation quality assessments.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve translation quality assessments. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve translation quality assessments. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching translation quality assessments in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves translation quality assessments from the specified location.
        - "bloodline": Retrieves translation quality assessments from the specified location and its parent folders.
        - "lineage": Retrieves translation quality assessments from the specified location and its subfolders.
        - "genealogy": Retrieves translation quality assessments from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property to sort the results. If a value is provided with a `-` ahead, it indicates descending order; otherwise, the order is ascending.

.OUTPUTS
    Returns a list of translation quality assessments containing relevant details such as ID, name, description, and other related metadata.

.EXAMPLE
    # Example 1: Retrieve all translation quality assessments from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationQualityAssessments -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve translation quality assessments from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationQualityAssessments -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve translation quality assessments from a specific location using the bloodline strategy and sort by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTranslationQualityAssessments -accessKey $accessKey -locationName "FolderA" -locationStrategy "bloodline" -sortProperty "name"
#>
function Get-AllTranslationQualityAssessments 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/tqa-profiles" `
                         -location $location `
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific translation quality assessment by ID or name.

.DESCRIPTION
    The `Get-TranslationQualityAssessment` function retrieves the details of a specific translation quality assessment based on the provided TQA ID or name.
    Either the `tqaId` or `tqaName` must be provided to retrieve the translation quality assessment information.
    If both parameters are provided, the function will prioritize `tqaId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the translation quality assessment.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER tqaId
    (Optional) The ID of the translation quality assessment to retrieve. Either `tqaId` or `tqaName` must be provided.

.PARAMETER tqaName
    (Optional) The name of the translation quality assessment to retrieve. Either `tqaId` or `tqaName` must be provided.

.OUTPUTS
    Returns the specified translation quality assessment with fields such as ID, name, description, and assessment criteria.

.EXAMPLE
    # Example 1: Retrieve a translation quality assessment by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-TranslationQualityAssessment -accessKey $accessKey -tqaId "12345"

.EXAMPLE
    # Example 2: Retrieve a translation quality assessment by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-TranslationQualityAssessment -accessKey $accessKey -tqaName "MyTranslationQualityAssessment"
#>
function Get-TranslationQualityAssessment 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey, 

        [string] $tqaId,
        [string] $tqaName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/tqa-profiles" -id $tqaId -name $tqaName -propertyName "Tqa profile";
}

<#
.SYNOPSIS
    Retrieves all language processing rules available in the system.

.DESCRIPTION
    The `Get-AllLanguageProcessingRules` function retrieves a list of all language processing rules. 
    You can optionally filter the results based on the location ID or name, and define a strategy for fetching processing rules from specific locations.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the language processing rules.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve language processing rules. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve language processing rules. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching language processing rules in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves language processing rules from the specified location.
        - "bloodline": Retrieves language processing rules from the specified location and its parent folders.
        - "lineage": Retrieves language processing rules from the specified location and its subfolders.
        - "genealogy": Retrieves language processing rules from both subfolders and parent folders of the specified location.

.OUTPUTS
    Returns a list of language processing rules containing relevant details such as ID, name, description, and other related metadata.

.EXAMPLE
    # Example 1: Retrieve all language processing rules from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllLanguageProcessingRules -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve language processing rules from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllLanguageProcessingRules -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve language processing rules from a specific location using the genealogy strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllLanguageProcessingRules -accessKey $accessKey -locationName "FolderA" -locationStrategy "genealogy"
#>
function Get-AllLanguageProcessingRules 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    $location = @{}
    if ($locationId -or $locationName) # find a way to shorten this..
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/language-processing-rules" `
                         -location $location -fields "fields=id,name,description"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific language processing rule by ID or name.

.DESCRIPTION
    The `Get-LanguageProcessingRule` function retrieves the details of a specific language processing rule based on the provided ID or name.
    Either the `languageProcessingId` or `languageProcessingName` must be provided to retrieve the language processing rule information.
    If both parameters are provided, the function will prioritize `languageProcessingId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the language processing rule.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER languageProcessingId
    (Optional) The ID of the language processing rule to retrieve. Either `languageProcessingId` or `languageProcessingName` must be provided.

.PARAMETER languageProcessingName
    (Optional) The name of the language processing rule to retrieve. Either `languageProcessingId` or `languageProcessingName` must be provided.

.OUTPUTS
    Returns the specified language processing rule with fields such as ID, name, description, and associated processing criteria.

.EXAMPLE
    # Example 1: Retrieve a language processing rule by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-LanguageProcessingRule -accessKey $accessKey -languageProcessingId "67890"

.EXAMPLE
    # Example 2: Retrieve a language processing rule by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-LanguageProcessingRule -accessKey $accessKey -languageProcessingName "MyLanguageProcessingRule"
#>
function Get-LanguageProcessingRule 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $languageProcessingId,
        [string] $languageProcessingName
    )

    return Get-Item -accessKey $accessKey  -uri "$baseUri/language-processing-rules" `
             -uriQuery "?fields=id,name,description" -id $languageProcessingId -name $languageProcessingName `
             -propertyName "Language processing rule"
}

<#
.SYNOPSIS
    Retrieves all field templates available in the system.

.DESCRIPTION
    The `Get-AllFieldTemplates` function retrieves a list of all field templates. 
    You can optionally filter the results based on the location ID or name, and define a strategy for fetching field templates from specific locations.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the field templates.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve field templates. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve field templates. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching field templates in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves field templates from the specified location.
        - "bloodline": Retrieves field templates from the specified location and its parent folders.
        - "lineage": Retrieves field templates from the specified location and its subfolders.
        - "genealogy": Retrieves field templates from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
    (Optional) The property by which the field templates should be sorted. 
    If a value is provided with a '-' prefix, the sorting will be in descending order; otherwise, it will be in ascending order.

.OUTPUTS
    Returns a list of field templates containing relevant details such as ID, name, description, and other related metadata.

.EXAMPLE
    # Example 1: Retrieve all field templates from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFieldTemplates -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve field templates from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFieldTemplates -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve field templates from a specific location using the bloodline strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFieldTemplates -accessKey $accessKey -locationName "FolderA" -locationStrategy "bloodline"

.EXAMPLE
    # Example 4: Retrieve and sort field templates by name in descending order
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllFieldTemplates -accessKey $accessKey -sortProperty "-name"
#>
function Get-AllFieldTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location",
        [string] $sortProperty
    )

    $location = @{};
    if ($locationId -or $locationName) # find a way to shorten this..
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/translation-memory/field-templates" `
                         -location $location -fields "fields=id,name,description,location"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific field template by ID or name.

.DESCRIPTION
    The `Get-FieldTemplate` function retrieves the details of a specific field template based on the provided ID or name.
    Either the `fieldTemplateId` or `fieldTemplateName` must be provided to retrieve the field template information.
    If both parameters are provided, the function will prioritize `fieldTemplateId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the field template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER fieldTemplateId
    (Optional) The ID of the field template to retrieve. Either `fieldTemplateId` or `fieldTemplateName` must be provided.

.PARAMETER fieldTemplateName
    (Optional) The name of the field template to retrieve. Either `fieldTemplateId` or `fieldTemplateName` must be provided.

.OUTPUTS
    Returns the specified field template with fields such as ID, name, description, and associated configurations.

.EXAMPLE
    # Example 1: Retrieve a field template by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-FieldTemplate -accessKey $accessKey -fieldTemplateId "67890"

.EXAMPLE
    # Example 2: Retrieve a field template by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-FieldTemplate -accessKey $accessKey -fieldTemplateName "MyFieldTemplate"
#>
function Get-FieldTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $fieldTemplateId,
        [string] $fieldTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/translation-memory/field-templates" -uriQuery "?fields=id,name,description,location" `
                -id $fieldTemplateId -name $fieldTemplateName -propertyName "Field template";
}

<#
.SYNOPSIS
    Creates a language pair linking one source language to multiple target languages.

.DESCRIPTION
    The `Get-LanguagePair` function constructs a PowerShell object that associates a specified source language 
    with multiple target languages. This function is particularly useful when creating translation memories 
    and project templates, allowing for the definition of language relationships in a structured format.

.PARAMETER sourceLanguage
    (Mandatory) The language code of the source language.

.PARAMETER targetLanguages
    (Mandatory) An array of language codes representing the target languages to link with the source language.

.OUTPUTS
    Returns an array of PowerShell objects, each representing a language direction linking the source language
    with one of the specified target languages. Each object contains structured information about the language pair.

.EXAMPLE
    # Example 1: Create language pairs linking English to multiple languages
    $languagePairs = Get-LanguagePair -sourceLanguage "en-US" -targetLanguages @("fr-FR", "de-DE", "es-ES")
#>
function Get-LanguagePair {
    param (
        [Parameter(Mandatory=$true)]
        [string] $sourceLanguage,

        [Parameter(Mandatory=$true)]
        [string[]] $targetLanguages
    )

    $languageDirections = @();
    foreach ($target in $targetLanguages)
    {

        $languageDirection = [ordered]@{
            sourceLanguage = [ordered]@{languageCode = $sourceLanguage}
            targetLanguage = [ordered]@{languageCode = $target}
        }
        
        $languageDirections += $languageDirection;
    }

    return $languageDirections;
}

function Get-Item 
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

function Get-LanguageDirections 
{
    param (
        [String[]] $sourceLanguage,
        [String[]] $targetLanguages,
        [psobject[]] $languagePairs
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
    elseif ($languagePairs)
    {
        foreach ($pairs in $languagePairs) {
            $languageDirections += $pairs;
        }
    }

    return $languageDirections;
}

Export-ModuleMember Get-AllProjectTemplates;
Export-ModuleMember Get-ProjectTemplate;
Export-ModuleMember New-ProjectTemplate;
Export-ModuleMember Remove-ProjectTemplate;
Export-ModuleMember Update-ProjectTemplate;
Export-ModuleMember Get-AllTranslationEngines;
Export-ModuleMember Get-TranslationEngine;
Export-ModuleMember Get-AllCustomers;
Export-ModuleMember Get-Customer;
Export-ModuleMember New-Customer;
Export-ModuleMember Remove-Customer;
Export-ModuleMember Update-Customer;
Export-ModuleMember Get-AllWorkflows;
Export-ModuleMember Get-Workflow;
Export-ModuleMember Get-AllPricingModels;
Export-ModuleMember Get-PricingModel;
Export-ModuleMember Get-AllScheduleTemplates;
Export-ModuleMember Get-ScheduleTemplate;
Export-ModuleMember Remove-ScheduleTemplate;
Export-ModuleMember Get-AllFileTypeConfigurations;
Export-ModuleMember Get-FileTypeConfiguration;
Export-ModuleMember Get-AllLocations;
Export-ModuleMember Get-Location;
Export-ModuleMember Get-AllCustomFields;
Export-ModuleMember Get-CustomField;
Export-ModuleMember Copy-TranslationMemory;
Export-ModuleMember Get-AllTranslationMemories;
Export-ModuleMember Get-TranslationMemory;
Export-ModuleMember New-TranslationMemory;
Export-ModuleMember Remove-TranslationMemory;
Export-ModuleMember Update-TranslationMemory;
Export-ModuleMember Import-TranslationMemory;   
Export-ModuleMember Export-TranslationMemory;
Export-ModuleMember Get-AllTranslationQualityAssessments;
Export-ModuleMember Get-TranslationQualityAssessment;
Export-ModuleMember Get-AllLanguageProcessingRules;
Export-ModuleMember Get-LanguageProcessingRule;
Export-ModuleMember Get-AllFieldTemplates;
Export-ModuleMember Get-FieldTemplate;
Export-ModuleMember Get-LanguagePair;