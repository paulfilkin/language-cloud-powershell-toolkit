<#
.SYNOPSIS
Retrieves an access key for accessing resources.

.DESCRIPTION
The `Get-AccessKey` function sends a request to the specified authentication endpoint to retrieve an access key 
(also known as a bearer token) that is required to access other resources. This function returns a PowerShell 
object containing the bearer token and tenant information, which can be used in subsequent API requests.

.PARAMETER id
The client ID required for authentication. This is typically provided by your authentication service.

.PARAMETER secret
The client secret corresponding to the client ID. This is used to authenticate and authorize the client.

.PARAMETER lcTenant
The tenant identifier for your organization or resource group. This value is returned as part of the access key object.

.EXAMPLE
$accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
This example retrieves an access key using the provided client ID, secret, and tenant identifier, and stores it in the `$accessKey` variable.

.OUTPUTS
PSObject
Returns a PowerShell object with the following properties:
- `token`: The bearer token string used for authorization in subsequent API calls.
- `tenant`: The tenant identifier passed as a parameter to the function.

.NOTES
The function uses the `Invoke-RestMethod` cmdlet to send a POST request to the specified authentication endpoint. 
In case of any errors during the request, the function will catch the exception and output the error message to the console.

#>
function Get-AccessKey
{
    param (
        [String] $id, 
        [String] $secret,
        [String] $lcTenant
    )


    $uri = "https://sdl-prod.eu.auth0.com/oauth/token"

    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }

    $body = @{
        'client_id' = $id 
        'client_secret' = $secret
        'audience' = "https://api.sdl.com"
        'grant_type' = "client_credentials"
    }
    $json = $body | ConvertTo-Json

    try
    {
        $response = Invoke-RestMethod -Headers $headers -Uri $uri -Body $json -method Post
        $accessKey = @{
            "token" = "Bearer $($response.access_token)"
            "tenant" = $lcTenant
        }

        return $accessKey;
    }
    catch 
    {
        Write-host "$_"
    }
}

Export-ModuleMember Get-AccessKey;