$baseUri = "https://lc-api.sdl.com/public-api/v1"

<#
.SYNOPSIS
Retrieves all project templates available in the system.

.DESCRIPTION
The `Get-AllProjectTemplates` function fetches a list of all project templates from the API, 
including their IDs, names, descriptions, language directions, and locations. This is useful for 
understanding the available templates for project creation.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$templates = Get-AllProjectTemplates -accessKey $accessKey
This example retrieves all project templates and stores them in the `$templates` variable.

.NOTES
This function makes a GET request to the project templates API endpoint and returns a collection of project template objects.
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
        [psobject] $languagePairs,
        [string[]] $userManagerIdsOrNames,
        [string[]] $customFieldIdsOrNames,
        [string] $translationEngineIdOrName,
        [string] $pricingModelIdOrName,
        [string] $workflowIdOrName,
        [string] $tqaIdOrName,

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

    if ($userManagerIdsOrNames) # add later the bloodline part..
    {
    }
    if ($projectManagerIdsOrNames)
    {
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

        $body.worfklow = [ordered] @{
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
        }

        $body.settings.qualityManagement = @{
            qualityManagement = @{
                tqaProfile = @{
                    id = $tqa.Id 
                    strategy = $tqaStrategy
                }
            }
        }
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
    Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json;
}

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

<#
.SYNOPSIS
Retrieves all translation engines available in the system.

.DESCRIPTION
The `Get-AllTranslationEngines` function fetches a list of all translation engines from the API, 
including their names, descriptions, locations, and definitions. This is useful for identifying 
available translation engines for project configurations.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$translationEngines = Get-AllTranslationEngines -accessKey $accessKey
This example retrieves all translation engines and stores them in the `$translationEngines` variable.

.NOTES
This function makes a GET request to the translation engines API endpoint and returns a collection of translation engine objects.
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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/translation-engines" `
                         -location $location -fields "fields=name,description,location,definition"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-TranslationEngine 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $translationEngineId,
        [String] $translationEngineName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/translation-engines" -uriQuery "?fields=name,description,location,definition" -id $translationEngineId -name $translationEngineName;
}

<#
.SYNOPSIS
Retrieves all customers available in the system.

.DESCRIPTION
The `Get-AllCustomers` function fetches a list of all customers from the API, including their IDs, names, and locations. 
This is useful for identifying customers associated with projects.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$customers = Get-AllCustomers -accessKey $accessKey
This example retrieves all customers and stores them in the `$customers` variable.

.NOTES
This function makes a GET request to the customers API endpoint and returns a collection of customer objects.
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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/customers" `
                         -location $location -fields "fields=id,name,location"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

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
Retrieves all file type configurations available in the system.

.DESCRIPTION
The `Get-AllFileTypeConfigurations` function fetches a list of all file processing configurations 
from the API, including their IDs, names, and locations. This is useful for identifying 
available configurations for file processing.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$fileTypeConfigs = Get-AllFileTypeConfigurations -accessKey $accessKey
This example retrieves all file type configurations and stores them in the `$fileTypeConfigs` variable.

.NOTES
This function makes a GET request to the file type configurations API endpoint and returns a collection of file type configuration objects.
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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/file-processing-configurations" `
                        -location $location -fields "fields=id,name,location" `
                        -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-FileTypeConfiguration 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $fileTypeId,
        [string] $fileTypeName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/file-processing-configurations" -uriQuery "?fields=id,name,location" -id $fileTypeId -name $fileTypeName;
}

<#
.SYNOPSIS
Retrieves all workflows available in the system.

.DESCRIPTION
The `Get-AllWorkflows` function fetches a list of all workflows from the API, including their IDs, names, descriptions, 
locations, workflow templates, and language directions. This is useful for identifying workflows that can be applied to projects.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$workflows = Get-AllWorkflows -accessKey $accessKey
This example retrieves all workflows and stores them in the `$workflows` variable.

.NOTES
This function makes a GET request to the workflows API endpoint and returns a collection of workflow objects.
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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/workflows" `
                         -location $location -fields "fields=id,name,description,location,workflowTemplate,languageDirections"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-Workflow 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $workflowId,
        [string] $workflowName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/workflows" -uriQuery "?fields=id,name,description,location,workflowTemplate,languageDirections" -id $workflowId -name $workflowName;
}

<#
.SYNOPSIS
Retrieves all pricing models available in the system.

.DESCRIPTION
The `Get-AllPricingModels` function fetches a list of all pricing models from the API, including their IDs, names, 
descriptions, currency codes, and locations. This is useful for understanding the pricing options available for projects.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$pricingModels = Get-AllPricingModels -accessKey $accessKey
This example retrieves all pricing models and stores them in the `$pricingModels` variable.

.NOTES
This function makes a GET request to the pricing models API endpoint and returns a collection of pricing model objects.
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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/pricing-models" `
                         -location $location -fields "fields=id,name,description,currencyCode,location,languageDirectionPricing"`
                         -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

# Might need to remove this one..
function  Get-PricingModel {
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $pricingModelId,
        [String] $pricingModelName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/pricing-models" -uriQuery "?fields=id,name,description,currencyCode,location" -id $pricingModelId -name $pricingModelName
}

<#
.SYNOPSIS
Retrieves all schedule templates available in the system.

.DESCRIPTION
The `Get-AllScheduleTemplates` function fetches a list of all schedule templates from the API, including their names, 
descriptions, and locations. This is useful for identifying templates that can be used to set project schedules.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$scheduleTemplates = Get-AllScheduleTemplates -accessKey $accessKey
This example retrieves all schedule templates and stores them in the `$scheduleTemplates` variable.

.NOTES
This function makes a GET request to the schedule templates API endpoint and returns a collection of schedule template objects.
#>
function Get-AllScheduleTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )

    return Get-AllItems $accessKey "$baseUri/schedule-templates?fields=name,description,location"
}

function Get-ScheduleTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $scheduleTemplateId,
        [string] $scheduleTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/schedule-templates" -uriQuery "?fields=name,description,location" -id $scheduleTemplateId -name $scheduleTemplateName;
}

function Remove-ScheduleTemplate
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $scheduleTemplateIdOrName
    )

    $scheduleTemplates = Get-AllScheduleTemplates $accessKey;
    $scheduleTemplate = $scheduleTemplates | Where-Object {$_.Id -eq $scheduleTemplateIdOrName -or $_.Name -eq $scheduleTemplateIdOrName } | Select-Object -First 1;

    if ($scheduleTemplate)
    {
        $headers = Get-RequestHeader -accessKey $accessKey;
        $uri = "$baseUri/schedule-templates/$($scheduleTemplate.Id)"
        return Invoke-RestMethod -uri $uri -Method Delete -Headers $headers;
    }

    Write-Host "Schedule Template $scheduleTemplateIdOrName does not exist" -ForegroundColor Green;
}

<#
.SYNOPSIS
Retrieves all locations available in the system.

.DESCRIPTION
The `Get-AllLocations` function fetches a list of all locations from the API. This is useful for understanding 
where resources and projects can be located.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$locations = Get-AllLocations -accessKey $accessKey
This example retrieves all locations and stores them in the `$locations` variable.

.NOTES
This function makes a GET request to the locations API endpoint and returns a collection of location objects.
#>
function Get-AllLocations 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey "$baseUri/folders"
}

function Get-Location 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $locationId,
        [String] $locationName
    )

    return Get-Item -accessKey $accessKey -id $locationId -name $locationName -uri "$baseUri/folders";
}

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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/custom-field-definitions" `
                         -location $location -fields "fields=id,name,key,description,defaultValue,type,location,resourceType,isMandatory,pickListOptions" `
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-CustomField 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $customFieldId,
        [String] $customFieldName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/custom-field-definitions" -uriQuery "?fields=id,name,key,description,defaultValue,type,location,resourceType,isMandatory,pickListOptions" -id $customFieldId -name $customFieldName;
}

function Get-AllTranslationMemories 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/translation-memory" `
                         -location $location `
                         -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

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

    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/tqa-profiles" `
                         -location $location `
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-TranslationQualityAssessment 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey, 

        [string] $tqaId,
        [string] $tqaName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/tqa-profiles" -id $tqaId -name $tqaName;
}

function Get-AllLanguageProcessingRules 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

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

function Get-LanguageProcessingRule 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $languageProcessingId,
        [string] $languageProcessingName
    )

    return Get-Item -accessKey $accessKey  -uri "$baseUri/language-processing-rules" -uriQuery "?fields=id,name,description" -id $languageProcessingId -name $languageProcessingName
}

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

function Get-FieldTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $fieldTemplateId,
        [string] $fieldTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/translation-memory/field-templates" -uriQuery "?fields=id,name,description,location" `
                -id $fieldTemplateId -name $fieldTemplateName; # I should only put the resource not found here..
}

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