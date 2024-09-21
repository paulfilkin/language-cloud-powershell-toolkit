$baseUri = "https://lc-api.sdl.com/public-api/v1"

<#
.SYNOPSIS
Retrieves all users available in the system.

.DESCRIPTION
The `Get-AllUsers` function fetches a list of all users from the API, 
including their IDs, emails, first names, last names, and locations. 
This is useful for managing user information and understanding the users 
associated with projects.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$users = Get-AllUsers -accessKey $accessKey
This example retrieves all users and stores them in the `$users` variable.

.NOTES
This function makes a GET request to the users API endpoint and returns a collection of user objects.
#>
function Get-AllUsers 
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

    $uri = Get-StringUri -root "$baseUri/users" `
                         -location $location -fields "fields=id,email,firstName,lastName,location"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;

}

function  Get-User {
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $userId,
        [string] $userEmail,
        [string] $userFirstName,
        [string] $userLastName
    )

    $uri = "$baseUri/users"

    if ($userId)
    {
        $uri = $baseUri + "/users/" + $userId
        $headers = Get-RequestHeader -accessKey $accessKey
        return Invoke-SafeMethod {
            Invoke-RestMethod -uri $uri -Headers $headers
        }
    }
    else 
    {
        $users = Get-AllItems -accessKey $accessKey -uri $uri;
        if ($userEmail)
        {
            $user = $users | Where-Object {$_.email -eq $userEmail } | Select-Object -First 1;
        }
        elseif ($userFirstName -and $userLastName)
        {
            $user = $users | Where-Object {$_.firstName -eq $userFirstName -and $_.lastName -eq $userLastName} | Select-Object -First 1;
        }

        if ($null -eq $user)
        {
            Write-Host "User could not be found" -ForegroundColor Green;
        }
        else 
        {
            return $user;
        }
    }

}

<#
.SYNOPSIS
Retrieves all groups available in the system.

.DESCRIPTION
The `Get-AllGroups` function fetches a list of all groups from the API, 
including their IDs, names, descriptions, and locations. 
This is useful for managing group information and understanding the groups 
associated with projects.

.PARAMETER accessKey
The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

.EXAMPLE
$groups = Get-AllGroups -accessKey $accessKey
This example retrieves all groups and stores them in the `$groups` variable.

.NOTES
This function makes a GET request to the groups API endpoint and returns a collection of group objects.
#>
function Get-AllGroups # apply filter on groups and users
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "bloodline",
        [string] $sortProperty
    )
    
    $location = @{};
    if ($locationId -or $locationName) # Might need some refactoring here as all the list-items will change
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/groups" `
                         -location $location -fields "fields=id,name,description,location"`
                         -locationStrategy $locationStrategy -sort $sortProperty;

    return Get-AllItems -accessKey $accessKey -uri $uri;
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

    $response = Invoke-SafeMethod {
        Invoke-RestMethod $uri -Method 'GET' -Headers $headers
    }

    if ($response)
    {
        return $response.Items;
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

Export-ModuleMember Get-AllUsers; 
Export-ModuleMember Get-User;
Export-ModuleMember Get-AllGroups;