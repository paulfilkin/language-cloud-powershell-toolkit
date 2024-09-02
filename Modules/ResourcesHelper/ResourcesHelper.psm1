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
        [psobject] $accessKey
    )

    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/project-templates?fields=id,name,description,languageDirections,location'
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
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/translation-engines?fields=name,description,location,definition'
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
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/customers?fields=id,name,location'
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
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/file-processing-configurations?fields=id,name,location'
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
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/workflows?fields=id,name,description,location,workflowTemplate,languageDirections'
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
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/pricing-models?fields=id,name,description,currencyCode,location'
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
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/schedule-templates?fields=name,description,location'
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
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/folders'
}

function Get-AllItems
{
    
    param (
        [psobject] $accessKey,
        [String] $uri)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

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

Export-ModuleMember Get-AllProjectTemplates;
Export-ModuleMember Get-AllTranslationEngines;
Export-ModuleMember Get-AllCustomers;
Export-ModuleMember Get-AllWorkflows;
Export-ModuleMember Get-AllPricingModels;
Export-ModuleMember Get-AllScheduleTemplates;
Export-ModuleMember Get-AllFileTypeConfigurations;
Export-ModuleMember Get-AllLocations;