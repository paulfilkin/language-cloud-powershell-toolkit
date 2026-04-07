Import-Module -Name CommonHelper

<#
.SYNOPSIS
Retrieves all users available in the system.

.DESCRIPTION
The `Get-AllUsers` function fetches a list of all users from the API, 
including their IDs, emails, first names, last names, and locations. 

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
(Optional) The ID of the location to filter the users. If specified, only users associated with this location will be retrieved.

.PARAMETER locationName
(Optional) The name of the location to filter the users. If specified, only users associated with this location will be retrieved.

.PARAMETER locationStrategy
(Optional) The strategy to determine how the location is used when filtering users. Default is "location".
The available options are:
    - "location" (default): Retrieves users from the specified location.
    - "bloodline": Retrieves users from the specified location and its parent folders.
    - "lineage": Retrieves users from the specified location and its subfolders.
    - "genealogy": Retrieves users from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
(Optional) The property by which the results should be sorted. Providing a property name (e.g., "name") will sort the list in ascending order. 
Prefixing a property with a dash (e.g., "-name") will sort it in descending order.

.EXAMPLE
    # Example 1: Retrieve all users available in the system
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllUsers -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve users from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllUsers -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve users from a specific location using the location name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllUsers -accessKey $accessKey -locationName "FolderA"

.EXAMPLE
    # Example 4: Retrieve users sorted by email
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllUsers -accessKey $accessKey -sortProperty "email"
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

    $baseUri = Get-BaseUri

    $location = @{}
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/users" `
                         -location $location -fields "fields=id,email,firstName,lastName,location" `
                         -locationStrategy $locationStrategy -sort $sortProperty

    return Get-AllItems -accessKey $accessKey -uri $uri
}

<#
.SYNOPSIS
Retrieves information about a user or a list of users from the system.

.DESCRIPTION
The `Get-User` function allows you to fetch details of a specific user by providing their user ID, or retrieve users based on their email, first name, or last name. 
If the user ID is provided, the function returns details for that specific user. 
Otherwise, it filters the list of users based on the provided criteria.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.
To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER userId
(Optional) The ID of the user to retrieve. If provided, it will return the user associated with this ID.

.PARAMETER userEmail
(Optional) The email address of the user to retrieve. If specified, the function will return the user with this email.

.PARAMETER userFirstName
(Optional) The first name of the user to retrieve. Used in conjunction with `userLastName`.

.PARAMETER userLastName
(Optional) The last name of the user to retrieve. Used in conjunction with `userFirstName`.

.EXAMPLE
    # Example 1: Retrieve a user by user ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-User -accessKey $accessKey -userId "12345"

.EXAMPLE
    # Example 2: Retrieve a user by email
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-User -accessKey $accessKey -userEmail "user@example.com"

.EXAMPLE
    # Example 3: Retrieve a user by first and last name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-User -accessKey $accessKey -userFirstName "John" -userLastName "Doe"
#>
function Get-User {
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $userId,
        [string] $userEmail,
        [string] $userFirstName,
        [string] $userLastName
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/users"

    if ($userId)
    {
        $uri = "$baseUri/users/$userId"
        $headers = Get-RequestHeader -accessKey $accessKey
        return Invoke-SafeMethod {
            Invoke-RestMethod -Uri $uri -Headers $headers
        }
    }
    else 
    {
        $users = Get-AllItems -accessKey $accessKey -uri $uri
        if ($userEmail)
        {
            $user = $users | Where-Object { $_.email -eq $userEmail } | Select-Object -First 1
        }
        elseif ($userFirstName -and $userLastName)
        {
            $user = $users | Where-Object { $_.firstName -eq $userFirstName -and $_.lastName -eq $userLastName } | Select-Object -First 1
        }

        if ($null -eq $user)
        {
            Write-Host "User could not be found" -ForegroundColor Green
        }
        else 
        {
            return $user
        }
    }
}

<#
.SYNOPSIS
Retrieves all groups available in the system.

.DESCRIPTION
The `Get-AllGroups` function fetches a list of all groups from the API, 
including their IDs, names, descriptions, and locations. 

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function. This is required to authenticate API requests.

To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
(Optional) The ID of the location to filter the groups. If specified, only groups associated with this location will be retrieved.

.PARAMETER locationName
(Optional) The name of the location to filter the groups. If specified, only groups associated with this location will be retrieved.

.PARAMETER locationStrategy
(Optional) The strategy to determine how the location is used when filtering groups. Default is "bloodline".
The available options are:
    - "location": Retrieves groups from the specified location.
    - "bloodline" (default): Retrieves groups from the specified location and its parent folders.
    - "lineage": Retrieves groups from the specified location and its subfolders.
    - "genealogy": Retrieves groups from both subfolders and parent folders of the specified location.

.PARAMETER sortProperty
(Optional) The property by which the results should be sorted. Providing a property name (e.g., "name") will sort the list in ascending order. 
Prefixing a property with a dash (e.g., "-name") will sort it in descending order.

.EXAMPLE
    # Example 1: Retrieve all groups available in the system
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllGroups -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve groups from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllGroups -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve groups sorted by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllGroups -accessKey $accessKey -sortProperty "name"
#>
function Get-AllGroups
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "bloodline",
        [string] $sortProperty
    )
    
    $baseUri = Get-BaseUri

    $location = @{}
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/groups" `
                         -location $location -fields "fields=id,name,description,location" `
                         -locationStrategy $locationStrategy -sort $sortProperty

    return Get-AllItems -accessKey $accessKey -uri $uri
}

Export-ModuleMember Get-AllUsers
Export-ModuleMember Get-User
Export-ModuleMember Get-AllGroups
