<#
.SYNOPSIS
Retrieves an access key for accessing resources.

.DESCRIPTION
The `Get-AccessKey` function sends a request to the specified authentication endpoint to retrieve an access key 
(also known as a bearer token) that is required to access other resources. This function returns a PowerShell 
object containing the bearer token and tenant information, which can be used in subsequent API requests.

Optionally, you can provide a custom API base URI via the `baseUri` parameter. If not provided, the toolkit 
defaults to "https://lc-api.sdl.com/public-api/v1". The recommended URI for new integrations is 
"https://api.eu.cloud.trados.com/public-api/v1".

.PARAMETER id
The client ID required for authentication. This is typically provided by your authentication service.

.PARAMETER secret
The client secret corresponding to the client ID. This is used to authenticate and authorise the client.

.PARAMETER lcTenant
The tenant identifier for your organisation or resource group. This value is returned as part of the access key object.

.PARAMETER baseUri
(Optional) The base URI for the Language Cloud API. Defaults to "https://lc-api.sdl.com/public-api/v1".
Use "https://api.eu.cloud.trados.com/public-api/v1" for the new recommended endpoint.

.EXAMPLE
$accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
This example retrieves an access key using the default API endpoint.

.EXAMPLE
$accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant" -baseUri "https://api.eu.cloud.trados.com/public-api/v1"
This example retrieves an access key and configures the toolkit to use the new API endpoint.

.OUTPUTS
PSObject
Returns a PowerShell object with the following properties:
- `token`: The bearer token string used for authorisation in subsequent API calls.
- `tenant`: The tenant identifier passed as a parameter to the function.

.NOTES
The function uses the `Invoke-RestMethod` cmdlet to send a POST request to the specified authentication endpoint. 
In case of any errors during the request, the function will catch the exception and output the error message to the console.

If a `baseUri` is provided, it is applied to the CommonHelper module via Set-BaseUri so that all subsequent 
API calls in the session use the specified endpoint.
#>
function Get-AccessKey
{
    param (
        [String] $id, 
        [String] $secret,
        [String] $lcTenant,
        [String] $baseUri
    )

    # If a custom base URI was provided, apply it to the shared CommonHelper module
    if ($baseUri)
    {
        Set-BaseUri -uri $baseUri
    }

    # Cache the token in the system temp folder (not the module directory)
    $tokenFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "lc-toolkit-accessToken.json"

    # Check if JSON file exists
    if (Test-Path $tokenFile) {
        # Read the JSON file
        $tokenData = Get-Content $tokenFile | ConvertFrom-Json
        
        # Check if the token data and expiration are valid
        if ($tokenData `
                -and $tokenData.tenant -eq $lcTenant `
                -and $tokenData.client_id -eq $id `
                -and $tokenData.expires_at) {
            $currentTime = Get-Date
            $tokenExpiration = [datetime]::Parse($tokenData.expires_at, [System.Globalization.CultureInfo]::InvariantCulture)

            # If token is valid, return it
            if ($currentTime -lt $tokenExpiration) {
                return @{
                    "token" = $tokenData.token
                    "tenant" = $tokenData.tenant
                }
            }
        }
    }

    # If JSON doesn't exist or token is expired, request a new token
    $uri = "https://sdl-prod.eu.auth0.com/oauth/token"
    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    $body = @{
        'client_id'     = $id 
        'client_secret' = $secret
        'audience'      = "https://api.sdl.com"
        'grant_type'    = "client_credentials"
    }

    $json = $body | ConvertTo-Json

    try
    {
        $response = Invoke-RestMethod -Headers $headers -Uri $uri -Body $json -Method Post

        if ($response -and $response.access_token -and $response.expires_in) {

            $expiresInSeconds = $response.expires_in
            $expirationTime = (Get-Date).AddSeconds($expiresInSeconds)

            $accessKeyData = @{
                "token"      = "Bearer $($response.access_token)"
                "tenant"     = $lcTenant
                "client_id"  = $id
                "expires_at" = $expirationTime.ToString("yyyy-MM-ddTHH:mm:ss")
            }

            # Write the token data to the temp folder
            $accessKeyData | ConvertTo-Json | Set-Content -Path $tokenFile

            return @{
                "token" = $accessKeyData.token
                "tenant" = $accessKeyData.tenant
            }
        }
        else {
            Write-Host "Error: Received invalid token response."
        }
    }
    catch 
    {
        Write-Host "Error retrieving token: $_"
    }
}

Export-ModuleMember Get-AccessKey