# Default base URI - can be overridden via Set-BaseUri
$script:baseUri = "https://lc-api.sdl.com/public-api/v1"

<#
.SYNOPSIS
    Gets the current base URI used for all API calls.

.DESCRIPTION
    Returns the base URI that all toolkit modules use when constructing API requests.

.OUTPUTS
    String. The current base URI.

.EXAMPLE
    Get-BaseUri
#>
function Get-BaseUri
{
    return $script:baseUri
}

<#
.SYNOPSIS
    Sets the base URI used for all API calls.

.DESCRIPTION
    Allows you to override the default base URI for the Language Cloud API.
    This is useful if you need to target a different region or environment.

.PARAMETER uri
    The base URI to use for all API calls, e.g. "https://api.eu.cloud.trados.com/public-api/v1".

.EXAMPLE
    Set-BaseUri -uri "https://api.eu.cloud.trados.com/public-api/v1"
#>
function Set-BaseUri
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $uri
    )

    $script:baseUri = $uri.TrimEnd('/')
}

<#
.SYNOPSIS
    Builds the standard HTTP request headers for Language Cloud API calls.

.DESCRIPTION
    Creates a dictionary of headers including the tenant identifier, authorisation token, 
    and content type settings required by the Language Cloud API.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey containing token and tenant properties.

.OUTPUTS
    System.Collections.Generic.Dictionary[String,String]. The headers dictionary.

.EXAMPLE
    $headers = Get-RequestHeader -accessKey $accessKey
#>
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

    return $headers
}

<#
.SYNOPSIS
    Retrieves all items from a paginated API endpoint.

.DESCRIPTION
    Fetches items from the specified URI, automatically handling pagination by following 
    the API's skip/top parameters. The Language Cloud API returns a maximum of 100 items 
    per request; this function retrieves all pages and returns the combined results.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER uri
    (Mandatory) The API endpoint URI to query.

.OUTPUTS
    Array of items returned by the API.

.EXAMPLE
    $allUsers = Get-AllItems -accessKey $accessKey -uri "https://lc-api.sdl.com/public-api/v1/users"
#>
function Get-AllItems
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $uri
    )

    $headers = Get-RequestHeader -accessKey $accessKey
    $allItems = @()
    $top = 100
    $skip = 0

    # Determine the correct separator for appending query parameters
    $separator = if ($uri.Contains("?")) { "&" } else { "?" }

    do
    {
        $pagedUri = "$uri${separator}top=$top&skip=$skip"

        $response = Invoke-SafeMethod {
            Invoke-RestMethod -Uri $pagedUri -Method 'GET' -Headers $headers
        }

        if ($null -eq $response -or $null -eq $response.Items)
        {
            break
        }

        $allItems += $response.Items
        $skip += $top

        # Stop if we received fewer items than the page size, meaning we have reached the last page
        if ($response.Items.Count -lt $top)
        {
            break
        }
    } while ($true)

    return $allItems
}

<#
.SYNOPSIS
    Retrieves a single item from the API by ID or name.

.DESCRIPTION
    Fetches a specific item from the given endpoint. If an ID is provided, the item is 
    retrieved directly. If a name is provided, all items are fetched and filtered locally.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey.

.PARAMETER uri
    (Mandatory) The base API endpoint URI for the resource type.

.PARAMETER uriQuery
    (Optional) Additional query string to append to the URI (e.g. field selections).

.PARAMETER id
    (Optional) The ID of the item to retrieve.

.PARAMETER name
    (Optional) The name of the item to retrieve. Used if ID is not provided.

.PARAMETER propertyName
    (Optional) A friendly name for the resource type, used in error messages.

.OUTPUTS
    The matching item object, or $null if not found.

.EXAMPLE
    $template = Get-Item -accessKey $accessKey -uri "$baseUri/project-templates" -id "12345" -propertyName "Project template"
#>
function Get-Item
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $uri,

        [String] $uriQuery,
        [String] $id,
        [String] $name,
        [String] $propertyName
    )

    if ($id)
    {
        $itemUri = "$uri/$id"
        if ($uriQuery) { $itemUri += $uriQuery }

        $headers = Get-RequestHeader -accessKey $accessKey
        $item = Invoke-SafeMethod { Invoke-RestMethod -Uri $itemUri -Headers $headers }
    }
    elseif ($name)
    {
        $listUri = $uri
        if ($uriQuery) { $listUri += $uriQuery }

        $items = Get-AllItems -accessKey $accessKey -uri $listUri
        if ($items)
        {
            $item = $items | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }

        if ($null -eq $item)
        {
            Write-Host "$propertyName could not be found" -ForegroundColor Green
        }
    }

    if ($item)
    {
        return $item
    }
}

<#
.SYNOPSIS
    Builds a complete URI with query string parameters for API requests.

.DESCRIPTION
    Constructs a URI from a root endpoint, optional name filter, location filter, 
    location strategy, sort parameter, and field selection.

.PARAMETER root
    The base endpoint URI.

.PARAMETER name
    (Optional) Filter by resource name.

.PARAMETER location
    (Optional) A location object whose ID will be used for filtering.

.PARAMETER locationStrategy
    (Optional) The location strategy (location, bloodline, lineage, genealogy).

.PARAMETER sort
    (Optional) The sort property. Prefix with "-" for descending order.

.PARAMETER fields
    (Optional) The fields query parameter string (e.g. "fields=id,name").

.OUTPUTS
    String. The complete URI with query parameters.

.EXAMPLE
    $uri = Get-StringUri -root "$baseUri/users" -fields "fields=id,email,firstName,lastName"
#>
function Get-StringUri
{
    param (
        [String] $root,
        [String] $name,
        [psobject] $location,
        [String] $locationStrategy,
        [String] $sort,
        [String] $fields
    )

    $filter = Get-FilterString -name $name -location $location -locationStrategy $locationStrategy -sort $sort

    # Clean any leading ampersand from the fields parameter
    if ($fields) { $fields = $fields.TrimStart('&') }

    if ($filter -and $fields)
    {
        return "$root`?$filter&$fields"
    }
    elseif ($filter)
    {
        return "$root`?$filter"
    }
    elseif ($fields)
    {
        return "$root`?$fields"
    }
    else
    {
        return $root
    }
}

<#
.SYNOPSIS
    Builds a filter query string from the provided parameters.

.DESCRIPTION
    Constructs the filter portion of an API query string based on name, location, 
    location strategy, and sort parameters.

.PARAMETER name
    (Optional) Filter by resource name.

.PARAMETER location
    (Optional) A location object whose ID will be used for filtering.

.PARAMETER locationStrategy
    (Optional) The location strategy to use with the location filter.

.PARAMETER sort
    (Optional) The sort property. Prefix with "-" for descending order.

.OUTPUTS
    String. The filter query string, or empty string if no filters are specified.
#>
function Get-FilterString
{
    param (
        [String] $name,
        [psobject] $location,
        [String] $locationStrategy,
        [String] $sort
    )

    $filter = @()

    if (-not [string]::IsNullOrEmpty($name))
    {
        $filter += "name=$name"
    }
    if ($location -and (-not [string]::IsNullOrEmpty($locationStrategy)))
    {
        $filter += "location=$($location.Id)&locationStrategy=$locationStrategy"
    }
    if (-not [string]::IsNullOrEmpty($sort))
    {
        $filter += "sort=$sort"
    }

    return $filter -join '&'
}

<#
.SYNOPSIS
    Wraps an API call in error handling.

.DESCRIPTION
    Executes the provided script block inside a try/catch. If the call fails, 
    the error message from the API response is displayed in the console.

.PARAMETER method
    (Mandatory) The script block containing the API call to execute.

.OUTPUTS
    The result of the API call, or $null if an error occurred.

.EXAMPLE
    $result = Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers }
#>
function Invoke-SafeMethod
{
    param (
        [Parameter(Mandatory=$true)]
        [scriptblock] $method
    )

    try
    {
        return & $method
    }
    catch
    {
        try
        {
            $response = ConvertFrom-Json $_
            Write-Host $response.Message -ForegroundColor Green
        }
        catch
        {
            Write-Host "Error: $_" -ForegroundColor Red
        }
        return $null
    }
}

<#
.SYNOPSIS
    Builds an array of language direction objects for project and template creation.

.DESCRIPTION
    Constructs language direction objects from either a single source language with 
    multiple target languages, or from pre-built language pair objects.

.PARAMETER sourceLanguage
    (Optional) The source language code (e.g. "en-US").

.PARAMETER targetLanguages
    (Optional) An array of target language codes (e.g. @("de-DE", "fr-FR")).

.PARAMETER languagePairs
    (Optional) Pre-built language pair objects, typically from Get-LanguagePair.

.OUTPUTS
    Array of language direction objects suitable for API request bodies.

.EXAMPLE
    $directions = Get-LanguageDirections -sourceLanguage "en-US" -targetLanguages @("de-DE", "fr-FR")
#>
function Get-LanguageDirections
{
    param (
        [String] $sourceLanguage,
        [String[]] $targetLanguages,
        [psobject[]] $languagePairs
    )

    $languageDirections = @()

    if ($sourceLanguage -and $targetLanguages)
    {
        foreach ($target in $targetLanguages)
        {
            $languageDirection = [ordered]@{
                sourceLanguage = [ordered]@{ languageCode = $sourceLanguage }
                targetLanguage = [ordered]@{ languageCode = $target }
            }
            $languageDirections += $languageDirection
        }
    }
    elseif ($languagePairs)
    {
        foreach ($pair in $languagePairs)
        {
            $languageDirections += $pair
        }
    }

    return $languageDirections
}

<#
.SYNOPSIS
    Retrieves the list of supported languages from Language Cloud.

.DESCRIPTION
    Calls the public languages endpoint to return all languages supported by Language Cloud.
    Supports optional filtering by language codes, type (all, specific, neutral), and field
    selection.

.PARAMETER accessKey
    (Mandatory) The access key object returned by Get-AccessKey containing token and tenant properties.

.PARAMETER languageCodes
    (Optional) An array of language codes to filter by (e.g. @("en-US", "de-DE")).

.PARAMETER type
    (Optional) Filter by language type. Allowed values: all, specific, neutral.

.PARAMETER fields
    (Optional) A comma-separated list of fields to include in the response
    (e.g. "languageCode,englishName").

.OUTPUTS
    Array of language objects with properties such as languageCode, englishName, direction,
    parentLanguageCode, defaultSpecificLanguageCode, and isNeutral.

.EXAMPLE
    $languages = Get-SupportedLanguages -accessKey $accessKey
    $languages | Format-Table languageCode, englishName, direction

.EXAMPLE
    $german = Get-SupportedLanguages -accessKey $accessKey -languageCodes @("de-DE", "de-AT")

.EXAMPLE
    $neutral = Get-SupportedLanguages -accessKey $accessKey -type "neutral" -fields "languageCode,englishName"
#>
function Get-SupportedLanguages
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [String[]] $languageCodes,

        [ValidateSet("all", "specific", "neutral")]
        [String] $type,

        [String] $fields
    )

    $uri = "$(Get-BaseUri)/languages"
    $queryParams = @()

    if ($languageCodes)
    {
        foreach ($code in $languageCodes)
        {
            $queryParams += "languageCodes=$code"
        }
    }

    if ($type)
    {
        $queryParams += "type=$type"
    }

    if ($fields)
    {
        $queryParams += "fields=$fields"
    }

    if ($queryParams.Count -gt 0)
    {
        $uri += "?" + ($queryParams -join "&")
    }

    $headers = Get-RequestHeader -accessKey $accessKey

    $response = Invoke-SafeMethod {
        Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    }

    if ($null -eq $response -or $null -eq $response.items)
    {
        return @()
    }

    return $response.items
}

Export-ModuleMember -Function Get-BaseUri
Export-ModuleMember -Function Set-BaseUri
Export-ModuleMember -Function Get-RequestHeader
Export-ModuleMember -Function Get-AllItems
Export-ModuleMember -Function Get-Item
Export-ModuleMember -Function Get-StringUri
Export-ModuleMember -Function Get-FilterString
Export-ModuleMember -Function Invoke-SafeMethod
Export-ModuleMember -Function Get-LanguageDirections
Export-ModuleMember -Function Get-SupportedLanguages
