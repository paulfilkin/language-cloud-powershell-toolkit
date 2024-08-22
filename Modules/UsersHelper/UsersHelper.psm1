function Get-AllUsers 
{
    param (
        [psobject] $accessKey
    )

    $usersEndpoint = 'https://lc-api.sdl.com/public-api/v1/users?fields=id,email,firstName,lastName,location';
    return Get-AllItems $accessKey $usersEndpoint;
}

function Get-AllGroups
{
    param (
        [psobject] $accessKey
    )

    $groupsEndpoint = 'https://lc-api.sdl.com/public-api/v1/groups?fields=id,name,description,location';
    return Get-AllItems $accessKey $groupsEndpoint;
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

Export-ModuleMember Get-AllUsers; # maybe find a way to change the fields given
Export-ModuleMember Get-AllGroups;