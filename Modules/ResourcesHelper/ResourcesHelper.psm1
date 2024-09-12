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

        [string] $name,
        [string] $locationId,
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    
    $uri = "$baseUri/project-templates";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?name=$name&location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,description,languageDirections,location";
    $uri = $uri + $filter + $uriFields
    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-ProjectTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String] $projectTemplateId,
        [String] $projectTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/project-templates" -uriQuery "?fields=id,name,description,languageDirections,location" -id $projectTemplateId -name $projectTemplateName;
}

# Left to implement
function New-ProjectTemplate 
{
    param (
        [Paramter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectTemplateName,

        [psobject] $location,
        [string] $locationId,
        [string] $locationName,

        [psobject] $fileTypeConfiguration,
        [string] $fileTypeConfigurationId,
        [string] $fileTypeConfigurationName
    )

    $uri = "$baseUri/project-templates"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        name = $projectTemplateName
    }

    # Get-And-AssignResource -accessKey $accessKey -projectTemplate $body -resourceName

    
}

function Remove-ProjectTemplate
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $projectTemplateIdOrName
    )

    $projectTemplates = Get-AllProjectTemplates $accessKey;
    $projectTemplate = $projectTEmplates | Where-Object {$_.Id -eq $projectTemplateIdOrName -or $_.Name -eq $projectTemplateIdOrName} | Select-Object -First 1;

    if ($projectTemplate)
    {
        $headers = Get-RequestHeader -accessKey $accessKey;

        $uri = "$baseUri/project-templates/$($projectTemplate.Id)";

        return Invoke-RestMethod -uri $uri -Method Delete -Headers $headers;
    }

    Write-Host "Project Template $projectTemplateIdOrName does not exist" -ForegroundColor Green;
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
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey "$baseUri/translation-engines?fields=name,description,location,definition"
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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/customers";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,location";
    $uri = $uri + $filter + $uriFields
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

    return Get-Item -accessKey $accessKey -uri "$baseUri/customers" -uriQuery "?fields=id,name,location" -id $customerId -name $customerName;
}

function Remove-Customer
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $customerIdOrName
    )

    $allCustomers = Get-AllCustomers $accessKey;
    $customer = $allCustomers | Where-Object {$_.id -eq $customerIdOrName -or $_.name -eq $customerIdOrName} | Select-Object -First 1;
    if ($customer)
    {
        $headers = Get-RequestHeader -accessKey $accessKey;

        $uri = "$baseUri/customers/$($customer.Id)"
        return Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri;
    }

    Write-Host "Customer $customerIdOrName does not exist" -ForegroundColor Green;

}

function New-Customer
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $customerName,

        [string] $locationIdOrName,
        [string] $firstName,
        [string] $lastName,
        [string] $email
    )

    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        name = $customerName;
    }

    if ($locationIdOrName)
    {
        $allLocations = Get-AllLocations $accessKey;
        $location = $allLocations | Where-Object {$_.Id -eq $locationIdOrName -or $_.Name -eq $locationIdOrName } | Select-Object -First 1;
        if ($location)
        {
            $body.location = $location.Id;
        }
    }

    if ($firstName -and $lastName -and $email)
    {
        $body.firstName = $firstName
        $body.lastName = $lastName 
        $body.email = $email
    }


    $json = $body | ConvertTo-Json;
    $uri = "$baseUri/customers"

    return Invoke-RestMethod -uri $uri -Method Post -Headers $headers -Body $json;
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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/file-processing-configurations";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,location";
    $uri = $uri + $filter + $uriFields
    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-FileTypeConfiguration 
{
    param (
        [Paramter(Mandatory=$true)]
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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/workflows";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,description,location,workflowTemplate,languageDirections";
    $uri = $uri + $filter + $uriFields
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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/pricing-models"
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,description,currencyCode,location"
    $uri = $uri + $filter + $uriFields;
    return Get-AllItems -accessKey $accessKey -uri $uri
}

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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/custom-field-definitions";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,key,type";
    $uri = $uri + $filter + $uriFields
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

    return Get-Item -accessKey $accessKey -uri "$baseUri/custom-field-definitions" -uriQuery "?fields=id,name,key,type" -id $customFieldId -name $customFieldName;
}

function Get-AllTranslationMemories 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )
    $uri = "$baseUri/translation-memory"
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"

    $uri = $uri + $filter;
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

    return Get-Item -accessKey $accessKey -uri "$baseUri/translation-memory" -id $translationMemoryId -name $translationMemoryName;
}

function Remove-TranslationMemory
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $tmIdOrName
    )

    $tms = Get-AllTranslationMemories $accessKey;
    $tm = $tms | Where-Object {$_.Id -eq $tmIdOrName -or $_.Name -eq $tmIdOrName } | Select-Object -First 1;

    if ($tm)
    {
        $headers = Get-RequestHeader -accessKey $accessKey;
        $uri = "$baseUri/translation-memory/$($tm.Id)"

        return Invoke-RestMethod -uri $uri -Method Delete -Headers $headers;
    }

    Write-Host "Translation Memory $tmIdOrName does not exist" -ForegroundColor Green;
}

function Get-AllTranslationQualityAssessments 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/tqa-profiles"
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uri = $uri + $filter 
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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/language-processing-rules";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,description";
    $uri = $uri + $filter + $uriFields
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
        [bool] $includeSubFolders = $false,
        [string] $sortProperty
    )

    $uri = "$baseUri/translation-memory/field-templates";
    $locationStrategy = Get-LocationStrategy -includeSubFolders $includeSubFolders;
    $filter = "?location=$locationId&locationStrategy=$locationStrategy&sort=$sortProperty"
    $uriFields = "&fields=id,name,description,location";
    $uri = $uri + $filter + $uriFields
    return Get-AllItems -accessKey $accessKey -uri $uri;
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
        [string] $name
    )

    if ($id)
    {
        $uri += "/$id/$uriQuery"
        $headers = Get-RequestHeader -accessKey $accessKey;
        return Invoke-RestMethod -uri $uri -Headers $headers;
    }
    elseif ($name)
    {
        $items = Get-AllItems -accessKey $accessKey -uri $($uri + $uriQuery);
        $item = $items | Where-Object {$_.Name -eq $name } | Select-Object -First 1;
        return $item;        
    }
}

function Get-AllItems
{
    param (
        [psobject] $accessKey,
        [String] $uri)

    $headers = Get-RequestHeader -accessKey $accessKey;

    try 
    {
        $response = Invoke-RestMethod $uri -Method 'GET' -Headers $headers
        return $response.Items;        
    }
    catch 
    {
        Write-Host "$_"
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

    return $propertyValues;
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

Export-ModuleMember Get-AllProjectTemplates;
Export-ModuleMember Get-ProjectTemplate;
Export-ModuleMember Remove-ProjectTemplate;
Export-ModuleMember Get-AllTranslationEngines;
Export-ModuleMember Get-TranslationEngine;
Export-ModuleMember Get-AllCustomers;
Export-ModuleMember Get-Customer;
Export-ModuleMember New-Customer;
Export-ModuleMember Remove-Customer;
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
Export-ModuleMember Get-AllTranslationMemories;
Export-ModuleMember Get-TranslationMemory;
Export-ModuleMember Remove-TranslationMemory;
Export-ModuleMember Get-AllTranslationQualityAssessments;
Export-ModuleMember Get-TranslationQualityAssessment;
Export-ModuleMember Get-AllLanguageProcessingRules;
Export-ModuleMember Get-LanguageProcessingRule;
Export-ModuleMember Get-AllFieldTemplates;