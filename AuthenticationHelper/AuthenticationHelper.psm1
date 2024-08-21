

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