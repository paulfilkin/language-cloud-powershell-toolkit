$baseUri = "https://lc-api.sdl.com/public-api/v1"

function Get-AllTermbases 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/termbases" `
            -location $location -fields "fields=id,name,description,copyright,location,termbaseStructure" `
            -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-Termbase 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseId,
        [string] $termbaseName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/termbases" `
                         -uriQuery "?fields=id,name,description,copyright,location,termbaseStructure" `
                         -id $termbaseId -name $termbaseName -propertyName "Termbase"
}

function New-Termbase 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [string] $locationId,
        [string] $locationName, #mandatory apparently

        [Parameter(Mandatory=$true)]
        [string[]] $languageCodes,

        [string] $description,
        [string] $copyRight
    )

    $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    if ($null -eq $location)
    {
        return;
    }

    $uri = "$baseUri/termbases"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        name = $name
        location = $location.Id 
        description = $description
        copyright = $copyRight
        termbaseStructure = [ordered]@{
            languages = @($languageCodes)
        }
    }

    $json = $body | ConvertTo-Json -Depth 3
    return Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json;
}

function Remove-Termbase 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseId,
        [string] $termbaseName
    )

    $termbase = Get-Termbase -accessKey $accessKey -termbaseId $termbaseId -termbaseName $termbaseName; 

    if ($termbase)
    {
        $uri = "$baseUri/termbases/$($termbase.Id)";
        $headers = Get-RequestHeader -accessKey $accessKey;
        Invoke-SafeMethod {
            $null = Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete;
            Write-Host "Termbase removed" -ForegroundColor Green;
        }
    }
}

function Get-AllTermbaseTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey, 

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/termbase-templates" `
            -location $location -fields "fields=id,name,description,copyright,location,type,languages,fields" `
            -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

function Get-TermbaseTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseTemplateId,
        [string] $termbaseTemplateName
    )

    return Get-Item -accessKey $accessKey -uri "$baseUri/termbase-templates" `
            -uriQuery "?fields=id,name,description,copyright,location,type,languages,fields" `
            -id $termbaseTemplateId -name $termbaseTemplateName -propertyName "Termbase template"
}

function Remove-TermbaseTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseTemplateId,
        [string] $termbaseTemplateName
    )

    $termbaseTemplate = Get-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId $termbaseTemplateId -termbaseTemplateName $termbaseTemplateName;

    if ($termbaseTemplate)
    {
        $uri = "$baseUri/termbase-templates/$($termbaseTemplate.Id)";
        $headers = Get-RequestHeader -accessKey $accessKey
        Invoke-SafeMethod {
            $null = Invoke-RestMethod -Uri $uri -Headers $headers -method Delete;
            Write-Host "Termbase template removed" -ForegroundColor Green;
        }
    }
}

function Get-Item 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [String] $uri,

        [String] $uriQuery,
        [String] $id,
        [string] $name,
        [string] $propertyName
    )

    if ($id)
    {
        $uri += "/$id/$uriQuery"
        $headers = Get-RequestHeader -accessKey $accessKey;

        $item = Invoke-SafeMethod { Invoke-RestMethod -uri $uri -Headers $headers }
    }
    elseif ($name)
    {
        $items = Get-AllItems -accessKey $accessKey -uri $($uri + $uriQuery);
        if ($items)
        {
            $item = $items | Where-Object {$_.Name -eq $name } | Select-Object -First 1;
        }

        if ($null -eq $item)
        {
            Write-Host "$propertyName could not be found" -ForegroundColor Green;
        }
    }

    if ($item)
    {
        return $item;
    }
}

function Get-AllItems
{
    param (
        [psobject] $accessKey,
        [String] $uri)

    $headers = Get-RequestHeader -accessKey $accessKey;

    $response = Invoke-SafeMethod { Invoke-RestMethod -uri $uri -Headers $headers}
    if ($response)
    {
        return $response.Items;
    }
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

Export-ModuleMember Get-AllTermbases;
Export-ModuleMember Get-Termbase;
Export-ModuleMember New-Termbase;
Export-ModuleMember Remove-Termbase;
Export-ModuleMember Get-AllTermbaseTemplates;
Export-ModuleMember Get-TermbaseTemplate;
Export-ModuleMember Remove-TermbaseTemplate;