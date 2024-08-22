function Get-AllProjectTemplates 
{
    param (
        [psobject] $accessKey
    )

    $projectTemplatesEndpoint = 'https://lc-api.sdl.com/public-api/v1/project-templates?fields=id,name,description,languageDirections,location';
    return Get-AllItems $accessKey $projectTemplatesEndpoint;
}

function Get-AllTranslationEngines 
{
    param (
        [psobject] $accessKey
    )
    $translationEnginesEndpoint = 'https://lc-api.sdl.com/public-api/v1/translation-engines?fields=name,description,location,definition'
    return Get-AllItems $accessKey $translationEnginesEndpoint;
}

function Get-AllCustomers 
{
    param (
        [psobject] $accessKey
    )

    $customersEndpoint = 'https://lc-api.sdl.com/public-api/v1/customers?fields=id,name,location'
    return Get-AllItems $accessKey $customersEndpoint
}

function Get-AllFileTypeConfigurations
{
    param (
        [psobject] $accessKey
    )

    $fileTypeConfigurationsEndpoint = 'https://lc-api.sdl.com/public-api/v1/file-processing-configurations?fields=id,name,location'
    return Get-AllItems $accessKey $fileTypeConfigurationsEndpoint
}

function Get-AllWorkflows 
{
    param (
        [psobject] $accessKey
    )

    $workflowsEndpoint = 'https://lc-api.sdl.com/public-api/v1/workflows?fields=id,name,description,location,workflowTemplate,languageDirections'
    return Get-AllItems $accessKey $workflowsEndpoint;
}

function Get-AllPricingModels 
{
    param (
        [psobject] $accessKey
    )

    $pricingModelsEndpoint = 'https://lc-api.sdl.com/public-api/v1/pricing-models?fields=id,name,description,currencyCode,location';
    return Get-AllItems $accessKey $pricingModelsEndpoint;
}

function Get-AllScheduleTemplates 
{
    param (
        [psobject] $accessKey
    )
    
    $scheduleTemplatesEndpoint = 'https://lc-api.sdl.com/public-api/v1/schedule-templates?fields=name,description,location'
    return Get-AllItems $accessKey $scheduleTemplatesEndpoint
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