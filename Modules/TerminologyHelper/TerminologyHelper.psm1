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
        [string] $locationName,

        [string[]] $languageCodes,
        [psobject[]] $fields,

        [string] $termbaseTemplateId,
        [string] $termbaseTemplateName,
        [string] $pathToXDT,
        
        [bool] $inheritLanguages = $true,
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
        termbaseStructure = @{
            languages = @()
        }
    }

    $fieldDefinitions = @();

    if ($termbaseTemplateId -or $termbaseTemplateName)
    {
        $termbaseTemplate = Get-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId $termbaseTemplateId -termbaseTemplateName $termbaseTemplateName;
        if ($null -eq $termbaseTemplate)
        {
            return;
        }

        if ($inheritLanguages)
        {
            $languageCodes += $termbaseTemplate.languages | ForEach-Object {$_.languageCode}
        }

        $languageCodes = $languageCodes | Select-Object -Unique;
        $body.termbaseStructure.languages = @($languageCodes | ForEach-Object { @{languageCode = $_} });
        $fieldDefinitions += Format-Fields -fields $termbaseTemplate.Fields;
    }
    elseif ($pathToXDT)
    {
        $xdt = ConvertTo-TermbaseStructure -accessKey $accessKey -pathToXDT $pathToXDT;
        if ($null -eq $xdt)
        {
            return;
        }

        if ($inheritLanguages)
        {
            $languageCodes += $xdt.languages | ForEach-Object {$_.languageCode };
        }

        $languageCodes = $languageCodes | Select-Object -Unique;
        $body.termbaseStructure.languages = @($languageCodes | ForEach-Object { @{languageCode = $_} })
        $fieldDefinitions += Format-Fields -fields $($xdt.Fields)
    }
    else 
    {
        $body.termbaseStructure.languages = @($languageCodes | ForEach-Object { @{languageCode = $_} })
    }

    if ($fields)
    {
        $fieldDefinitions += Format-Fields -fields $fields;
    }

    if ($fieldDefinitions)
    {
        $body.termbaseStructure.fields = @($fieldDefinitions);
    }
    
    $json = $body | ConvertTo-Json -Depth 10    
    return Invoke-SafeMethod {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json;
    }
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

function Update-Termbase 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseId,
        [string] $termbaseName,

        [string] $name,
        [string] $description,
        [string] $copyRight,
        [string[]] $languageCodes,
        [psobject[]] $fields
    )

    $termbase = Get-Termbase -accessKey $accessKey -termbaseId $termbaseId -termbaseName $termbaseName;
    if ($null -eq $termbase)
    {
        return;
    }

    $uri = "$baseUri/termbases/$($termbase.Id)";
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{}

    $termbaseStructure = @{}
    if ($name)
    {
        $body.name = $name
    }
    if ($description)
    {
        $body.description = $description;
    }
    if ($copyRight)
    {
        $body.copyright = $copyRight;
    }
    if ($languageCodes)
    {
        $termbaseStructure.languages = @($languageCodes | ForEach-Object { @{languageCode = $_} })
    }
    if ($fields)
    {
        $termbaseStructure.fields = $(Format-Fields -fields $fields)
    }

    if ($termbaseStructure)
    {
        $body.termbaseStructure = $termbaseStructure
    }

    $json = $body | ConvertTo-Json -Depth 10;
    Invoke-SafeMethod {
        $null = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $json;
        Write-Host "Termbase template updated successfully" -ForegroundColor Green;
    }
}

function Import-Termbase 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $pathToTermbase,

        [string] $termbaseId,
        [string] $termbaseName,

        [string] $duplicateEntriesStrategy = "overwrite",
        [bool] $strictImport = $true
        )

        $termbase = Get-Termbase -accessKey $accessKey -termbaseId $termbaseId -termbaseName $termbaseName;
        if ($null -eq $termbase)
        {
            return;
        }

        $uri = "$baseUri/termbases/$($termbase.Id)/imports?strictImport=$strictImport&duplicateEntriesStrategy=$duplicateEntriesStrategy";
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("X-LC-Tenant", $accessKey.tenant)
        $headers.Add("Content-Type", "multipart/form-data")
        $headers.Add("Accept", "application/json")
        $headers.Add("Authorization", $accessKey.token)

        $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
        $multipartFile = $pathToTermbase
        $FileStream = [System.IO.FileStream]::new($multipartFile, [System.IO.FileMode]::Open)
        $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
        $fileHeader.Name = "file"
        $fileHeader.FileName = $pathToTermbase
        $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
        $fileContent.Headers.ContentDisposition = $fileHeader
        $multipartContent.Add($fileContent)

        $body = $multipartContent

        $response = Invoke-SafeMethod {
            return Invoke-RestMethod -Uri $uri -Method 'POST' -Headers $headers -Body $body
        }

        if ($response)
        {
            $pollUri = "$baseUri/termbases/$($termbase.Id)/imports/$($response.Id)";
            $queueStatus = Invoke-SafeMethod {
                Invoke-RestMethod -uri $pollUri -Headers $headers
            }

        }

        while ($queueStatus)
        {
            Start-Sleep -Seconds 1;
            if ($queueStatus.Status -ne "queued")
            {
                Write-Host "Import Status $($queueStatus.Status)" -ForegroundColor Green;
                return;
            } 

            $queueStatus = Invoke-SafeMethod {
                Invoke-RestMethod -uri $pollUri -Headers $headers
            }
        }
}

function Export-Termbase
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseId,
        [string] $termbaseName,

        [Parameter(Mandatory=$true)]
        [string] $pathToExport,

        [string] $format = "tbx",
        [bool] $downloadCompressed = $false
    )

    
    $termbase = Get-Termbase -accessKey $accessKey -termbaseId $termbaseId -termbaseName $termbaseName;
    if ($null -eq $termbase)
    {
        return;
    }

    $uri = "$baseUri/termbases/$($termbase.Id)/exports";
    $body = [ordered]@{
        format = $format
        properties = @{
            downloadCompressed = $downloadCompressed
        }
    }
    $json = $body | ConvertTo-Json -Depth 5;

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant)
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)


    $response = Invoke-SafeMethod {
        Invoke-RestMethod -uri $uri -Method 'POST' -Headers $headers -Body $json
    } 

    if ($response)
    {
        $pollUri = "$baseUri/termbases/$($termbase.Id)/exports/$($response.Id)";
        $queueStatus = Invoke-SafeMethod {
            Invoke-RestMethod -uri $pollUri -Headers $headers
        }
    }

    while ($queueStatus)
    {
        Start-Sleep -Seconds 1;
        if ($queueStatus.Status -ne "queued")
        {
            return Invoke-SafeMethod {
                Invoke-RestMethod -Uri "$baseUri/termbases/$($termbase.Id)/exports/$($response.Id)/download" -Headers $headers -OutFile "$($pathToExport).$($format)";
            }
        } 

        $queueStatus = Invoke-SafeMethod {
            Invoke-RestMethod -uri $pollUri -Headers $headers
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
            -location $location -fields "fields=id,name,description,copyright,location,type,languages,fields,fields.name,fields.level,fields.dataType,fields.pickListValues,fields.allowCustomValues,fields.allowMultiple,fields.isMandatory" `
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
            -uriQuery "?fields=id,name,description,copyright,location,type,languages,fields.name,fields.level,fields.dataType,fields.pickListValues,fields.allowCustomValues,fields.allowMultiple,fields.isMandatory" `
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

function New-TermbaseTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $name,

        [string] $locationId,
        [string] $locationName,

        [string[]] $languageCodes,
        [psobject[]] $fields,

        [string] $termbaseTemplateId,
        [string] $termbaseTemplateName,
        [string] $pathToXDT,
        
        [bool] $inheritLanguages = $true,
        [string] $description,
        [string] $copyRight
    )

    $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    if ($null -eq $location)
    {
        return;
    }

    $uri = "$baseUri/termbase-templates"
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{
        name = $name
        location = $location.Id 
        description = $description
        copyright = $copyRight
    }

    $fieldDefinitions = @();
    $languages = @();
    if ($termbaseTemplateId -or $termbaseTemplateName)
    {
        $termbaseTemplate = Get-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId $termbaseTemplateId -termbaseTemplateName $termbaseTemplateName;
        if ($null -eq $termbaseTemplate)
        {
            return;
        }

        if ($inheritLanguages)
        {
            $languageCodes += $termbaseTemplate.languages | ForEach-Object {$_.languageCode}
        }

        $languageCodes = $languageCodes | Select-Object -Unique;
        $languages = @($languageCodes | ForEach-Object { @{languageCode = $_} });
        $fieldDefinitions += Format-Fields -fields $termbaseTemplate.Fields;
    }
    elseif ($pathToXDT)
    {
        $xdt = ConvertTo-TermbaseStructure -accessKey $accessKey -pathToXDT $pathToXDT;
        if ($null -eq $xdt)
        {
            return;
        }

        if ($inheritLanguages)
        {
            $languageCodes += $xdt.languages | ForEach-Object {$_.languageCode };
        }

        $languageCodes = $languageCodes | Select-Object -Unique;
        $languages = @($languageCodes | ForEach-Object { @{languageCode = $_} })
        $fieldDefinitions += Format-Fields -fields $($xdt.Fields)
    }
    else 
    {
        $languages = @($languageCodes | ForEach-Object { @{languageCode = $_} })
    }

    if ($fields)
    {
        $fieldDefinitions += Format-Fields -fields $fields;
    }

    if ($fieldDefinitions)
    {
        $body.fields = @($fieldDefinitions);
    }
    if ($languages)
    {
        $body.languages = @($languages);
    }
    
    $json = $body | ConvertTo-Json -Depth 10    
    return Invoke-SafeMethod {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json;
    }
}

function Update-TermbaseTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $termbaseTemplateId,
        [string] $termbaseTemplateName,

        [string] $name,
        [string] $description,
        [string] $copyRight,
        [string[]] $languageCodes
    )

    $termbaseTemplate = Get-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId $termbaseTemplateId -termbaseTemplateName $termbaseTemplateName;
    if ($null -eq $termbaseTemplate)
    {
        return;
    }

    $uri = "$baseUri/termbase-templates/$($termbaseTemplate.Id)";
    $headers = Get-RequestHeader -accessKey $accessKey;
    $body = [ordered]@{}

    if ($name)
    {
        $body.name = $name
    }
    if ($description)
    {
        $body.description = $description;
    }
    if ($copyRight)
    {
        $body.copyright = $copyRight;
    }
    if ($languageCodes)
    {
        $body.languages = @($languageCodes | ForEach-Object { @{languageCode = $_} })
    }
    if ($fields)
    {
        $body.fields = @(Format-Fields -fields $fields)
    }

    $json = $body | ConvertTo-Json -Depth 10;
    Invoke-SafeMethod {
        $null = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $json;
        Write-Host "Termbase template updated successfully" -ForegroundColor Green;
    }
}

function Get-Field 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $name,

        [Parameter(Mandatory=$true)]
        [string] $level,

        [Parameter(Mandatory=$true)]
        [string] $dataType,

        [string[]] $pickListValues,
        [bool] $allowCustomValues = $false,
        [bool] $allowMultiple = $true,
        [bool] $isMandatory = $false
    )

    return [ordered]@{
        name = $name
        level = $level 
        dataType = $dataType
        description = $description
        pickListValues = @($pickListValues)
        allowCustomValues = $allowCustomValues 
        allowMultiple = $allowMultiple
        isMandatory = $isMandatory
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

function Format-Fields 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $fields
    )

    $output = @() 

    foreach ($field in $fields)
    {
        $fieldModel = @{
            name = $field.name
            level = $field.level
            dataType = $field.dataType 
            allowCustomValues = $field.allowCustomValues
            allowMultiple = $field.allowMultiple
            isMandatory = $field.isMandatory
        }

        if ($field.dataType -eq "pickList")
        {
            $fieldModel.pickListValues = @($field.pickListValues)
        }

        $output += $fieldModel;
    }

    return $output;
}

function ConvertTo-TermbaseStructure 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [Parameter(Mandatory=$true)]
        [string] $pathToXDT
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-LC-Tenant", $accessKey.tenant) 
    $headers.Add("Content-Type", "multipart/form-data")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", $accessKey.token)

    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
    $multipartFile = $pathToXDT
    $FileStream = [System.IO.FileStream]::new($multipartFile, [System.IO.FileMode]::Open)
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileHeader.Name = "file"
    $fileHeader.FileName = $pathToXDT
    $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $multipartContent.Add($fileContent)

    $body = $multipartContent

    return Invoke-SafeMethod {
        Invoke-RestMethod 'https://lc-api.sdl.com/public-api/v1/termbase-templates/convert-xdt?fields=languages.languageCode, fields.name,fields.level, fields.dataType, fields.pickListValues,fields.allowCustomValues,fields.allowMultiple,fields.isMandatory' -Method 'POST' -Headers $headers -Body $body
    }
}

Export-ModuleMember Get-AllTermbases;
Export-ModuleMember Get-Termbase;
Export-ModuleMember New-Termbase;
Export-ModuleMember Remove-Termbase;
Export-ModuleMember Import-Termbase;
Export-ModuleMember Export-Termbase;
Export-ModuleMember Get-AllTermbaseTemplates;
Export-ModuleMember Get-TermbaseTemplate;
Export-ModuleMember Remove-TermbaseTemplate;
Export-ModuleMember New-TermbaseTemplate;
Export-ModuleMember Update-TermbaseTemplate;
Export-ModuleMember Get-Field;