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
        [psobject] $accessKey
    )

    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/users?fields=id,email,firstName,lastName,location';
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
function Get-AllGroups
{
    param (
        [psobject] $accessKey
    )

    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/groups?fields=id,name,description,location';
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

Export-ModuleMember Get-AllUsers; 
Export-ModuleMember Get-AllGroups;