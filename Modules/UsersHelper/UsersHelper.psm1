function Get-AllUsers 
{
    param (
        [psobject] $accessKey
    )

    return Get-AllItems $accessKey 'https://lc-api.sdl.com/public-api/v1/users?fields=id,email,firstName,lastName,location';
}

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