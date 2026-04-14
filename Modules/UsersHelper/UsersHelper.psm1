Import-Module -Name CommonHelper

#region Users - Read

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

#endregion

#region Users - Create

<#
.SYNOPSIS
Creates a new human user and sends an invitation.

.DESCRIPTION
The `New-User` function creates a new human (non-service) user in the system. The user will receive an 
invitation email unless `sendInvitationEmail` is set to $false. You can optionally assign the user to 
one or more groups and specify a custom invitation message.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER email
(Mandatory) The email address for the new user.

.PARAMETER firstName
(Mandatory) The first name of the new user.

.PARAMETER lastName
(Mandatory) The last name of the new user.

.PARAMETER locationId
(Optional) The ID of the location to assign the user to. Either locationId or locationName should be provided.

.PARAMETER locationName
(Optional) The name of the location to assign the user to. Either locationId or locationName should be provided.

.PARAMETER membership
(Optional) The membership level for the user. Default is "member".

.PARAMETER groupIds
(Optional) An array of group IDs to assign the user to.

.PARAMETER sendInvitationEmail
(Optional) Whether to send an invitation email to the user. Default is $true.

.PARAMETER invitationMessage
(Optional) A custom message to include in the invitation email.

.PARAMETER inviteInCustomerPortal
(Optional) Whether to invite the user in the customer portal. Default is $false.

.PARAMETER metadata
(Optional) A hashtable of additional metadata to attach to the user.

.EXAMPLE
    # Example 1: Create a new user with default settings
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-User -accessKey $accessKey -email "jane.doe@example.com" -firstName "Jane" -lastName "Doe" -locationId "12345"

.EXAMPLE
    # Example 2: Create a new user assigned to groups with a custom invitation message
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-User -accessKey $accessKey -email "john.smith@example.com" -firstName "John" -lastName "Smith" `
        -locationName "FolderA" -groupIds @("group-id-1", "group-id-2") `
        -invitationMessage "Welcome to the team!"

.EXAMPLE
    # Example 3: Create a user without sending an invitation email
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-User -accessKey $accessKey -email "test@example.com" -firstName "Test" -lastName "User" `
        -locationId "12345" -sendInvitationEmail $false
#>
function New-User
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $email,

        [Parameter(Mandatory=$true)]
        [string] $firstName,

        [Parameter(Mandatory=$true)]
        [string] $lastName,

        [string] $locationId,
        [string] $locationName,
        [string] $membership = "member",
        [string[]] $groupIds,
        [bool] $sendInvitationEmail = $true,
        [string] $invitationMessage,
        [bool] $inviteInCustomerPortal = $false,
        [hashtable] $metadata
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/users"
    $headers = Get-RequestHeader -accessKey $accessKey

    # Resolve location
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
        if ($null -eq $location)
        {
            return
        }
    }

    # Build userDetails
    $userDetails = [ordered]@{
        email                  = $email
        firstName              = $firstName
        lastName               = $lastName
        membership             = $membership
        sendInvitationEmail    = $sendInvitationEmail
        inviteInCustomerPortal = $inviteInCustomerPortal
    }

    if ($invitationMessage)
    {
        $userDetails.invitationMessage = $invitationMessage
    }

    # Build request body
    $body = [ordered]@{
        userDetails = $userDetails
    }

    if ($location)
    {
        $body.location = $location.Id
    }

    if ($groupIds)
    {
        $body.groups = @($groupIds | ForEach-Object { @{ id = $_ } })
    }

    if ($metadata)
    {
        $body.metadata = $metadata
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
}

<#
.SYNOPSIS
Creates a new service user.

.DESCRIPTION
The `New-ServiceUser` function creates a new service (non-human) user in the system. Service users are 
used for API integrations and automated processes. They require a name and optionally a description.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER name
(Mandatory) The display name for the service user.

.PARAMETER description
(Optional) A description of the service user's purpose.

.PARAMETER locationId
(Optional) The ID of the location to assign the service user to. Either locationId or locationName should be provided.

.PARAMETER locationName
(Optional) The name of the location to assign the service user to. Either locationId or locationName should be provided.

.PARAMETER groupIds
(Optional) An array of group IDs to assign the service user to.

.PARAMETER metadata
(Optional) A hashtable of additional metadata to attach to the service user.

.EXAMPLE
    # Example 1: Create a service user with a location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-ServiceUser -accessKey $accessKey -name "CI Pipeline" -description "Automated build integration" -locationId "12345"

.EXAMPLE
    # Example 2: Create a service user assigned to groups
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-ServiceUser -accessKey $accessKey -name "Import Bot" -locationName "FolderA" -groupIds @("group-id-1")
#>
function New-ServiceUser
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [string] $description,
        [string] $locationId,
        [string] $locationName,
        [string[]] $groupIds,
        [hashtable] $metadata
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/users"
    $headers = Get-RequestHeader -accessKey $accessKey

    # Resolve location
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
        if ($null -eq $location)
        {
            return
        }
    }

    # Build serviceUserDetails
    $serviceUserDetails = [ordered]@{
        name = $name
    }

    if ($description)
    {
        $serviceUserDetails.description = $description
    }

    # Build request body
    $body = [ordered]@{
        serviceUserDetails = $serviceUserDetails
    }

    if ($location)
    {
        $body.location = $location.Id
    }

    if ($groupIds)
    {
        $body.groups = @($groupIds | ForEach-Object { @{ id = $_ } })
    }

    if ($metadata)
    {
        $body.metadata = $metadata
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
}

#endregion

#region Users - Update / Remove

<#
.SYNOPSIS
Updates an existing user's details.

.DESCRIPTION
The `Update-User` function modifies the properties of a specified user. You can update the name, 
description, first name, last name, group memberships, and metadata. The user is identified by 
their user ID or by email lookup.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER userId
(Optional) The ID of the user to update. Either userId or userEmail must be provided.

.PARAMETER userEmail
(Optional) The email of the user to update. Either userId or userEmail must be provided.

.PARAMETER name
(Optional) The updated display name for the user (applicable to service users).

.PARAMETER description
(Optional) The updated description for the user (applicable to service users).

.PARAMETER firstName
(Optional) The updated first name (applicable to human users).

.PARAMETER lastName
(Optional) The updated last name (applicable to human users).

.PARAMETER groupIds
(Optional) An array of group IDs to assign to the user. This replaces the current group assignments.

.PARAMETER metadata
(Optional) A hashtable of additional metadata to attach to the user.

.EXAMPLE
    # Example 1: Update a user's name by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-User -accessKey $accessKey -userId "12345" -firstName "Jane" -lastName "Smith"

.EXAMPLE
    # Example 2: Update a service user's description and group membership
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-User -accessKey $accessKey -userId "67890" -name "Updated Bot" -description "New purpose" `
        -groupIds @("group-id-1", "group-id-2")

.EXAMPLE
    # Example 3: Update a user found by email
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-User -accessKey $accessKey -userEmail "jane@example.com" -lastName "Doe-Smith"
#>
function Update-User
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $userId,
        [string] $userEmail,

        [string] $name,
        [string] $description,
        [string] $firstName,
        [string] $lastName,
        [string[]] $groupIds,
        [hashtable] $metadata
    )

    # Resolve user
    $user = Get-User -accessKey $accessKey -userId $userId -userEmail $userEmail
    if ($null -eq $user)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/users/$($user.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{}

    if ($name)        { $body.name = $name }
    if ($description) { $body.description = $description }
    if ($firstName)   { $body.firstName = $firstName }
    if ($lastName)    { $body.lastName = $lastName }

    if ($groupIds)
    {
        $body.groups = @($groupIds | ForEach-Object { @{ id = $_ } })
    }

    if ($metadata)
    {
        $body.metadata = $metadata
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
}

<#
.SYNOPSIS
Removes a user from the system.

.DESCRIPTION
The `Remove-User` function deletes a specified user. The user can be identified by their user ID 
or by email lookup.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER userId
(Optional) The ID of the user to remove. Either userId or userEmail must be provided.

.PARAMETER userEmail
(Optional) The email of the user to remove. Either userId or userEmail must be provided.

.EXAMPLE
    # Example 1: Remove a user by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-User -accessKey $accessKey -userId "12345"

.EXAMPLE
    # Example 2: Remove a user by email
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-User -accessKey $accessKey -userEmail "user@example.com"
#>
function Remove-User
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $userId,
        [string] $userEmail
    )

    $user = Get-User -accessKey $accessKey -userId $userId -userEmail $userEmail
    if ($null -eq $user)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/users/$($user.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    Invoke-SafeMethod -method {
        $null = Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri
        Write-Host "User removed" -ForegroundColor Green
    }
}

#endregion

#region Groups - Read

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

<#
.SYNOPSIS
Retrieves a specific group by ID or name.

.DESCRIPTION
The `Get-Group` function retrieves the details of a specific group. If a group ID is provided, it is 
fetched directly via GET /groups/{groupId}. If a name is provided, all groups are listed and filtered locally.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER groupId
(Optional) The ID of the group to retrieve. Either groupId or groupName must be provided.

.PARAMETER groupName
(Optional) The name of the group to retrieve. Either groupId or groupName must be provided.

.EXAMPLE
    # Example 1: Retrieve a group by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Group -accessKey $accessKey -groupId "group-12345"

.EXAMPLE
    # Example 2: Retrieve a group by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Group -accessKey $accessKey -groupName "Translators"
#>
function Get-Group
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $groupId,
        [string] $groupName
    )

    $baseUri = Get-BaseUri

    return Get-SingleItem -accessKey $accessKey -uri "$baseUri/groups" `
                    -id $groupId -name $groupName -propertyName "Group"
}

#endregion

#region Groups - Create / Update / Remove

<#
.SYNOPSIS
Creates a new group.

.DESCRIPTION
The `New-Group` function creates a new group in the system. You can assign roles, additional 
location-scoped roles, and users at creation time.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER name
(Mandatory) The name of the group.

.PARAMETER description
(Optional) A description of the group.

.PARAMETER locationId
(Optional) The ID of the location to assign the group to. Either locationId or locationName should be provided.

.PARAMETER locationName
(Optional) The name of the location to assign the group to. Either locationId or locationName should be provided.

.PARAMETER roleIds
(Optional) An array of role IDs to assign to the group at its home location.

.PARAMETER additionalRoles
(Optional) An array of hashtables, each with a 'location' key (location ID string) and a 'roles' key 
(array of role ID strings), for assigning roles at additional locations.

.PARAMETER userIds
(Optional) An array of user IDs to add as members of the group.

.PARAMETER metadata
(Optional) A hashtable of additional metadata to attach to the group.

.EXAMPLE
    # Example 1: Create a simple group
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Group -accessKey $accessKey -name "Translators" -description "Translation team" -locationId "12345"

.EXAMPLE
    # Example 2: Create a group with roles and users
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Group -accessKey $accessKey -name "Reviewers" -locationName "FolderA" `
        -roleIds @("role-id-1", "role-id-2") -userIds @("user-id-1", "user-id-2")

.EXAMPLE
    # Example 3: Create a group with additional location-scoped roles
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $extraRoles = @(
        @{ location = "location-id-2"; roles = @("role-id-3") }
    )
    New-Group -accessKey $accessKey -name "Multi-location Team" -locationId "12345" `
        -roleIds @("role-id-1") -additionalRoles $extraRoles
#>
function New-Group
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [string] $description,
        [string] $locationId,
        [string] $locationName,
        [string[]] $roleIds,
        [hashtable[]] $additionalRoles,
        [string[]] $userIds,
        [hashtable] $metadata
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/groups"
    $headers = Get-RequestHeader -accessKey $accessKey

    # Resolve location
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
        if ($null -eq $location)
        {
            return
        }
    }

    $body = [ordered]@{
        name = $name
    }

    if ($description) { $body.description = $description }

    if ($location)
    {
        $body.location = $location.Id
    }

    if ($roleIds)
    {
        $body.roles = @($roleIds)
    }

    if ($additionalRoles)
    {
        $body.additionalRoles = @($additionalRoles)
    }

    if ($userIds)
    {
        $body.users = @($userIds)
    }

    if ($metadata)
    {
        $body.metadata = $metadata
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
}

<#
.SYNOPSIS
Updates an existing group.

.DESCRIPTION
The `Update-Group` function modifies the properties of a specified group. You can update the name, 
description, role assignments, additional location-scoped roles, user memberships, and metadata.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER groupId
(Optional) The ID of the group to update. Either groupId or groupName must be provided.

.PARAMETER groupName
(Optional) The name of the group to update. Either groupId or groupName must be provided.

.PARAMETER name
(Optional) The updated name for the group.

.PARAMETER description
(Optional) The updated description for the group.

.PARAMETER roleIds
(Optional) An array of role IDs to assign to the group. This replaces the current role assignments.

.PARAMETER additionalRoles
(Optional) An array of hashtables, each with a 'location' key (location ID string) and a 'roles' key 
(array of role ID strings). This replaces the current additional role assignments.

.PARAMETER userIds
(Optional) An array of user IDs to set as members of the group. This replaces the current membership.

.PARAMETER metadata
(Optional) A hashtable of additional metadata to attach to the group.

.EXAMPLE
    # Example 1: Update a group's description
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Group -accessKey $accessKey -groupId "group-12345" -description "Updated description"

.EXAMPLE
    # Example 2: Update group membership and roles
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Group -accessKey $accessKey -groupName "Translators" `
        -roleIds @("role-id-1") -userIds @("user-id-1", "user-id-2", "user-id-3")
#>
function Update-Group
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $groupId,
        [string] $groupName,

        [string] $name,
        [string] $description,
        [string[]] $roleIds,
        [hashtable[]] $additionalRoles,
        [string[]] $userIds,
        [hashtable] $metadata
    )

    $group = Get-Group -accessKey $accessKey -groupId $groupId -groupName $groupName
    if ($null -eq $group)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/groups/$($group.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{}

    if ($name)        { $body.name = $name }
    if ($description) { $body.description = $description }

    if ($roleIds)
    {
        $body.roles = @($roleIds)
    }

    if ($additionalRoles)
    {
        $body.additionalRoles = @($additionalRoles)
    }

    if ($userIds)
    {
        $body.users = @($userIds)
    }

    if ($metadata)
    {
        $body.metadata = $metadata
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
}

<#
.SYNOPSIS
Removes a group from the system.

.DESCRIPTION
The `Remove-Group` function deletes a specified group. The group can be identified by its ID or name.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER groupId
(Optional) The ID of the group to remove. Either groupId or groupName must be provided.

.PARAMETER groupName
(Optional) The name of the group to remove. Either groupId or groupName must be provided.

.EXAMPLE
    # Example 1: Remove a group by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Group -accessKey $accessKey -groupId "group-12345"

.EXAMPLE
    # Example 2: Remove a group by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Group -accessKey $accessKey -groupName "Old Team"
#>
function Remove-Group
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $groupId,
        [string] $groupName
    )

    $group = Get-Group -accessKey $accessKey -groupId $groupId -groupName $groupName
    if ($null -eq $group)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/groups/$($group.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    Invoke-SafeMethod -method {
        $null = Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri
        Write-Host "Group removed" -ForegroundColor Green
    }
}

#endregion

#region Roles - Read

<#
.SYNOPSIS
Retrieves all roles available in the system.

.DESCRIPTION
The `Get-AllRoles` function fetches a paginated list of all roles from the API, including their IDs, 
names, descriptions, types, and permissions. This is useful for discovering available role IDs when 
creating or updating groups.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllRoles -accessKey $accessKey
#>
function Get-AllRoles
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/roles"

    return Get-AllItems -accessKey $accessKey -uri $uri
}

<#
.SYNOPSIS
Retrieves a specific role by ID or name.

.DESCRIPTION
The `Get-Role` function retrieves the details of a specific role, including its permissions. If a role 
ID is provided, it is fetched directly. If a name is provided, all roles are listed and filtered locally.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER roleId
(Optional) The ID of the role to retrieve. Either roleId or roleName must be provided.

.PARAMETER roleName
(Optional) The name of the role to retrieve. Either roleId or roleName must be provided.

.EXAMPLE
    # Example 1: Retrieve a role by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Role -accessKey $accessKey -roleId "role-12345"

.EXAMPLE
    # Example 2: Retrieve a role by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Role -accessKey $accessKey -roleName "Project Manager"
#>
function Get-Role
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $roleId,
        [string] $roleName
    )

    $baseUri = Get-BaseUri

    return Get-SingleItem -accessKey $accessKey -uri "$baseUri/roles" `
                    -id $roleId -name $roleName -propertyName "Role"
}

#endregion

#region Roles - Create / Update / Remove

<#
.SYNOPSIS
Creates a new custom role.

.DESCRIPTION
The `New-Role` function creates a new custom role in the system with the specified permissions. Use 
`Get-AllPermissions` to discover available permission names.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER name
(Mandatory) The name of the role.

.PARAMETER description
(Optional) A description of the role.

.PARAMETER permissions
(Mandatory) An array of permission name strings to assign to the role (e.g. "projectCreate", "projectRead").

.EXAMPLE
    # Example 1: Create a role with specific permissions
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Role -accessKey $accessKey -name "Reviewer" -description "Can read and review projects" `
        -permissions @("projectRead", "taskRead", "taskUpdate")

.EXAMPLE
    # Example 2: Create a minimal role
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Role -accessKey $accessKey -name "Read Only" -permissions @("projectRead")
#>
function New-Role
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [string] $description,

        [Parameter(Mandatory=$true)]
        [string[]] $permissions
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/roles"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{
        name        = $name
        permissions = @($permissions)
    }

    if ($description)
    {
        $body.description = $description
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
}

<#
.SYNOPSIS
Updates an existing custom role.

.DESCRIPTION
The `Update-Role` function modifies the properties of a specified custom role. You can update the name, 
description, and permission assignments.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER roleId
(Optional) The ID of the role to update. Either roleId or roleName must be provided.

.PARAMETER roleName
(Optional) The name of the role to update. Either roleId or roleName must be provided.

.PARAMETER name
(Optional) The updated name for the role.

.PARAMETER description
(Optional) The updated description for the role.

.PARAMETER permissions
(Optional) An array of permission name strings. This replaces the current permission assignments.

.EXAMPLE
    # Example 1: Update a role's permissions
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Role -accessKey $accessKey -roleId "role-12345" `
        -permissions @("projectRead", "projectCreate", "taskRead", "taskUpdate")

.EXAMPLE
    # Example 2: Rename a role
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Role -accessKey $accessKey -roleName "Reviewer" -name "Senior Reviewer" `
        -description "Extended review permissions"
#>
function Update-Role
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $roleId,
        [string] $roleName,

        [string] $name,
        [string] $description,
        [string[]] $permissions
    )

    $role = Get-Role -accessKey $accessKey -roleId $roleId -roleName $roleName
    if ($null -eq $role)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/roles/$($role.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{}

    if ($name)        { $body.name = $name }
    if ($description) { $body.description = $description }

    if ($permissions)
    {
        $body.permissions = @($permissions)
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
}

<#
.SYNOPSIS
Removes a custom role from the system.

.DESCRIPTION
The `Remove-Role` function deletes a specified custom role. The role can be identified by its ID or name.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER roleId
(Optional) The ID of the role to remove. Either roleId or roleName must be provided.

.PARAMETER roleName
(Optional) The name of the role to remove. Either roleId or roleName must be provided.

.EXAMPLE
    # Example 1: Remove a role by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Role -accessKey $accessKey -roleId "role-12345"

.EXAMPLE
    # Example 2: Remove a role by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Role -accessKey $accessKey -roleName "Deprecated Role"
#>
function Remove-Role
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $roleId,
        [string] $roleName
    )

    $role = Get-Role -accessKey $accessKey -roleId $roleId -roleName $roleName
    if ($null -eq $role)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/roles/$($role.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    Invoke-SafeMethod -method {
        $null = Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri
        Write-Host "Role removed" -ForegroundColor Green
    }
}

#endregion

#region Permissions - Read

<#
.SYNOPSIS
Retrieves all available permissions in the system.

.DESCRIPTION
The `Get-AllPermissions` function fetches a paginated list of all permissions from the API. Each 
permission includes its name, description, category, entity type, and dependencies. This is useful 
for discovering valid permission names when creating or updating custom roles.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllPermissions -accessKey $accessKey
#>
function Get-AllPermissions
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/permissions"

    return Get-AllItems -accessKey $accessKey -uri $uri
}

#endregion

#region Applications - Read

<#
.SYNOPSIS
Retrieves all applications available in the system.

.DESCRIPTION
The `Get-AllApplications` function fetches a paginated list of all applications (integrations) from the API.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.EXAMPLE
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllApplications -accessKey $accessKey
#>
function Get-AllApplications
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/applications"

    return Get-AllItems -accessKey $accessKey -uri $uri
}

<#
.SYNOPSIS
Retrieves a specific application by ID or name.

.DESCRIPTION
The `Get-Application` function retrieves the details of a specific application. If an application ID is 
provided, it is fetched directly. If a name is provided, all applications are listed and filtered locally.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER applicationId
(Optional) The ID of the application to retrieve. Either applicationId or applicationName must be provided.

.PARAMETER applicationName
(Optional) The name of the application to retrieve. Either applicationId or applicationName must be provided.

.EXAMPLE
    # Example 1: Retrieve an application by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Application -accessKey $accessKey -applicationId "app-12345"

.EXAMPLE
    # Example 2: Retrieve an application by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Application -accessKey $accessKey -applicationName "My Integration"
#>
function Get-Application
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $applicationId,
        [string] $applicationName
    )

    $baseUri = Get-BaseUri

    return Get-SingleItem -accessKey $accessKey -uri "$baseUri/applications" `
                    -id $applicationId -name $applicationName -propertyName "Application"
}

#endregion

#region Applications - Create / Update / Remove

<#
.SYNOPSIS
Creates a new application (integration).

.DESCRIPTION
The `New-Application` function creates a new application in the system. An application wraps a service 
user and optionally enables API access, which generates client credentials (client ID and secret).

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER name
(Mandatory) The name of the application.

.PARAMETER description
(Optional) A description of the application.

.PARAMETER enableApiAccess
(Optional) Whether to enable API access for this application. Default is $true.

.PARAMETER serviceUserId
(Optional) The ID of an existing service user to associate with the application. If not provided, 
the API may create one automatically depending on tenant configuration.

.EXAMPLE
    # Example 1: Create an application with API access enabled
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Application -accessKey $accessKey -name "CI Pipeline" -description "Build automation"

.EXAMPLE
    # Example 2: Create an application linked to an existing service user
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Application -accessKey $accessKey -name "Import Tool" -serviceUserId "service-user-id-123"
#>
function New-Application
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [string] $description,
        [bool] $enableApiAccess = $true,
        [string] $serviceUserId
    )

    $baseUri = Get-BaseUri
    $uri = "$baseUri/applications"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{
        name            = $name
        enableApiAccess = $enableApiAccess
    }

    if ($description)
    {
        $body.description = $description
    }

    if ($serviceUserId)
    {
        $body.serviceUserId = $serviceUserId
    }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
}

<#
.SYNOPSIS
Updates an existing application.

.DESCRIPTION
The `Update-Application` function modifies the properties of a specified application. You can update 
the name, description, API access setting, associated service user, and optionally regenerate the 
client secret.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER applicationId
(Optional) The ID of the application to update. Either applicationId or applicationName must be provided.

.PARAMETER applicationName
(Optional) The name of the application to update. Either applicationId or applicationName must be provided.

.PARAMETER name
(Optional) The updated name for the application.

.PARAMETER description
(Optional) The updated description for the application.

.PARAMETER enableApiAccess
(Optional) Whether to enable or disable API access.

.PARAMETER serviceUserId
(Optional) The ID of a service user to associate with the application.

.PARAMETER regenerateSecret
(Optional) Whether to regenerate the client secret. Default is $false.

.EXAMPLE
    # Example 1: Update an application's description
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Application -accessKey $accessKey -applicationId "app-12345" -description "Updated description"

.EXAMPLE
    # Example 2: Regenerate the client secret for an application
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Application -accessKey $accessKey -applicationName "CI Pipeline" -regenerateSecret $true

.EXAMPLE
    # Example 3: Disable API access for an application
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Application -accessKey $accessKey -applicationId "app-12345" -enableApiAccess $false
#>
function Update-Application
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $applicationId,
        [string] $applicationName,

        [string] $name,
        [string] $description,
        [System.Nullable[bool]] $enableApiAccess,
        [string] $serviceUserId,
        [bool] $regenerateSecret = $false
    )

    $application = Get-Application -accessKey $accessKey -applicationId $applicationId -applicationName $applicationName
    if ($null -eq $application)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/applications/$($application.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    $body = [ordered]@{}

    if ($name)             { $body.name = $name }
    if ($description)      { $body.description = $description }
    if ($null -ne $enableApiAccess) { $body.enableApiAccess = $enableApiAccess }
    if ($serviceUserId)    { $body.serviceUserId = $serviceUserId }
    if ($regenerateSecret) { $body.regenerateSecret = $regenerateSecret }

    $json = $body | ConvertTo-Json -Depth 5
    return Invoke-SafeMethod { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
}

<#
.SYNOPSIS
Removes an application from the system.

.DESCRIPTION
The `Remove-Application` function deletes a specified application. The application can be identified 
by its ID or name.

.PARAMETER accessKey
(Mandatory) The access key object returned by the `Get-AccessKey` function.

.PARAMETER applicationId
(Optional) The ID of the application to remove. Either applicationId or applicationName must be provided.

.PARAMETER applicationName
(Optional) The name of the application to remove. Either applicationId or applicationName must be provided.

.EXAMPLE
    # Example 1: Remove an application by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Application -accessKey $accessKey -applicationId "app-12345"

.EXAMPLE
    # Example 2: Remove an application by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Application -accessKey $accessKey -applicationName "Old Integration"
#>
function Remove-Application
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $applicationId,
        [string] $applicationName
    )

    $application = Get-Application -accessKey $accessKey -applicationId $applicationId -applicationName $applicationName
    if ($null -eq $application)
    {
        return
    }

    $baseUri = Get-BaseUri
    $uri = "$baseUri/applications/$($application.Id)"
    $headers = Get-RequestHeader -accessKey $accessKey

    Invoke-SafeMethod -method {
        $null = Invoke-RestMethod -Headers $headers -Method Delete -Uri $uri
        Write-Host "Application removed" -ForegroundColor Green
    }
}

#endregion

#region Exports

Export-ModuleMember Get-AllUsers
Export-ModuleMember Get-User
Export-ModuleMember New-User
Export-ModuleMember New-ServiceUser
Export-ModuleMember Update-User
Export-ModuleMember Remove-User
Export-ModuleMember Get-AllGroups
Export-ModuleMember Get-Group
Export-ModuleMember New-Group
Export-ModuleMember Update-Group
Export-ModuleMember Remove-Group
Export-ModuleMember Get-AllRoles
Export-ModuleMember Get-Role
Export-ModuleMember New-Role
Export-ModuleMember Update-Role
Export-ModuleMember Remove-Role
Export-ModuleMember Get-AllPermissions
Export-ModuleMember Get-AllApplications
Export-ModuleMember Get-Application
Export-ModuleMember New-Application
Export-ModuleMember Update-Application
Export-ModuleMember Remove-Application

#endregion
