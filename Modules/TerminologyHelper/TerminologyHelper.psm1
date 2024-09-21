$baseUri = "https://lc-api.sdl.com/public-api/v1"

<#
.SYNOPSIS
    Retrieves all the termbases from the specified location or strategy.

.DESCRIPTION
    The `Get-AllTermbases` function retrieves a list of all termbases available in the specified location or based on the provided strategy.
    You can optionally provide the location ID or name, and define a strategy to retrieve termbases from specific locations such as subfolders, parent folders, or a combination of both.
    
.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the termbases.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.
    
.PARAMETER locationId
    (Optional) The ID of the specific location from which to retrieve termbases. You can specify either a location ID or name, but not both.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve termbases. You can specify either a location ID or name, but not both.

.PARAMETER locationStrategy
    (Optional) The strategy to be used for fetching termbases in relation to the provided location.
    The available options are:
        - "location" (default): Retrieves termbases from the specified location.
        - "bloodline": Retrieves termbases from the specified location and its parent folders.
        - "lineage": Retrieves termbases from the specified location and its subfolders.
        - "genealogy": Retrieves termbases from both subfolders and parent folders of the specified location.

.OUTPUTS
    Returns a list of termbases containing fields such as ID, name, description, copyright, location, and structure.

.EXAMPLE
    # Example 1: Retrieve all termbases from the default location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTermbases -accessKey $accessKey

.EXAMPLE
    # Example 2: Retrieve termbases from a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTermbases -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 3: Retrieve termbases from a specific location using the lineage strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-AllTermbases -accessKey $accessKey -locationName "FolderA" -locationStrategy "lineage"
#>
    function Get-AllTermbases 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey,

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    $location = @{}
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/termbases" `
            -location $location -fields "fields=id,name,description,copyright,location,termbaseStructure" `
            -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific termbase by ID or name.

.DESCRIPTION
    The `Get-Termbase` function retrieves the details of a specific termbase based on the provided termbase ID or name.
    Either the `termbaseId` or `termbaseName` must be provided to retrieve the termbase information. 
    If both parameters are provided, the function will prioritize `termbaseId`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to query the termbase.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER termbaseId
    (Optional) The ID of the termbase to retrieve. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER termbaseName
    (Optional) The name of the termbase to retrieve. Either `termbaseId` or `termbaseName` must be provided.

.OUTPUTS
    Returns the specified termbase with fields such as ID, name, description, copyright, location, and structure.

.Example
    # Example 1: Retrieve a termbase by its ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Termbase -accessKey $accessKey -termbaseId "67890"

.EXAMPLE
    # Example 2: Retrieve a termbase by its name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Get-Termbase -accessKey $accessKey -termbaseName "MyTermbase"

#>
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

<#
.SYNOPSIS
    Creates a new termbase in the specified location with the provided structure and settings.

.DESCRIPTION
    The `New-Termbase` function creates a new termbase based on the provided parameters, including 
    **name**, **location**, **languages**, and **fields**. 

    You can specify **either** a termbase template (by ID or name) **or** provide a path to an XDT file 
    to define the termbase structure. **Both options cannot be used together.**

    Additionally, you can choose to inherit languages from the provided template or XDT file using the 
    `inheritLanguages` parameter. If additional languages are specified along with 
    `inheritLanguages = $true`, the termbase will be created for **all languages** (both inherited 
    and specified).

    You can also include additional fields, which will be combined with the fields from the termbase 
    template or XDT file.

    The termbase can be created in a specified location using either `locationId` or `locationName`. 
    If neither a termbase template nor an XDT file is provided, the structure will be defined by 
    the specified `languageCodes` and `fields`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to create the termbase.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER name
    (Mandatory) The name of the new termbase.

.PARAMETER locationId
    (Optional) The ID of the location where the termbase will be created.

.PARAMETER locationName
    (Optional) The name of the location where the termbase will be created.

.PARAMETER languageCodes
    (Optional) A list of language codes for the termbase (e.g., "en", "de"). If a termbase template or XDT 
    file is provided, languages can be inherited from those sources.

.PARAMETER fields
    (Optional) A list of field definitions for the termbase structure. These fields can be defined manually or inherited 
    from a template or XDT file. 

    You can retrieve field definitions using the `Get-Field` method. 

    - If fields are provided alongside a termbase template or XDT file, both sets of fields will be combined.
    - If fields are not provided but a termbase template or XDT file is used, only the fields from the template or XDT 
      file will be utilized.
    - If no fields are provided at all, the termbase will be created without any fields.

.PARAMETER termbaseTemplateId
    (Optional) The ID of a termbase template. The template defines the structure and languages of the termbase. 
    **Cannot be used together with `pathToXDT`.**

.PARAMETER termbaseTemplateName
    (Optional) The name of a termbase template. This parameter serves the same purpose as `termbaseTemplateId`. 
    **Cannot be used together with `pathToXDT`.**

.PARAMETER pathToXDT
    (Optional) A path to an XDT file that defines the termbase structure. **Cannot be used together with 
    `termbaseTemplateId` or `termbaseTemplateName`.**

.PARAMETER inheritLanguages
    (Optional) A boolean value indicating whether to inherit languages from the termbase template or XDT file. 
    Defaults to `$true`. If additional languages are specified in `languageCodes`, the termbase will include 
    both the inherited languages and the additional ones.

.PARAMETER description
    (Optional) A description for the termbase.

.PARAMETER copyRight
    (Optional) A copyright statement for the termbase.

.OUTPUTS
    Returns the created termbase with details such as its ID, name, description, and structure.

.EXAMPLE
    # Example 1: Create a new termbase using a termbase template and inherit languages
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Termbase -accessKey $accessKey -name "SampleTermbase" -termbaseTemplateId "12345" -inheritLanguages $true

.EXAMPLE
    # Example 2: Create a new termbase with additional languages
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Termbase -accessKey $accessKey -name "SampleTermbase" -languageCodes @("en-US", "de-DE") -fields @($fields) -locationName "RootLocation"

.EXAMPLE
    # Example 3: Create a new termbase using an XDT file
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-Termbase -accessKey $accessKey -name "SampleTermbase" -pathToXDT "C:\path\to\file.xdt" -inheritLanguages $true
#>

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

<#
.SYNOPSIS
    Removes a specified termbase from the system.

.DESCRIPTION
    The `Remove-Termbase` function deletes a termbase identified by either its ID or name. The function first 
    retrieves the termbase using the provided credentials, then constructs the URI for the deletion request 
    and invokes the delete method. If the termbase is successfully removed, a confirmation message is displayed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to delete the termbase.
   
    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER termbaseId
    (Optional) The ID of the termbase to be removed. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER termbaseName
    (Optional) The name of the termbase to be removed. Either `termbaseId` or `termbaseName` must be provided.

.OUTPUTS
    If the termbase is successfully removed, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Remove a termbase by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Termbase -accessKey $accessKey -termbaseId "12345"

.EXAMPLE
    # Example 2: Remove a termbase by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-Termbase -accessKey $accessKey -termbaseName "SampleTermbase"
#>
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

<#
.SYNOPSIS
    Updates an existing termbase with new details.

.DESCRIPTION
    The `Update-Termbase` function modifies the properties of a specified termbase. It retrieves the termbase 
    using the provided access key and either its ID or name. Users can update the name, description, copyright, 
    language codes, and fields associated with the termbase. Upon successful update, a confirmation message 
    is displayed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to update the termbase.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER termbaseId
    (Optional) The ID of the termbase to be updated. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER termbaseName
    (Optional) The name of the termbase to be updated. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER name
    (Optional) The new name for the termbase. If provided, the existing name will be replaced.

.PARAMETER description
    (Optional) The new description for the termbase. If provided, the existing description will be replaced.

.PARAMETER copyRight
    (Optional) The new copyright information for the termbase. If provided, the existing copyright will be replaced.

.PARAMETER languageCodes
    (Optional) An array of language codes to be associated with the termbase. If provided, these languages will 
    replace the existing ones.

.PARAMETER fields
    (Optional) An array of field definitions to update the termbase structure. If provided, these fields will 
    replace the existing fields.

    You can retrieve field definitions using the `Get-Field` method. 

.OUTPUTS
    If the termbase is successfully updated, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Update a termbase by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Termbase -accessKey $accessKey -termbaseId "12345" -name "Updated Termbase Name" -description "New description here."

.EXAMPLE
    # Example 2: Update a termbase by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-Termbase -accessKey $accessKey -termbaseName "SampleTermbase" -copyRight "Updated Copyright Info" -languageCodes @("en-US", "fr-FR")

#>
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

<#
.SYNOPSIS
    Imports entries into an existing termbase from a specified file.

.DESCRIPTION
    The `Import-Termbase` function allows users to import entries into a specified termbase. The function 
    accepts a file path to the termbase data and an access key for authentication. Users can specify 
    how to handle duplicate entries and whether to perform a strict import. The function polls for 
    import status and provides feedback on the import progress.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to import entries into the termbase.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.
    
.PARAMETER pathToTermbase
    (Mandatory) The file path to the termbase data file that is to be imported. 
    The file must be in either **XML** or **TBX** format.

.PARAMETER termbaseId
    (Optional) The ID of the termbase into which entries are to be imported. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER termbaseName
    (Optional) The name of the termbase into which entries are to be imported. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER duplicateEntriesStrategy
    (Optional) Specifies the strategy for handling duplicate entries during import. 
    Valid options are:
      - `overwrite`: Replace existing entries with the new data.
      - `ignore`: Skip the new entries that would create duplicates.
      - `merge`: Combine existing entries with the new data where applicable.
    The default value is `overwrite`.

.PARAMETER strictImport
    (Optional) A boolean value indicating whether to enforce strict validation during the import. The default is `$true`.

.OUTPUTS
    The function provides feedback on the import status to the console. If the import is successful, 
    a message indicating the status of the import will be displayed. If there is an error, it will 
    be logged in the console.

.EXAMPLE
    # Example 1: Import entries into a termbase by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Import-Termbase -accessKey $accessKey -pathToTermbase "C:\path\to\your\termbase.csv" -termbaseId "12345" -duplicateEntriesStrategy "merge"

.EXAMPLE
    # Example 2: Import entries into a termbase by name with strict import
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Import-Termbase -accessKey $accessKey -pathToTermbase "C:\path\to\your\termbase.csv" -termbaseName "SampleTermbase" -strictImport $false
#>
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

<#
.SYNOPSIS
    Exports entries from a specified termbase to a file.

.DESCRIPTION
    The `Export-Termbase` function allows users to export entries from an existing termbase into a specified file format. 
    The function requires an access key for authentication, as well as the ID or name of the termbase. 
    Users can specify the desired export format and whether the export file should be compressed.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to export entries from the termbase.

.PARAMETER termbaseId
    (Optional) The ID of the termbase to export. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER termbaseName
    (Optional) The name of the termbase to export. Either `termbaseId` or `termbaseName` must be provided.

.PARAMETER pathToExport
    (Mandatory) The file path where the exported termbase will be saved.

.PARAMETER format
    (Optional) The desired export format. Valid options are:
      - `tbx`: Export in the TBX (TermBase eXchange) format.
      - `xml`: Export in XML format.
    The default value is `tbx`.

.PARAMETER downloadCompressed
    (Optional) A boolean value indicating whether to download the exported file in a compressed format. The default is `$false`.

.OUTPUTS
    The function will download the exported termbase file to the specified location. If the export is successful, 
    the file will be saved with the specified format.

.EXAMPLE
    # Example 1: Export a termbase to TBX format
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Export-Termbase -accessKey $accessKey -termbaseId "12345" -pathToExport "C:\path\to\exportedTermbase" -format "tbx"

.EXAMPLE
    # Example 2: Export a termbase to XML format and download compressed
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Export-Termbase -accessKey $accessKey -termbaseName "SampleTermbase" -pathToExport "C:\path\to\exportedTermbase" -format "xml" -downloadCompressed $true

#>
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

<#
.SYNOPSIS
    Retrieves all termbase templates available for a specific location.

.DESCRIPTION
    The `Get-AllTermbaseTemplates` function fetches a list of termbase templates from the API. 
    Users can specify a location by either its ID or name. If neither is provided, the function will return 
    all termbase templates. The function also allows for filtering based on the location strategy.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to access termbase templates.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER locationId
    (Optional) The ID of the location from which to retrieve termbase templates.

.PARAMETER locationName
    (Optional) The name of the location from which to retrieve termbase templates.

.PARAMETER locationStrategy
    (Optional) The strategy to filter termbases based on their location. Valid options are:
      - `location`: Returns termbase templates in the specified location.
      - `bloodline`: Returns termbase templates in the specified folder and all parent folders.
      - `lineage`: Returns termbase templates in the specified folder and its subfolders.
      - `genealogy`: Returns termbase templates in sub and parent folders.
    The default value is `location`.

.OUTPUTS
    An array of termbase templates, including details such as ID, name, description, copyright information, 
    location, type, languages, and field definitions.

.EXAMPLE
    # Example 1: Retrieve all termbase templates in a specific location by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $templates = Get-AllTermbaseTemplates -accessKey $accessKey -locationId "12345"

.EXAMPLE
    # Example 2: Retrieve all termbase templates in a specific location by name with bloodline strategy
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $templates = Get-AllTermbaseTemplates -accessKey $accessKey -locationName "SampleLocation" -locationStrategy "bloodline"
#>
function Get-AllTermbaseTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [psobject] $accessKey, 

        [string] $locationId,
        [string] $locationName,
        [string] $locationStrategy = "location"
    )

    $location = @{};
    if ($locationId -or $locationName)
    {
        $location = Get-Location -accessKey $accessKey -locationId $locationId -locationName $locationName
    }

    $uri = Get-StringUri -root "$baseUri/termbase-templates" `
            -location $location -fields "fields=id,name,description,copyright,location,type,languages,fields,fields.name,fields.level,fields.dataType,fields.pickListValues,fields.allowCustomValues,fields.allowMultiple,fields.isMandatory" `
            -locationStrategy $locationStrategy;

    return Get-AllItems -accessKey $accessKey -uri $uri;
}

<#
.SYNOPSIS
    Retrieves a specific termbase template by either its ID or name.

.DESCRIPTION
    The `Get-TermbaseTemplate` function fetches details of a termbase template 
    from the API. Users must provide either the termbase template ID or name 
    to retrieve the corresponding template.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization to access termbase templates.


.PARAMETER termbaseTemplateId
    (Optional) The ID of the termbase template to be retrieved. If provided, 
    the function will use this to fetch the template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER termbaseTemplateName
    (Optional) The name of the termbase template to be retrieved. If provided, 
    the function will use this to fetch the template.

.OUTPUTS
    A termbase template object containing details such as ID, name, description, copyright information, 
    location, type, languages, and field definitions.

.EXAMPLE
    # Example 1: Retrieve a termbase template by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $template = Get-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId "template123"

.EXAMPLE
    # Example 2: Retrieve a termbase template by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    $template = Get-TermbaseTemplate -accessKey $accessKey -termbaseTemplateName "Sample Template"
#>
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

<#
.SYNOPSIS
    Removes a specified termbase template from the system.

.DESCRIPTION
    The `Remove-TermbaseTemplate` function deletes a termbase template using 
    its ID or name. The function first retrieves the specified termbase template 
    and, if found, proceeds to delete it from the API.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization 
    to access termbase templates.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER termbaseTemplateId
    (Optional) The ID of the termbase template to be removed. If provided, 
    the function will use this to identify the template.

.PARAMETER termbaseTemplateName
    (Optional) The name of the termbase template to be removed. If provided, 
    the function will use this to identify the template.

.OUTPUTS
    This function does not return any output. It will provide a message indicating 
    that the termbase template has been removed.

.EXAMPLE
    # Example 1: Remove a termbase template by ID
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId "template123"

.EXAMPLE
    # Example 2: Remove a termbase template by name
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Remove-TermbaseTemplate -accessKey $accessKey -termbaseTemplateName "Sample Template"
#>
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

<#
.SYNOPSIS
    Creates a new termbase template in the system.

.DESCRIPTION
    The `New-TermbaseTemplate` function creates a new termbase template based on the provided parameters, including 
    **name**, **location**, **languages**, and **fields**. 

    You can specify **either** an existing termbase template (by ID or name) **or** provide a path to an XDT file 
    to define the termbase structure. **Both options cannot be used together.**

    Additionally, you can choose to inherit languages from the specified template or XDT file using the 
    `inheritLanguages` parameter. If additional languages are specified along with 
    `inheritLanguages = $true`, the new termbase template will be created for **all languages** (both inherited 
    and specified).

    You can also include additional fields, which will be combined with the fields from the existing termbase 
    template or XDT file.

    The termbase template can be created in a specified location using either `locationId` or `locationName`. 
    If neither a termbase template nor an XDT file is provided, the structure will be defined by 
    the specified `languageCodes` and `fields`.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization 
    to create a new termbase template.

    To obtain this access key, you can use the `Get-AccessKey` method, which retrieves the necessary credentials for API access.

.PARAMETER name
    (Mandatory) The name of the new termbase termplate.

.PARAMETER locationId
    (Optional) The ID of the location where the termbase termplate will be created.

.PARAMETER locationName
    (Optional) The name of the location where the termbase termplate will be created.

.PARAMETER languageCodes
    (Optional) A list of language codes for the termbase termplate (e.g., "en", "de"). If a termbase template or XDT 
    file is provided, languages can be inherited from those sources.

.PARAMETER fields
    (Optional) A list of field definitions for the termbase structure. These fields can be defined manually or inherited 
    from a template or XDT file. 

    You can retrieve field definitions using the `Get-Field` method. 

    - If fields are provided alongside a termbase template or XDT file, both sets of fields will be combined.
    - If fields are not provided but a termbase template or XDT file is used, only the fields from the template or XDT 
      file will be utilized.
    - If no fields are provided at all, the termbase will be created without any fields.

.PARAMETER termbaseTemplateId
    (Optional) The ID of a termbase template. The template defines the structure and languages of the termbase. 
    **Cannot be used together with `pathToXDT`.**

.PARAMETER termbaseTemplateName
    (Optional) The name of a termbase template. This parameter serves the same purpose as `termbaseTemplateId`. 
    **Cannot be used together with `pathToXDT`.**

.PARAMETER pathToXDT
    (Optional) A path to an XDT file that defines the termbase structure. **Cannot be used together with 
    `termbaseTemplateId` or `termbaseTemplateName`.**

.PARAMETER inheritLanguages
    (Optional) A boolean value indicating whether to inherit languages from the termbase template or XDT file. 
    Defaults to `$true`. If additional languages are specified in `languageCodes`, the termbase will include 
    both the inherited languages and the additional ones.

.PARAMETER description
    (Optional) A description for the termbase.

.PARAMETER copyRight
    (Optional) A copyright statement for the termbase.

.OUTPUTS
    Returns the newly created termbase template object.

.EXAMPLE
    # Example 1: Create a new termbase template with a specified name and location
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-TermbaseTemplate -accessKey $accessKey -name "My New Template" -locationId "location123"

.EXAMPLE
    # Example 2: Create a new termbase template inheriting from an existing one
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    New-TermbaseTemplate -accessKey $accessKey -name "Inherit Template" -termbaseTemplateName "Existing Template"
#>
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

<#
.SYNOPSIS
    Updates an existing termbase template with new values.

.DESCRIPTION
    The `Update-TermbaseTemplate` function allows users to modify an existing termbase 
    template by updating its properties such as name, description, copyright, and 
    associated languages. If a termbase template with the specified ID or name does 
    not exist, the function will exit without making any changes.

.PARAMETER accessKey
    (Mandatory) The access key required for authentication and authorization 
    to update an existing termbase template.

.PARAMETER termbaseTemplateId
    (Optional) The ID of the termbase template to update.

.PARAMETER termbaseTemplateName
    (Optional) The name of the termbase template to update.

.PARAMETER name
    (Optional) The new name for the termbase template. If provided, the existing name will be replaced.

.PARAMETER description
    (Optional) The new description for the termbase template. If provided, the existing description will be replaced.

.PARAMETER copyRight
    (Optional) The new copyright information for the termbase template. If provided, the existing copyright will be replaced.

.PARAMETER languageCodes
    (Optional) An array of language codes to be associated with the termbase template. If provided, these languages will 
    replace the existing ones.

.PARAMETER fields
    (Optional) An array of field definitions to update the termbase template structure. If provided, these fields will 
    replace the existing fields.

    You can retrieve field definitions using the `Get-Field` method. 

.OUTPUTS
    If the termbase template is successfully updated, a confirmation message will be printed to the console. 
    No output will be returned from the function itself.

.EXAMPLE
    # Example 1: Update the name and description of an existing termbase template
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-TermbaseTemplate -accessKey $accessKey -termbaseTemplateId "template123" -name "Updated Template" -description "This is an updated template."

.EXAMPLE
    # Example 2: Update copyright and languages of a termbase template
    $accessKey = Get-AccessKey -id "yourClientID" -secret "yourClientSecret" -lcTenant "yourTenant"
    Update-TermbaseTemplate -accessKey $accessKey -termbaseTemplateName "Existing Template" -copyRight "© 2024 Company" -languageCodes @("en", "fr", "es")
#>
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
        [psobject[]] $fields,
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

<#
.SYNOPSIS
    Creates a field object for use in termbase or termbase template creation and updates.

.DESCRIPTION
    The `Get-Field` function constructs a field object that can be used to define 
    the structure of a termbase or termbase template. It includes properties such 
    as name, level, data type, pick list values, and restrictions on custom values, 
    multiple selections, and mandatory status. 

    Note: The pick list values should only be provided if the `dataType` is 
    specified as "picklist".

.PARAMETER name
    (Mandatory) The name of the field.

.PARAMETER level
    (Mandatory) Specifies the level of the field. 
    Acceptable values are "entry language" or "term".

.PARAMETER dataType
    (Mandatory) Defines the data type of the field. 
    Acceptable values are "text", "double", "date", "picklist", or "boolean".

.PARAMETER pickListValues
    (Optional) An array of values that can be selected if the `dataType` is 
    set to "picklist".

.PARAMETER allowCustomValues
    (Optional) Indicates whether custom values are allowed. 
    Default is `false`.

.PARAMETER allowMultiple
    (Optional) Indicates whether multiple values can be selected. 
    Default is `true`.

.PARAMETER isMandatory
    (Optional) Indicates whether the field is mandatory. 
    Default is `false`.

.OUTPUTS
    Returns an ordered hashtable representing the field object.

.EXAMPLE
    # Example 1: Create a text field for a termbase
    $textField = Get-Field -name "ExampleTextField" -level "entry" -dataType "text"

    # Example 2: Create a picklist field for a termbase with specific values
    $picklistField = Get-Field -name "ExamplePicklistField" -level "term" -dataType "picklist" -pickListValues @("Option1", "Option2", "Option3")
#>
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
Export-ModuleMember Update-Termbase;
Export-ModuleMember Import-Termbase;
Export-ModuleMember Export-Termbase;
Export-ModuleMember Get-AllTermbaseTemplates;
Export-ModuleMember Get-TermbaseTemplate;
Export-ModuleMember Remove-TermbaseTemplate;
Export-ModuleMember New-TermbaseTemplate;
Export-ModuleMember Update-TermbaseTemplate;
Export-ModuleMember Get-Field;