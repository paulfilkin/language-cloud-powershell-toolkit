function Get-AllProjectTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )

    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/project-templates?fields=id,name,description,languageDirections,location'
}

function Get-AllTranslationEngines 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/translation-engines?fields=name,description,location,definition'
}

function Get-AllCustomers 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/customers?fields=id,name,location'
}

function Get-AllFileTypeConfigurations
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/file-processing-configurations?fields=id,name,location'
}

function Get-AllWorkflows 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/workflows?fields=id,name,description,location,workflowTemplate,languageDirections'
}

function Get-AllPricingModels 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/pricing-models?fields=id,name,description,currencyCode,location'
}

function Get-AllScheduleTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )
    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/schedule-templates?fields=name,description,location'
}

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